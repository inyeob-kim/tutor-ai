import { TextInput, TextInputProps } from "react-native";

type Props = TextInputProps & { className?: string };

export default function Input({ className = "", ...rest }: Props) {
  return (
    <TextInput
      placeholderTextColor="#9CA3AF"
      className={`bg-white border border-gray100 rounded-xl px-4 py-3 text-gray900 ${className}`}
      {...rest}
    />
  );
}
