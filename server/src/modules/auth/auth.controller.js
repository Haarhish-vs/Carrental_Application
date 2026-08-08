// auth.controller.js
const authService = require('./auth.service');

const sendOtp = async (req, res, next) => {
  try {
    const { phoneNumber, isRegister } = req.body;
    const rawOtp = await authService.sendOtp(phoneNumber, isRegister);
    
    // In development or test, we return the raw OTP in response so client tests can use it
    const responseData = {};
    if (process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development') {
      responseData.otp = rawOtp;
    }

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      data: responseData
    });
  } catch (error) {
    next(error);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const { phoneNumber, otp } = req.body;
    const result = await authService.verifyOtpAndLogin(phoneNumber, otp);

    return res.status(200).json({
      success: true,
      message: 'Verification successful',
      data: {
        token: result.token,
        user: result.user,
        isNewUser: result.isNewUser
      }
    });
  } catch (error) {
    next(error);
  }
};

const completeProfile = async (req, res, next) => {
  try {
    const { fullName } = req.body;
    const updatedUser = await authService.completeProfile(req.user.id, fullName);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedUser
      }
    });
  } catch (error) {
    next(error);
  }
};

const getMe = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      data: {
        user: req.user
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendOtp,
  verifyOtp,
  completeProfile,
  getMe
};
