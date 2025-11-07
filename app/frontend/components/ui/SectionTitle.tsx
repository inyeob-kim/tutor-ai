import React from "react";
import { StyleSheet, Text, View, ViewProps } from "react-native";

type Props = ViewProps & {
  children: React.ReactNode;
  subtitle?: string;     // optional subtitle
};

export function SectionTitle({ children, subtitle, style, ...rest }: Props) {
  return (
    <View style={[styles.container, style]} {...rest}>
      <Text style={styles.title}>{children}</Text>
      {subtitle && <Text style={styles.subtitle}>{subtitle}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 12,
    marginBottom: 12,
  },
  title: {
    fontSize: 18,
    fontWeight: "700",
    color: "#111827",
    letterSpacing: -0.3,
  },
  subtitle: {
    fontSize: 13,
    color: "#6B7280",
    marginTop: 4,
  },
});
