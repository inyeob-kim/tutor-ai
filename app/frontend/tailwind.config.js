/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
      "./app/**/*.{js,jsx,ts,tsx}",
      "./components/**/*.{js,jsx,ts,tsx}",
      "./src/**/*.{js,jsx,ts,tsx}",
    ],
    darkMode: "class",
    theme: {
      extend: {
        colors: {
          primary: "#3182F6",
          gray900: "#111827",
          gray700: "#374151",
          gray100: "#F3F4F6",
          success: "#10B981",
          danger:  "#EF4444",
        },
        borderRadius: { xl: "0.875rem", "2xl": "1.25rem" },
        boxShadow: {
          card: "0 4px 14px rgba(17,24,39,0.06)" // iOS용(안드는 elevation)
        },
        fontSize: {
          h1: ["28px", "34px"],
          h2: ["22px", "28px"],
        },
      },
    },
    plugins: [],
  };
  