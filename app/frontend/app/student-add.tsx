// app/student-add.tsx
import { Button } from "@/components/ui/Button";
import { Card, CardContent } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { useStudentStore } from "@/stores/students";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
    ActivityIndicator,
    Alert,
    KeyboardAvoidingView,
    Platform,
    ScrollView,
    StyleSheet,
    Switch,
    Text,
    View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

const phoneNormalize = (s: string) =>
  s.replace(/[^\d]/g, "").replace(/^(\d{2,3})(\d{3,4})(\d{4}).*$/, "$1-$2-$3");

export default function StudentAddScreen() {
  const router = useRouter();
  // ✅ 서버 연동 액션 (store에 createOnServer 반드시 구현되어 있어야 함)
  const createOnServer = useStudentStore((s) => s.createOnServer);

  const [name, setName] = useState("");
  const [grade, setGrade] = useState("");
  const [isAdult, setIsAdult] = useState(false); // 기본은 미성년
  const [birthdate, setBirthdate] = useState(""); // 선택
  const [guardianName, setGuardianName] = useState("");
  const [guardianPhone, setGuardianPhone] = useState("");
  const [email, setEmail] = useState("");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const disabled = submitting;

  const emailInvalid = useMemo(() => {
    if (!email.trim()) return false;
    // 매우 간단한 검증 (백엔드가 최종 검증)
    return !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
  }, [email]);

  const onSubmit = async () => {
    if (submitting) return;

    // 기본 검증
    if (!name.trim()) {
      return Alert.alert("확인", "학생 이름은 필수입니다.");
    }
    if (emailInvalid) {
      return Alert.alert("확인", "이메일 형식을 확인해주세요.");
    }
    // 미성년 검증
    if (!isAdult) {
      if (!guardianName.trim()) {
        return Alert.alert("확인", "미성년은 보호자 이름이 필요합니다.");
      }
      const digits = guardianPhone.replace(/[^\d]/g, "");
      if (digits.length < 9) {
        return Alert.alert("확인", "보호자 연락처를 확인해주세요.");
      }
    }

    try {
      setSubmitting(true);
      const id = await createOnServer({
        name: name.trim(),
        isAdult,
        birthdate: birthdate.trim() || undefined,
        grade: grade.trim() || undefined,
        guardianName: isAdult ? undefined : guardianName.trim() || undefined,
        guardianPhone: isAdult ? undefined : guardianPhone.trim() || undefined,
        email: email.trim() || undefined,
        note: note.trim() || undefined,
      });

      // 성공 시 상세 페이지로 이동
      router.replace(`/students/${id}`);
    } catch (e: any) {
      const msg =
        typeof e?.message === "string" ? e.message : "저장에 실패했습니다.";
      Alert.alert("오류", msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={["top"]}>
      <KeyboardAvoidingView
        behavior={Platform.select({ ios: "padding", android: undefined })}
        style={{ flex: 1 }}
      >
        <ScrollView
          style={{ flex: 1 }}
          contentContainerStyle={{ padding: 16, gap: 16 }}
          keyboardShouldPersistTaps="handled"
        >
          {/* 헤더 */}
          <View style={styles.header}>
            <Text style={styles.title}>학생 등록</Text>
            <Text style={styles.subtitle}>새 학생 정보를 입력하세요</Text>
          </View>

          {/* 기본 정보 */}
          <Card>
            <CardContent style={{ gap: 12 }}>
              <Text style={styles.sectionLabel}>기본 정보</Text>

              <View style={styles.field}>
                <Text style={styles.label}>
                  이름 <Text style={styles.required}>*</Text>
                </Text>
                <Input
                  value={name}
                  onChangeText={setName}
                  placeholder="예: 김민지"
                  editable={!disabled}
                />
              </View>

              <View style={styles.field}>
                <Text style={styles.label}>학년/학제</Text>
                <Input
                  value={grade}
                  onChangeText={setGrade}
                  placeholder="예: 중2 / HS-1 / 대학1"
                  editable={!disabled}
                />
              </View>

              <View style={styles.switchRow}>
                <Text style={styles.label}>성인(만 19세 이상)</Text>
                <Switch
                  value={isAdult}
                  onValueChange={setIsAdult}
                  disabled={disabled}
                />
              </View>

              <View style={styles.field}>
                <Text style={styles.label}>생년월일 (선택)</Text>
                <Input
                  value={birthdate}
                  onChangeText={setBirthdate}
                  placeholder="YYYY-MM-DD"
                  autoCapitalize="none"
                  editable={!disabled}
                />
              </View>
            </CardContent>
          </Card>

          {/* 연락/보호자 정보 */}
          <Card>
            <CardContent style={{ gap: 12 }}>
              <Text style={styles.sectionLabel}>연락/보호자</Text>

              {!isAdult && (
                <>
                  <View style={styles.field}>
                    <Text style={styles.label}>
                      보호자 이름 <Text style={styles.required}>*</Text>
                    </Text>
                    <Input
                      value={guardianName}
                      onChangeText={setGuardianName}
                      placeholder="예: 김수현"
                      editable={!disabled}
                    />
                  </View>

                  <View style={styles.field}>
                    <Text style={styles.label}>
                      보호자 연락처 <Text style={styles.required}>*</Text>
                    </Text>
                    <Input
                      keyboardType="phone-pad"
                      value={guardianPhone}
                      onChangeText={(t) => setGuardianPhone(phoneNormalize(t))}
                      placeholder="010-0000-0000"
                      editable={!disabled}
                    />
                  </View>
                </>
              )}

              <View style={styles.field}>
                <Text style={styles.label}>이메일</Text>
                <Input
                  keyboardType="email-address"
                  value={email}
                  onChangeText={setEmail}
                  placeholder="name@example.com"
                  autoCapitalize="none"
                  editable={!disabled}
                  style={emailInvalid && { borderColor: "#F87171" }}
                />
                {emailInvalid && (
                  <Text style={styles.errorText}>
                    이메일 형식이 올바르지 않습니다.
                  </Text>
                )}
              </View>

              <View style={styles.field}>
                <Text style={styles.label}>메모</Text>
                <Input
                  value={note}
                  onChangeText={setNote}
                  placeholder="특이사항/학습 목표 등을 적어주세요"
                  editable={!disabled}
                  multiline
                  style={{ minHeight: 90, textAlignVertical: "top" }}
                />
              </View>
            </CardContent>
          </Card>

          {/* 액션 버튼 */}
          <View style={styles.actions}>
            <Button
              variant="outline"
              onPress={() => router.back()}
              disabled={disabled}
              style={{ flex: 1 }}
            >
              취소
            </Button>

            <Button
              onPress={onSubmit}
              disabled={disabled}
              style={{ flex: 1 }}
            >
              {submitting ? <ActivityIndicator /> : "등록"}
            </Button>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#F9FAFB" },
  header: {
    gap: 4,
    paddingHorizontal: 4,
  },
  title: { fontSize: 22, fontWeight: "700", color: "#111827" },
  subtitle: { fontSize: 14, color: "#6B7280" },

  sectionLabel: {
    fontSize: 16,
    fontWeight: "700",
    color: "#111827",
    marginBottom: 4,
  },
  field: { gap: 6 },
  label: { fontSize: 14, color: "#374151" },
  required: { color: "#EF4444" },

  switchRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 2,
  },

  actions: {
    flexDirection: "row",
    gap: 10,
    marginTop: 4,
    marginBottom: 24,
  },

  errorText: {
    marginTop: 4,
    fontSize: 12,
    color: "#EF4444",
  },
});
