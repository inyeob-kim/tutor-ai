// components/ui/Button.tsx
import React from "react";
import {
    GestureResponderEvent,
    Text,
    TextStyle,
    TouchableOpacity,
    View,
    ViewStyle,
} from "react-native";

type ButtonVariant = "default" | "outline" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

interface ButtonProps {
  children: React.ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  onPress?: (e: GestureResponderEvent) => void;
  style?: ViewStyle;
  disabled?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = "default",
  size = "md",
  onPress,
  style,
  disabled = false,
}) => {
  const base: ViewStyle = {
    borderRadius: 10,
    justifyContent: "center",
    alignItems: "center",
    flexDirection: "row",
  };

  const sizeStyles: Record<ButtonSize, ViewStyle> = {
    sm: { paddingVertical: 8, paddingHorizontal: 12 },
    md: { paddingVertical: 12, paddingHorizontal: 16 },
    lg: { paddingVertical: 16, paddingHorizontal: 24 },
  };

  const variantStyles: Record<ButtonVariant, ViewStyle> = {
    default: { backgroundColor: "#2563EB" },
    outline: { backgroundColor: "transparent", borderWidth: 1, borderColor: "#E5E7EB" },
    ghost: { backgroundColor: "transparent" },
  };

  const textColors: Record<ButtonVariant, TextStyle> = {
    default: { color: "white" },
    outline: { color: "#374151" },
    ghost: { color: "#374151" },
  };

  const textStyle: TextStyle = {
    fontWeight: "600",
    ...textColors[variant],
  };

  // ✅ 문자열/숫자는 자동으로 <Text>로 래핑
  const content = React.Children.map(children, (child) => {
    if (typeof child === "string" || typeof child === "number") {
      return <Text style={textStyle}>{child}</Text>;
    }
    return child as React.ReactElement;
  });

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.7}
      style={[
        base,
        sizeStyles[size],
        variantStyles[variant],
        disabled ? { opacity: 0.5 } : null,
        style,
      ]}
    >
      <View style={{ flexDirection: "row", alignItems: "center" }}>{content}</View>
    </TouchableOpacity>
  );
};
