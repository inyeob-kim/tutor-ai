import Card from "@/components/ui/Card";
import { Link } from "expo-router";
import { Pressable, Text, View } from "react-native";

export type Student = {
  id: number | string;
  name: string;
  grade?: string | null;
  isAdult?: boolean;
  guardianName?: string | null;
  guardianPhone?: string | null;
};

export default function StudentItem({ s }: { s: Student }) {
  return (
    <Card className="p-3">
      <View className="flex-row items-center justify-between">
        <View>
          <Text className="font-semibold text-gray900">
            {s.name}{" "}
            {s.grade ? <Text className="text-xs opacity-60">· {s.grade}</Text> : null}
            {s.isAdult ? <Text className="text-xs opacity-60"> · 성인</Text> : null}
          </Text>

          {!s.isAdult && (
            <Text className="text-xs opacity-60 mt-0.5">
              보호자 {s.guardianName ?? "-"} / {s.guardianPhone ?? "-"}
            </Text>
          )}
        </View>

        <Link href={`/students/${s.id}`} asChild>
          <Pressable className="active:opacity-70">
            <Text className="underline text-primary font-medium">프로필</Text>
          </Pressable>
        </Link>
      </View>
    </Card>
  );
}
