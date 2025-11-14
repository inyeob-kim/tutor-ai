import 'package:flutter/material.dart';

/// 부드럽고 안정적인 스크롤 물리학 (진동 없음)
class TossScrollPhysics extends ClampingScrollPhysics {
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
}

