const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const { v4: uuidv4 } = require('uuid'); // npm install uuid

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Main UI
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Track users and messages
const users = new Map(); // socket.id => username
const messages = new Map(); // messageId => { senderSocketId, seenBy: Set }

io.on('connection', socket => {
  console.log('🔌 User connected:', socket.id);

  socket.on('user joined', username => {
    socket.username = username;
    users.set(socket.id, username);
    io.emit('user joined', username);
  });

  socket.on('chat message', msg => {
    const messageId = uuidv4(); // generate a unique ID
    const enrichedMsg = {
      ...msg,
      id: messageId,
      time: msg.time || new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    messages.set(messageId, { senderSocketId: socket.id, seenBy: new Set() });
    io.emit('chat message', enrichedMsg);
  });

  socket.on('message seen', messageId => {
    const entry = messages.get(messageId);
    if (entry && socket.id !== entry.senderSocketId) {
      entry.seenBy.add(socket.id);
      const senderSocket = io.sockets.sockets.get(entry.senderSocketId);
      if (senderSocket) {
        senderSocket.emit('message seen', { messageId });
      }
    }
  });

  socket.on('typing', () => {
    if (socket.username) {
      socket.broadcast.emit('user typing', socket.username);
    }
  });

  socket.on('stop typing', () => {
    if (socket.username) {
      socket.broadcast.emit('user stopped typing', socket.username);
    }
  });

  socket.on('disconnect', () => {
    const username = users.get(socket.id);
    if (username) {
      users.delete(socket.id);
      io.emit('user left', username);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => console.log(`🚀 Server running on http://0.0.0.0:${PORT}`));