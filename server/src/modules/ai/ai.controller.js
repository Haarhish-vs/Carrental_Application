const aiService = require('./ai.service');

exports.handleChat = async (req, res, next) => {
  try {
    const { messages } = req.body;

    // Validate request
    if (!messages) {
      return res.status(400).json({ success: false, message: 'Messages are required.' });
    }
    
    if (!Array.isArray(messages)) {
      return res.status(400).json({ success: false, message: 'Messages must be an array.' });
    }

    if (messages.length === 0) {
      return res.status(400).json({ success: false, message: 'Messages array cannot be empty.' });
    }

    // Call service to get AI response
    const assistantMessage = await aiService.getChatCompletion(messages);

    return res.status(200).json({
      success: true,
      message: assistantMessage
    });
  } catch (error) {
    console.error('AI Chat Error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'AI service is temporarily unavailable.'
    });
  }
};
