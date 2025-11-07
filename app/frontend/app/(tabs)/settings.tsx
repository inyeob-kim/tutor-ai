import { Text, View } from "react-native";

export default function SettingsScreen() {
  return (
    <View style={{ flex: 1, backgroundColor: "white", padding: 16 }}>
      <Text style={{ fontSize: 20, fontWeight: "600" }}>설정</Text>
      <Text style={{ marginTop: 8 }}>언어, 알림, 계정 등</Text>
    </View>
  );
}
