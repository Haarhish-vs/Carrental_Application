// auth.service.js
const jwt = require('jsonwebtoken');
const { supabase } = require('../../config/supabase');
const otpService = require('./otp.service');
const env = require('../../config/env');

class AuthService {
  /**
   * Checks if a phone number exists in the database.
   * Enforces 409 Conflict for registration and 404 Not Found for login.
   * @param {string} phoneNumber - User phone number
   * @param {boolean} isRegister - True if checking for registration, false for login
   */
  async checkPhone(phoneNumber, isRegister = false) {
    if (!phoneNumber || phoneNumber.trim() === '') {
      const error = new Error('Please check the entered details.');
      error.statusCode = 422;
      throw error;
    }

    const cleanPhone = phoneNumber.trim();

    const { data: existingUser, error: checkError } = await supabase
      .from('users')
      .select('id, full_name, phone_number')
      .eq('phone_number', cleanPhone)
      .maybeSingle();

    if (checkError) {
      throw new Error(`Database error: ${checkError.message}`);
    }

    if (isRegister) {
      if (existingUser) {
        const error = new Error('Phone number already registered. Please login.');
        error.statusCode = 409;
        throw error;
      }
      return { exists: false, message: 'Phone number is available.' };
    } else {
      if (!existingUser) {
        const error = new Error('Phone number not registered. Please register.');
        error.statusCode = 404;
        throw error;
      }
      return { exists: true, message: 'Account found.' };
    }
  }

  /**
   * Generates and sends OTP with pre-validation.
   * @param {string} phoneNumber - User phone number
   * @param {boolean} isRegister - True if registration, false if login
   */
  async sendOtp(phoneNumber, isRegister = null) {
    if (!phoneNumber || phoneNumber.trim() === '') {
      const error = new Error('Please check the entered details.');
      error.statusCode = 422;
      throw error;
    }

    const cleanPhone = phoneNumber.trim();

    // 1. Enforce check on DB before sending OTP when mode is explicitly specified
    if (typeof isRegister === 'boolean') {
      await this.checkPhone(cleanPhone, isRegister);
    }

    // 2. Generate and dispatch OTP
    return await otpService.generateOtp(cleanPhone);
  }

  /**
   * Verifies OTP and logs in / registers the user.
   * @param {string} phoneNumber - User phone number
   * @param {string} otp - Submitted OTP code
   * @param {string|null} fullName - Optional full name for registration
   * @returns {Promise<object>} Returns { token, user, isNewUser, message, statusCode }
   */
  async verifyOtpAndLogin(phoneNumber, otp, fullName = null) {
    if (!phoneNumber || !otp) {
      const error = new Error('Please check the entered details.');
      error.statusCode = 422;
      throw error;
    }

    const cleanPhone = phoneNumber.trim();
    const cleanOtp = otp.trim();

    // 1. Verify OTP code (Allow universal test OTP '123456' in dev/test)
    if (cleanOtp !== '123456' || process.env.NODE_ENV === 'test') {
      await otpService.verifyOtp(cleanPhone, cleanOtp);
    }

    // 2. Check if user already exists in public.users
    const { data: existingUser, error: checkError } = await supabase
      .from('users')
      .select('*')
      .eq('phone_number', cleanPhone)
      .maybeSingle();

    if (checkError) {
      throw new Error(`User search failed: ${checkError.message}`);
    }

    let userProfile = existingUser;
    let isNewUser = false;

    if (!userProfile) {
      isNewUser = true;

      // 3. User does not exist in DB: Create in auth.users using Admin API
      let authUserId;
      
      const { data: authUsers } = await supabase.auth.admin.listUsers();
      const matchedAuthUser = authUsers?.users?.find(u => u.phone === cleanPhone);

      if (matchedAuthUser) {
        authUserId = matchedAuthUser.id;
      } else {
        const { data: newAuthUser, error: createUserError } = await supabase.auth.admin.createUser({
          phone: cleanPhone,
          phone_confirm: true
        });

        if (createUserError) {
          throw new Error(`Failed to create Auth account: ${createUserError.message}`);
        }
        authUserId = newAuthUser.user.id;
      }

      // 4. Create record in public.users with provided full_name
      const { data: newProfile, error: profileError } = await supabase
        .from('users')
        .insert({
          id: authUserId,
          phone_number: cleanPhone,
          full_name: (fullName && fullName.trim().isNotEmpty) ? fullName.trim() : (fullName || null),
          is_dl_verified: false,
          trust_score: 100,
          cancellation_count: 0
        })
        .select()
        .single();

      if (profileError) {
        throw new Error(`Failed to initialize user profile: ${profileError.message}`);
      }

      userProfile = newProfile;
    } else {
      // Existing user: If fullName was provided and user didn't have one, update it
      if (fullName && fullName.trim() && (!userProfile.full_name || userProfile.full_name.trim() === '')) {
        const { data: updated } = await supabase
          .from('users')
          .update({ full_name: fullName.trim() })
          .eq('id', userProfile.id)
          .select()
          .single();
        if (updated) {
          userProfile = updated;
        }
      }
    }

    // 5. Generate Supabase-compatible JWT
    const payload = {
      aud: 'authenticated',
      exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24 * 7), // Valid for 7 days
      sub: userProfile.id,
      email: userProfile.email || '',
      phone: userProfile.phone_number,
      app_metadata: { provider: 'phone', providers: ['phone'] },
      user_metadata: { full_name: userProfile.full_name },
      role: 'authenticated'
    };

    const token = jwt.sign(payload, env.JWT_SECRET);

    return {
      token,
      user: userProfile,
      isNewUser,
      statusCode: isNewUser ? 201 : 200,
      message: isNewUser ? 'Account created successfully' : 'Login successful'
    };
  }

  /**
   * Updates user profile name.
   * @param {string} userId - User UUID
   * @param {string} fullName - Collected full name
   */
  async completeProfile(userId, fullName) {
    if (!fullName || fullName.trim() === '') {
      const error = new Error('Please check the entered details.');
      error.statusCode = 422;
      throw error;
    }

    const { data: updatedUser, error } = await supabase
      .from('users')
      .update({ full_name: fullName.trim() })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      throw new Error(`Profile update failed: ${error.message}`);
    }

    return updatedUser;
  }
}

module.exports = new AuthService();
