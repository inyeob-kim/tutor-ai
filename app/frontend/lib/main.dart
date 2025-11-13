import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 인증 상태 확인 (Web/모바일 공통)
  // Web에서는 signInWithPopup을 사용하므로 getRedirectResult() 불필요
  // 모바일에서는 google_sign_in 패키지를 사용하므로 currentUser만 확인
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser != null) {
    print('✅ 로그인된 사용자 발견: uid=${currentUser.uid}, email=${currentUser.email}');
    
    try {
      final idToken = await currentUser.getIdToken();
      if (idToken != null) {
        final previewLength = idToken.length > 40 ? 40 : idToken.length;
        print('idToken 앞부분: ${idToken.substring(0, previewLength)}...');

        // 🔥 백엔드에 우리 서비스용 로그인 요청 (선택적)
        // 에러 발생해도 앱은 계속 실행되도록 처리
        try {
          await ApiService.googleLogin(idToken);
          print('✅ 구글 로그인 백엔드 연동 성공');
        } catch (e) {
          print('⚠️ 백엔드 연동 실패 (앱은 계속 진행): $e');
        }
      }
    } catch (e) {
      print('⚠️ idToken 가져오기 실패: $e');
    }
  } else {
    print('ℹ️ 로그인된 사용자 없음 (첫 진입이거나 아직 로그인 안 함)');
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildLightTheme(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
      // ✅ 스플래시에서 FirebaseAuth.instance.currentUser를 확인
      //    - currentUser가 null이면 → GoogleSignupScreen으로 이동
      //    - currentUser가 있으면 → 회원가입 여부 확인 후 적절한 화면으로 이동
      home: const SplashScreen(),
    );
  }
}
