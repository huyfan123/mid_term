const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

/**
 * Uploads a buffer directly to Cloudinary using upload_stream
 * @param {Buffer} buffer - File buffer from Multer memoryStorage
 * @param {String} folder - Optional destination folder in Cloudinary
 * @returns {Promise<String>} - Returns the secure_url
 */
const uploadToCloudinary = (buffer, folder = 'giangvien_images') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: folder,
        resource_type: 'image',
      },
      (error, result) => {
        if (error) {
          return reject(error);
        }
        resolve(result.secure_url);
      }
    );
    uploadStream.end(buffer);
  });
};

/**
 * Extracts public_id from Cloudinary URL
 * Example: https://res.cloudinary.com/cloud_name/image/upload/v12345/giangvien_images/sample.jpg
 * Returns: "giangvien_images/sample"
 * @param {String} url - Full Cloudinary image URL
 * @returns {String|null}
 */
const getPublicIdFromUrl = (url) => {
  if (!url || !url.includes('cloudinary.com')) return null;
  try {
    const parts = url.split('/upload/');
    if (parts.length < 2) return null;
    let path = parts[1]; // e.g. "v1715500000/giangvien_images/abcxyz.jpg" or "giangvien_images/abcxyz.jpg"
    // Remove version prefix if present (v followed by digits/)
    path = path.replace(/^v\d+\//, '');
    // Remove extension
    const dotIndex = path.lastIndexOf('.');
    if (dotIndex !== -1) {
      path = path.substring(0, dotIndex);
    }
    return path;
  } catch (e) {
    return null;
  }
};

/**
 * Deletes an image from Cloudinary by its URL or public_id
 * @param {String} imageUrlOrPublicId
 */
const deleteFromCloudinary = async (imageUrlOrPublicId) => {
  if (!imageUrlOrPublicId) return;

  const publicId = imageUrlOrPublicId.startsWith('http')
      ? getPublicIdFromUrl(imageUrlOrPublicId)
      : imageUrlOrPublicId;

  if (!publicId) return;

  try {
    const result = await cloudinary.uploader.destroy(publicId);
    console.log(`[Cloudinary] Đã xóa ảnh cũ thành công (${publicId}):`, result);
    return result;
  } catch (error) {
    console.error(`[Cloudinary] Lỗi khi xóa ảnh (${publicId}):`, error.message);
  }
};

module.exports = {
  cloudinary,
  uploadToCloudinary,
  deleteFromCloudinary,
  getPublicIdFromUrl,
};
