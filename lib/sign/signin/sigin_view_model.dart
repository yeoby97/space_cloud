import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/user.dart';

class SignInViewModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  bool _isLoading = false;
  String? _error;

  SignInViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return _complete(false);

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return _complete(false);

      await _createUserIfNeeded(user);
      return _complete(true);
    } catch (e, stack) {
      debugPrint('Google Sign-In Error: $e\n$stack');
      return _fail('로그인 중 오류가 발생했습니다.');
    }
  }

  Future<void> _createUserIfNeeded(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '사용자',
        photoURL: user.photoURL ?? '',
        phoneNumber: user.phoneNumber ?? '01012345678',
      );
      await docRef.set(newUser.toMap());
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  bool _complete(bool result) {
    _setLoading(false);
    return result;
  }

  bool _fail(String message) {
    _error = message;
    _setLoading(false);
    return false;
  }
}
