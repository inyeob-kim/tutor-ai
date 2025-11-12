import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildLightTheme(),
      debugShowCheckedModeBanner: false,
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('토스 스타일 홈')),
      body: ListView.separated(
        padding: const EdgeInsets.all(Gaps.screen),
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(Gaps.cardPad),
            child: Row(
              children: const [
                CircleAvatar(radius: 18, backgroundColor: AppColors.primaryLight),
                SizedBox(width: Gaps.row),
                Expanded(child: Text('카드 내용', style: TextStyle(fontSize: 16))),
                SizedBox(width: Gaps.row),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: Gaps.card),
        itemCount: 5,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: '자산'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
      ),
    );
  }
}
