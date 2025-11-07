import { Text, View } from "react-native";

export default function ScheduleScreen() {
  return (
    <View style={{ flex: 1, backgroundColor: "white", padding: 16 }}>
      <Text style={{ fontSize: 20, fontWeight: "600" }}>스케줄</Text>
      <Text style={{ marginTop: 8 }}>수업 일정/달력 연동 영역</Text>
    </View>
  );
}
