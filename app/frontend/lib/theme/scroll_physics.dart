import 'package:flutter/material.dart';

/// 토스 앱처럼 부드럽고 빠른 스크롤 물리학
class TossScrollPhysics extends BouncingScrollPhysics {
  const TossScrollPhysics({super.parent});

  @override
  TossScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TossScrollPhysics(parent: buildParent(ancestor));
  }

  // 스크롤 속도 조정 (더 빠르고 부드럽게)
  @override
  double get minFlingVelocity => 50.0; // 기본값보다 낮게 설정하여 더 쉽게 스크롤 시작

  @override
  double get maxFlingVelocity => 8000.0; // 기본값보다 높게 설정하여 더 빠른 스크롤

  // 마찰 감소로 더 부드러운 스크롤
  @override
  double frictionFactor(double velocity) {
    // 속도가 빠를수록 마찰 감소 (더 부드럽게)
    if (velocity.abs() > 1000) {
      return 0.01; // 매우 낮은 마찰
    } else if (velocity.abs() > 500) {
      return 0.015;
    }
    return 0.02; // 기본 마찰
  }

  // 바운스 효과 조정
  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5, // 더 가벼워서 빠르게 반응
        stiffness: 100.0, // 더 탄력적으로
        damping: 0.8, // 적절한 감쇠
      );
}

