import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// 풀스크린 해제 상태에서 창을 16:9 비율로,
/// 1920x1080을 상한으로 화면(work area)에 맞춰 리사이즈 + 중앙정렬.
Future<void> fitWindowToDisplay({Size base = const Size(1920, 1080)}) async {
  final display = await screenRetriever.getPrimaryDisplay();
  final availW = display.visibleSize?.width.toDouble();
  final availH = display.visibleSize?.height.toDouble();

  const aspect = 16 / 9;
  double targetW = math.min(base.width, availW!);
  double targetH = targetW / aspect;

  if (targetH > availH!) {
    targetH = availH;
    targetW = targetH * aspect;
  }

  final size = Size(targetW, targetH);
  await windowManager.setAspectRatio(aspect); // 비율 고정(원하면 제거 가능)
  await windowManager.setSize(size);
  await windowManager.center();
}
