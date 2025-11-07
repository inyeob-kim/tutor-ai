// app/(tabs)/_layout.tsx
import { Tabs } from "expo-router";
import { CalendarDays, CreditCard, GraduationCap, Home, Settings } from "lucide-react-native";
import { Platform } from "react-native";

export default function TabsLayout() {
  const tabBarHeight = Platform.select({ ios: 88, android: 64, default: 64 });

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: {
          height: tabBarHeight,
          backgroundColor: "white", 
          borderTopColor: "#eee",
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          tabBarIcon: ({ color, size }) => <Home color={color} size={size} />,
          title: "Home",
        }}
      />
      <Tabs.Screen
        name="schedule"
        options={{
          tabBarIcon: ({ color, size }) => <CalendarDays color={color} size={size} />,
          title: "Schedule",
        }}
      />
      <Tabs.Screen
        name="students"
        options={{
          tabBarIcon: ({ color, size }) => <GraduationCap color={color} size={size} />,
          title: "Students",
        }}
      />
      <Tabs.Screen
        name="billing"
        options={{
          tabBarIcon: ({ color, size }) => <CreditCard color={color} size={size} />,
          title: "Billing",
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          tabBarIcon: ({ color, size }) => <Settings color={color} size={size} />,
          title: "Settings",
        }}
      />
    </Tabs>
  );
}
