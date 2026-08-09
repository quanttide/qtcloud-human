import 'package:flutter/material.dart';

import 'screens/compensation_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/recruitment_screen.dart';
import 'screens/relation_screen.dart';
import 'screens/training_screen.dart';

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

  static const _pages = <Widget>[
    OverviewScreen(),
    PlanScreen(),
    RecruitmentPage(),
    TrainingScreen(),
    PerformanceScreen(),
    CompensationScreen(),
    RelationScreen(),
  ];

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
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('总览'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: Text('计划'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.mail_outline),
                selectedIcon: Icon(Icons.mail),
                label: Text('招聘'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: Text('培训'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: Text('绩效'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: Text('薪酬'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('关系'),
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
