import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pabfasum/screens/sign_in_screen.dart';
import 'package:pabfasum/screens/add_post_screen.dart';

// Halaman utama aplikasi setelah login berhasil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Fungsi untuk logout dari Firebase dan kembali ke halaman SignIn
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () {
              signOut(context); // Logout saat tombol ditekan
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Currently no posts'), // Konten placeholder
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Arahkan ke halaman tambah post
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
