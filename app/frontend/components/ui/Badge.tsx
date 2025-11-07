import React from "react";
import { Text, View, ViewProps } from "react-native";

type Variant = "default" | "secondary" | "outline";

export function Badge({
  children,
  variant = "secondary",
  style,
  ...rest
}: ViewProps & { children?: React.ReactNode; variant?: Variant }) {
  const stylesByVariant: Record<Variant, { bg: string; color: string; border?: string }> = {
    default:   { bg: "#111827", color: "#fff" },
    secondary: { bg: "#F3F4F6", color: "#111827" },
    outline:   { bg: "transparent", color: "#111827", border: "#E5E7EB" },
  };

  const s = stylesByVariant[variant];

  return (
    <View
      style={[
        {
          flexDirection: "row",
          alignItems: "center",
          alignSelf: "flex-start",
          paddingVertical: 4,
          paddingHorizontal: 8,
          borderRadius: 999,
          backgroundColor: s.bg,
          borderWidth: s.border ? 1 : 0,
          borderColor: s.border ?? "transparent",
        },
        style,
      ]}
      {...rest}
    >
      <Text style={{ fontSize: 12, fontWeight: "600", color: s.color }}>{children}</Text>
    </View>
  );
}
