import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rana_jayeen/constants.dart' as AppColors;
import 'package:rana_jayeen/l10n/app_localizations.dart';

class ContentCreationPage extends StatefulWidget {
  static const routeName = '/create-content';
  const ContentCreationPage({super.key});

  @override
  _ContentCreationPageState createState() => _ContentCreationPageState();
}

class _ContentCreationPageState extends State<ContentCreationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _partNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  XFile? _videoFile;
  String _contentType = 'article';
  int _rating = 0;
  bool _isUploading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _videoFile = null;
        _contentType = 'article';
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = pickedFile;
        _imageFile = null;
        _contentType = 'video';
      });
    }
  }

  Future<String?> _uploadFile(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(File(file.path));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (error) {
      debugPrint('Error uploading file: $error');
      return null;
    }
  }

  Future<void> _submitPost() async {
    final loc = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorToast(loc.loginRequired);
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showErrorToast(loc.titleRequired);
      return;
    }

    if (_contentType == 'article' && _contentController.text.trim().isEmpty) {
      _showErrorToast(loc.contentRequired);
      return;
    }

    if (_contentType == 'video' && _videoFile == null) {
      _showErrorToast(loc.videoRequired);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      String? videoUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadFile(
          _imageFile!,
          'posts/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (_videoFile != null) {
        videoUrl = await _uploadFile(
          _videoFile!,
          'posts/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
      }

      final postRef = FirebaseDatabase.instance
          .ref()
          .child('auth_user')
          .child(currentUser.uid)
          .child('posts')
          .push();

      final tags = _tagsController.text
          .trim()
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await postRef.set({
        'title': _titleController.text.trim(),
        'content':
            _contentType == 'article' ? _contentController.text.trim() : null,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'contentType': _contentType,
        'partName': _partNameController.text.trim(),
        'rating': _rating,
        'tags': tags,
        'status': 'published',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': {},
        'shares': 0,
        'comments': {},
      });

      _showSuccessToast(loc.postCreated);
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error creating post: $error');
      _showErrorToast(loc.postCreateError);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSuccessToast(String message) {
    final loc = AppLocalizations.of(context)!;
    Fluttertoast.showToast(
      msg: '${loc.success}: $message',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: AppColors.kSuccess,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: 'center',
      webBgColor: '#4CAF50',
    );
  }

  void _showErrorToast(String message) {
    final loc = AppLocalizations.of(context)!;
    Fluttertoast.showToast(
      msg: '${loc.error}: $message',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 5,
      backgroundColor: AppColors.kEmergency,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: 'center',
      webBgColor: '#E57373',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.kPrimaryGradientColor,
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              loc.createPost,
              style: AppColors.textTheme(context).headlineSmall?.copyWith(
                    color: AppColors.kTextPrimary,
                  ),
              textDirection: loc.localeName == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
            leading: IconButton(
              icon: Icon(Symbols.arrow_back_rounded,
                  color: AppColors.kPrimaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    decoration: AppColors.otpInputDecoration.copyWith(
                      labelText: loc.title,
                      prefixIcon: Icon(Symbols.title_rounded,
                          color: AppColors.kPrimaryColor),
                    ),
                    style: AppColors.textTheme(context).bodyMedium,
                    textDirection: loc.localeName == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _partNameController,
                    decoration: AppColors.otpInputDecoration.copyWith(
                      labelText: 'Part Name (optional)',
                      prefixIcon: Icon(Symbols.build_rounded,
                          color: AppColors.kPrimaryColor),
                    ),
                    style: AppColors.textTheme(context).bodyMedium,
                    textDirection: loc.localeName == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${loc.rating}: ',
                        style: AppColors.textTheme(context).bodyMedium,
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating
                                  ? Symbols.star_rounded
                                  : Symbols.star_border_rounded,
                              color: Colors.amber,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_contentType == 'article')
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: AppColors.otpInputDecoration.copyWith(
                        labelText: loc.content,
                        prefixIcon: Icon(Symbols.description_rounded,
                            color: AppColors.kPrimaryColor),
                      ),
                      style: AppColors.textTheme(context).bodyMedium,
                      textDirection: loc.localeName == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: AppColors.otpInputDecoration.copyWith(
                      labelText: loc.tags,
                      hintText: loc.tags_hint,
                      prefixIcon: Icon(Symbols.tag_rounded,
                          color: AppColors.kPrimaryColor),
                    ),
                    style: AppColors.textTheme(context).bodyMedium,
                    textDirection: loc.localeName == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Symbols.image_rounded, size: 20),
                        label: Text(
                          loc.uploadImage,
                          style: AppColors.textTheme(context)
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppColors.kBorderRadius),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickVideo,
                        icon: Icon(Symbols.videocam_rounded, size: 20),
                        label: Text(
                          loc.uploadVideo,
                          style: AppColors.textTheme(context)
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppColors.kBorderRadius),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_imageFile != null)
                    ClipRRect(
                      borderRadius: AppColors.kBorderRadius,
                      child: Image.file(
                        File(_imageFile!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (_videoFile != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppColors.kBorderRadius,
                        color: AppColors.kSurface.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          loc.videoSelected,
                          style:
                              AppColors.textTheme(context).bodyMedium?.copyWith(
                                    color: AppColors.kTextPrimary,
                                  ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: _isUploading
                        ? CircularProgressIndicator(
                            color: AppColors.kPrimaryColor,
                            strokeWidth: 3,
                          )
                        : ElevatedButton(
                            onPressed: _submitPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: AppColors.kBorderRadius),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            child: Text(
                              loc.submit,
                              style: AppColors.textTheme(context)
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _partNameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
