import { Mic, Sparkles, X } from "lucide-react-native";
import React from "react";
import { Modal, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import Animated, { FadeIn, useAnimatedStyle, useSharedValue, withTiming } from "react-native-reanimated";
import { SafeAreaView, useSafeAreaInsets } from "react-native-safe-area-context";
import { useAiAssistantFlow } from "./useAiAssistantFlow";

const ATouchableOpacity = Animated.createAnimatedComponent(TouchableOpacity);

type Props = {
  visible: boolean;
  onClose: () => void;
};

export default function AiAssistantModal({ visible, onClose }: Props) {
  const { isListening, transcription, aiResponse } = useAiAssistantFlow(visible);
  const insets = useSafeAreaInsets();

  // press 애니메이션
  const scale = useSharedValue(1);
  const animatedStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  const onPressIn = () => (scale.value = withTiming(0.92, { duration: 90 }));
  const onPressOut = () => (scale.value = withTiming(1, { duration: 120 }));

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <SafeAreaView style={styles.modalContainer}>
        <ATouchableOpacity
          accessibilityRole="button"
          accessibilityLabel="AI 모달 닫기"
          onPress={onClose}
          onPressIn={onPressIn}
          onPressOut={onPressOut}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          style={[styles.closeButton, animatedStyle, { top: insets.top + 8, right: 16 }]}
        >
          <X size={22} color="white" />
        </ATouchableOpacity>

        <View style={styles.modalContent}>
          <View style={styles.modalHeader}>
            <Sparkles size={32} color="white" />
            <Text style={styles.modalTitle}>AI 어시스턴트</Text>
            <Text style={styles.modalSubtitle}>음성으로 수업을 관리하세요</Text>
          </View>

          <View style={styles.micContainer}>
            <View
              style={[
                styles.micCircle,
                { backgroundColor: isListening ? "#EF4444" : "rgba(255,255,255,0.2)" },
              ]}
            >
              <Mic size={80} color="white" />
            </View>
          </View>

          <Text style={styles.statusText}>
            {isListening ? "듣고 있습니다..." : transcription ? "처리중..." : "음성 입력 대기중"}
          </Text>

          {transcription ? (
            <Animated.View entering={FadeIn} style={styles.transcriptionBox}>
              <Text style={styles.transcriptionLabel}>음성 입력</Text>
              <Text style={styles.transcriptionText}>"{transcription}"</Text>
            </Animated.View>
          ) : null}

          {aiResponse ? (
            <Animated.View entering={FadeIn} style={styles.responseBox}>
              <View style={styles.responseHeader}>
                <Sparkles size={20} color="#9333EA" />
                <Text style={styles.responseLabel}>AI 응답</Text>
              </View>
              <Text style={styles.responseText}>{aiResponse}</Text>
            </Animated.View>
          ) : null}
        </View>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  modalContainer: {
    flex: 1,
    backgroundColor: "#7C3AED",
    padding: 24,
  },
  closeButton: {
    position: "absolute",
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.24)",
    justifyContent: "center",
    alignItems: "center",
    zIndex: 10,
  },
  modalContent: { flex: 1, alignItems: "center" },
  modalHeader: { alignItems: "center", marginBottom: 32 },
  modalTitle: { fontSize: 28, fontWeight: "700", color: "white", marginTop: 8 },
  modalSubtitle: { fontSize: 16, color: "rgba(255,255,255,0.8)", marginTop: 8 },
  micContainer: { marginBottom: 32 },
  micCircle: { width: 160, height: 160, borderRadius: 80, justifyContent: "center", alignItems: "center" },
  statusText: { fontSize: 20, color: "white", marginBottom: 24 },
  transcriptionBox: {
    backgroundColor: "rgba(255,255,255,0.2)",
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    width: "100%",
  },
  transcriptionLabel: { fontSize: 12, color: "rgba(255,255,255,0.7)", marginBottom: 4 },
  transcriptionText: { fontSize: 16, color: "white" },
  responseBox: { backgroundColor: "white", borderRadius: 16, padding: 16, width: "100%" },
  responseHeader: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 8 },
  responseLabel: { fontSize: 12, color: "#6B7280" },
  responseText: { fontSize: 16, color: "#111827" },
});
