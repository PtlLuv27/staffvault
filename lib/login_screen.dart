import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'main.dart';
import 'set_password_screen.dart'; // New screen required

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;

  void _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);
    User? user;

    if (_isLoginMode) {
      user = await AuthService().loginWithEmail(_emailController.text, _passwordController.text);
    } else {
      user = await AuthService().signUpWithEmail(_emailController.text, _passwordController.text);
    }

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen(message: "Welcome!")),
      );
    } else {
      _showError("Authentication Failed. Check credentials or internet.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
              const SizedBox(height: 10),
              const Text("StaffVault", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(_isLoginMode ? "Login to your account" : "Create new account",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _handleAuth,
                  child: Text(_isLoginMode ? "Login" : "Sign Up"),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(_isLoginMode ? "New here? Create Account" : "Already have an account? Login"),
                ),
              ],

              const Divider(height: 40),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text("Continue with Google"),
                onPressed: () async {
                  User? user = await AuthService().signInWithGoogle();
                  if (user != null && mounted) {
                    // Logic: Check if password setup is needed
                    if (!AuthService().hasPassword(user)) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SetPasswordScreen()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SplashScreen(message: "Welcome!")),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}