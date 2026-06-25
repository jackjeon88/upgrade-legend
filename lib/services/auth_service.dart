import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인된 유저 반환
  User? get currentUser => _auth.currentUser;

  // Google 로그인 (google_sign_in 7.x 방식)
  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // 초기화 (최초 1회 필수)
      await googleSignIn.initialize();

      GoogleSignInAccount? googleUser;

      // 1) 이미 로그인된 계정 있으면 재사용
      googleUser = await googleSignIn.attemptLightweightAuthentication();

      // 2) 없으면 Google 계정 선택 팝업
      googleUser ??= await googleSignIn.authenticate();

      // ID 토큰 가져오기 (7.x: authentication getter)
      final googleAuth = googleUser.authentication;

      // Firebase 자격증명 생성
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Firestore에 유저 데이터 초기화
        await FirestoreService().initUserData(user);
      }

      return user;
    } catch (e) {
      print('Google 로그인 오류: $e');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}