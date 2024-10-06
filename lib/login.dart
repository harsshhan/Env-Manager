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
  bool isLoading=false;
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Center(
        child: isLoading?CircularProgressIndicator():IconButton(
          onPressed: () async {
            try {
              setState(() {
                isLoading=true;
              });
              User? user = await Auth().signInWithGoogle();
              if (user != null) {
                print(user);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Home(userdata: user,)), 
                  (Route<dynamic> route) => false,
                );
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Login Failed")));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Sign-in failed: ${e.toString()}")),
              );
            }finally{
              setState(() {
                isLoading=false;
              });
            }
          },
          icon: Icon(Icons.login),
        ),
      ),
    );
  }
}
