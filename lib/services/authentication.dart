import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class Auth {
  String apiUrl = dotenv.env['API_URL'] ?? '';
  Future<User?> signInWithGoogle() async{
    try{
      final GoogleSignInAccount? googleuser = await GoogleSignIn().signIn();
      if(googleuser == null){
        return null;
      }

    final GoogleSignInAuthentication gAuth= await googleuser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(accessToken: gAuth.accessToken,idToken: gAuth.idToken);

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    final User? user = userCredential.user;

    await http.post(Uri.parse('$apiUrl/newuser/${user!.email}'));
    return user;
  

    }catch(e){
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async{
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}