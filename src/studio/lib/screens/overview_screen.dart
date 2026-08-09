import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/overview.dart';

/// 总览仪表盘页面。
///
/// 聚合各模块关键指标与最新动态，一屏掌握全局；首页入口。
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Future<Overview>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadOverview();
  }

  Future<Overview> _loadOverview() async {
    final raw = await rootBundle.loadString('assets/mock/overview.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return Overview.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('总览')),
      body: FutureBuilder<Overview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Overview overview) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, overview),
        const SizedBox(height: 24),
        Text('关键指标', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            for (final s in overview.stats) _buildStatCard(context, s),
          ],
        ),
        const SizedBox(height: 24),
        Text('最新动态', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final a in overview.activities) _buildActivityCard(context, a),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Overview overview) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.dashboard, size: 32, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('量潮人事云工作台', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '数据时点：${overview.asOf}',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Stat s) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (s.module) {
      '招聘' => Icons.mail_outline,
      '培训' => Icons.school_outlined,
      '绩效' => Icons.assessment_outlined,
      '薪酬' => Icons.payments_outlined,
      _ => Icons.widgets_outlined,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.module,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              s.value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(s.label, style: TextStyle(fontSize: 12)),
            Text(
              s.detail,
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity a) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (a.module) {
      '招聘' => Icons.mail_outline,
      '培训' => Icons.school_outlined,
      '绩效' => Icons.assessment_outlined,
      '薪酬' => Icons.payments_outlined,
      _ => Icons.widgets_outlined,
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(a.title),
        subtitle: Text(
          '${a.module} · ${a.time}',
          style: TextStyle(color: colorScheme.outline, fontSize: 12),
        ),
      ),
    );
  }
}
