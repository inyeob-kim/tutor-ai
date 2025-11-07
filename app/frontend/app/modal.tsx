// app/frontend/app/modal.tsx
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useRouter } from "expo-router";
import { Pressable } from "react-native";

export default function ModalScreen() {
  const router = useRouter();
  return (
    <ThemedView style={{ flex: 1, padding: 20, gap: 12, justifyContent: "center" }}>
      <ThemedText type="title">모달</ThemedText>
      <ThemedText>여기에 모달 콘텐츠를 넣으세요.</ThemedText>
      <Pressable onPress={() => router.back()} style={{ padding: 12, borderWidth: 1, borderRadius: 8 }}>
        <ThemedText>닫기</ThemedText>
      </Pressable>
    </ThemedView>
  );
}
