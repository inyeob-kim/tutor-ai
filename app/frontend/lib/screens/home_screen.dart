import 'package:flutter/material.dart';
import '../widgets/badge.dart' show CustomBadge;
import '../widgets/section_title.dart';

enum ScheduleStatus { completed, current, upcoming }

class ScheduleItem {
  final String id;
  final String time;
  final String endTime;
  final String student;
  final String subject;
  ScheduleStatus status;

  ScheduleItem({
    required this.id,
    required this.time,
    required this.endTime,
    required this.student,
    required this.subject,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScheduleItem> schedule = [
    ScheduleItem(
      id: "1",
      time: "10:00",
      endTime: "11:30",
      student: "김민수",
      subject: "수학",
      status: ScheduleStatus.completed,
    ),
    ScheduleItem(
      id: "2",
      time: "14:00",
      endTime: "15:00",
      student: "이지은",
      subject: "영어",
      status: ScheduleStatus.current,
    ),
    ScheduleItem(
      id: "3",
      time: "16:00",
      endTime: "17:00",
      student: "박서준",
      subject: "과학",
      status: ScheduleStatus.upcoming,
    ),
    ScheduleItem(
      id: "4",
      time: "18:00",
      endTime: "19:00",
      student: "최유진",
      subject: "수학",
      status: ScheduleStatus.upcoming,
    ),
  ];

  bool showAiModal = false;

  void toggleComplete(String id) {
    setState(() {
      final item = schedule.firstWhere((s) => s.id == id);
      item.status = item.status == ScheduleStatus.completed
          ? ScheduleStatus.upcoming
          : ScheduleStatus.completed;
    });
  }

  Map<String, dynamic> get stats {
    final total = schedule.length;
    final completed = schedule.where((s) => s.status == ScheduleStatus.completed).length;
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;
    const unpaid = 2;
    return {
      'total': total,
      'completed': completed,
      'completionRate': completionRate,
      'unpaid': unpaid,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '안녕하세요! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오늘 ${stats['total']}개 수업이 예정되어 있어요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 오늘의 스케줄 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle(title: '오늘의 스케줄'),
                CustomBadge(text: '${stats['total']}개'),
              ],
            ),
            const SizedBox(height: 12),

            // 스케줄 리스트
            ...schedule.map((item) => _buildScheduleCard(item)).toList(),

            const SizedBox(height: 24),

            // 빠른 실행 섹션
            const SectionTitle(title: '빠른 실행'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.calendar_today,
                    iconColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFDBEAFE),
                    title: '수업 등록',
                    subtitle: '새 수업 추가',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFF9333EA),
                    backgroundColor: const Color(0xFFF3E8FF),
                    title: 'AI 어시스턴트',
                    subtitle: '음성으로 관리',
                    onTap: () {
                      setState(() {
                        showAiModal = true;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 오늘의 현황 섹션
            const SectionTitle(title: '오늘의 현황'),
            const SizedBox(height: 12),
            _buildStatsCard(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showAiModal = true;
          });
        },
        backgroundColor: const Color(0xFF9333EA),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    final isCompleted = item.status == ScheduleStatus.completed;
    final isCurrent = item.status == ScheduleStatus.current;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEFF6FF) : Colors.white,
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF3B82F6)
              : isCompleted
                  ? Colors.grey[300]!
                  : Colors.grey[200]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => toggleComplete(item.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 체크박스
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // 스케줄 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.time} - ${item.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isCurrent ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            const CustomBadge(
                              text: '진행중',
                              backgroundColor: Color(0xFF3B82F6),
                              textColor: Colors.white,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.student,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey[500] : Colors.black87,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFDBEAFE),
              value: '${stats['total']}',
              label: '오늘 수업',
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF10B981),
              backgroundColor: const Color(0xFFD1FAE5),
              value: '${stats['completed']}',
              label: '완료',
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.trending_up,
              iconColor: const Color(0xFF9333EA),
              backgroundColor: const Color(0xFFF3E8FF),
              value: '${stats['completionRate']}%',
              label: '주간 완료율',
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.warning,
              iconColor: const Color(0xFFF97316),
              backgroundColor: const Color(0xFFFED7AA),
              value: '${stats['unpaid']}',
              label: '미납',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
