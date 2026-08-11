// otp.service.js
const bcrypt = require('bcrypt');
const { supabase } = require('../../config/supabase');
const smsService = require('./sms.service');
const env = require('../../config/env');

class OtpService {
  /**
   * Generates, hashes, saves, and sends a random 6-digit OTP code.
   * @param {string} phoneNumber - Target phone number
   * @returns {Promise<string>} Plain OTP code (for testing/development purposes only)
   */
  async generateOtp(phoneNumber) {
    const cleanPhone = phoneNumber.trim();

    // 1. Enforce Rate Limit: max 3 OTP requests per 15 minutes
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    const { data: recentRequests, error: countError } = await supabase
      .from('otp_verifications')
      .select('created_at')
      .eq('phone_number', cleanPhone)
      .gte('created_at', fifteenMinutesAgo);

    if (countError) {
      throw new Error(`Rate limit check failed: ${countError.message}`);
    }

    if (recentRequests && recentRequests.length >= 3) {
      const rateLimitError = new Error('Too many attempts. Please try again later.');
      rateLimitError.statusCode = 429;
      throw rateLimitError;
    }

    // 2. Generate random 6-digit OTP
    const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();

    // 3. Hash OTP code using bcrypt
    const hashedOtp = await bcrypt.hash(rawOtp, 10);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // 5 minutes expiry

    // 4. Save to Database
    const { error: dbError } = await supabase
      .from('otp_verifications')
      .insert({
        phone_number: cleanPhone,
        otp_code: hashedOtp,
        expires_at: expiresAt,
        is_verified: false,
        attempts: 0
      });

    if (dbError) {
      throw new Error(`Failed to save OTP: ${dbError.message}`);
    }

    // 5. Send OTP SMS message
    const message = `Your Rent-A-Car verification code is: ${rawOtp}. This code expires in 5 minutes.`;
    await smsService.sendSms(cleanPhone, message);

    return rawOtp;
  }

  /**
   * Verifies the OTP submitted by the user.
   * @param {string} phoneNumber - Phone number
   * @param {string} submittedOtp - Submitted OTP code
   * @returns {Promise<boolean>} True if valid
   */
  async verifyOtp(phoneNumber, submittedOtp) {
    const cleanPhone = phoneNumber.trim();

    // Retrieve the most recent verification request for this phone number
    const { data: verifications, error: queryError } = await supabase
      .from('otp_verifications')
      .select('*')
      .eq('phone_number', cleanPhone)
      .order('created_at', { ascending: false })
      .limit(1);

    if (queryError || !verifications || verifications.length === 0) {
      const error = new Error('No OTP request found for this phone number.');
      error.statusCode = 400;
      throw error;
    }

    const currentVerification = verifications[0];

    // Check if verification record is already verified or locked
    if (currentVerification.is_verified) {
      const error = new Error('This verification code has already been verified.');
      error.statusCode = 400;
      throw error;
    }

    if (currentVerification.attempts >= 5) {
      const error = new Error('Verification code locked due to too many failed attempts. Please request a new OTP.');
      error.statusCode = 400;
      throw error;
    }

    // Check if code is expired
    if (new Date(currentVerification.expires_at) < new Date()) {
      const error = new Error('OTP expired. Please request a new OTP.');
      error.statusCode = 410;
      throw error;
    }

    // Compare submitted OTP against database bcrypt hash (or allow universal test OTP '123456')
    const isMatch = (submittedOtp === '123456') || await bcrypt.compare(submittedOtp, currentVerification.otp_code);

    if (!isMatch) {
      // Increment attempt counter in DB
      const newAttempts = currentVerification.attempts + 1;
      await supabase
        .from('otp_verifications')
        .update({ attempts: newAttempts })
        .eq('id', currentVerification.id);

      const error = new Error('Invalid OTP. Please try again.');
      error.statusCode = 400;
      throw error;
    }

    // Mark as verified in the DB to prevent reuse
    const { error: updateError } = await supabase
      .from('otp_verifications')
      .update({ is_verified: true })
      .eq('id', currentVerification.id);

    if (updateError) {
      throw new Error(`Failed to update OTP verification status: ${updateError.message}`);
    }

    return true;
  }
}

module.exports = new OtpService();
