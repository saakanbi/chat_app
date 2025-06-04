
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Serve index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Socket.io connection handling
io.on('connection', socket => {
  console.log('User connected');
  
  // Handle chat messages
  socket.on('chat message', (msg) => {
    io.emit('chat message', msg);
  });
  
  // Handle user joining
  socket.on('user joined', (username) => {
    socket.username = username;
    io.emit('user joined', username);
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('User disconnected');
    if (socket.username) {
      io.emit('user left', socket.username);
    }
  });
});

// Use environment port or default to 3000
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Chat app running on port ${PORT}`));
