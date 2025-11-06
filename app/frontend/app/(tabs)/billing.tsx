import { useState } from "react";
import { Pressable, ScrollView, Text, TextInput, View } from "react-native";

export default function Billing() {
  const [month, setMonth] = useState("2025-11");
  const rows = [
    { date: "11/06", name: "김민지", amount: 60000, status: "미납" },
    { date: "11/05", name: "Alex", amount: 50000, status: "완료" },
  ];

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>청구/정산</Text>

      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput
          value={month}
          onChangeText={setMonth}
          placeholder="YYYY-MM"
          style={{ borderWidth: 1, borderRadius: 10, padding: 10, width: 140 }}
        />
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>필터 적용</Text>
        </Pressable>
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>CSV 내보내기</Text>
        </Pressable>
      </View>

      <View style={{ flexDirection: "row", gap: 12 }}>
        <View style={{ borderWidth: 1, borderRadius: 16, padding: 12, flex: 1 }}>
          <Text style={{ fontWeight: "600", marginBottom: 6 }}>이번 달 수익</Text>
          <Text style={{ fontSize: 20, fontWeight: "700" }}>₩1,200,000</Text>
          <Text style={{ opacity: 0.6 }}>세후 추정 ₩1,050,000</Text>
        </View>
        <View style={{ borderWidth: 1, borderRadius: 16, padding: 12, flex: 1 }}>
          <Text style={{ fontWeight: "600", marginBottom: 6 }}>미수금</Text>
          <Text style={{ fontSize: 20, fontWeight: "700" }}>2건</Text>
          <Text style={{ opacity: 0.6 }}>메시지 발송 예정 11/07 10:00</Text>
        </View>
      </View>

      <View style={{ borderWidth: 1, borderRadius: 16 }}>
        {/* 간단한 표 형태 */}
        <View style={{ flexDirection: "row", padding: 12, backgroundColor: "#f5f5f5" }}>
          <Text style={{ flex: 1, fontWeight: "600" }}>일자</Text>
          <Text style={{ flex: 1, fontWeight: "600" }}>학생</Text>
          <Text style={{ flex: 1, fontWeight: "600" }}>금액</Text>
          <Text style={{ flex: 1, fontWeight: "600" }}>상태</Text>
          <Text style={{ width: 120, fontWeight: "600" }}>액션</Text>
        </View>
        {rows.map((r, i) => (
          <View key={i} style={{ flexDirection: "row", padding: 12, borderTopWidth: 1 }}>
            <Text style={{ flex: 1 }}>{r.date}</Text>
            <Text style={{ flex: 1 }}>{r.name}</Text>
            <Text style={{ flex: 1 }}>₩{r.amount.toLocaleString()}</Text>
            <Text style={{ flex: 1 }}>{r.status}</Text>
            <View style={{ width: 120, flexDirection: "row", gap: 8 }}>
              <Pressable style={{ borderWidth: 1, paddingVertical: 6, paddingHorizontal: 10, borderRadius: 8 }}>
                <Text>청구서</Text>
              </Pressable>
              <Pressable style={{ borderWidth: 1, paddingVertical: 6, paddingHorizontal: 10, borderRadius: 8 }}>
                <Text>리마인드</Text>
              </Pressable>
            </View>
          </View>
        ))}
      </View>
    </ScrollView>
  );
}
