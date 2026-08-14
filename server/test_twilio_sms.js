const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const smsService = require('./src/modules/auth/sms.service');

async function testTwilioSMS() {
  console.log("🧪 Testing Twilio SMS sending...");
  console.log("Account SID:", process.env.TWILIO_ACCOUNT_SID);
  console.log("Twilio Phone:", process.env.TWILIO_PHONE_NUMBER);

  // Test phone number (user's phone or test number)
  const targetPhone = "+918825430047"; 
  const result = await smsService.sendSms(targetPhone, "Your Rent-A-Car verification code is: 123456. Expires in 5 mins.");
  console.log("Send SMS result:", result);
}

testTwilioSMS();
