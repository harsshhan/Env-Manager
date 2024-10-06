import 'package:env_manager/home.dart';
import 'package:env_manager/services/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ENV MANAGER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        try {
                          setState(() {
                            isLoading = true;
                          });
                          User? user = await Auth().signInWithGoogle();
                          if (user != null) {
                            print(user);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Home(userdata: user)),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Login Failed")),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Sign-in failed: ${e.toString()}")),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.blueAccent, // Text color
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 32.0),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Login with Google'), 
                    ),
            ],
          ),
        ),
      ),
    );
  }
}