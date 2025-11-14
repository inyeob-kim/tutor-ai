import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likes = 0;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['isLiked'] as bool? ?? false;
    _likes = widget.post['likes'] as int? ?? 0;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() {
    // 테스트 댓글 데이터
    final postId = widget.post['id'] as String;
    final testComments = {
      '1': [
        {
          'id': 'c1',
          'author': '이선생',
          'content': '정말 좋은 자료네요! 저도 활용해볼게요.',
          'time': '1시간 전',
          'isLiked': false,
          'likes': 3,
        },
        {
          'id': 'c2',
          'author': '박선생',
          'content': '저도 비슷한 경험이 있어요. 학생들이 정말 좋아했어요.',
          'time': '2시간 전',
          'isLiked': true,
          'likes': 5,
        },
        {
          'id': 'c3',
          'author': '최선생',
          'content': '추가로 이런 방법도 시도해보시면 좋을 것 같아요.',
          'time': '3시간 전',
          'isLiked': false,
          'likes': 2,
        },
      ],
      '2': [
        {
          'id': 'c4',
          'author': '김선생',
          'content': '저도 이 방법을 사용하고 있는데 효과가 좋아요!',
          'time': '30분 전',
          'isLiked': false,
          'likes': 1,
        },
        {
          'id': 'c5',
          'author': '정선생',
          'content': '학생들의 반응이 어떤가요?',
          'time': '1시간 전',
          'isLiked': false,
          'likes': 0,
        },
      ],
      '3': [
        {
          'id': 'c6',
          'author': '강선생',
          'content': '실험 준비물 리스트 정리해주셔서 감사합니다!',
          'time': '2시간 전',
          'isLiked': true,
          'likes': 4,
        },
      ],
    };

    setState(() {
      _comments = (testComments[postId] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes = _isLiked ? _likes + 1 : (_likes - 1).clamp(0, double.infinity).toInt();
    });
  }

  void _toggleCommentLike(int index) {
    setState(() {
      final comment = _comments[index];
      final isLiked = comment['isLiked'] as bool? ?? false;
      comment['isLiked'] = !isLiked;
      final currentLikes = comment['likes'] as int? ?? 0;
      comment['likes'] = !isLiked ? currentLikes + 1 : (currentLikes - 1).clamp(0, double.infinity).toInt();
    });
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _comments.insert(0, {
        'id': 'c${DateTime.now().millisecondsSinceEpoch}',
        'author': '나',
        'content': _commentController.text.trim(),
        'time': '방금 전',
        'isLiked': false,
        'likes': 0,
      });
      _commentController.clear();
    });

    // 키보드 닫기
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              padding: EdgeInsets.symmetric(horizontal: Gaps.screen),
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '게시물',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: 공유 기능
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Gaps.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 게시물 카드
                    _buildPostCard(theme, colorScheme),
                    SizedBox(height: Gaps.card),

                    // 댓글 섹션 헤더
                    Row(
                      children: [
                        Text(
                          '댓글 ${_comments.length}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Gaps.card),

                    // 댓글 목록
                    if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(Gaps.screen * 2),
                          child: Column(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: Gaps.card),
                              Text(
                                '아직 댓글이 없습니다',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._comments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final comment = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: Gaps.card),
                          child: _buildCommentCard(comment, index, theme, colorScheme),
                        );
                      }),

                    SizedBox(height: Gaps.screen * 2),
                  ],
                ),
              ),
            ),

            // 댓글 입력창
            Container(
              padding: EdgeInsets.all(Gaps.screen),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.chip),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Gaps.card,
                            vertical: 12,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    SizedBox(width: Gaps.row),
                    IconButton(
                      onPressed: _addComment,
                      icon: Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(ThemeData theme, ColorScheme colorScheme) {
    final post = widget.post;
    final author = post['author'] as String;
    final subject = post['subject'] as String;
    final content = post['content'] as String;
    final time = post['time'] as String;
    final comments = post['comments'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(Gaps.cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Subject
          Row(
            children: [
              // Author Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    author[0],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Gaps.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Gaps.row,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(Radii.chip),
                          ),
                          child: Text(
                            subject,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        SizedBox(width: Gaps.row - 2),
                        Text(
                          time,
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
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          SizedBox(height: Gaps.card),
          // Actions
          Row(
            children: [
              // Like Button
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(Radii.icon),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Gaps.row,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isLiked
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.icon),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: _isLiked
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '$_likes',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isLiked
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: Gaps.row),
              // Comment Button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Gaps.row,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
    Map<String, dynamic> comment,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final author = comment['author'] as String;
    final content = comment['content'] as String;
    final time = comment['time'] as String;
    final isLiked = comment['isLiked'] as bool? ?? false;
    final likes = comment['likes'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(Gaps.cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Time
          Row(
            children: [
              // Author Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    author[0],
                    style: theme.textTheme.bodyMedium?.copyWith(
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
                      author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Gaps.card),
          // Content
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          SizedBox(height: Gaps.row),
          // Like Button
          InkWell(
            onTap: () => _toggleCommentLike(index),
            borderRadius: BorderRadius.circular(Radii.icon),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Gaps.row,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: isLiked
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$likes',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLiked
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

