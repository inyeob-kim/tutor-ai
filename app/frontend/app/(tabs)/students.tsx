// ===================================
// 👨‍🎓 StudentsScreen.tsx (Expo Router Tab)
// ===================================

import { Avatar, AvatarFallback } from "@/components/ui/Avatar";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { useRouter } from "expo-router";
import {
    Award,
    Calendar,
    Clock,
    Edit,
    Phone,
    Plus,
    Search,
    TrendingUp,
    Users,
    X,
} from "lucide-react-native";
import React, { useMemo, useState } from "react";
import {
    FlatList,
    Modal,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

type Student = {
  name: string;
  grade: string;
  subjects: string[];
  phone: string;
  sessions: number;
  completedSessions: number;
  color: string;
  nextClass: string; // ex) "11월 7일 10:00"
  attendanceRate: number; // 0~100
};

type TabKey = "all" | "today" | "lowAttendance";

/** 데모 데이터 */
const STUDENTS: Student[] = [
  {
    name: "김민수",
    grade: "고등학교 2학년",
    subjects: ["수학"],
    phone: "010-1234-5678",
    sessions: 24,
    completedSessions: 22,
    color: "#3B82F6",
    nextClass: "11월 7일 10:00",
    attendanceRate: 92,
  },
  {
    name: "이지은",
    grade: "중학교 3학년",
    subjects: ["영어", "수학"],
    phone: "010-2345-6789",
    sessions: 18,
    completedSessions: 18,
    color: "#10B981",
    nextClass: "11월 7일 14:00",
    attendanceRate: 100,
  },
  {
    name: "박서준",
    grade: "고등학교 1학년",
    subjects: ["과학", "수학"],
    phone: "010-3456-7890",
    sessions: 20,
    completedSessions: 18,
    color: "#9333EA",
    nextClass: "11월 7일 16:00",
    attendanceRate: 90,
  },
];

/** 학생 카드 (리스트 아이템) */
function StudentRow({
  student,
  onPress,
}: {
  student: Student;
  onPress: () => void;
}) {
  const barColor =
    student.attendanceRate >= 95
      ? "#10B981"
      : student.attendanceRate >= 85
      ? "#2563EB"
      : "#F97316";

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.8}>
      <Card style={styles.studentCard}>
        <View style={[styles.accentLine, { backgroundColor: student.color }]} />
        <CardContent style={styles.studentCardContent}>
          {/* 헤더 */}
          <View style={styles.studentHeader}>
            <Avatar size={56} style={styles.avatar}>
              <AvatarFallback backgroundColor={student.color}>
                {student.name.charAt(0)}
              </AvatarFallback>
            </Avatar>

            <View style={styles.studentInfo}>
              <View style={styles.studentNameRow}>
                <Text style={styles.studentName}>{student.name}</Text>
                {student.attendanceRate === 100 && (
                  <Award size={16} color="#F59E0B" />
                )}
              </View>
              <Text style={styles.studentGrade}>{student.grade}</Text>
            </View>
          </View>

          {/* 출석률 */}
          <View style={styles.progressContainer}>
            <View style={styles.progressHeader}>
              <Text style={styles.progressLabel}>출석률</Text>
              <Text style={[styles.progressValue, { color: barColor }]}>
                {student.attendanceRate}%
              </Text>
            </View>
            <View style={styles.progressBar}>
              <View
                style={[
                  styles.progressFill,
                  { width: `${student.attendanceRate}%`, backgroundColor: barColor },
                ]}
              />
            </View>
          </View>

          {/* 다음 수업 */}
          {!!student.nextClass && (
            <View style={styles.nextClassBox}>
              <Clock size={16} color="#2563EB" />
              <View style={{ flex: 1 }}>
                <Text style={styles.nextClassLabel}>다음 수업</Text>
                <Text style={styles.nextClassTime}>{student.nextClass}</Text>
              </View>
            </View>
          )}

          {/* 과목 태그 & 횟수 */}
          <View style={styles.tagsRow}>
            {student.subjects.map((subject, idx) => (
              <Badge key={subject + idx} variant="secondary">
                {subject}
              </Badge>
            ))}
            <Badge variant="outline">{student.sessions}회 수업</Badge>
          </View>
        </CardContent>
      </Card>
    </TouchableOpacity>
  );
}

/** 학생 상세 모달 */
function StudentDetailModal({
  student,
  onClose,
}: {
  student: Student | null;
  onClose: () => void;
}) {
  return (
    <Modal
      visible={!!student}
      animationType="slide"
      transparent
      onRequestClose={onClose}
    >
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          {/* 헤더 */}
          <View
            style={[
              styles.modalHeader,
              { backgroundColor: student?.color ?? "#2563EB" },
            ]}
          >
            <TouchableOpacity style={styles.closeButton} onPress={onClose}>
              <X size={24} color="white" />
            </TouchableOpacity>

            <View style={styles.modalProfileSection}>
              <Avatar size={80} style={styles.modalAvatar}>
                <AvatarFallback
                  backgroundColor="rgba(255,255,255,0.2)"
                  textColor="white"
                >
                  {student?.name.charAt(0)}
                </AvatarFallback>
              </Avatar>
              <Text style={styles.modalName}>{student?.name}</Text>
              <Text style={styles.modalGrade}>{student?.grade}</Text>
            </View>

            <View style={styles.modalStats}>
              <View style={styles.modalStatBox}>
                <Text style={styles.modalStatValue}>{student?.sessions}</Text>
                <Text style={styles.modalStatLabel}>총 수업</Text>
              </View>
              <View style={styles.modalStatBox}>
                <Text style={styles.modalStatValue}>
                  {student?.attendanceRate}%
                </Text>
                <Text style={styles.modalStatLabel}>출석률</Text>
              </View>
            </View>
          </View>

          {/* 바디 */}
          <View style={styles.modalBody}>
            <View style={styles.infoRow}>
              <Phone size={20} color="#6B7280" />
              <Text style={styles.infoText}>{student?.phone}</Text>
            </View>

            <View style={styles.subjectsSection}>
              <Text style={styles.sectionTitle}>수강 과목</Text>
              <View style={styles.subjectsList}>
                {student?.subjects.map((s, i) => <Badge key={s + i}>{s}</Badge>)}
              </View>
            </View>

            <Button style={styles.editButton}>
              <Edit size={16} color="white" />
              <Text style={styles.editButtonText}>학생 정보 수정</Text>
            </Button>
          </View>
        </View>
      </View>
    </Modal>
  );
}

export default function StudentsScreen() {
  const router = useRouter(); // ✅ router 선언 위치 수정

  const [activeTab, setActiveTab] = useState<TabKey>("all");
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState<Student | null>(null);

  // 통계
  const totalStudents = STUDENTS.length;
  const todayStudents = STUDENTS.filter((s) => s.nextClass.includes("11월 7일")).length;
  const avgAttendance = Math.round(
    STUDENTS.reduce((sum, s) => sum + s.attendanceRate, 0) / STUDENTS.length
  );
  const perfectAttendance = STUDENTS.filter((s) => s.attendanceRate === 100).length;

  // 필터링
  const filtered = useMemo(() => {
    const byTab = (s: Student) => {
      if (activeTab === "today") return s.nextClass.includes("11월 7일");
      if (activeTab === "lowAttendance") return s.attendanceRate < 90;
      return true; // all
    };
    const byQuery = (s: Student) =>
      s.name.toLowerCase().includes(query.trim().toLowerCase());
    return STUDENTS.filter((s) => byTab(s) && byQuery(s));
  }, [activeTab, query]);

  return (
    <SafeAreaView style={styles.container} edges={["top"]}>
      {/* 헤더 */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>학생 관리</Text>
          <Text style={styles.subtitle}>총 {totalStudents}명의 학생</Text>
        </View>

        <TouchableOpacity
          style={styles.addButton}
          onPress={() => router.push("/student-add")}
          accessibilityRole="button"
          accessibilityLabel="학생 추가 페이지로 이동"
        >
          <Plus size={16} color="#374151" />
          <Text style={styles.addButtonText}>학생 추가</Text>
        </TouchableOpacity>
      </View>

      {/* 통계 */}
      <Card style={styles.statsCard}>
        <CardContent style={{ padding: 0 }}>
          <View style={styles.statsGrid}>
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: "#DBEAFE" }]}>
                <Users size={20} color="#2563EB" />
              </View>
              <Text style={styles.statValue}>{totalStudents}</Text>
              <Text style={styles.statLabel}>전체 학생</Text>
            </View>

            <View style={[styles.statItem, styles.statBorder]}>
              <View style={[styles.statIcon, { backgroundColor: "#F3E8FF" }]}>
                <Calendar size={20} color="#9333EA" />
              </View>
              <Text style={styles.statValue}>{todayStudents}</Text>
              <Text style={styles.statLabel}>오늘 수업</Text>
            </View>

            <View style={[styles.statItem, styles.statBorder]}>
              <View style={[styles.statIcon, { backgroundColor: "#D1FAE5" }]}>
                <TrendingUp size={20} color="#10B981" />
              </View>
              <Text style={styles.statValue}>{avgAttendance}%</Text>
              <Text style={styles.statLabel}>평균 출석률</Text>
            </View>

            <View style={[styles.statItem, styles.statBorder]}>
              <View style={[styles.statIcon, { backgroundColor: "#FEF3C7" }]}>
                <Award size={20} color="#F59E0B" />
              </View>
              <Text style={styles.statValue}>{perfectAttendance}</Text>
              <Text style={styles.statLabel}>100% 출석</Text>
            </View>
          </View>
        </CardContent>
      </Card>

      {/* 탭 */}
      <View style={styles.tabs}>
        {(["all", "today", "lowAttendance"] as TabKey[]).map((tab) => (
          <TouchableOpacity
            key={tab}
            style={[styles.tab, activeTab === tab && styles.tabActive]}
            onPress={() => setActiveTab(tab)}
          >
            <Text style={[styles.tabText, activeTab === tab && styles.tabTextActive]}>
              {tab === "all" ? "전체" : tab === "today" ? "오늘 수업" : "출석 주의"}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* 검색 */}
      <View style={styles.searchContainer}>
        <Search size={20} color="#9CA3AF" style={styles.searchIcon} />
        <Input
          placeholder="학생 이름 검색..."
          value={query}
          onChangeText={setQuery}
          style={styles.searchInput}
        />
      </View>

      {/* 리스트 */}
      <FlatList
        data={filtered}
        keyExtractor={(item) => item.name}
        contentContainerStyle={styles.studentsList}
        ItemSeparatorComponent={() => <View style={{ height: 12 }} />}
        renderItem={({ item }) => (
          <StudentRow student={item} onPress={() => setSelected(item)} />
        )}
      />

      {/* 상세 모달 */}
      <StudentDetailModal student={selected} onClose={() => setSelected(null)} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  // Screen
  container: { flex: 1, backgroundColor: "#F9FAFB" },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    padding: 16,
    backgroundColor: "white",
    borderBottomWidth: 1,
    borderBottomColor: "#E5E7EB",
  },
  title: { fontSize: 24, fontWeight: "700", color: "#111827" },
  subtitle: { fontSize: 14, color: "#6B7280", marginTop: 4 },
  addButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderRadius: 8,
  },
  addButtonText: { fontSize: 14, color: "#374151" },

  // Stats
  statsCard: { margin: 16, marginBottom: 12 },
  statsGrid: { flexDirection: "row" },
  statItem: { flex: 1, alignItems: "center", paddingVertical: 16 },
  statBorder: { borderLeftWidth: 1, borderLeftColor: "#E5E7EB" },
  statIcon: {
    width: 40, height: 40, borderRadius: 20,
    justifyContent: "center", alignItems: "center", marginBottom: 8,
  },
  statValue: { fontSize: 24, fontWeight: "700", color: "#111827" },
  statLabel: { fontSize: 12, color: "#6B7280", marginTop: 4 },

  // Tabs
  tabs: { flexDirection: "row", gap: 8, paddingHorizontal: 16, marginBottom: 12 },
  tab: {
    flex: 1, paddingVertical: 12, alignItems: "center",
    backgroundColor: "white", borderRadius: 8, borderWidth: 1, borderColor: "#E5E7EB",
  },
  tabActive: { backgroundColor: "#2563EB", borderColor: "#2563EB" },
  tabText: { fontSize: 14, fontWeight: "600", color: "#6B7280" },
  tabTextActive: { color: "white" },

  // Search
  searchContainer: { marginHorizontal: 16, marginBottom: 16, position: "relative" },
  searchIcon: { position: "absolute", left: 12, top: 12, zIndex: 1 },
  searchInput: { paddingLeft: 40 },

  // List
  studentsList: { paddingHorizontal: 16, paddingBottom: 24 },

  // Card
  studentCard: { position: "relative" },
  accentLine: {
    position: "absolute", top: 0, left: 0, right: 0, height: 4,
    borderTopLeftRadius: 8, borderTopRightRadius: 8,
  },
  studentCardContent: { paddingTop: 20 },
  studentHeader: { flexDirection: "row", gap: 12, marginBottom: 12 },
  avatar: {
    shadowColor: "#000", shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1, shadowRadius: 4, elevation: 3,
  },
  studentInfo: { flex: 1 },
  studentNameRow: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 4 },
  studentName: { fontSize: 18, fontWeight: "600", color: "#111827" },
  studentGrade: { fontSize: 14, color: "#6B7280" },

  // Progress
  progressContainer: { marginBottom: 12 },
  progressHeader: { flexDirection: "row", justifyContent: "space-between", marginBottom: 4 },
  progressLabel: { fontSize: 12, color: "#6B7280" },
  progressValue: { fontSize: 14, fontWeight: "600" },
  progressBar: { height: 8, backgroundColor: "#E5E7EB", borderRadius: 4, overflow: "hidden" },
  progressFill: { height: "100%", borderRadius: 4 },

  // Next class
  nextClassBox: {
    flexDirection: "row", alignItems: "center", gap: 8,
    padding: 12, backgroundColor: "#EFF6FF", borderRadius: 8, marginBottom: 12,
  },
  nextClassLabel: { fontSize: 12, color: "#6B7280" },
  nextClassTime: { fontSize: 14, fontWeight: "600", color: "#2563EB" },

  // Tags
  tagsRow: { flexDirection: "row", flexWrap: "wrap", gap: 8 },

  // Modal
  modalOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.5)", justifyContent: "flex-end" },
  modalContent: {
    maxHeight: "90%", backgroundColor: "white",
    borderTopLeftRadius: 24, borderTopRightRadius: 24, overflow: "hidden",
  },
  modalHeader: { padding: 24, paddingTop: 32 },
  closeButton: {
    position: "absolute", top: 16, right: 16, width: 40, height: 40,
    borderRadius: 20, backgroundColor: "rgba(255,255,255,0.2)",
    justifyContent: "center", alignItems: "center", zIndex: 10,
  },
  modalProfileSection: { alignItems: "center", marginBottom: 16 },
  modalAvatar: { marginBottom: 12 },
  modalName: { fontSize: 24, fontWeight: "700", color: "white", marginBottom: 4 },
  modalGrade: { fontSize: 16, color: "rgba(255,255,255,0.9)" },
  modalStats: { flexDirection: "row", gap: 12 },
  modalStatBox: {
    flex: 1, alignItems: "center", padding: 12,
    backgroundColor: "rgba(255,255,255,0.2)", borderRadius: 12,
  },
  modalStatValue: { fontSize: 24, fontWeight: "700", color: "white", marginBottom: 4 },
  modalStatLabel: { fontSize: 12, color: "rgba(255,255,255,0.8)" },
  modalBody: { padding: 24 },
  infoRow: {
    flexDirection: "row", alignItems: "center", gap: 12,
    paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#E5E7EB",
  },
  infoText: { fontSize: 16, color: "#374151" },
  subjectsSection: { marginTop: 24, marginBottom: 24 },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: "#111827", marginBottom: 12 },
  subjectsList: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  editButton: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8 },
  editButtonText: { color: "white", fontSize: 16, fontWeight: "600" },
});
