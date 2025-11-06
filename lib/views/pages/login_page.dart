import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:skillswap/views/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TapGestureRecognizer _signUpRecognizer;

  @override
  void initState() {
    super.initState();
    _signUpRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // Navigate to the RegisterPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4ED), // Background color from the image
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SkillSwap Title
            const Text(
              'SkillSwap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B3A7B), // Color from the image
              ),
            ),
            const SizedBox(height: 80),

            // Create an account / Enter your email and password
            const Text(
              'Log in to your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email and password\nto log in to your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),

            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@domain.com',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'password',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 32),

            // Continue Button
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login/registration logic here
                print('Email: ${_emailController.text}');
                print('Password: ${_passwordController.text}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Log in',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
        const SizedBox(height: 24), // Space before the new text

        // *** NEW CLICKABLE TEXT ***
        Text.rich(
          TextSpan(
            text: "You don't have an account? ",
            style: const TextStyle(color: Colors.black54, fontSize: 16),
            children: <TextSpan>[
              TextSpan(
                text: 'Sign up',
                style: const TextStyle(
                  color: Color(0xFF9B3A7B), // Theme color
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: _signUpRecognizer, // This makes it clickable
              ),
            ],
          ),
          textAlign: TextAlign.center,
          ),

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}