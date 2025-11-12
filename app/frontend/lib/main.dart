import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Google Sign-In 리다이렉트 결과 처리
  // getRedirectResult는 한 번만 호출되어야 하므로 여기서 처리
  final auth = FirebaseAuth.instance;
  try {
    final result = await auth.getRedirectResult();
    
    // getRedirectResult()는 UserCredential 객체를 반환합니다
    // UserCredential에는 다음이 포함됩니다:
    // - user: User 객체 (사용자 정보)
    // - credential: AuthCredential 객체
    // - additionalUserInfo: AdditionalUserInfo 객체
    
    print('=== Google 로그인 반환값 확인 ===');
    print('result.user: ${result.user}');
    print('result.credential: ${result.credential}');
    print('result.additionalUserInfo: ${result.additionalUserInfo}');
    
    // 에러 확인
    if (result.user == null && result.credential == null) {
      print('⚠️ 리다이렉트 결과가 없습니다. 가능한 원인:');
      print('  1. Google 로그인을 아직 시도하지 않았거나');
      print('  2. 리다이렉트가 완료되지 않았거나');
      print('  3. Firebase Console에서 Authorized redirect URIs가 설정되지 않았을 수 있습니다');
      print('  현재 URL: ${Uri.base}');
    }
    
    if (result.user != null) {
      final user = result.user!;
      print('user.uid: ${user.uid}');
      print('user.email: ${user.email}');
      print('user.displayName: ${user.displayName}');
      print('user.photoURL: ${user.photoURL}');
      print('user.emailVerified: ${user.emailVerified}');
      print('user.providerData: ${user.providerData}');
      
      // 리다이렉트 후 로그인 성공 처리
      final idToken = await user.getIdToken();
      if (idToken != null) {
        print('idToken: ${idToken.substring(0, 50)}...'); // 처음 50자만 출력
        try {
          await ApiService.googleLogin(idToken);
          print('구글 로그인 성공: ${user.email}');
          // 로그인 성공 후 사용자는 Firebase Auth에 자동으로 설정됨
          // splash screen에서 currentUser를 확인하여 과목 선택 화면으로 이동
        } catch (e) {
          print('구글 로그인 처리 실패: $e');
        }
      }
    } else {
      print('리다이렉트 결과 없음 (main.dart) - 로그인하지 않았거나 이미 처리됨');
    }
  } catch (e) {
    print('리다이렉트 결과 처리 중 오류: $e');
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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const SplashScreen(),
    );
  }
}
