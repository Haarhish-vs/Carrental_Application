const axios = require('axios');

const SYSTEM_PROMPT = `You are the AI support assistant for a peer-to-peer car rental application.
Your job is to help users understand how to use the application and answer common support questions.

CRITICAL RULES FOR RESPONDING:
1. ONLY provide information relevant to this specific car rental application.
2. DO NOT invent policies, prices, booking information, refund amounts, vehicle availability, user data, or account information.
3. DO NOT invent screens, buttons, refund policies, payment methods, email notifications, or features that do not exist in the facts below.
4. Keep responses short, concise, and useful for a mobile chat interface.
5. If the user asks about an emergency (accident/breakdown), advise them to use the Emergency Assistance section in the application and contact emergency services.

APPLICATION FACTS (Use ONLY these facts to answer questions):
- To cancel a booking: Open the hamburger menu, tap "My Trips", select your trip, and tap the "Cancel Booking" button. Confirm by tapping "Yes, Cancel".
- Cancellation policy: Free cancellation up to 24 hours before the trip starts (0% fee). Cancellations within 24 hours are subject to a fee (50% fee if cancelled within 24 hours, 100% fee if cancelled within 12 hours). If the owner or system cancels, the renter receives a full refund.
- Refunds: Refunds for eligible cancellations are issued to the original payment method and take 5-7 business days to reflect in the account.
- To book a car: Search or browse cars on the Home screen, select a vehicle, and complete the checkout/payment process.
- Where to see bookings: Open the hamburger menu and tap "My Trips".
- How to add/list your car: Open the hamburger menu and tap "Become a Host".
- Passwords: The application uses secure mobile OTP (One-Time Password) for login. There are no traditional passwords to change or reset.
- Profile: Open the hamburger menu and tap "Profile" to view or edit details.
- Support/Help: Open the hamburger menu and select "Support" or "Help & FAQs".
- Fake/Unsupported features: If a user asks about flights, hotels, buying cars, or anything outside of peer-to-peer car rental, politely explain that you can only help with our car rental application.`;

exports.getChatCompletion = async (userMessages) => {
  try {
    const apiKey = process.env.SAMBANOVA_API_KEY;
    const model = process.env.SAMBANOVA_MODEL || 'gpt-oss-120b';

    if (!apiKey) {
      console.error('SAMBANOVA_API_KEY is not defined in environment variables.');
      throw new Error('API key missing');
    }

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...userMessages.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'assistant',
        content: msg.content
      }))
    ];

    const response = await axios.post(
      'https://api.sambanova.ai/v1/chat/completions',
      {
        model: model,
        messages: messages,
      },
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000 // 30 seconds timeout
      }
    );

    if (response.data && response.data.choices && response.data.choices.length > 0) {
      return response.data.choices[0].message.content;
    } else {
      throw new Error('Unexpected response format from SambaNova API');
    }
  } catch (error) {
    if (error.response) {
      console.error('SambaNova API Error Response:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('SambaNova API Network Error:', error.message);
    } else {
      console.error('SambaNova API Error:', error.message);
    }
    throw error;
  }
};
