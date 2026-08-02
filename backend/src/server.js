require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const connectDB = require('./config/db');

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  },
});

io.on('connection', (socket) => {
  // Client connected
});

// Attach io to express app so routes can broadcast
app.set('io', io);
app.use((req, res, next) => {
  req.io = io;
  next();
});

const startServer = async () => {
  try {
    await connectDB();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`FoodBillX Backend engine with Socket.IO running on port ${PORT} (Listening on 0.0.0.0)`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();