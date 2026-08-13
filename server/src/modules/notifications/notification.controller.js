// notification.controller.js
const { registerFcmToken, unregisterFcmToken } = require('../../config/firebase');

class NotificationController {
  /**
   * POST /api/notifications/register-token
   * Associate FCM token with authenticated user.
   */
  async registerToken(req, res) {
    try {
      const userId = req.user.id;
      const { fcmToken, deviceInfo } = req.body;

      if (!fcmToken) {
        return res.status(400).json({ error: 'fcmToken is required' });
      }

      await registerFcmToken(userId, fcmToken, deviceInfo);
      return res.status(200).json({
        message: 'FCM token registered successfully',
        userId
      });
    } catch (err) {
      console.error('[FCM ERROR] Token registration failed:', err.message);
      return res.status(500).json({ error: 'Failed to register FCM token' });
    }
  }

  /**
   * POST /api/notifications/unregister-token
   * Disassociate FCM token on logout.
   */
  async unregisterToken(req, res) {
    try {
      const userId = req.user.id;
      const { fcmToken } = req.body;

      if (fcmToken) {
        await unregisterFcmToken(userId, fcmToken);
      }

      return res.status(200).json({
        message: 'FCM token unregistered successfully'
      });
    } catch (err) {
      console.error('[FCM ERROR] Token unregistration failed:', err.message);
      return res.status(500).json({ error: 'Failed to unregister FCM token' });
    }
  }
}

module.exports = new NotificationController();
