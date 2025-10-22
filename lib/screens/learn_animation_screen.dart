import 'package:flutter/material.dart';
import '../widgets/sequence_sprites.dart'; // SequenceSprite / AnchoredBox

class LearnAnimationScreen extends StatefulWidget {
  const LearnAnimationScreen({super.key});

  @override
  State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
}

class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
  final seqCtrl = SequenceController();
  late final List<String> frames100;

  @override
  void initState() {
    super.initState();
    // kkomi_game_base_000 ~ 099
    frames100 = List.generate(
      100,
      (i) =>
          'assets/images/kkomi_game_base/kkomi_game_base_${i.toString().padLeft(3, "0")}.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0e0e0e),
      appBar: AppBar(
        title: const Text('학습 애니메이션 (Simple)'),
        actions: [
          IconButton(
            onPressed: () => seqCtrl.start(),
            tooltip: '재생',
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: () => seqCtrl.stop(),
            tooltip: '정지(처음 프레임)',
            icon: const Icon(Icons.stop),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 배경 (선택)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          /// ===========================
          /// CASE A) 이미지 전용 가장 기본
          /// - 자동재생(on), 루프(on), 마지막프레임 유지(on), 프리캐시(on)
          /// - 부모 Stack 좌표 (x: 520, y: 380)에 "센터 기준"으로 배치
          /// ===========================
          AnchoredBox(
            position: const Offset(520, 380),
            anchor: Anchor.center,
            size: const Size(640, 360), // 필요 시 고정 사이즈; 없애면 원본 비율에 맞게
            child: SequenceSprite(
              controller: seqCtrl,
              assetPaths: frames100,
              fps: 24,
              loop: true,
              autoplay: true,
              holdLastFrameWhenFinished: true,
              precache: true, // 첫 재생 전에 전부 로드(깜빡임 최소화)
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../widgets/png_sequence_player.dart'; // 위 파일 경로에 맞게 import

// class LearnAnimationScreen extends StatefulWidget {
//   const LearnAnimationScreen({super.key});
//   @override
//   State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
// }

// class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
//   final _ctrl = PngSequenceController();
//   late final List<String> _frames;

//   @override
//   void initState() {
//     super.initState();
//     _frames = List.generate(100, (i) {
//       final n = i.toString().padLeft(3, '0');
//       return 'assets/images/kkomi_game_base/kkomi_game_base_$n.png';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('학습 애니메이션'),
//         actions: [
//           IconButton(
//             onPressed: () => _ctrl.start(),
//             icon: const Icon(Icons.play_arrow),
//             tooltip: '재생',
//           ),
//           IconButton(
//             onPressed: () => _ctrl.stop(),
//             icon: const Icon(Icons.stop),
//             tooltip: '정지(처음으로)',
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Center(
//         child: FittedBox(
//           fit: BoxFit.contain,
//           child: PngSequencePlayer(
//             controller: _ctrl,
//             assetPaths: _frames,
//             fps: 24,
//             loop: true,
//             fixedSize: const Size(1280, 720), // 원하면 지정, 아니면 생략
//             precache: true, // 첫 재생 전에 전부 로드(깜빡임 최소화)
//           ),
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:image_sequence_animator/image_sequence_animator.dart';

// // class LearnAnimationScreen extends StatefulWidget {
// //   const LearnAnimationScreen({super.key});

// //   @override
// //   State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
// // }

// // class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
// //   ImageSequenceAnimatorState? _seq;

// //   int _fps = 24; // fps는 named(double) 인자로 전달
// //   bool _isLooping = true;
// //   bool _isPlaying = true;

// //   late final List<String> _fullPaths; // kkomi_game_base_000 ~ 099
// //   String? _debugPath; // 현재 재생 중 경로 디버그 표시

// //   @override
// //   void initState() {
// //     super.initState();
// //     // 000 ~ 099 파일 경로 생성
// //     _fullPaths = List.generate(100, (i) {
// //       final n = i.toString().padLeft(3, '0');
// //       return 'assets/images/kkomi_game_base/kkomi_game_base_$n.png';
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final totalProgress = _seq?.totalProgress ?? 100.0;
// //     final currentProgress = _seq?.currentProgress ?? 0.0;

// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       appBar: AppBar(
// //         title: const Text('학습 애니메이션'),
// //         actions: [
// //           IconButton(
// //             tooltip: _isPlaying ? '일시정지' : '재생',
// //             onPressed: () {
// //               final s = _seq;
// //               if (s == null) return;
// //               if (s.isPlaying) {
// //                 s.pause();
// //                 setState(() => _isPlaying = false);
// //               } else {
// //                 s.play();
// //                 setState(() => _isPlaying = true);
// //               }
// //             },
// //             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
// //           ),
// //           IconButton(
// //             tooltip: _isLooping ? '루프 끄기' : '루프 켜기',
// //             onPressed: () {
// //               final s = _seq;
// //               if (s == null) return;
// //               s.setIsLooping(!_isLooping);
// //               setState(() => _isLooping = !_isLooping);
// //             },
// //             icon: Icon(_isLooping ? Icons.loop : Icons.loop_outlined),
// //           ),
// //           const SizedBox(width: 8),
// //         ],
// //       ),
// //       body: Center(
// //         child: FittedBox(
// //           fit: BoxFit.contain,
// //           child: SizedBox(
// //             width: 1280,
// //             height: 720,
// //             child: Stack(
// //               children: [
// //                 // folderName, fileName, suffixStart, suffixCount(자릿수), fileFormat, frameCount(총 프레임)
// //                 ImageSequenceAnimator(
// //                   'assets/images/kkomi_game_base',
// //                   'kkomi_game_base_',
// //                   0,
// //                   3, // 000 형식
// //                   'png',
// //                   100, // 000~099 → 100프레임
// //                   key: ValueKey('seq-$_fps-$_isLooping'),
// //                   fullPaths: _fullPaths, // 안전하게 풀경로 사용
// //                   fps: _fps.toDouble(), // ← double
// //                   isAutoPlay: true,
// //                   isOnline: false,
// //                   onReadyToPlay: (state) {
// //                     _seq = state;
// //                     _seq!.setIsLooping(_isLooping);
// //                     setState(() => _isPlaying = _seq!.isPlaying);
// //                   },
// //                   onPlaying: (state) {
// //                     // 디버그: 현재 프레임 경로 계산/표시
// //                     if (state.totalProgress > 0) {
// //                       final ratio =
// //                           (state.currentProgress / state.totalProgress).clamp(
// //                             0.0,
// //                             1.0,
// //                           );
// //                       final idx = (ratio * (_fullPaths.length - 1)).round();
// //                       if (idx >= 0 && idx < _fullPaths.length) {
// //                         _debugPath = _fullPaths[idx];
// //                       }
// //                     }
// //                     setState(() {});
// //                   },
// //                 ),

// //                 // 좌하단 현재 경로 표시(디버그용)
// //                 Positioned(
// //                   left: 8,
// //                   bottom: 8,
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 8,
// //                       vertical: 4,
// //                     ),
// //                     color: Colors.black54,
// //                     child: Text(
// //                       _debugPath ?? '로딩 중...',
// //                       style: const TextStyle(color: Colors.white, fontSize: 12),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //       bottomNavigationBar: Container(
// //         color: const Color(0xFF1A1A1A),
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             // 진행 슬라이더 (progress 단위)
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: Slider(
// //                     min: 0.0,
// //                     max: totalProgress,
// //                     value: currentProgress.clamp(0.0, totalProgress).toDouble(),
// //                     onChanged: (v) {
// //                       _seq?.skip(v); // progress로 점프
// //                       setState(() {});
// //                     },
// //                   ),
// //                 ),
// //                 SizedBox(
// //                   width: 96,
// //                   child: Text(
// //                     _seq == null
// //                         ? '0/0'
// //                         : '${_seq!.currentTime.floor()}/${_seq!.totalTime.floor()}',
// //                     textAlign: TextAlign.center,
// //                     style: const TextStyle(color: Colors.white),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 8),
// //             // FPS 변경(위젯 재생성 방식)
// //             Row(
// //               children: [
// //                 const Text('FPS', style: TextStyle(color: Colors.white)),
// //                 Expanded(
// //                   child: Slider(
// //                     min: 6,
// //                     max: 60,
// //                     divisions: 54,
// //                     value: _fps.toDouble(),
// //                     onChanged: (v) => setState(() => _fps = v.round()),
// //                   ),
// //                 ),
// //                 Text('$_fps', style: const TextStyle(color: Colors.white)),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:image_sequence_animator/image_sequence_animator.dart';

// // // class LearnAnimationScreen extends StatefulWidget {
// // //   const LearnAnimationScreen({super.key});

// // //   @override
// // //   State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
// // // }

// // // class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
// // //   ImageSequenceAnimatorState? _seq;

// // //   int _fps = 24; // 패키지는 int fps
// // //   bool _isLooping = true;
// // //   bool _isPlaying = true;

// // //   late final List<String> _fullPaths; // kkomi_game_base_000 ~ 099
// // //   String? _lastTriedPath; // 디버그 표시용

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fullPaths = List.generate(100, (i) {
// // //       final n = i.toString().padLeft(3, '0'); // 000 ~ 099
// // //       return 'assets/images/kkomi_game_base/kkomi_game_base_$n.png';
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final totalProgress = _seq?.totalProgress ?? 100.0;
// // //     final currentProgress = _seq?.currentProgress ?? 0.0;

// // //     return Scaffold(
// // //       backgroundColor: Colors.black,
// // //       appBar: AppBar(
// // //         title: const Text('학습 애니메이션'),
// // //         actions: [
// // //           IconButton(
// // //             tooltip: _isPlaying ? '일시정지' : '재생',
// // //             onPressed: () {
// // //               if (_seq == null) return;
// // //               if (_seq!.isPlaying) {
// // //                 _seq!.pause();
// // //                 setState(() => _isPlaying = false);
// // //               } else {
// // //                 _seq!.play();
// // //                 setState(() => _isPlaying = true);
// // //               }
// // //             },
// // //             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
// // //           ),
// // //           IconButton(
// // //             tooltip: _isLooping ? '루프 끄기' : '루프 켜기',
// // //             onPressed: () {
// // //               if (_seq == null) return;
// // //               _seq!.setIsLooping(!_isLooping);
// // //               setState(() => _isLooping = !_isLooping);
// // //             },
// // //             icon: Icon(_isLooping ? Icons.loop : Icons.loop_outlined),
// // //           ),
// // //           const SizedBox(width: 8),
// // //         ],
// // //       ),
// // //       body: Center(
// // //         child: FittedBox(
// // //           fit: BoxFit.contain,
// // //           child: SizedBox(
// // //             width: 1280,
// // //             height: 720,
// // //             child: Stack(
// // //               children: [
// // //                 // 시퀀스 애니메이터
// // //                 ImageSequenceAnimator(
// // //                   // fullPaths를 쓰지만, 포지셔널 인자는 형식상 채워야 함
// // //                   'assets/images/kkomi_game_base',
// // //                   'kkomi_game_base_',
// // //                   0,
// // //                   _fullPaths.length - 1,
// // //                   'png',
// // //                   _fps as double,
// // //                   key: ValueKey('seq-$_fps-$_isLooping'),
// // //                   fullPaths: _fullPaths,
// // //                   isAutoPlay: true,
// // //                   isOnline: false,
// // //                   color: Colors.white,
// // //                   onReadyToPlay: (state) {
// // //                     _seq = state;
// // //                     _seq!.setIsLooping(_isLooping);
// // //                     setState(() => _isPlaying = _seq!.isPlaying);
// // //                   },
// // //                   onPlaying: (state) {
// // //                     // 프레임 index = progress 비율로 계산
// // //                     final tp = state.totalProgress;
// // //                     final cp = state.currentProgress;
// // //                     if (tp > 0) {
// // //                       final ratio = (cp / tp).clamp(0.0, 1.0);
// // //                       final idx = (ratio * (_fullPaths.length - 1)).round();
// // //                       if (idx >= 0 && idx < _fullPaths.length) {
// // //                         _lastTriedPath = _fullPaths[idx];
// // //                       }
// // //                     }
// // //                     setState(() {});
// // //                   },
// // //                 ),

// // //                 // 디버그: 현재 프레임 파일 경로 표시
// // //                 Positioned(
// // //                   left: 8,
// // //                   bottom: 8,
// // //                   child: Container(
// // //                     padding: const EdgeInsets.symmetric(
// // //                       horizontal: 8,
// // //                       vertical: 4,
// // //                     ),
// // //                     color: Colors.black54,
// // //                     child: Text(
// // //                       _lastTriedPath ?? '로딩 중...',
// // //                       style: const TextStyle(color: Colors.white, fontSize: 12),
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //       bottomNavigationBar: Container(
// // //         color: const Color(0xFF1A1A1A),
// // //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             // 진행 슬라이더
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: Slider(
// // //                     min: 0.0,
// // //                     max: totalProgress,
// // //                     value: currentProgress.clamp(0.0, totalProgress),
// // //                     onChanged: (v) {
// // //                       _seq?.skip(v); // progress 단위 이동
// // //                       setState(() {});
// // //                     },
// // //                   ),
// // //                 ),
// // //                 SizedBox(
// // //                   width: 96,
// // //                   child: Text(
// // //                     _seq == null
// // //                         ? '0/0'
// // //                         : '${_seq!.currentTime.floor()}/${_seq!.totalTime.floor()}',
// // //                     textAlign: TextAlign.center,
// // //                     style: const TextStyle(color: Colors.white),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 8),
// // //             // 컨트롤 버튼
// // //             Row(
// // //               children: [
// // //                 ElevatedButton.icon(
// // //                   onPressed: () => _seq?.rewind(),
// // //                   icon: const Icon(Icons.replay_10),
// // //                   label: const Text('되감기'),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 ElevatedButton.icon(
// // //                   onPressed: () => _seq?.skip(currentProgress + 10),
// // //                   icon: const Icon(Icons.forward_10),
// // //                   label: const Text('앞으로'),
// // //                 ),
// // //                 const Spacer(),
// // //                 ElevatedButton.icon(
// // //                   onPressed: () => _seq?.restart(),
// // //                   icon: const Icon(Icons.restart_alt),
// // //                   label: const Text('재시작'),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 ElevatedButton.icon(
// // //                   onPressed: () {
// // //                     _seq?.stop();
// // //                     setState(() => _isPlaying = false);
// // //                   },
// // //                   icon: const Icon(Icons.stop),
// // //                   label: const Text('정지'),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 8),
// // //             // FPS 변경 → 패키지에 setFps가 없으므로 위젯 재생성
// // //             Row(
// // //               children: [
// // //                 const Text('FPS', style: TextStyle(color: Colors.white)),
// // //                 Expanded(
// // //                   child: Slider(
// // //                     min: 6,
// // //                     max: 60,
// // //                     divisions: 54,
// // //                     value: _fps.toDouble(),
// // //                     onChanged: (v) => setState(() => _fps = v.round()),
// // //                   ),
// // //                 ),
// // //                 Text('$_fps', style: const TextStyle(color: Colors.white)),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:image_sequence_animator/image_sequence_animator.dart';

// // // // class LearnAnimationScreen extends StatefulWidget {
// // // //   const LearnAnimationScreen({super.key});

// // // //   @override
// // // //   State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
// // // // }

// // // // class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
// // // //   // 패키지의 State 인스턴스를 콜백으로 받아서 제어한다.
// // // //   ImageSequenceAnimatorState? _seq;

// // // //   // 재생 옵션
// // // //   int _fps = 24; // 패키지 시그니처는 int fps
// // // //   bool _isLooping = true; // setIsLooping으로 토글
// // // //   bool _isPlaying = true; // UI 표시 용도

// // // //   // 진행 슬라이더 제어
// // // //   bool _wasPlayingForSlider = false;

// // // //   // 전체 프레임 fullPaths (3자리 zero padding 보장)
// // // //   late final List<String> _fullPaths;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fullPaths = List.generate(100, (i) {
// // // //       final n = i.toString().padLeft(3, '0'); // 000 ~ 099
// // // //       return 'assets/images/kkomi_game_base/kkomi_game_base_$n.png';
// // // //     });
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.black,
// // // //       appBar: AppBar(
// // // //         title: const Text('학습 애니메이션'),
// // // //         actions: [
// // // //           IconButton(
// // // //             tooltip: _isPlaying ? '일시정지' : '재생',
// // // //             onPressed: () {
// // // //               if (_seq == null) return;
// // // //               if (_seq!.isPlaying) {
// // // //                 _seq!.pause();
// // // //                 setState(() => _isPlaying = false);
// // // //               } else {
// // // //                 _seq!.play();
// // // //                 setState(() => _isPlaying = true);
// // // //               }
// // // //             },
// // // //             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
// // // //           ),
// // // //           IconButton(
// // // //             tooltip: _isLooping ? '루프 끄기' : '루프 켜기',
// // // //             onPressed: () {
// // // //               if (_seq == null) return;
// // // //               _seq!.setIsLooping(!_isLooping);
// // // //               setState(() => _isLooping = !_isLooping);
// // // //             },
// // // //             icon: Icon(_isLooping ? Icons.loop : Icons.loop_outlined),
// // // //           ),
// // // //           const SizedBox(width: 8),
// // // //         ],
// // // //       ),
// // // //       body: LayoutBuilder(
// // // //         builder: (context, c) {
// // // //           return Center(
// // // //             child: FittedBox(
// // // //               fit: BoxFit.contain,
// // // //               child: SizedBox(
// // // //                 width: 1280,
// // // //                 height: 720,
// // // //                 // fps를 바꾸면 위젯을 재생성해야 하므로 key에 fps를 섞어서 강제 리빌드
// // // //                 child: ImageSequenceAnimator(
// // // //                   // 데모 시그니처: (pathOrUrl, fileNamePrefix, first, last, ext, fps, ...)
// // // //                   // fullPaths를 주면 내부가 그것만 사용하므로 path/prefix는 의미 없음.
// // // //                   'assets/images/kkomi_game_base',
// // // //                   'kkomi_game_base_',
// // // //                   0,
// // // //                   99,
// // // //                   'png',
// // // //                   _fps as double,
// // // //                   key: ValueKey('seq-$_fps-$_isLooping'),
// // // //                   fullPaths: _fullPaths, // ← 정확한 파일명으로 재생
// // // //                   isAutoPlay: true,
// // // //                   // isLooping은 런타임 토글이 setIsLooping으로 가능하므로 초기값만 주거나 생략해도 OK
// // // //                   // color: Colors.white,    // 필요시 틴트 적용 가능
// // // //                   onReadyToPlay: (state) {
// // // //                     _seq = state;
// // // //                     // 초기 루프 상태 반영
// // // //                     _seq!.setIsLooping(_isLooping);
// // // //                     setState(() {
// // // //                       _isPlaying = _seq!.isPlaying;
// // // //                     });
// // // //                   },
// // // //                   onPlaying: (state) {
// // // //                     // 진행중 UI 업데이트가 필요할 때 호출됨
// // // //                     setState(() {});
// // // //                   },
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           );
// // // //         },
// // // //       ),
// // // //       bottomNavigationBar: _bottomControls(),
// // // //     );
// // // //   }

// // // //   Widget _bottomControls() {
// // // //     final totalProgress = _seq?.totalProgress ?? 100.0;
// // // //     final currentProgress = _seq?.currentProgress ?? 0.0;

// // // //     return Container(
// // // //       color: const Color(0xFF1A1A1A),
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // //       child: Column(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           // 진행 슬라이더 (패키지 데모와 동일한 방식: skip(progress))
// // // //           Row(
// // // //             children: [
// // // //               Expanded(
// // // //                 child: Slider(
// // // //                   min: 0.0,
// // // //                   max: totalProgress,
// // // //                   value: currentProgress.clamp(0.0, totalProgress),
// // // //                   onChangeStart: (_) {
// // // //                     if (_seq == null) return;
// // // //                     _wasPlayingForSlider = _seq!.isPlaying;
// // // //                     _seq!.pause();
// // // //                   },
// // // //                   onChanged: (v) {
// // // //                     _seq?.skip(v); // progress로 점프
// // // //                     setState(() {});
// // // //                   },
// // // //                   onChangeEnd: (_) {
// // // //                     if (_wasPlayingForSlider) _seq?.play();
// // // //                   },
// // // //                 ),
// // // //               ),
// // // //               SizedBox(
// // // //                 width: 96,
// // // //                 child: Text(
// // // //                   _seq == null
// // // //                       ? '0/0'
// // // //                       : '${_seq!.currentTime.floor()}/${_seq!.totalTime.floor()}',
// // // //                   textAlign: TextAlign.center,
// // // //                   style: const TextStyle(color: Colors.white),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),

// // // //           const SizedBox(height: 8),

// // // //           // 버튼들: 되감기/앞으로/재시작/정지
// // // //           Row(
// // // //             children: [
// // // //               ElevatedButton.icon(
// // // //                 onPressed: () => _seq?.rewind(),
// // // //                 icon: const Icon(Icons.replay_10),
// // // //                 label: const Text('되감기'),
// // // //               ),
// // // //               const SizedBox(width: 8),
// // // //               ElevatedButton.icon(
// // // //                 onPressed: () => _seq?.skip(currentProgress + 10),
// // // //                 icon: const Icon(Icons.forward_10),
// // // //                 label: const Text('앞으로'),
// // // //               ),
// // // //               const Spacer(),
// // // //               ElevatedButton.icon(
// // // //                 onPressed: () => _seq?.restart(),
// // // //                 icon: const Icon(Icons.restart_alt),
// // // //                 label: const Text('재시작'),
// // // //               ),
// // // //               const SizedBox(width: 8),
// // // //               ElevatedButton.icon(
// // // //                 onPressed: () {
// // // //                   _seq?.stop();
// // // //                   setState(() => _isPlaying = false);
// // // //                 },
// // // //                 icon: const Icon(Icons.stop),
// // // //                 label: const Text('정지'),
// // // //               ),
// // // //             ],
// // // //           ),

// // // //           const SizedBox(height: 8),

// // // //           // FPS 조절 (패키지에 setFps가 없으므로 위젯 재생성 방식)
// // // //           Row(
// // // //             children: [
// // // //               const Text('FPS', style: TextStyle(color: Colors.white)),
// // // //               Expanded(
// // // //                 child: Slider(
// // // //                   min: 6,
// // // //                   max: 60,
// // // //                   divisions: 54,
// // // //                   value: _fps.toDouble(),
// // // //                   onChanged: (v) => setState(() => _fps = v.round()),
// // // //                 ),
// // // //               ),
// // // //               Text('$_fps', style: const TextStyle(color: Colors.white)),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // import 'package:flutter/material.dart';

// // // // /// 간단 PNG 시퀀스 플레이어 (패키지 의존성 없음)
// // // // /// prefix: 'assets/images/kkomi_game_base/kkomi_game_base_'
// // // // /// ext: 'png'
// // // // /// start=0, end=99, digits=3  ->  kkomi_game_base_000.png ~ _099.png
// // // // class PngSequencePlayer extends StatefulWidget {
// // // //   final String prefix;
// // // //   final String ext;
// // // //   final int start;
// // // //   final int end; // inclusive
// // // //   final int digits;
// // // //   final double fps;
// // // //   final bool isLooping;
// // // //   final bool autoPlay;
// // // //   final VoidCallback? onComplete;

// // // //   const PngSequencePlayer({
// // // //     super.key,
// // // //     required this.prefix,
// // // //     required this.ext,
// // // //     required this.start,
// // // //     required this.end,
// // // //     this.digits = 3,
// // // //     this.fps = 24,
// // // //     this.isLooping = true,
// // // //     this.autoPlay = true,
// // // //     this.onComplete,
// // // //   });

// // // //   @override
// // // //   State<PngSequencePlayer> createState() => PngSequencePlayerState();
// // // // }

// // // // class PngSequencePlayerState extends State<PngSequencePlayer>
// // // //     with SingleTickerProviderStateMixin {
// // // //   late AnimationController _controller;
// // // //   late int _frameCount;
// // // //   late double _fps;

// // // //   int get _currentFrameIndex {
// // // //     final idx = (widget.start + (_controller.value * _frameCount).floor());
// // // //     return idx.clamp(widget.start, widget.end);
// // // //   }

// // // //   String get _currentAssetPath {
// // // //     final n = _currentFrameIndex.toString().padLeft(widget.digits, '0');
// // // //     return '${widget.prefix}$n.${widget.ext}';
// // // //   }

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _frameCount = (widget.end - widget.start + 1).clamp(1, 1000000);
// // // //     _fps = widget.fps;
// // // //     _controller =
// // // //         AnimationController(
// // // //             vsync: this,
// // // //             duration: Duration(
// // // //               milliseconds: (_frameCount / _fps * 1000).round(),
// // // //             ),
// // // //           )
// // // //           ..addStatusListener((s) {
// // // //             if (s == AnimationStatus.completed) {
// // // //               if (widget.isLooping) {
// // // //                 _controller.repeat();
// // // //               } else {
// // // //                 widget.onComplete?.call();
// // // //               }
// // // //             }
// // // //           })
// // // //           ..addListener(() {
// // // //             // 프레임 갱신
// // // //             setState(() {});
// // // //           });

// // // //     if (widget.autoPlay) {
// // // //       widget.isLooping ? _controller.repeat() : _controller.forward(from: 0);
// // // //     }
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _controller.dispose();
// // // //     super.dispose();
// // // //   }

// // // //   // 외부 제어용 메서드
// // // //   void play() {
// // // //     widget.isLooping ? _controller.repeat() : _controller.forward();
// // // //   }

// // // //   void pause() => _controller.stop();

// // // //   void rewind([int frames = 10]) {
// // // //     final delta = frames / _frameCount;
// // // //     _controller.value = (_controller.value - delta).clamp(0.0, 1.0);
// // // //   }

// // // //   void skip([int frames = 10]) {
// // // //     final delta = frames / _frameCount;
// // // //     _controller.value = (_controller.value + delta).clamp(0.0, 1.0);
// // // //   }

// // // //   void setFps(double fps) {
// // // //     _fps = fps.clamp(1, 120);
// // // //     final playing = _controller.isAnimating;
// // // //     final pos = _controller.value;
// // // //     _controller.duration = Duration(
// // // //       milliseconds: (_frameCount / _fps * 1000).round(),
// // // //     );
// // // //     if (playing) {
// // // //       widget.isLooping
// // // //           ? _controller.repeat(min: pos)
// // // //           : _controller.forward(from: pos);
// // // //     } else {
// // // //       _controller.value = pos; // 위치 유지
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Image.asset(
// // // //       _currentAssetPath,
// // // //       gaplessPlayback: true, // 프레임 전환시 깜빡임 최소화
// // // //       fit: BoxFit.contain,
// // // //     );
// // // //   }
// // // // }

// // // // class LearnAnimationScreen extends StatefulWidget {
// // // //   const LearnAnimationScreen({super.key});

// // // //   @override
// // // //   State<LearnAnimationScreen> createState() => _LearnAnimationScreenState();
// // // // }

// // // // class _LearnAnimationScreenState extends State<LearnAnimationScreen> {
// // // //   final _playerKey = GlobalKey<PngSequencePlayerState>();
// // // //   double _fps = 24;
// // // //   bool _isPlaying = true;
// // // //   bool _isLooping = true;

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.black,
// // // //       appBar: AppBar(
// // // //         title: const Text('학습 애니메이션'),
// // // //         actions: [
// // // //           IconButton(
// // // //             tooltip: _isPlaying ? '일시정지' : '재생',
// // // //             onPressed: () {
// // // //               final ctrl = _playerKey.currentState;
// // // //               if (ctrl == null) return;
// // // //               if (_isPlaying) {
// // // //                 ctrl.pause();
// // // //               } else {
// // // //                 ctrl.play();
// // // //               }
// // // //               setState(() => _isPlaying = !_isPlaying);
// // // //             },
// // // //             icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
// // // //           ),
// // // //           // 루프 토글은 내부 위젯의 isLooping을 바꾸려면 다시 빌드가 필요.
// // // //           // 간단히 Navigator로 다시 열거나, 여기선 setState로 전체를 리빌드해 새 값 전달.
// // // //           IconButton(
// // // //             tooltip: _isLooping ? '루프 끄기' : '루프 켜기',
// // // //             onPressed: () => setState(() => _isLooping = !_isLooping),
// // // //             icon: Icon(_isLooping ? Icons.loop : Icons.loop_outlined),
// // // //           ),
// // // //           const SizedBox(width: 8),
// // // //         ],
// // // //       ),
// // // //       body: LayoutBuilder(
// // // //         builder: (context, c) {
// // // //           return Center(
// // // //             child: FittedBox(
// // // //               fit: BoxFit.contain,
// // // //               child: SizedBox(
// // // //                 width: 1280,
// // // //                 height: 720,
// // // //                 child: PngSequencePlayer(
// // // //                   key: _playerKey,
// // // //                   prefix: 'assets/images/kkomi_game_base/kkomi_game_base_',
// // // //                   ext: 'png',
// // // //                   start: 0,
// // // //                   end: 99,
// // // //                   digits: 3, // 000 패딩
// // // //                   fps: _fps,
// // // //                   isLooping: _isLooping,
// // // //                   autoPlay: true,
// // // //                   onComplete: () {
// // // //                     // 루프가 꺼져 있을 때만 호출
// // // //                   },
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           );
// // // //         },
// // // //       ),
// // // //       bottomNavigationBar: _controls(),
// // // //     );
// // // //   }

// // // //   Widget _controls() {
// // // //     return Container(
// // // //       color: const Color(0xFF1A1A1A),
// // // //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // //       child: Row(
// // // //         children: [
// // // //           const Text('FPS', style: TextStyle(color: Colors.white)),
// // // //           Expanded(
// // // //             child: Slider(
// // // //               min: 6,
// // // //               max: 60,
// // // //               divisions: 54,
// // // //               value: _fps,
// // // //               onChanged: (v) {
// // // //                 setState(() => _fps = v);
// // // //                 _playerKey.currentState?.setFps(v);
// // // //               },
// // // //             ),
// // // //           ),
// // // //           Text(
// // // //             _fps.toStringAsFixed(0),
// // // //             style: const TextStyle(color: Colors.white),
// // // //           ),
// // // //           const SizedBox(width: 16),
// // // //           ElevatedButton.icon(
// // // //             onPressed: () => _playerKey.currentState?.rewind(10),
// // // //             icon: const Icon(Icons.replay_10),
// // // //             label: const Text('되감기'),
// // // //           ),
// // // //           const SizedBox(width: 8),
// // // //           ElevatedButton.icon(
// // // //             onPressed: () => _playerKey.currentState?.skip(10),
// // // //             icon: const Icon(Icons.forward_10),
// // // //             label: const Text('앞으로'),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // }
