import { Pressable, ScrollView, Text, View } from "react-native";

function Section(props: { title: string; desc: string; children?: React.ReactNode }) {
  return (
    <View style={{ borderWidth: 1, borderRadius: 16, padding: 12 }}>
      <Text style={{ fontWeight: "600", marginBottom: 4 }}>{props.title}</Text>
      <Text style={{ opacity: 0.6, marginBottom: 8 }}>{props.desc}</Text>
      {props.children}
    </View>
  );
}

export default function Settings() {
  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "600" }}>설정</Text>

      <Section title="계정/기관" desc="은행 계좌, 청구서 로고·발신자명, 영수증 양식">
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>프로필 설정</Text>
        </Pressable>
      </Section>

      <Section title="AI/음성" desc="명령어, 자동 요약, 템플릿">
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>명령 템플릿</Text>
        </Pressable>
      </Section>

      <Section title="데이터" desc="백업/복원, 내보내기(CSV), 보안">
        <Pressable style={{ borderWidth: 1, padding: 10, borderRadius: 10 }}>
          <Text>내보내기</Text>
        </Pressable>
      </Section>
    </ScrollView>
  );
}
