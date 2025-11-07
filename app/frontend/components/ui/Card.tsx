import { View, ViewProps } from "react-native";

type Props = ViewProps & { className?: string };

export default function Card({ className = "", style, ...props }: Props) {
  return (
    <View
      className={`bg-white rounded-2xl border border-gray100 ${className}`}
      style={[
        {
          shadowColor: "#000",
          shadowOpacity: 0.06,
          shadowRadius: 10,
          shadowOffset: { width: 0, height: 4 },
          elevation: 3,
        },
        style,
      ]}
      {...props}
    />
  );
}
