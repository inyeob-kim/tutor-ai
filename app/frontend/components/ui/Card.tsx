import React from "react";
import { View, ViewProps } from "react-native";

export function Card({ style, ...rest }: ViewProps) {
  return (
    <View
      style={[
        {
          borderRadius: 16,
          backgroundColor: "white",
          borderWidth: 1,
          borderColor: "#E5E7EB",
          overflow: "hidden",
        },
        style,
      ]}
      {...rest}
    />
  );
}

export function CardContent({ style, ...rest }: ViewProps) {
  return (
    <View
      style={[
        {
          padding: 12,
        },
        style,
      ]}
      {...rest}
    />
  );
}
