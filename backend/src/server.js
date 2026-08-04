const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`[Server] Booking Module Backend running on port ${PORT}`);
});
