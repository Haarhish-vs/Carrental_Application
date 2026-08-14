// support.controller.js
const supportService = require('./support.service');

const getSupportDetails = async (req, res, next) => {
  try {
    const data = await supportService.getSupportDetails();
    return res.status(200).json({
      success: true,
      message: 'Support details and policies retrieved successfully',
      data
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getSupportDetails
};
