import { useState } from "react";
import { ActivityIndicator, Pressable, Text, ViewStyle } from "react-native";

type Props = {
  title: string;
  onPress?: () => Promise<void> | void;
  variant?: "primary" | "ghost" | "danger";
  disabled?: boolean;
  className?: string;
  style?: ViewStyle;
};

export default function Button({
  title,
  onPress,
  variant = "primary",
  disabled,
  className = "",
  style,
}: Props) {
  const [loading, setLoading] = useState(false);

  const base = "rounded-xl px-4 py-3 items-center justify-center active:opacity-90";
  const variants = {
    primary: "bg-primary",
    ghost: "bg-transparent border border-gray100",
    danger: "bg-danger",
  } as const;

  const textBy = {
    primary: "text-white",
    ghost: "text-gray900",
    danger: "text-white",
  } as const;

  const handlePress = async () => {
    if (!onPress || loading) return;
    try {
      setLoading(true);
      await onPress();
    } finally {
      setLoading(false);
    }
  };

  return (
    <Pressable
      className={`${base} ${variants[variant]} ${disabled ? "opacity-50" : ""} ${className}`}
      onPress={handlePress}
      disabled={disabled || loading}
      style={style}
    >
      {loading ? (
        <ActivityIndicator color={variant === "ghost" ? "#111827" : "#fff"} />
      ) : (
        <Text className={`font-semibold ${textBy[variant]}`}>{title}</Text>
      )}
    </Pressable>
  );
}
