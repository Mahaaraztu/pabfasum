import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pabfasum/screens/home_screen.dart';
import 'package:pabfasum/screens/sign_up_screen.dart';

// Widget untuk halaman Sign In
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  // Controller untuk input email dan password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Untuk mengatur tampilan loading dan visibilitas password
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey, // Mengaitkan form dengan formKey untuk validasi
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Input email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      // Validasi email kosong atau tidak valid
                      if (value == null || value.isEmpty || !_isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Input password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Mengatur apakah password terlihat atau tidak
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          // Toggle visibilitas password
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Tombol Sign In atau indikator loading
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('Sign In'),
                  ),

                  const SizedBox(height: 16.0),

                  // Tautan ke halaman Sign Up
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16.0, color: Colors.black),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigasi ke halaman Sign Up
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpScreen()),
                              );
                            },
                        ),
                      ],
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

  // Fungsi untuk proses Sign In ke Firebase
  void _signIn() async {
    if (!_formKey.currentState!.validate()) {
      // Jika form tidak valid, hentikan proses
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true); // Tampilkan loading spinner

    try {
      // Autentikasi dengan Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigasi ke halaman Home jika berhasil login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (error) {
      // Menampilkan error dari Firebase Auth
      _showSnackBar(_getAuthErrorMessage(error.code));
    } catch (error) {
      // Menampilkan error umum
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() => _isLoading = false); // Sembunyikan loading
    }
  }

  // Fungsi untuk menampilkan snackbar pesan error
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Fungsi validasi format email
  bool _isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
    return RegExp(emailRegex).hasMatch(email);
  }

  // Mengubah kode error Firebase menjadi pesan yang lebih ramah pengguna
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with that email';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
