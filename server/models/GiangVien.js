const mongoose = require('mongoose');

/**
 * STRICT SCHEMA REQUIREMENT:
 * Collection name: GiangVien
 * Database name: QLHocPhan
 * Must ONLY contain the 4 fields below:
 * - IDGV (String)
 * - Fullname (String)
 * - Image (String)
 * - SumClass (Number)
 * Timestamps and versionKey (__v) are strictly disabled.
 */
const GiangVienSchema = new mongoose.Schema(
  {
    IDGV: {
      type: String,
      required: [true, 'IDGV (Mã Giảng viên) là bắt buộc'],
      trim: true,
    },
    Fullname: {
      type: String,
      required: [true, 'Fullname (Họ và tên) là bắt buộc'],
      trim: true,
    },
    Image: {
      type: String,
      required: [true, 'Image (URL hình ảnh Cloudinary) là bắt buộc'],
    },
    SumClass: {
      type: Number,
      required: [true, 'SumClass (Tổng số lớp) là bắt buộc'],
      min: [0, 'Tổng số lớp không được nhỏ hơn 0'],
    },
  },
  {
    collection: 'GiangVien', // Exactly named collection
    timestamps: false,       // Strictly disabled
    versionKey: false,       // Strictly disable __v field
  }
);

module.exports = mongoose.model('GiangVien', GiangVienSchema);

