import { Text, View } from "react-native";

export default function BillingScreen() {
  return (
    <View style={{ flex: 1, backgroundColor: "white", padding: 16 }}>
      <Text style={{ fontSize: 20, fontWeight: "600" }}>청구</Text>
      <Text style={{ marginTop: 8 }}>결제/인보이스/정산 예정</Text>
    </View>
  );
}
