const mongoose = require('mongoose');
const dns = require('dns');

// Fix for Node.js on Windows: querySrv ECONNREFUSED
// Force Node.js to use Google & Cloudflare Public DNS to reliably resolve MongoDB SRV records
try {
  dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
} catch (e) {
  console.warn('[DNS] Không thể gán custom DNS servers:', e.message);
}

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGO_URI;
    if (!mongoURI) {
      throw new Error('MONGO_URI chưa được định nghĩa trong file .env');
    }

    const conn = await mongoose.connect(mongoURI, {
      dbName: 'QLHocPhan',
    });

    console.log(`[MongoDB] Kết nối thành công tới Database: ${conn.connection.name}`);
    return conn;
  } catch (error) {
    console.error(`[MongoDB] Lỗi kết nối: ${error.message}`);
    throw error;
  }
};

module.exports = connectDB;
