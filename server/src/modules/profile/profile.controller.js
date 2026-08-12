// profile.controller.js
const profileService = require('./profile.service');

const getProfile = async (req, res, next) => {
  try {
    const profile = await profileService.getProfile(req.user.id);
    return res.status(200).json({
      success: true,
      data: profile
    });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { fullName, phoneNumber, email } = req.body;
    const updatedProfile = await profileService.updateProfile(req.user.id, {
      fullName,
      phoneNumber,
      email
    });

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedProfile
    });
  } catch (error) {
    next(error);
  }
};

const uploadProfileImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided for profile upload'
      });
    }

    const updatedProfile = await profileService.uploadProfileImage(
      req.user.id,
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname
    );

    return res.status(200).json({
      success: true,
      message: 'Profile image uploaded successfully',
      data: updatedProfile
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  uploadProfileImage
};
