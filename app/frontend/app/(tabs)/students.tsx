import { useMemo, useState } from "react";
import { Pressable, ScrollView, Text, TextInput, View } from "react-native";

export default function Students() {
  const [q, setQ] = useState("");
  const data = [
    { name: "김민지", grade: "중2", guardian: "김수현", phone: "010-1234-5678" },
    { name: "Alex", grade: "HS-1", guardian: "—", phone: "010-5555-9999" },
  ];
  const items = useMemo(() => data.filter(s => s.name.includes(q)), [q]);

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>학생</Text>

      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput
          value={q}
          onChangeText={setQ}
          placeholder="학생 검색"
          style={{ borderWidth: 1, borderRadius: 10, padding: 10, flex: 1 }}
        />
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>학생 등록</Text>
        </Pressable>
      </View>

      {items.map((s, i) => (
        <View key={i} style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
            <View>
              <Text style={{ fontWeight: "600" }}>
                {s.name} <Text style={{ opacity: 0.6, fontSize: 12 }}>· {s.grade}</Text>
              </Text>
              <Text style={{ opacity: 0.6, fontSize: 12 }}>
                보호자 {s.guardian} / {s.phone}
              </Text>
            </View>
            {/* <Link href={`/students/${encodeURIComponent(s.name)}`} style={{ textDecorationLine: "underline" }}>
              프로필
            </Link> */}
          </View>
        </View>
      ))}
    </ScrollView>
  );
}
