import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 로딩 애니메이션 위젯 (loading.json 사용)
class LoadingIndicator extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 100,
      height: height ?? 100,
      child: Lottie.asset(
        'assets/animations/loading.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

/// 작은 로딩 인디케이터 (버튼 내부 등에서 사용)
class SmallLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const SmallLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: Lottie.asset(
        'assets/animations/loading.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

