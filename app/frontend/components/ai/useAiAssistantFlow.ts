import { useCallback, useEffect, useState } from "react";

/** AI 어시스턴트의 간단한 데모 플로우 (STT→처리→응답) */
export function useAiAssistantFlow(visible: boolean) {
  const [isListening, setIsListening] = useState(false);
  const [transcription, setTranscription] = useState("");
  const [aiResponse, setAiResponse] = useState("");

  const reset = useCallback(() => {
    setIsListening(false);
    setTranscription("");
    setAiResponse("");
  }, []);

  const startFlow = useCallback(() => {
    setIsListening(true);
    setTranscription("");
    setAiResponse("");

    // 데모 시뮬: STT 후 응답
    const t1 = setTimeout(() => {
      setTranscription("내일 오후 2시에 김민수 학생 수학 수업 추가해줘");
      const t2 = setTimeout(() => {
        setIsListening(false);
        setAiResponse("✓ 11월 8일 14:00에 김민수 학생 수학 수업을 등록했습니다.");
      }, 1200);
      return () => clearTimeout(t2);
    }, 800);

    return () => clearTimeout(t1);
  }, []);

  useEffect(() => {
    if (visible) {
      const cleanup = startFlow();
      return () => {
        if (typeof cleanup === "function") cleanup();
      };
    } else {
      reset();
    }
  }, [visible, startFlow, reset]);

  return { isListening, transcription, aiResponse, reset };
}
