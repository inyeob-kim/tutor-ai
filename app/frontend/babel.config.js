// module.exports = function (api) {
//   api.cache(true);
//   return {
//     presets: ["babel-preset-expo"],
//     plugins: [
//       "nativewind/babel",
//       "react-native-reanimated/plugin", // 항상 마지막
//     ],
//   };
// };  


module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'], // 절대 옵션 객체 붙이지 말 것!
    plugins: [
      'nativewind/babel',
      'react-native-reanimated/plugin',
    ],                    // 일단 플러그인 비움
  };
}; 