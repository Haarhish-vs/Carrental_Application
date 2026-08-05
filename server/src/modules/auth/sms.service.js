// sms.service.js
const env = require('../../config/env');

/**
 * Abstract SMS Service interface to send messages.
 * Implement Twilio, MSG91, AWS SNS, etc. by modifying this file.
 */
class SmsService {
  constructor() {
    this.apiKey = env.SMS_PROVIDER_API_KEY;
  }

  /**
   * Send an SMS to a phone number.
   * @param {string} phone - Target phone number in E.164 format (e.g. +1234567890)
   * @param {string} message - Message body content
   * @returns {Promise<boolean>} True if successful
   */
  async sendSms(phone, message) {
    // Stub logging to console for testing/development purposes
    if (process.env.NODE_ENV !== 'test') {
      console.log(`[SMS Service] [To: ${phone}] Content: "${message}"`);
    }
    
    // Example Twilio integration placeholder:
    /*
    try {
      const client = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
      await client.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phone
      });
      return true;
    } catch (err) {
      console.error('Twilio SMS delivery failed:', err);
      return false;
    }
    */
    
    return true;
  }
}

module.exports = new SmsService();
