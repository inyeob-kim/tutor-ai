import { useRouter } from "expo-router";
import { useState } from "react";
import { ActivityIndicator, Alert, Pressable, ScrollView, Switch, Text, TextInput, View } from "react-native";
import { useStudentStore } from "../../src/stores/students";

const phoneNormalize = (s: string) =>
  s.replace(/[^\d]/g, "").replace(/^(\d{2,3})(\d{3,4})(\d{4}).*$/, "$1-$2-$3");

export default function NewStudent() {
  const router = useRouter();
  // ✅ 서버 연동 액션 사용 (store에 createOnServer 구현되어 있어야 함)
  const createOnServer = useStudentStore((s) => s.createOnServer);

  const [name, setName] = useState("");
  const [grade, setGrade] = useState("");
  const [isAdult, setIsAdult] = useState(false);          // 기본: 미성년
  const [birthdate, setBirthdate] = useState("");         // 선택
  const [guardianName, setGuardianName] = useState("");
  const [guardianPhone, setGuardianPhone] = useState("");
  const [email, setEmail] = useState("");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async () => {
    if (submitting) return;
    if (!name.trim()) return Alert.alert("확인", "학생 이름은 필수입니다.");

    // 미성년 유효성
    if (!isAdult) {
      if (!guardianName.trim()) return Alert.alert("확인", "미성년은 보호자 이름이 필요합니다.");
      const digits = guardianPhone.replace(/[^\d]/g, "");
      if (digits.length < 9) return Alert.alert("확인", "보호자 연락처를 확인해주세요.");
    }

    try {
      setSubmitting(true);
      const id = await createOnServer({
        name: name.trim(),
        isAdult,
        birthdate: birthdate.trim() || undefined,
        grade: grade.trim() || undefined,
        guardianName: isAdult ? undefined : (guardianName.trim() || undefined),
        guardianPhone: isAdult ? undefined : (guardianPhone.trim() || undefined),
        email: email.trim() || undefined,
        note: note.trim() || undefined,
      });
      router.replace(`/students/${id}`);
    } catch (e: any) {
      // FastAPI 에러 메시지 표출
      const msg = typeof e?.message === "string" ? e.message : "저장에 실패했습니다.";
      Alert.alert("오류", msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>학생 등록</Text>

      <View style={{ gap: 6 }}>
        <Text>이름 *</Text>
        <TextInput
          value={name}
          onChangeText={setName}
          placeholder="예: 김민지"
          editable={!submitting}
          style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
        />
      </View>

      <View style={{ gap: 6 }}>
        <Text>학년/학제</Text>
        <TextInput
          value={grade}
          onChangeText={setGrade}
          placeholder="예: 중2 / HS-1 / 대학1"
          editable={!submitting}
          style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
        />
      </View>

      {/* 성인 스위치 */}
      <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
        <Text>성인(만 19세 이상)</Text>
        <Switch value={isAdult} onValueChange={setIsAdult} disabled={submitting} />
      </View>

      {/* 생년월일 (선택) */}
      <View style={{ gap: 6 }}>
        <Text>생년월일 (선택)</Text>
        <TextInput
          value={birthdate}
          onChangeText={setBirthdate}
          placeholder="YYYY-MM-DD"
          autoCapitalize="none"
          editable={!submitting}
          style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
        />
      </View>

      {/* 미성년일 때만 보호자 입력 */}
      {!isAdult && (
        <>
          <View style={{ gap: 6 }}>
            <Text>보호자 이름 *</Text>
            <TextInput
              value={guardianName}
              onChangeText={setGuardianName}
              placeholder="예: 김수현"
              editable={!submitting}
              style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
            />
          </View>

          <View style={{ gap: 6 }}>
            <Text>보호자 연락처 *</Text>
            <TextInput
              keyboardType="phone-pad"
              value={guardianPhone}
              onChangeText={(t) => setGuardianPhone(phoneNormalize(t))}
              placeholder="010-0000-0000"
              editable={!submitting}
              style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
            />
          </View>
        </>
      )}

      <View style={{ gap: 6 }}>
        <Text>이메일</Text>
        <TextInput
          keyboardType="email-address"
          value={email}
          onChangeText={setEmail}
          placeholder="name@example.com"
          autoCapitalize="none"
          editable={!submitting}
          style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
        />
      </View>

      <View style={{ gap: 6 }}>
        <Text>메모</Text>
        <TextInput
          value={note}
          onChangeText={setNote}
          placeholder="특이사항/학습 목표 등을 적어주세요"
          multiline
          editable={!submitting}
          style={{ borderWidth: 1, borderRadius: 10, padding: 10, minHeight: 90, textAlignVertical: "top" }}
        />
      </View>

      <View style={{ flexDirection: "row", gap: 8, marginTop: 8 }}>
        <Pressable
          onPress={() => router.back()}
          disabled={submitting}
          style={{ borderWidth: 1, paddingVertical: 12, paddingHorizontal: 16, borderRadius: 10, flex: 1, alignItems: "center", opacity: submitting ? 0.6 : 1 }}
        >
          <Text>취소</Text>
        </Pressable>

        <Pressable
          onPress={onSubmit}
          disabled={submitting}
          style={{ borderWidth: 1, paddingVertical: 12, paddingHorizontal: 16, borderRadius: 10, flex: 1, alignItems: "center", backgroundColor: "#efefef", opacity: submitting ? 0.6 : 1 }}
        >
          {submitting ? <ActivityIndicator /> : <Text>등록</Text>}
        </Pressable>
      </View>
    </ScrollView>
  );
}
