import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

// import 'package:firebase_auth/firebase_auth.dart'
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});
  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image:$e')));
      }
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGenerating = true);
    try {
      final imageBytes = await _image!.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      const apiKey =
          'AIzaSyA49t3OGFXk9Yk6nz8ZiQljaDzxVE8rNvE'; // ganti dengan API key kamu
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {
                "text":
                "Berdasarkan foto ini, identifikasi satu kategori utama kerusakan fasilitas umum "
                    "dari daftar berikut: Jalan Rusak, Marka Pudar, Lampu Mati, Trotoar Rusak, "
                    "Rambu Rusak, Jembatan Rusak, Sampah Menumpuk, Saluran Tersumbat, Sungai Tercemar, "
                    "Sampah Sungai, Pohon Tumbang, Taman Rusak, Fasilitas Rusak, Pipa Bocor, "
                    "Vandalisme, Banjir, dan Lainnya. "
                    "Pilih kategori yang paling dominan atau paling mendesak untuk dilaporkan. "
                    "Buat deskripsi singkat untuk laporan perbaikan, dan tambahkan permohonan perbaikan. "
                    "Fokus pada kerusakan yang terlihat dan hindari spekulasi.\n\n"
                    "Format output yang diinginkan:\n"
                    "Kategori: [satu kategori yang dipilih]\n"
                    "Deskripsi: [deskripsi singkat]",
              },
            ],
          },
        ],
      });
      final headers = {'Content-Type': 'application/json'};
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text =
        jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        print("AI TEXT: $text");
        if (text != null && text.isNotEmpty) {
          final lines = text.trim().split('\n');
          String? category;
          String? description;
          for (var line in lines) {
            final lower = line.toLowerCase();
            if (lower.startsWith('kategori:')) {
              category = line.substring(9).trim();
            } else if (lower.startsWith('deskripsi:')) {
              description = line.substring(10).trim();
            }
            // else if (lower.startsWith('keterangan:')) {
            //   description = line.substring(11).trim();
            // }
          }
          description ??= text.trim();
          setState(() {
            _aiCategory = category ?? 'Tidak diketahui';
            _aiDescription = description!;
            _descriptionController.text = _aiDescription!;
          });
        }
      } else {
        debugPrint('Request failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to generate AI description: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 10));
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      } catch (e) {
        debugPrint('Gagal mendapatkan lokasi: $e');
        setState(() {
          _latitude = null;
          _longitude = null;
        });
      }
    }
  }

  Future<void> sendNotificationToTopic(String body, String senderName) async {
    final uri = Uri.parse('fasum-cloud-pi.vercel.app/send-to-topic');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "topic": "berita-fasum",
        "title": "️ Laporan Baru",
        "body": body,
        "senderName": senderName,
        "senderPhotoUrl": "https://static.vecteezy.com/system/resources/thumbnails/041/642/167/small_2x/ai-generated-portrait-of-handsome-smiling-young-man-with-folded-arms-isolated-free-png.png",
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Notifikasi berhasil dikirim')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal kirim notifikasi: ${response.body}')),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (_base64Image == null || _descriptionController.text.isEmpty) return;
    setState(() => _isUploading = true);
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pengguna tidak ditemukan.')));
      return;
    }
    try {
      await _getLocation();
      // Ambil nama lengkap dari koleksi users
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fullName = userDoc.data()?['fullName'] ?? 'Tanpa Nama';
      await FirebaseFirestore.instance.collection('posts').add({
        'image': _base64Image,
        'description': _descriptionController.text,
        'createdAt': now,
        'latitude': _latitude,
        'longitude': _longitude,
        'fullName': fullName,
        // 'aiCategory': _aiCategory,
        'userId': uid, //optional
      });
      if (!mounted) return;

      sendNotificationToTopic(_descriptionController.text, fullName);

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Gagal menyimpan postingan: $e');
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunggah postingan.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Post')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
                child:
                _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
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
                ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Add a brief description...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _submitPost,
              icon: Icon(Icons.upload),
              label: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
