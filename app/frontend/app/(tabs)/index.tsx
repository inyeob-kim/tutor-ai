import { useState } from "react";
import { Pressable, ScrollView, Text, TextInput, View } from "react-native";

export default function Home() {
  const [cmd, setCmd] = useState("");

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>대시보드</Text>

      <View style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
        <Text style={{ fontWeight: "600" }}>오늘 수업</Text>
        <Text style={{ opacity: 0.6, marginTop: 4 }}>
          16:00 김민지 · 수학{"\n"}18:00 Alex · 영어회화
        </Text>
      </View>

      <View style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
        <Text style={{ fontWeight: "600" }}>청구 현황 (이번 달)</Text>
        <Text style={{ marginTop: 4, fontSize: 20, fontWeight: "700" }}>₩1,200,000</Text>
        <Text style={{ opacity: 0.6 }}>미수금 2건</Text>
      </View>

      <View style={{ borderWidth: 1, borderRadius: 16, padding: 12, gap: 8 }}>
        <Text style={{ fontWeight: "600" }}>빠른 작업</Text>
        <View style={{ flexDirection: "row", gap: 8, flexWrap: "wrap" }}>
          <Pressable style={{ borderWidth: 1, padding: 8, borderRadius: 10 }}>
            <Text>수업 추가</Text>
          </Pressable>
          <Pressable style={{ borderWidth: 1, padding: 8, borderRadius: 10 }}>
            <Text>학생 등록</Text>
          </Pressable>
          <Pressable style={{ borderWidth: 1, padding: 8, borderRadius: 10 }}>
            <Text>청구 생성</Text>
          </Pressable>
        </View>
      </View>

      <View style={{ borderWidth: 1, borderRadius: 16, padding: 12, gap: 8 }}>
        <Text style={{ fontWeight: "600" }}>음성 명령</Text>
        <Text style={{ opacity: 0.6 }}>예: ‘내일 5시에 민지 수학 90분 추가’</Text>
        <TextInput
          value={cmd}
          onChangeText={setCmd}
          placeholder="여기에 말하거나, 입력해보세요"
          style={{ borderWidth: 1, borderRadius: 10, padding: 10 }}
        />
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10, alignSelf: "flex-start" }}>
          <Text>🎤 마이크</Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}
