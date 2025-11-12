import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlaying = false;
  String? _transcribedText;
  String? _aiResponseText;
  String? _audioPath;
  String? _responseAudioPath;
  Duration _recordingDuration = Duration.zero;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String? _sessionId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _checkPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('마이크 권한이 필요합니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // 권한 확인
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('마이크 권한이 필요합니다.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      // 임시 파일 경로
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioPath = '${directory.path}/recording_$timestamp.m4a';

      // 녹음 시작
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _audioPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
          _errorMessage = null;
        });

        // 녹음 시간 업데이트
        _updateRecordingDuration();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('마이크 권한이 없습니다.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '녹음 시작 실패: $e';
      });
    }
  }

  void _updateRecordingDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
        _updateRecordingDuration();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      if (_audioPath != null) {
        await _processAudio();
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = '녹음 중지 실패: $e';
      });
    }
  }

  Future<void> _processAudio() async {
    if (_audioPath == null) return;

    setState(() {
      _isProcessing = true;
      _transcribedText = null;
      _aiResponseText = null;
      _responseAudioPath = null;
      _errorMessage = null;
    });

    try {
      // 오디오 파일 읽기
      final audioFile = File(_audioPath!);
      if (!await audioFile.exists()) {
        throw Exception('오디오 파일을 찾을 수 없습니다.');
      }

      final audioBytes = await audioFile.readAsBytes();

      // API 호출
      final uri = Uri.parse('${ApiService.baseUrl}/ai/process_audio');
      final request = http.MultipartRequest('POST', uri);
      
      if (_sessionId != null) {
        request.fields['session_id'] = _sessionId!;
      }
      request.fields['teacher_id'] = '1'; // TODO: 실제 teacher_id 가져오기
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.m4a',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        setState(() {
          _sessionId = data['session_id'] as String?;
          _aiResponseText = data['text'] as String?;
        });

        // 오디오 응답이 있으면 재생
        if (data.containsKey('audio')) {
          final audioBase64 = data['audio'] as String;
          final audioBytes = base64Decode(audioBase64);
          
          // 임시 파일로 저장
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _responseAudioPath = '${directory.path}/response_$timestamp.mp3';
          
          final responseFile = File(_responseAudioPath!);
          await responseFile.writeAsBytes(audioBytes);
          
          // 자동 재생
          await _playResponseAudio();
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '처리 실패: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _playResponseAudio() async {
    if (_responseAudioPath == null) return;

    try {
      setState(() {
        _isPlaying = true;
      });

      await _audioPlayer.play(DeviceFileSource(_responseAudioPath!));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _errorMessage = '오디오 재생 실패: $e';
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('AI 어시스턴트'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const TossScrollPhysics(),
          padding: EdgeInsets.all(Gaps.cardPad + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 메시지
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.card + 2),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(Gaps.cardPad),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      SizedBox(height: Gaps.row),
                      Text(
                        '음성으로 말씀해주세요',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Gaps.row - 2),
                      Text(
                        '예: "김민수 학생 내일 오후 2시 수업 등록해줘"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: Gaps.screen * 2),
              
              // 녹음 버튼
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording
                                ? AppColors.error
                                : colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? AppColors.error
                                        : colorScheme.primary)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: 48,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: Gaps.cardPad + 4),
              
              // 녹음 시간 표시
              if (_isRecording)
                Center(
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              
              // 처리 중 표시
              if (_isProcessing) ...[
                SizedBox(height: Gaps.cardPad + 4),
                Center(
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: Gaps.row),
                Center(
                  child: Text(
                    '처리 중...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              
              // AI 응답 텍스트
              if (_aiResponseText != null) ...[
                SizedBox(height: Gaps.card + 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.card + 2),
                    side: BorderSide(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: EdgeInsets.all(Gaps.cardPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: Gaps.row - 2),
                            Text(
                              'AI 응답',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Gaps.row),
                        Text(
                          _aiResponseText!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (_responseAudioPath != null && !_isPlaying) ...[
                          SizedBox(height: Gaps.card),
                          OutlinedButton.icon(
                            onPressed: _playResponseAudio,
                            icon: Icon(Icons.play_arrow),
                            label: Text('다시 듣기'),
                          ),
                        ],
                        if (_isPlaying) ...[
                          SizedBox(height: Gaps.card),
                          Row(
                            children: [
                              SizedBox(
                                width: Gaps.card,
                                height: Gaps.card,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: Gaps.row - 2),
                              Text(
                                '재생 중...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              
              // 에러 메시지
              if (_errorMessage != null) ...[
                SizedBox(height: Gaps.cardPad + 4),
                Card(
                  elevation: 0,
                  color: AppColors.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip + 4),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(Gaps.card),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(width: Gaps.row),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: Gaps.screen * 2),
            ],
          ),
        ),
      ),
    );
  }
}

