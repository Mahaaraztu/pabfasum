import 'dart:convert';
import 'package:pabfasum/screens/full_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.imageBase64,
    required this.description,
    required this.createdAt,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.heroTag,
  });
  final String imageBase64;
  final String description;
  final DateTime createdAt;
  final String fullName;
  final double latitude;
  final double longitude;
  final String category;
  final String heroTag;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}
class _DetailScreenState extends State<DetailScreen> {
  Future<void> openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return; // Pastikan widget masih aktif
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final createdAtFormatted = DateFormat(
      'dd MMMM yyyy, HH:mm',
    ).format(widget.createdAt);
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Laporan")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.heroTag,
                  child: Image.memory(
                    base64Decode(widget.imageBase64),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullScreenImageScreen(
                            imageBase64: widget.imageBase64,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Lihat gambar penuh',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kiri: Kategori & Waktu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.category,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  createdAtFormatted,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
// Kanan: Icon map
                      IconButton(
                        onPressed: openMap,
                        icon: const Icon(
                          Icons.map,
                          size: 38,
                          color: Colors.lightGreen,
                        ),
                        tooltip: "Buka di Google Maps",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}