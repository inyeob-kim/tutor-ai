import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useEffect } from "react";
import { ActivityIndicator, Alert, Pressable, ScrollView, Text, View } from "react-native";
import { useStudentStore } from "../../src/stores/students";

export default function StudentProfile() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const loadFromServer = useStudentStore((s) => s.loadFromServer);
  const deleteOnServer = useStudentStore((s) => s.deleteOnServer);
  const student = useStudentStore((s) => s.students.find((x) => x.id === id));

  // URL로 직접 진입했을 때 대비: 학생 정보 없으면 서버에서 한 번 로드
  useEffect(() => {
    if (!student && id) {
      loadFromServer().catch(() => {});
    }
  }, [id]);

  // 액션: 수업 추가 / 청구 생성 / 수정 / 삭제
  const goAddLesson = () => {
    router.push({ pathname: "/schedule", params: { studentId: id } });
  };

  const goCreateInvoice = () => {
    router.push({ pathname: "/billing", params: { studentId: id } });
  };

  const goEdit = () => {
    router.push(`/students/${id}/edit`);
  };

  const onDelete = () => {
    Alert.alert("삭제 확인", "정말 이 학생을 삭제할까요? 이 작업은 되돌릴 수 없습니다.", [
      { text: "취소", style: "cancel" },
      {
        text: "삭제",
        style: "destructive",
        onPress: async () => {
          try {
            await deleteOnServer(id!);
            router.replace("/students");
          } catch (e: any) {
            Alert.alert("오류", e?.message?.toString() ?? "삭제 실패");
          }
        },
      },
    ]);
  };

  // 로딩/미발견 처리
  if (!student) {
    return (
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 16 }}>
        <ActivityIndicator />
        <Text style={{ marginTop: 8 }}>학생 정보를 불러오는 중…</Text>
        <Pressable
          onPress={() => router.replace("/students")}
          style={{ borderWidth: 1, marginTop: 12, paddingVertical: 10, paddingHorizontal: 16, borderRadius: 10 }}
        >
          <Text>학생 목록으로</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>{student.name} 프로필</Text>

      <View style={{ borderWidth: 1, borderRadius: 16, padding: 12, gap: 6 }}>
        <Text>성인 여부: {student.isAdult ? "성인" : "미성년"}</Text>
        <Text>생년월일: {student.birthdate ?? "-"}</Text>
        <Text>학년: {student.grade ?? "-"}</Text>

        {!student.isAdult && (
          <>
            <Text>보호자: {student.guardianName ?? "-"}</Text>
            <Text>연락처: {student.guardianPhone ?? "-"}</Text>
          </>
        )}

        <Text>이메일: {student.email ?? "-"}</Text>
        <Text>메모: {student.note ?? "-"}</Text>
      </View>

      {/* 1줄차: 수업/청구 */}
      <View style={{ flexDirection: "row", gap: 8 }}>
        <Pressable
          onPress={goAddLesson}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, flex: 1, alignItems: "center" }}
        >
          <Text>수업 추가</Text>
        </Pressable>
        <Pressable
          onPress={goCreateInvoice}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, flex: 1, alignItems: "center" }}
        >
          <Text>청구 생성</Text>
        </Pressable>
      </View>

      {/* 2줄차: 수정/삭제 */}
      <View style={{ flexDirection: "row", gap: 8 }}>
        <Pressable
          onPress={goEdit}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, flex: 1, alignItems: "center" }}
        >
          <Text>수정</Text>
        </Pressable>
        <Pressable
          onPress={onDelete}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, flex: 1, alignItems: "center" }}
        >
          <Text>삭제</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}
