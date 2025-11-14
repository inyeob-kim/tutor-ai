import 'package:flutter/material.dart';
import 'sns_screen.dart';

/// 커뮤니티 화면 - SNS 화면을 재사용
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // SNS 화면을 그대로 사용
    return const SnsScreen();
  }
}

