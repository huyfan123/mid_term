const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const GiangVien = require('../models/GiangVien');
const upload = require('../middlewares/upload');
const { uploadToCloudinary } = require('../config/cloudinary');

/**
 * Helper to build search query by _id or IDGV
 */
const buildIdQuery = (idParam) => {
  if (mongoose.Types.ObjectId.isValid(idParam)) {
    return { _id: idParam };
  }
  return { IDGV: idParam };
};

/**
 * @route   GET /api/giangviens
 * @desc    Get all GiangVien documents
 */
router.get('/', async (req, res, next) => {
  try {
    const list = await GiangVien.find().lean();
    return res.status(200).json({
      success: true,
      count: list.length,
      data: list,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/giangviens/:id
 * @desc    Get single GiangVien by _id or IDGV
 */
router.get('/:id', async (req, res, next) => {
  try {
    const query = buildIdQuery(req.params.id);
    const gv = await GiangVien.findOne(query).lean();

    if (!gv) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy giảng viên!',
      });
    }

    return res.status(200).json({
      success: true,
      data: gv,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/giangviens
 * @desc    Create a new GiangVien with image uploaded to Cloudinary
 */
router.post('/', upload.single('image'), async (req, res, next) => {
  try {
    const { IDGV, Fullname, SumClass, Image: imageUrlText } = req.body;

    // Validate required fields
    if (!IDGV || !Fullname || SumClass === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ: IDGV, Fullname, SumClass!',
      });
    }

    // Check duplicate IDGV
    const existing = await GiangVien.findOne({ IDGV: IDGV.trim() });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: `Mã giảng viên "${IDGV}" đã tồn tại trong hệ thống!`,
      });
    }

    let finalImageUrl = '';

    // Handle Image: File upload takes precedence
    if (req.file) {
      finalImageUrl = await uploadToCloudinary(req.file.buffer);
    } else if (imageUrlText && imageUrlText.trim()) {
      finalImageUrl = imageUrlText.trim();
    } else {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn ảnh đại diện từ máy hoặc máy ảnh!',
      });
    }

    // Create document strictly following the 4 fields
    const newGiangVien = new GiangVien({
      IDGV: IDGV.trim(),
      Fullname: Fullname.trim(),
      Image: finalImageUrl,
      SumClass: Number(SumClass),
    });

    const saved = await newGiangVien.save();

    return res.status(201).json({
      success: true,
      message: 'Thêm giảng viên thành công!',
      data: saved,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   PUT /api/giangviens/:id
 * @desc    Update GiangVien (optional new image upload)
 */
router.put('/:id', upload.single('image'), async (req, res, next) => {
  try {
    const query = buildIdQuery(req.params.id);
    const existingGv = await GiangVien.findOne(query);

    if (!existingGv) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy giảng viên để cập nhật!',
      });
    }

    const { IDGV, Fullname, SumClass, Image: imageUrlText } = req.body;

    // Check duplicate IDGV if IDGV is being changed
    if (IDGV && IDGV.trim() !== existingGv.IDGV) {
      const duplicate = await GiangVien.findOne({
        IDGV: IDGV.trim(),
        _id: { $ne: existingGv._id },
      });
      if (duplicate) {
        return res.status(409).json({
          success: false,
          message: `Mã giảng viên "${IDGV}" đã được sử dụng bởi giảng viên khác!`,
        });
      }
      existingGv.IDGV = IDGV.trim();
    }

    if (Fullname) existingGv.Fullname = Fullname.trim();
    if (SumClass !== undefined) existingGv.SumClass = Number(SumClass);

    // If new image file is uploaded, upload to Cloudinary and update URL
    if (req.file) {
      const newImageUrl = await uploadToCloudinary(req.file.buffer);
      existingGv.Image = newImageUrl;
    } else if (imageUrlText && imageUrlText.trim()) {
      existingGv.Image = imageUrlText.trim();
    }

    const updated = await existingGv.save();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật giảng viên thành công!',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   DELETE /api/giangviens/:id
 * @desc    Delete GiangVien by _id or IDGV
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const query = buildIdQuery(req.params.id);
    const deleted = await GiangVien.findOneAndDelete(query);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy giảng viên để xóa!',
      });
    }

    return res.status(200).json({
      success: true,
      message: `Đã xóa giảng viên "${deleted.Fullname}" (Mã: ${deleted.IDGV}) thành công!`,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

