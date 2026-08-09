import 'package:flutter/material.dart';

import 'screens/performance_screen.dart';
import 'screens/recruitment_screen.dart';

void main() => runApp(const WorkbenchApp());

class WorkbenchApp extends StatelessWidget {
  const WorkbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮人事云工作台',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const WorkbenchShell(),
    );
  }
}

/// 工作台骨架：左侧导航栏 + 模块页面。
///
/// 各模块独立文件、独立 Scaffold，通过侧边导航切换。
class WorkbenchShell extends StatefulWidget {
  const WorkbenchShell({super.key});

  @override
  State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
  int _index = 0;

  static const _pages = <Widget>[PerformanceScreen(), RecruitmentPage()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Icon(Icons.workspaces, size: 28, color: colorScheme.primary),
                  const SizedBox(height: 4),
                  Text(
                    '量潮人事',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: Text('绩效'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.mail_outline),
                selectedIcon: Icon(Icons.mail),
                label: Text('招聘'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }
}
