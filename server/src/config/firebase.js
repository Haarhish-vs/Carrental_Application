// firebase.js
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { supabase } = require('./supabase');

let isFirebaseInitialized = false;

function initFirebaseAdmin() {
  if (isFirebaseInitialized || admin.apps.length > 0) {
    isFirebaseInitialized = true;
    return;
  }

  console.log('[FCM] Initializing Firebase Admin SDK...');

  try {
    let serviceAccount = null;

    // 1. Check environment variable FIREBASE_SERVICE_ACCOUNT (JSON string or base64)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const rawEnv = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        const jsonString = rawEnv.startsWith('{')
          ? rawEnv
          : Buffer.from(rawEnv, 'base64').toString('utf8');
        serviceAccount = JSON.parse(jsonString);
        console.log('[FCM] Loaded Firebase service account from environment variable');
      } catch (e) {
        console.error('[FCM ERROR] Failed to parse FIREBASE_SERVICE_ACCOUNT env variable:', e.message);
      }
    }

    // 2. Local developer fallback file search if env not set
    if (!serviceAccount) {
      const devPathDownloads = 'C:\\Users\\HAARHISH\\Downloads\\carrentalapp-e833a-firebase-adminsdk-fbsvc-67c879c0f6.json';
      const devPathLocal = path.join(__dirname, 'firebase-service-account.json');

      if (fs.existsSync(devPathDownloads)) {
        serviceAccount = JSON.parse(fs.readFileSync(devPathDownloads, 'utf8'));
        console.log('[FCM] Loaded Firebase service account from Downloads directory');
      } else if (fs.existsSync(devPathLocal)) {
        serviceAccount = JSON.parse(fs.readFileSync(devPathLocal, 'utf8'));
        console.log('[FCM] Loaded Firebase service account from local config directory');
      }
    }

    if (serviceAccount) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      isFirebaseInitialized = true;
      console.log('[FCM] Firebase initialized successfully');
    } else {
      console.warn('[FCM WARNING] No Firebase service account credentials found. Set FIREBASE_SERVICE_ACCOUNT environment variable.');
    }
  } catch (err) {
    console.error('[FCM ERROR] Firebase Admin initialization failed:', err.message);
  }
}

// Call initialization
initFirebaseAdmin();

/**
 * Register an FCM token for a user (Supports multiple devices per user).
 */
async function registerFcmToken(userId, fcmToken, deviceInfo = '') {
  if (!userId || !fcmToken) {
    throw new Error('User ID and FCM token are required');
  }

  console.log(`[FCM] Registering token for user: ${userId}`);

  try {
    const { data, error } = await supabase
      .from('user_fcm_tokens')
      .upsert(
        {
          user_id: userId,
          fcm_token: fcmToken,
          device_info: deviceInfo,
          updated_at: new Date().toISOString()
        },
        { onConflict: 'fcm_token' }
      )
      .select();

    if (error) {
      console.error(`[FCM ERROR] Token registration failed: ${error.message}`);
      throw error;
    }

    console.log(`[FCM] Token synchronized with backend successfully for user: ${userId}`);
    return data;
  } catch (err) {
    console.error(`[FCM ERROR] Token registration failed for user ${userId}:`, err.message);
    throw err;
  }
}

/**
 * Unregister an FCM token on logout.
 */
async function unregisterFcmToken(userId, fcmToken) {
  if (!userId || !fcmToken) return;

  console.log(`[FCM] Unregistering token for user: ${userId}`);

  try {
    const { error } = await supabase
      .from('user_fcm_tokens')
      .delete()
      .eq('user_id', userId)
      .eq('fcm_token', fcmToken);

    if (error) {
      console.error(`[FCM ERROR] Token disassociation failed: ${error.message}`);
    } else {
      console.log(`[FCM] Token removed successfully for user: ${userId}`);
    }
  } catch (err) {
    console.error(`[FCM ERROR] Token unregistration error:`, err.message);
  }
}

/**
 * Send push notification to a user's registered devices.
 * Removes expired/invalid FCM tokens automatically.
 */
async function sendPushNotificationToUser(userId, { title, body, data = {} }) {
  if (!userId) return { success: false, reason: 'Missing userId' };

  console.log(`[NOTIFICATION] Preparing notification for user: ${userId}`);

  try {
    // 1. Fetch user's registered FCM tokens
    const { data: tokenRecords, error: fetchError } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .eq('user_id', userId);

    if (fetchError || !tokenRecords || tokenRecords.length === 0) {
      console.log(`[NOTIFICATION] No active FCM tokens found for user: ${userId}`);
      return { success: false, reason: 'No tokens found' };
    }

    const tokens = tokenRecords.map(r => r.fcm_token).filter(Boolean);
    if (tokens.length === 0) return { success: false, reason: 'Empty tokens list' };

    return await sendMulticastNotification(tokens, { title, body, data }, userId);
  } catch (err) {
    console.error(`[FCM ERROR] Notification delivery failed for user ${userId}:`, err.message);
    return { success: false, error: err.message };
  }
}

/**
 * Send push notification to multiple user IDs.
 */
async function sendPushNotificationToUsers(userIds, { title, body, data = {} }) {
  if (!Array.isArray(userIds) || userIds.length === 0) return;

  console.log(`[NOTIFICATION] Sending multicast notification to users:`, userIds);
  const results = [];

  for (const uid of userIds) {
    if (uid) {
      const res = await sendPushNotificationToUser(uid, { title, body, data });
      results.push({ userId: uid, ...res });
    }
  }

  return results;
}

/**
 * Send multicast notification via Firebase Admin SDK.
 */
async function sendMulticastNotification(tokens, { title, body, data = {} }, targetUserId = '') {
  if (!admin.apps.length || !isFirebaseInitialized) {
    console.warn(`[FCM WARNING] Firebase Admin not initialized. Skipping push notification.`);
    return { success: false, reason: 'Firebase Admin uninitialized' };
  }

  // Ensure all data values are stringified (FCM requirement for data payload)
  const stringifiedData = {};
  for (const [key, value] of Object.entries(data)) {
    stringifiedData[key] = String(value);
  }

  const message = {
    notification: {
      title,
      body
    },
    data: stringifiedData,
    tokens
  };

  console.log(`[NOTIFICATION] Sending notification to target: ${targetUserId || 'users'}`);
  console.log(`[NOTIFICATION] FCM request sent`);

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`[NOTIFICATION] Notification sent successfully. Success: ${response.successCount}, Failure: ${response.failureCount}`);

    // Handle invalid/stale tokens
    const staleTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        console.error(`[FCM ERROR] Delivery failed for token index ${idx}: ${resp.error?.message}`);
        if (
          errorCode === 'messaging/invalid-registration-token' ||
          errorCode === 'messaging/registration-token-not-registered'
        ) {
          staleTokens.push(tokens[idx]);
          console.log(`[FCM ERROR] Invalid/stale token detected: ${tokens[idx].substring(0, 15)}...`);
        }
      }
    });

    // Automatically remove stale tokens from database
    if (staleTokens.length > 0) {
      console.log(`[FCM] Pruning ${staleTokens.length} stale FCM token(s)...`);
      await supabase
        .from('user_fcm_tokens')
        .delete()
        .in('fcm_token', staleTokens);
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount
    };
  } catch (err) {
    console.error(`[FCM ERROR] Notification delivery failed: ${err.message}`);
    return { success: false, error: err.message };
  }
}

module.exports = {
  initFirebaseAdmin,
  registerFcmToken,
  unregisterFcmToken,
  sendPushNotificationToUser,
  sendPushNotificationToUsers
};
