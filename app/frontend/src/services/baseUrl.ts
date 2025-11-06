// src/services/baseUrl.ts
import { Platform } from "react-native";

export const getApiBaseUrl = () => {
  // iOS 시뮬레이터/웹: localhost
  if (Platform.OS === "ios") return "http://127.0.0.1:8000";
  // Android 에뮬레이터: 10.0.2.2
  if (Platform.OS === "android") return "http://10.0.2.2:8000";
  // Expo web 등
  return "http://127.0.0.1:8000";
};

// 실기기(휴대폰)에서 개발 시에는 노트북의 LAN IP로 바꿔야 합니다. 예: http://192.168.0.12:8000