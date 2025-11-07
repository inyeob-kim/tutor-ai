// ===================================
// 📱 HomeScreen.tsx (Expo Router Tab Home) — AI 모달 분리 버전
// ===================================

import { AlertCircle, Calendar, CheckCircle, Sparkles, TrendingUp } from "lucide-react-native";
import React, { useCallback, useMemo, useState } from "react";
import { FlatList, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import AiAssistantModal from "@/components/ai/AiAssistantModal";
import { Badge } from "@/components/ui/Badge";
import { Card, CardContent } from "@/components/ui/Card";
import { SectionTitle } from "@/components/ui/SectionTitle";

type ScheduleStatus = "completed" | "current" | "upcoming";
type ScheduleItem = {
  id: string;
  time: string;
  endTime: string;
  student: string;
  subject: string;
  status: ScheduleStatus;
};

export default function HomeScreen() {
  const [showAiModal, setShowAiModal] = useState(false);
  const [schedule, setSchedule] = useState<ScheduleItem[]>([
    { id: "1", time: "10:00", endTime: "11:30", student: "김민수", subject: "수학", status: "completed" },
    { id: "2", time: "14:00", endTime: "15:00", student: "이지은", subject: "영어", status: "current" },
    { id: "3", time: "16:00", endTime: "17:00", student: "박서준", subject: "과학", status: "upcoming" },
    { id: "4", time: "18:00", endTime: "19:00", student: "최유진", subject: "수학", status: "upcoming" },
  ]);

  const toggleComplete = useCallback((id: string) => {
    setSchedule(prev =>
      prev.map(item =>
        item.id === id ? { ...item, status: item.status === "completed" ? "upcoming" : "completed" } : item
      )
    );
  }, []);

  const stats = useMemo(() => {
    const total = schedule.length;
    const completed = schedule.filter(s => s.status === "completed").length;
    const completionRate = total ? Math.round((completed / total) * 100) : 0;
    const unpaid = 2;
    return { total, completed, completionRate, unpaid };
  }, [schedule]);

  const renderItem = useCallback(
    ({ item }: { item: ScheduleItem }) => {
      const isCompleted = item.status === "completed";
      const isCurrent = item.status === "current";

      return (
        <Card
          style={[
            styles.scheduleCard,
            isCurrent && styles.scheduleCardCurrent,
            isCompleted && styles.scheduleCardCompleted,
          ]}
        >
          <CardContent style={styles.scheduleCardContent}>
            <TouchableOpacity
              accessibilityRole="checkbox"
              accessibilityState={{ checked: isCompleted }}
              accessibilityLabel={`${item.student} ${item.subject} 수업 완료 처리`}
              onPress={() => toggleComplete(item.id)}
              style={[styles.checkbox, isCompleted && styles.checkboxCompleted]}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            >
              {isCompleted && <CheckCircle size={16} color="white" />}
            </TouchableOpacity>

            <View style={styles.scheduleInfo}>
              <View style={styles.scheduleTimeRow}>
                <View style={[styles.timeTag, isCurrent && styles.timeTagCurrent]}>
                  <Text style={[styles.timeTagText, isCurrent && styles.timeTagTextCurrent]}>
                    {item.time} - {item.endTime}
                  </Text>
                </View>
                {isCurrent && <Badge variant="default">진행중</Badge>}
              </View>

              <Text style={[styles.studentName, isCompleted && styles.completedText]}>{item.student}</Text>
              <Text style={styles.subject}>{item.subject}</Text>
            </View>
          </CardContent>
        </Card>
      );
    },
    [toggleComplete]
  );

  return (
    <SafeAreaView style={styles.container} edges={["top"]}>
      <FlatList
        ListHeaderComponent={
          <>
            <View style={styles.header}>
              <Text style={styles.headerTitle}>안녕하세요! 👋</Text>
              <Text style={styles.headerSubtitle}>오늘 {stats.total}개 수업이 예정되어 있어요</Text>
            </View>

            <View style={styles.content}>
              <View style={styles.section}>
                <View style={styles.sectionHeader}>
                  <SectionTitle style={styles.sectionTitle}>오늘의 스케줄</SectionTitle>
                  <Badge>{stats.total}개</Badge>
                </View>
              </View>
            </View>
          </>
        }
        data={schedule}
        keyExtractor={item => item.id}
        renderItem={renderItem}
        contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 120 }}
        ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
        ListFooterComponent={
          <View style={styles.section}>
            <SectionTitle style={styles.sectionTitle}>빠른 실행</SectionTitle>
            <View style={styles.quickActions}>
              <TouchableOpacity style={styles.quickActionCard} onPress={() => {}}>
                <Card>
                  <CardContent style={styles.quickActionContent}>
                    <View style={[styles.iconCircle, { backgroundColor: "#DBEAFE" }]}>
                      <Calendar size={20} color="#2563EB" />
                    </View>
                    <View>
                      <Text style={styles.quickActionTitle}>수업 등록</Text>
                      <Text style={styles.quickActionSubtitle}>새 수업 추가</Text>
                    </View>
                  </CardContent>
                </Card>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.quickActionCard}
                onPress={() => setShowAiModal(true)}
                accessibilityRole="button"
                accessibilityLabel="AI 어시스턴트 열기"
              >
                <Card>
                  <CardContent style={styles.quickActionContent}>
                    <View style={[styles.iconCircle, { backgroundColor: "#F3E8FF" }]}>
                      <Sparkles size={20} color="#9333EA" />
                    </View>
                    <View>
                      <Text style={styles.quickActionTitle}>AI 어시스턴트</Text>
                      <Text style={styles.quickActionSubtitle}>음성으로 관리</Text>
                    </View>
                  </CardContent>
                </Card>
              </TouchableOpacity>
            </View>

            <View style={styles.section}>
              <SectionTitle>오늘의 현황</SectionTitle>
              <Card>
                <CardContent style={{ padding: 0 }}>
                  <View style={styles.statsGrid}>
                    <View style={styles.statItem}>
                      <View style={[styles.iconCircle, { backgroundColor: "#DBEAFE" }]}>
                        <Calendar size={20} color="#2563EB" />
                      </View>
                      <Text style={styles.statValue}>{stats.total}</Text>
                      <Text style={styles.statLabel}>오늘 수업</Text>
                    </View>

                    <View style={[styles.statItem, styles.statItemBorder]}>
                      <View style={[styles.iconCircle, { backgroundColor: "#D1FAE5" }]}>
                        <CheckCircle size={20} color="#10B981" />
                      </View>
                      <Text style={styles.statValue}>{stats.completed}</Text>
                      <Text style={styles.statLabel}>완료</Text>
                    </View>

                    <View style={[styles.statItem, styles.statItemBorder]}>
                      <View style={[styles.iconCircle, { backgroundColor: "#F3E8FF" }]}>
                        <TrendingUp size={20} color="#9333EA" />
                      </View>
                      <Text style={styles.statValue}>
                        {stats.completionRate}
                        <Text style={styles.statUnit}>%</Text>
                      </Text>
                      <Text style={styles.statLabel}>주간 완료율</Text>
                    </View>

                    <View style={[styles.statItem, styles.statItemBorder]}>
                      <View style={[styles.iconCircle, { backgroundColor: "#FED7AA" }]}>
                        <AlertCircle size={20} color="#F97316" />
                      </View>
                      <Text style={styles.statValue}>{stats.unpaid}</Text>
                      <Text style={styles.statLabel}>미납</Text>
                    </View>
                  </View>
                </CardContent>
              </Card>
            </View>
          </View>
        }
        showsVerticalScrollIndicator={false}
      />

      <TouchableOpacity
        style={styles.floatingButton}
        onPress={() => setShowAiModal(true)}
        accessibilityRole="button"
        accessibilityLabel="AI 어시스턴트 열기"
      >
        <Sparkles size={28} color="white" />
      </TouchableOpacity>

      {/* 분리된 AI 모달 */}
      <AiAssistantModal visible={showAiModal} onClose={() => setShowAiModal(false)} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#F9FAFB" },
  header: {
    backgroundColor: "white",
    borderBottomWidth: 1,
    borderBottomColor: "#E5E7EB",
    padding: 16,
    paddingBottom: 12,
  },
  headerTitle: { fontSize: 24, fontWeight: "700", color: "#111827", marginBottom: 4 },
  headerSubtitle: { fontSize: 14, color: "#6B7280" },

  content: { paddingHorizontal: 16, paddingTop: 16 },
  section: { marginBottom: 16 },
  sectionHeader: {
    flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12,
  },
  sectionTitle: { fontSize: 18, fontWeight: "600", color: "#111827", marginBottom: 12 },

  // Schedule
  scheduleCard: { borderWidth: 2, backgroundColor: "white", borderColor: "#E5E7EB", borderRadius: 16 },
  scheduleCardCurrent: { borderColor: "#3B82F6", backgroundColor: "#EFF6FF" },
  scheduleCardCompleted: { borderColor: "#E5E7EB", backgroundColor: "#F9FAFB" },
  scheduleCardContent: { flexDirection: "row", alignItems: "center", gap: 12 },
  checkbox: {
    width: 24, height: 24, borderRadius: 12, borderWidth: 2, borderColor: "#D1D5DB",
    justifyContent: "center", alignItems: "center",
  },
  checkboxCompleted: { backgroundColor: "#10B981", borderColor: "#10B981" },
  scheduleInfo: { flex: 1 },
  scheduleTimeRow: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 4 },
  timeTag: { paddingVertical: 2, paddingHorizontal: 10, borderRadius: 6, backgroundColor: "#F3F4F6" },
  timeTagCurrent: { backgroundColor: "#2563EB" },
  timeTagText: { fontSize: 12, color: "#374151" },
  timeTagTextCurrent: { color: "white" },
  studentName: { fontSize: 16, fontWeight: "600", color: "#111827", marginBottom: 2 },
  completedText: { textDecorationLine: "line-through", color: "#6B7280" },
  subject: { fontSize: 14, color: "#6B7280" },

  // Quick actions
  quickActions: { flexDirection: "row", gap: 12 },
  quickActionCard: { flex: 1 },
  quickActionContent: { flexDirection: "row", alignItems: "center", gap: 12 },
  iconCircle: { width: 40, height: 40, borderRadius: 20, justifyContent: "center", alignItems: "center" },
  quickActionTitle: { fontSize: 14, fontWeight: "500", color: "#111827" },
  quickActionSubtitle: { fontSize: 12, color: "#6B7280" },

  // Stats
  statsGrid: { flexDirection: "row" },
  statItem: { flex: 1, alignItems: "center", paddingVertical: 16 },
  statItemBorder: { borderLeftWidth: 1, borderLeftColor: "#E5E7EB" },
  statValue: { fontSize: 24, fontWeight: "700", color: "#111827", marginTop: 8 },
  statUnit: { fontSize: 14, color: "#6B7280" },
  statLabel: { fontSize: 12, color: "#6B7280", marginTop: 4 },

  // FAB
  floatingButton: {
    position: "absolute",
    bottom: 80, right: 24, width: 64, height: 64, borderRadius: 32,
    backgroundColor: "#9333EA", justifyContent: "center", alignItems: "center",
    shadowColor: "#000", shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8, elevation: 8,
  },
});
