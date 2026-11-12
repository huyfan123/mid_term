const express = require('express');
const router = express.Router();

/**
 * @route   POST /api/auth/login
 * @desc    Dummy login endpoint for Admin module (admin/admin)
 */
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  if (
    username &&
    password &&
    username.trim().toLowerCase() === 'admin' &&
    password.trim() === 'admin'
  ) {
    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công',
      user: {
        username: 'admin',
        role: 'admin',
      },
      token: 'dummy_jwt_token_for_exam',
    });
  }

  return res.status(401).json({
    success: false,
    message: 'Tên đăng nhập hoặc mật khẩu không chính xác!',
  });
});

module.exports = router;

