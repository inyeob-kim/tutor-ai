import { format, isSameDay, parseISO } from "date-fns";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, Text, TextInput, View } from "react-native";
import { useLessonStore } from "../../src/stores/lessons";
import { useStudentStore } from "../../src/stores/students";

export default function Schedule() {
  const router = useRouter();
  const [view, setView] = useState<"list" | "calendar">("list");
  const [dateStr, setDateStr] = useState<string>(() => format(new Date(), "yyyy-MM-dd"));

  const lessons = useLessonStore((s) => s.lessons);
  const setAttendance = useLessonStore((s) => s.setAttendance);
  const toggleDone = useLessonStore((s) => s.toggleDone);

  const students = useStudentStore((s) => s.students);

  const items = useMemo(() => {
    const selectedDate = new Date(`${dateStr}T00:00:00`);
    return lessons
      .filter((l) => isSameDay(parseISO(l.startsAt), selectedDate))
      .sort((a, b) => parseISO(a.startsAt).getTime() - parseISO(b.startsAt).getTime());
  }, [lessons, dateStr]);

  const goNewLesson = () => router.push({ pathname: "/lessons/new", params: { date: dateStr } });

  return (
    <View style={{ flex: 1, padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>스케줄</Text>

      <View style={{ flexDirection: "row", gap: 8 }}>
        <TextInput
          value={dateStr}
          onChangeText={setDateStr}
          placeholder="YYYY-MM-DD"
          style={{ borderWidth: 1, borderRadius: 10, padding: 10, flex: 1 }}
        />
        <Pressable
          onPress={() => setView("list")}
          style={{
            borderWidth: 1,
            padding: 10,
            borderRadius: 10,
            backgroundColor: view === "list" ? "#efefef" : "white",
          }}
        >
          <Text>리스트</Text>
        </Pressable>
        <Pressable
          onPress={() => setView("calendar")}
          style={{
            borderWidth: 1,
            padding: 10,
            borderRadius: 10,
            backgroundColor: view === "calendar" ? "#efefef" : "white",
          }}
        >
          <Text>달력</Text>
        </Pressable>
        <Pressable onPress={goNewLesson} style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>수업 추가</Text>
        </Pressable>
      </View>

      {view === "list" ? (
        <ScrollView style={{ flex: 1 }} contentContainerStyle={{ gap: 0 }}>
          <View style={{ borderWidth: 1, borderRadius: 16, overflow: "hidden" }}>
            {items.length === 0 ? (
              <View style={{ padding: 12 }}>
                <Text style={{ opacity: 0.6 }}>선택한 날짜에 수업이 없습니다.</Text>
              </View>
            ) : (
              items.map((l, i) => {
                const st = students.find((s) => s.id === l.studentId);
                const time = format(parseISO(l.startsAt), "HH:mm");
                const dimStyle = l.status === "done" ? { opacity: 0.55 } : null;
                const lineStyle = l.status === "done" ? { textDecorationLine: "line-through" as const } : null;

                return (
                  <View
                    key={l.id}
                    style={{
                      padding: 12,
                      borderTopWidth: i === 0 ? 0 : 1,
                      gap: 8,
                    }}
                  >
                    {/* 상단 줄 */}
                    <View
                      style={{
                        flexDirection: "row",
                        alignItems: "center",
                        justifyContent: "space-between",
                      }}
                    >
                      <View>
                        <Text style={[{ fontWeight: "600" }, lineStyle]}>
                          {time} · {st?.name ?? "(삭제된 학생)"}
                        </Text>
                        <Text style={[{ opacity: 0.6 }, lineStyle]}>
                          {l.subject} · {l.durationMin}분
                        </Text>
                      </View>

                      {/* 완료 토글 */}
                      <Pressable
                        onPress={() => toggleDone(l.id)}
                        style={{
                          borderWidth: 1,
                          paddingVertical: 6,
                          paddingHorizontal: 10,
                          borderRadius: 999,
                          backgroundColor: l.status === "done" ? "#e5ffe5" : "white",
                        }}
                      >
                        <Text>{l.status === "done" ? "완료 취소" : "완료"}</Text>
                      </Pressable>
                    </View>

                    {/* 출결 칩들 */}
                    <View style={[{ flexDirection: "row", gap: 8 }, dimStyle]}>
                      <Pressable
                        onPress={() => setAttendance(l.id, "show")}
                        style={{
                          borderWidth: 1,
                          paddingVertical: 6,
                          paddingHorizontal: 10,
                          borderRadius: 999,
                          backgroundColor: l.attendance === "show" ? "#efefef" : "white",
                        }}
                      >
                        <Text>출석</Text>
                      </Pressable>
                      <Pressable
                        onPress={() => setAttendance(l.id, "late")}
                        style={{
                          borderWidth: 1,
                          paddingVertical: 6,
                          paddingHorizontal: 10,
                          borderRadius: 999,
                          backgroundColor: l.attendance === "late" ? "#efefef" : "white",
                        }}
                      >
                        <Text>지각</Text>
                      </Pressable>
                      <Pressable
                        onPress={() => setAttendance(l.id, "absent")}
                        style={{
                          borderWidth: 1,
                          paddingVertical: 6,
                          paddingHorizontal: 10,
                          borderRadius: 999,
                          backgroundColor: l.attendance === "absent" ? "#efefef" : "white",
                        }}
                      >
                        <Text>결석</Text>
                      </Pressable>
                    </View>
                  </View>
                );
              })
            )}
          </View>
        </ScrollView>
      ) : (
        <View style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
          <Text style={{ opacity: 0.6 }}>달력(주/월) 뷰 자리 — 외부 캘린더 연동 예정</Text>
        </View>
      )}
    </View>
  );
}
