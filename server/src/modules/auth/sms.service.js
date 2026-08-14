// sms.service.js
const axios = require('axios');
const env = require('../../config/env');

class SmsService {
  /**
   * Sends an SMS via Twilio API if credentials are provided in .env,
   * otherwise logs to server console.
   * @param {string} phone - Target phone number in E.164 format (e.g. +919876543210)
   * @param {string} message - Message body text
   * @returns {Promise<boolean>} True if successful
   */
  async sendSms(phone, message) {
    const accountSid = env.TWILIO_ACCOUNT_SID;
    const authToken = env.TWILIO_AUTH_TOKEN;
    const twilioPhone = env.TWILIO_PHONE_NUMBER;

    // Always log OTP to server logs for debugging and local test mode
    console.log(`📡 [SMS Service] Target: ${phone} | Content: "${message}"`);

    // If Twilio credentials are configured in .env, dispatch real SMS via Twilio API
    if (accountSid && authToken && twilioPhone) {
      try {
        const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
        const authHeader = 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64');

        const params = new URLSearchParams();
        params.append('To', phone);
        params.append('From', twilioPhone);
        params.append('Body', message);

        const response = await axios.post(url, params.toString(), {
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded'
          }
        });

        console.log(`✅ [Twilio SMS] Message queued/sent successfully (SID: ${response.data.sid})`);
        return true;
      } catch (err) {
        const twilioErr = err.response?.data?.message || err.message;
        console.error(`⚠️ [Twilio SMS] Error sending SMS via Twilio: ${twilioErr}`);
        // Return true so authentication flow does not crash if Twilio trial limits occur
        return false;
      }
    } else {
      console.log(`ℹ️ [SMS Service] Twilio keys unconfigured in .env. SMS logged to console.`);
      return true;
    }
  }
}

module.exports = new SmsService();
