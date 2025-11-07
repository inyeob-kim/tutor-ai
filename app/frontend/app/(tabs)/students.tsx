// app/(tabs)/students.tsx
import { Link } from "expo-router";
import { useMemo, useState } from "react";
import { ScrollView, Text, View } from "react-native";
import { useStudentStore } from "../../src/stores/students";

// 공통 컴포넌트
import StudentItem from "@/components/list/StudentItem";
import Button from "@/components/ui/Button";
import Card from "@/components/ui/Card";
import Input from "@/components/ui/Input";

export default function Students() {
  const [q, setQ] = useState("");
  const students = useStudentStore((s) => s.students);

  const items = useMemo(() => {
    const query = q.trim().toLowerCase();
    return students.filter((s) => s.name.toLowerCase().includes(query));
  }, [q, students]);

  return (
    <ScrollView className="flex-1 bg-white">
      <View className="p-4 gap-3">
        {/* 타이틀 */}
        <Text className="text-xl font-semibold text-gray900">학생</Text>

        {/* 검색 + 등록 버튼 */}
        <View className="flex-row gap-2">
          <Input
            value={q}
            onChangeText={setQ}
            placeholder="학생 검색"
            className="flex-1"
          />

          <Link href="/students/new" asChild>
            <Button title="학생 등록" variant="ghost" />
          </Link>
        </View>

        {/* 결과 없음 */}
        {items.length === 0 ? (
          <Card className="p-4">
            <Text className="opacity-70">검색 결과가 없습니다.</Text>
          </Card>
        ) : null}

        {/* 결과 리스트 */}
        <View className="gap-3">
          {items.map((s) => (
            <StudentItem key={s.id} s={s} />
          ))}
        </View>
      </View>
    </ScrollView>
  );
}
