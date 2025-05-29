import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String? imageBase64;
  final String? description;
  final String? category;

  const EditPostScreen({
    Key? key,
    required this.postId,
    this.imageBase64,
    this.description,
    this.category,
  }) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedCategory;
  bool _isUpdating = false;

  final List<String> categories = [
    'Jalan Rusak',
    'Marka Pudar',
    'Lampu Mati',
    'Trotoar Rusak',
    'Rambu Rusak',
    'Jembatan Rusak',
    'Sampah Menumpuk',
    'Saluran Tersumbat',
    'Sungai Tercemar',
    'Sampah Sungai',
    'Pohon Tumbang',
    'Taman Rusak',
    'Fasilitas Rusak',
    'Pipa Bocor',
    'Vandalisme',
    'Banjir',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _base64Image = widget.imageBase64;
    _descriptionController.text = widget.description ?? '';
    _selectedCategory = widget.category;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _compressAndEncodeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage == null) return;
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to compress image: $e')),
      );
    }
  }

  Future<void> _updatePost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image and description.')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'image': _base64Image,
        'description': _descriptionController.text,
        'category': _selectedCategory ?? 'Lainnya',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update the post: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : (_base64Image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_base64Image!),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: Colors.grey,
                  ),
                )),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showCategorySelection,
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(_selectedCategory ?? 'Select Category'),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 16),
                  ],
                ),
                backgroundColor: Colors.blue[100],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Edit description...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUpdating ? null : _updatePost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.green,
              ),
              child: _isUpdating
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
                  : const Text(
                'Update Post',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}