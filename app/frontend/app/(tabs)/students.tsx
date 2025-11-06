import { Link } from "expo-router";
import { useMemo, useState } from "react";
import { Pressable, ScrollView, Text, TextInput, View } from "react-native";
import { useStudentStore } from "../../src/stores/students";

export default function Students() {
  const [q, setQ] = useState("");
  const students = useStudentStore((s) => s.students);

  const items = useMemo(() => {
    const query = q.trim().toLowerCase();
    return students.filter((s) => s.name.toLowerCase().includes(query));
  }, [q, students]);

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
        <Link href="/students/new" asChild>
          <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
            <Text>학생 등록</Text>
          </Pressable>
        </Link>
      </View>

      {items.length === 0 ? (
        <View style={{ padding: 16, borderWidth: 1, borderRadius: 16 }}>
          <Text style={{ opacity: 0.7 }}>검색 결과가 없습니다.</Text>
        </View>
      ) : null}

      {items.map((s) => (
        <View key={s.id} style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
            <View>
              <Text style={{ fontWeight: "600" }}>
                {s.name} {s.grade ? <Text style={{ opacity: 0.6, fontSize: 12 }}>· {s.grade}</Text> : null}
                {s.isAdult ? <Text style={{ opacity: 0.6, fontSize: 12 }}> · 성인</Text> : null}
              </Text>

              {/* 미성년일 때만 보호자 표시 */}
              {!s.isAdult && (
                <Text style={{ opacity: 0.6, fontSize: 12 }}>
                  보호자 {s.guardianName ?? "-"} / {s.guardianPhone ?? "-"}
                </Text>
              )}
            </View>

            <Link href={`/students/${s.id}`} style={{ textDecorationLine: "underline" }}>
              프로필
            </Link>
          </View>
        </View>
      ))}
    </ScrollView>
  );
}
