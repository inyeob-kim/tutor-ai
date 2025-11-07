import React from "react";
import { Text, View, ViewStyle } from "react-native";

interface AvatarProps {
  size?: number;
  style?: ViewStyle;
  children: React.ReactNode;
}

export const Avatar: React.FC<AvatarProps> = ({ size = 40, style, children }) => {
  return (
    <View
      style={[
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          overflow: "hidden",
        },
        style,
      ]}
    >
      {children}
    </View>
  );
};

interface AvatarFallbackProps {
  children: React.ReactNode;
  backgroundColor?: string;
  textColor?: string;
}

export const AvatarFallback: React.FC<AvatarFallbackProps> = ({
  children,
  backgroundColor = "#3B82F6",
  textColor = "white",
}) => {
  return (
    <View
      style={{
        flex: 1,
        backgroundColor,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <Text style={{ color: textColor, fontSize: 18, fontWeight: "600" }}>
        {children}
      </Text>
    </View>
  );
};
