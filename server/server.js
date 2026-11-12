require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

// Route imports
const authRoutes = require('./routes/authRoutes');
const giangvienRoutes = require('./routes/giangvienRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'GiangVien Management API is running',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth/login',
      giangviens: '/api/giangviens',
    },
  });
});

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/giangviens', giangvienRoutes);

// 404 Route Handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `Không tìm thấy endpoint: ${req.method} ${req.originalUrl}`,
  });
});

// Centralized Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('[Server Error]:', err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Lỗi hệ thống máy chủ nội bộ!';

  res.status(statusCode).json({
    success: false,
    message: message,
    error: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
});

// Start Express Server after connecting to MongoDB
connectDB()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`===============================================`);
      console.log(` Server đang chạy tại: http://localhost:${PORT}`);
      console.log(`===============================================`);
    });
  })
  .catch((err) => {
    console.error('Không thể khởi động server do lỗi kết nối cơ sở dữ liệu:', err);
  });
