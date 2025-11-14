import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/scroll_physics.dart';
import '../theme/tokens.dart';
import '../services/settings_service.dart';
import 'post_detail_screen.dart';

class SnsScreen extends StatefulWidget {
  const SnsScreen({super.key});

  @override
  State<SnsScreen> createState() => _SnsScreenState();
}

class _SnsScreenState extends State<SnsScreen> {
  String? _selectedSubject;
  List<String> _teacherSubjects = [];

  final List<Map<String, dynamic>> _allPosts = [
    {
      'id': '1',
      'author': '김선생',
      'subject': '수학',
      'content': '오늘 학생들과 함께 문제를 풀었는데 정말 뿌듯하네요!',
      'likes': 12,
      'comments': 5,
      'time': '2시간 전',
      'isLiked': false,
    },
    {
      'id': '2',
      'author': '이선생',
      'subject': '영어',
      'content': '새로운 교수법을 시도해봤는데 학생들의 반응이 좋았어요. 추천합니다!',
      'likes': 28,
      'comments': 8,
      'time': '5시간 전',
      'isLiked': true,
    },
    {
      'id': '3',
      'author': '박선생',
      'subject': '과학',
      'content': '실험 수업 준비하는데 도움이 될 만한 자료를 공유합니다.',
      'likes': 15,
      'comments': 3,
      'time': '1일 전',
      'isLiked': false,
    },
    {
      'id': '4',
      'author': '최선생',
      'subject': '수학',
      'content': '중학교 2학년 함수 단원 수업 자료 공유합니다. 도움이 되셨으면 좋겠어요!',
      'likes': 34,
      'comments': 12,
      'time': '3시간 전',
      'isLiked': false,
    },
    {
      'id': '5',
      'author': '정선생',
      'subject': '국어',
      'content': '문학 작품 해석 수업에서 학생들이 많이 참여했어요. 토론식 수업 추천드립니다.',
      'likes': 19,
      'comments': 7,
      'time': '6시간 전',
      'isLiked': true,
    },
    {
      'id': '6',
      'author': '강선생',
      'subject': '영어',
      'content': '영어 회화 수업에서 게임을 활용했는데 학생들이 너무 좋아했어요. 자료 공유합니다!',
      'likes': 42,
      'comments': 15,
      'time': '8시간 전',
      'isLiked': false,
    },
    {
      'id': '7',
      'author': '윤선생',
      'subject': '과학',
      'content': '화학 실험 수업 준비물 리스트 정리했습니다. 참고하세요!',
      'likes': 27,
      'comments': 9,
      'time': '12시간 전',
      'isLiked': false,
    },
    {
      'id': '8',
      'author': '장선생',
      'subject': '수학',
      'content': '고등학교 미적분 단원에서 학생들이 어려워하는 부분을 쉽게 설명하는 방법을 찾았어요.',
      'likes': 38,
      'comments': 11,
      'time': '1일 전',
      'isLiked': true,
    },
    {
      'id': '9',
      'author': '임선생',
      'subject': '사회',
      'content': '역사 수업에서 타임라인을 활용한 수업 방법을 공유합니다. 시각적으로 이해하기 쉬워요!',
      'likes': 23,
      'comments': 6,
      'time': '1일 전',
      'isLiked': false,
    },
    {
      'id': '10',
      'author': '한선생',
      'subject': '영어',
      'content': '영어 문법 수업에서 학생들이 자주 틀리는 부분을 정리한 자료입니다.',
      'likes': 31,
      'comments': 10,
      'time': '2일 전',
      'isLiked': false,
    },
    {
      'id': '11',
      'author': '조선생',
      'subject': '과학',
      'content': '물리 실험 수업 영상 자료를 만들었는데 학생들이 이해를 잘 했어요.',
      'likes': 29,
      'comments': 8,
      'time': '2일 전',
      'isLiked': true,
    },
    {
      'id': '12',
      'author': '오선생',
      'subject': '국어',
      'content': '독서 수업에서 학생들이 책을 읽고 토론하는 시간을 가졌어요. 정말 의미있었습니다.',
      'likes': 18,
      'comments': 5,
      'time': '3일 전',
      'isLiked': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    if (_allPosts.isEmpty) {
      return [];
    }
    if (_selectedSubject == null) {
      return _allPosts;
    }
    return _allPosts.where((post) {
      final subject = post['subject'];
      return subject != null && subject == _selectedSubject;
    }).toList();
  }

  List<String> get _availableSubjects {
    // 선생님이 가르치는 과목만 반환
    if (_teacherSubjects.isEmpty) {
      return [];
    }
    return List<String>.from(_teacherSubjects)..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherSubjects();
  }

  Future<void> _loadTeacherSubjects() async {
    try {
      final subjects = await SettingsService.getTeacherSubjects();
      if (mounted) {
        setState(() {
          _teacherSubjects = subjects.isNotEmpty ? subjects : [];
        });
      }
    } catch (e) {
      print('⚠️ 선생님 과목 목록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _teacherSubjects = [];
        });
      }
    }
  }


  void _toggleLike(int index) {
    // 햅틱 피드백 추가
    HapticFeedback.lightImpact();
    
    setState(() {
      final filteredPosts = _filteredPosts;
      if (index >= filteredPosts.length) return;
      
      final post = filteredPosts[index];
      final currentLiked = post['isLiked'] as bool? ?? false;
      post['isLiked'] = !currentLiked;
      
      final currentLikes = post['likes'] as int? ?? 0;
      if (post['isLiked'] as bool) {
        post['likes'] = currentLikes + 1;
      } else {
        post['likes'] = (currentLikes - 1).clamp(0, double.infinity).toInt();
      }
    });
  }

  void _selectSubject(String? subject) {
    setState(() {
      _selectedSubject = _selectedSubject == subject ? null : subject;
    });
  }

  Future<void> _refreshPosts() async {
    // 새로고침 로직 (필요시 API 호출)
    await Future.delayed(const Duration(milliseconds: 500));
    // 선생님 과목 목록도 다시 로드
    await _loadTeacherSubjects();
    setState(() {
      // 데이터 새로고침
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: TossScrollPhysics(),
          ),
          slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            pinned: true,
            title: Text(
              '커뮤니티',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: false,
          ),
          // Content
          SliverPadding(
            padding: EdgeInsets.all(Gaps.screen),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filteredPosts = _filteredPosts;
                  if (index == 0) {
                    return _buildFilterSection(theme, colorScheme);
                  }
                  final postIndex = index - 1;
                  if (postIndex >= filteredPosts.length) {
                    return null;
                  }
                  return Padding(
                    padding: EdgeInsets.only(bottom: Gaps.card),
                    child: _buildPostCard(
                      filteredPosts[postIndex],
                      theme,
                      colorScheme,
                      postIndex,
                    ),
                  );
                },
                childCount: _filteredPosts.length + 1,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme, ColorScheme colorScheme) {
    final subjects = _availableSubjects;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 전체 버튼
              _buildFilterChip(
                label: '전체',
                isSelected: _selectedSubject == null,
                onTap: () => _selectSubject(null),
                theme: theme,
              ),
              SizedBox(width: Gaps.row),
              // 과목별 필터 버튼
              if (subjects.isNotEmpty)
                ...subjects.map((subject) {
                  return Padding(
                    padding: EdgeInsets.only(right: Gaps.row),
                    child: _buildFilterChip(
                      label: subject,
                      isSelected: _selectedSubject == subject,
                      onTap: () => _selectSubject(subject),
                      theme: theme,
                    ),
                  );
                }),
            ],
          ),
        ),
        SizedBox(height: Gaps.card),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final isLiked = post['isLiked'] as bool;
    final likes = post['likes'] as int;
    final comments = post['comments'] as int;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: EdgeInsets.all(Gaps.cardPad),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author & Subject
            Row(
              children: [
                // Author Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (post['author'] as String)[0],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Gaps.row),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Gaps.row,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(Radii.chip),
                            ),
                            child: Text(
                              post['subject'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(width: Gaps.row - 2),
                          Text(
                            post['time'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Gaps.card),
            // Content
            Text(
              post['content'] as String,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            SizedBox(height: Gaps.card),
            // Actions
            Row(
              children: [
                // Like Button
                _AnimatedLikeButton(
                  isLiked: isLiked,
                  likes: likes,
                  onTap: () => _toggleLike(index),
                ),
                SizedBox(width: Gaps.row),
                // Comment Button
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(Radii.icon),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Gaps.row,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$comments',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 애니메이션이 적용된 좋아요 버튼
class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(Radii.icon),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Gaps.row,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: widget.isLiked
              ? AppColors.primaryLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.icon),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: widget.isLiked
                    ? AppColors.error
                    : AppColors.textMuted,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '${widget.likes}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.isLiked
                    ? AppColors.error
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


