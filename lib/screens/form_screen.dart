import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/giang_vien_model.dart';
import '../providers/giang_vien_provider.dart';
import '../widgets/giang_vien_image.dart';

class FormScreen extends StatefulWidget {
  final GiangVien? giangVien;

  const FormScreen({super.key, this.giangVien});

  bool get isEditMode => giangVien != null;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idgvController;
  late final TextEditingController _fullnameController;
  late final TextEditingController _sumClassController;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _idgvController = TextEditingController(text: widget.giangVien?.idgv ?? '');
    _fullnameController =
        TextEditingController(text: widget.giangVien?.fullname ?? '');
    _sumClassController = TextEditingController(
      text: widget.giangVien != null
          ? widget.giangVien!.sumClass.toString()
          : '0',
    );
  }

  @override
  void dispose() {
    _idgvController.dispose();
    _fullnameController.dispose();
    _sumClassController.dispose();
    super.dispose();
  }

  /// Pick image from Gallery or Camera
  /// Works across both Flutter Web and Flutter Mobile
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFileName = pickedFile.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn ảnh: ${pickedFile.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate image: for new GiangVien, image is required
    if (!widget.isEditMode && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Vui lòng chọn ảnh đại diện từ Thư viện hoặc Máy ảnh!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final provider = Provider.of<GiangVienProvider>(context, listen: false);
    final idgv = _idgvController.text.trim();
    final fullname = _fullnameController.text.trim();
    final sumClass = int.tryParse(_sumClassController.text.trim()) ?? 0;

    // Check duplicate IDGV
    if (provider.isIdgvExists(
      idgv,
      excludeOriginalIdgv: widget.isEditMode ? widget.giangVien!.idgv : null,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã giảng viên "$idgv" đã tồn tại!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    bool success;
    if (widget.isEditMode) {
      final updated = GiangVien(
        id: widget.giangVien!.id,
        idgv: idgv,
        fullname: fullname,
        image: widget.giangVien!.image, // Preserved if no new image picked
        sumClass: sumClass,
      );
      success = await provider.updateGiangVien(
        updated,
        imageBytes: _selectedImageBytes,
        imageFileName: _selectedImageFileName,
        originalIdgv: widget.giangVien!.idgv,
      );
    } else {
      final newGv = GiangVien(
        idgv: idgv,
        fullname: fullname,
        image: '', // Will be assigned by backend Cloudinary upload
        sumClass: sumClass,
      );
      success = await provider.addGiangVien(
        newGv,
        imageBytes: _selectedImageBytes,
        imageFileName: _selectedImageFileName,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Cập nhật giảng viên thành công!'
                : 'Thêm mới giảng viên thành công!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Thao tác không thành công!',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<GiangVienProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Chỉnh sửa Giảng Viên' : 'Thêm mới Giảng Viên',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Lưu',
            onPressed: provider.isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang lưu dữ liệu...'),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. IMAGE PREVIEW & PICKER SECTION
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: SizedBox(
                                          width: 130,
                                          height: 130,
                                          child: _buildAvatarPreview(theme),
                                        ),
                                      ),
                                    ),
                                    if (_isPickingImage)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black38,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    FilledButton.tonalIcon(
                                      icon: const Icon(
                                          Icons.photo_library_outlined,
                                          size: 20),
                                      label: const Text('Chọn ảnh từ máy'),
                                      onPressed: _isPickingImage
                                          ? null
                                          : () =>
                                              _pickImage(ImageSource.gallery),
                                    ),
                                    FilledButton.tonalIcon(
                                      icon: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 20),
                                      label: const Text('Máy ảnh'),
                                      onPressed: _isPickingImage
                                          ? null
                                          : () =>
                                              _pickImage(ImageSource.camera),
                                    ),
                                    if (_selectedImageBytes != null)
                                      TextButton.icon(
                                        icon: const Icon(Icons.undo_rounded,
                                            size: 18),
                                        label: const Text('Hủy chọn ảnh'),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImageBytes = null;
                                            _selectedImageFileName = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                if (_selectedImageFileName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Chip(
                                      avatar: const Icon(Icons.image, size: 16),
                                      label: Text(
                                        _selectedImageFileName!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 2. IDGV FIELD
                          TextFormField(
                            controller: _idgvController,
                            decoration: InputDecoration(
                              labelText: 'Mã Giảng Viên *',
                              hintText: 'Ví dụ: GV01, GV02...',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập mã giảng viên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. FULLNAME FIELD
                          TextFormField(
                            controller: _fullnameController,
                            decoration: InputDecoration(
                              labelText: 'Họ và tên *',
                              hintText: 'Ví dụ: Nguyễn Văn An',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên giảng viên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 4. SUMCLASS FIELD
                          TextFormField(
                            controller: _sumClassController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tổng số lớp *',
                              hintText: 'Ví dụ: 3',
                              prefixIcon: const Icon(Icons.class_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số lớp';
                              }
                              final numVal = int.tryParse(value.trim());
                              if (numVal == null) {
                                return 'Tổng số lớp phải là số nguyên';
                              }
                              if (numVal < 0) {
                                return 'Số lớp không được nhỏ hơn 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // 5. SUBMIT BUTTON
                          FilledButton.icon(
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              widget.isEditMode
                                  ? 'Cập nhật Giảng Viên'
                                  : 'Lưu Giảng Viên',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: provider.isLoading ? null : _handleSave,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarPreview(ThemeData theme) {
    // 1. If newly picked image
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(theme),
      );
    }

    // 2. If in Edit mode and lecturer already has an image from Cloudinary
    if (widget.isEditMode && widget.giangVien!.image.isNotEmpty) {
      return GiangVienImage(
        imageSource: widget.giangVien!.image,
        width: 130,
        height: 130,
      );
    }

    // 3. Empty placeholder
    return _buildFallback(theme);
  }

  Widget _buildFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 70,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
