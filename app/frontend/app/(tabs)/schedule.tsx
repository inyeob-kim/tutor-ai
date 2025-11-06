import { useState } from "react";
import { Pressable, Text, TextInput, View } from "react-native";

export default function Schedule() {
  const [view, setView] = useState<"list" | "calendar">("list");

  return (
    <View style={{ flex: 1, padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>스케줄</Text>

      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput placeholder="YYYY-MM-DD" style={{ borderWidth: 1, borderRadius: 10, padding: 10, flex: 1 }} />
        <Pressable
          onPress={() => setView("list")}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, backgroundColor: view === "list" ? "#efefef" : "white" }}
        >
          <Text>리스트</Text>
        </Pressable>
        <Pressable
          onPress={() => setView("calendar")}
          style={{ borderWidth: 1, padding: 10, borderRadius: 10, backgroundColor: view === "calendar" ? "#efefef" : "white" }}
        >
          <Text>달력</Text>
        </Pressable>
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>수업 추가</Text>
        </Pressable>
      </View>

      {view === "list" ? (
        <View style={{ borderWidth: 1, borderRadius: 16 }}>
          {[
            { time: "16:00", name: "김민지", subject: "수학", dur: "90분" },
            { time: "18:00", name: "Alex", subject: "영어", dur: "60분" },
          ].map((s, i) => (
            <View
              key={i}
              style={{
                padding: 12,
                borderTopWidth: i === 0 ? 0 : 1,
                flexDirection: "row",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <View>
                <Text style={{ fontWeight: "600" }}>
                  {s.time} · {s.name}
                </Text>
                <Text style={{ opacity: 0.6 }}>
                  {s.subject} · {s.dur}
                </Text>
              </View>
              <View style={{ flexDirection: "row", gap: 8 }}>
                <Pressable style={{ borderWidth: 1, paddingVertical: 6, paddingHorizontal: 10, borderRadius: 8 }}>
                  <Text>수정</Text>
                </Pressable>
                <Pressable style={{ borderWidth: 1, paddingVertical: 6, paddingHorizontal: 10, borderRadius: 8 }}>
                  <Text>삭제</Text>
                </Pressable>
              </View>
            </View>
          ))}
        </View>
      ) : (
        <View style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
          <Text style={{ opacity: 0.6 }}>달력(주/월) 뷰 자리 — 외부 캘린더 연동 예정</Text>
        </View>
      )}
    </View>
  );
}
