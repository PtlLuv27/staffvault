import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isSyncing = false;

  void _submit() async {
    if (_passController.text.length < 6) {
      _error("Password must be at least 6 characters");
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      _error("Passwords do not match");
      return;
    }

    setState(() => _isSyncing = true);
    bool success = await AuthService().linkPassword(_passController.text);
    setState(() => _isSyncing = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen(message: "Account Secured!")),
      );
    } else {
      _error("Failed to link password. Try again.");
    }
  }

  void _error(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Account Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("To enable email login, please set a password for your account."),
            const SizedBox(height: 20),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 16),
            TextField(controller: _confirmPassController, decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 30),
            _isSyncing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: _submit,
                child: const Text("Secure Account & Continue")
            ),
          ],
        ),
      ),
    );
  }
}