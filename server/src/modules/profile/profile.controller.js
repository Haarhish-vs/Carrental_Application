const cloudinary = require('cloudinary').v2;
const profileService = require('./profile.service');
const env = require('../../config/env');

cloudinary.config({ cloud_name: env.CLOUDINARY_CLOUD_NAME, api_key: env.CLOUDINARY_API_KEY, api_secret: env.CLOUDINARY_API_SECRET });

exports.getProfile = async (req, res, next) => { try { res.json({ success: true, data: await profileService.getProfile(req.user.id) }); } catch (error) { next(error); } };
exports.updateProfile = async (req, res, next) => { try { res.json({ success: true, data: { user: await profileService.updateProfile(req.user.id, req.body) } }); } catch (error) { next(error); } };
exports.becomeOwner = async (req, res, next) => { try { await profileService.becomeOwner(req.user.id); res.status(201).json({ success: true, message: 'Hosting capability enabled' }); } catch (error) { next(error); } };
exports.uploadPhoto = async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Profile photo is required' });
    const upload = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream({ folder: 'car-rental/profiles', resource_type: 'image' }, (error, result) => error ? reject(error) : resolve(result));
      stream.end(req.file.buffer);
    });
    const user = await profileService.setPhoto(req.user.id, upload.secure_url);
    res.json({ success: true, data: { user } });
  } catch (error) { next(error); }
};
exports.submitRating = async (req, res, next) => { try { await profileService.submitRating(req.user.id, req.body.bookingId, Number(req.body.rating)); res.status(201).json({ success: true, message: 'Rating saved' }); } catch (error) { next(error); } };
