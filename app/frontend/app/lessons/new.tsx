import { formatISO } from "date-fns";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import { Alert, Pressable, ScrollView, Text, TextInput, View } from "react-native";
import { useLessonStore } from "../../src/stores/lessons";
import { useStudentStore } from "../../src/stores/students";

export default function NewLesson() {
  const router = useRouter();
  const { studentId } = useLocalSearchParams<{ studentId?: string }>();

  const students = useStudentStore(s => s.students);
  const [selected, setSelected] = useState<string | undefined>(studentId);
  const [subject, setSubject] = useState("");
  const [date, setDate] = useState("");        // YYYY-MM-DD
  const [time, setTime] = useState("");        // HH:MM (24h)
  const [durationMin, setDurationMin] = useState("60");
  const [rateType, setRateType] = useState<"hourly" | "fixed">("hourly");
  const [rate, setRate] = useState("50000");
  const [memo, setMemo] = useState("");

  const addLesson = useLessonStore(s => s.addLesson);

  const valid = useMemo(() => {
    return selected && subject.trim() && date.match(/^\d{4}-\d{2}-\d{2}$/) && time.match(/^\d{2}:\d{2}$/);
  }, [selected, subject, date, time]);

  const submit = () => {
    if (!valid) {
      return Alert.alert("확인", "학생/과목/날짜/시간을 확인해주세요.");
    }
    const startsAt = formatISO(new Date(`${date}T${time}:00`)); // 단순 조합
    const id = addLesson({
      studentId: selected!,
      subject: subject.trim(),
      startsAt,
      durationMin: Number(durationMin) || 60,
      rateType,
      rate: Number(rate) || 0,
      memo: memo.trim() || undefined,
    });
    router.replace({ pathname: "/schedule", params: { focus: id } });
  };

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>수업 추가</Text>

      {/* 학생 선택 */}
      <View style={{ borderWidth:1, borderRadius:12, padding:10, gap:8 }}>
        <Text style={{ fontWeight:"600" }}>학생 *</Text>
        <View style={{ flexDirection:"row", flexWrap:"wrap", gap:8 }}>
          {students.map(st => (
            <Pressable
              key={st.id}
              onPress={() => setSelected(st.id)}
              style={{
                borderWidth:1, paddingVertical:8, paddingHorizontal:12, borderRadius:999,
                backgroundColor: selected === st.id ? "#eee" : "white"
              }}
            >
              <Text>{st.name}</Text>
            </Pressable>
          ))}
        </View>
      </View>

      {/* 과목 */}
      <View style={{ gap:6 }}>
        <Text>과목 *</Text>
        <TextInput
          value={subject}
          onChangeText={setSubject}
          placeholder="예: 수학 / 영어회화"
          style={{ borderWidth:1, borderRadius:10, padding:10 }}
        />
      </View>

      {/* 날짜/시간 */}
      <View style={{ flexDirection:"row", gap:8 }}>
        <View style={{ flex:1, gap:6 }}>
          <Text>날짜(YYYY-MM-DD) *</Text>
          <TextInput
            value={date}
            onChangeText={setDate}
            placeholder="2025-11-06"
            style={{ borderWidth:1, borderRadius:10, padding:10 }}
          />
        </View>
        <View style={{ width:120, gap:6 }}>
          <Text>시간(HH:MM) *</Text>
          <TextInput
            value={time}
            onChangeText={setTime}
            placeholder="17:00"
            style={{ borderWidth:1, borderRadius:10, padding:10 }}
          />
        </View>
      </View>

      {/* 기간/단가 */}
      <View style={{ flexDirection:"row", gap:8 }}>
        <View style={{ flex:1, gap:6 }}>
          <Text>수업 길이(분)</Text>
          <TextInput
            value={durationMin}
            onChangeText={setDurationMin}
            keyboardType="numeric"
            placeholder="60"
            style={{ borderWidth:1, borderRadius:10, padding:10 }}
          />
        </View>
        <View style={{ width:120, gap:6 }}>
          <Text>단가 유형</Text>
          <View style={{ flexDirection:"row", gap:8 }}>
            <Pressable
              onPress={() => setRateType("hourly")}
              style={{ borderWidth:1, padding:8, borderRadius:8, backgroundColor: rateType==="hourly" ? "#eee":"white" }}
            >
              <Text>시간당</Text>
            </Pressable>
            <Pressable
              onPress={() => setRateType("fixed")}
              style={{ borderWidth:1, padding:8, borderRadius:8, backgroundColor: rateType==="fixed" ? "#eee":"white" }}
            >
              <Text>회당</Text>
            </Pressable>
          </View>
        </View>
        <View style={{ width:120, gap:6 }}>
          <Text>단가(₩)</Text>
          <TextInput
            value={rate}
            onChangeText={setRate}
            keyboardType="numeric"
            placeholder="50000"
            style={{ borderWidth:1, borderRadius:10, padding:10 }}
          />
        </View>
      </View>

      {/* 메모 */}
      <View style={{ gap:6 }}>
        <Text>메모</Text>
        <TextInput
          value={memo}
          onChangeText={setMemo}
          placeholder="과외 장소/온라인 링크 등"
          multiline
          style={{ borderWidth:1, borderRadius:10, padding:10, minHeight:80, textAlignVertical:"top" }}
        />
      </View>

      {/* 액션 */}
      <View style={{ flexDirection:"row", gap:8, marginTop:8 }}>
        <Pressable
          onPress={() => router.back()}
          style={{ borderWidth:1, paddingVertical:12, paddingHorizontal:16, borderRadius:10, flex:1, alignItems:"center" }}
        >
          <Text>취소</Text>
        </Pressable>
        <Pressable
          onPress={submit}
          style={{ borderWidth:1, paddingVertical:12, paddingHorizontal:16, borderRadius:10, flex:1, alignItems:"center", backgroundColor:"#efefef" }}
        >
          <Text>저장</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}
