// auth.controller.js
const authService = require('./auth.service');

const checkPhone = async (req, res, next) => {
  try {
    const { phoneNumber, isRegister } = req.body;
    const result = await authService.checkPhone(phoneNumber, isRegister);

    return res.status(200).json({
      success: true,
      message: result.message,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

const sendOtp = async (req, res, next) => {
  try {
    const { phoneNumber, isRegister } = req.body;
    const rawOtp = await authService.sendOtp(phoneNumber, isRegister);
    
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
    const { phoneNumber, otp, fullName } = req.body;
    const result = await authService.verifyOtpAndLogin(phoneNumber, otp, fullName);

    return res.status(result.statusCode || 200).json({
      success: true,
      message: result.message,
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
      message: 'User session verified',
      data: {
        user: req.user
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  checkPhone,
  sendOtp,
  verifyOtp,
  completeProfile,
  getMe
};
