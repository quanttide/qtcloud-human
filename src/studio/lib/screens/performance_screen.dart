import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/performance.dart';

/// 绩效页面。
///
/// 主体 = 行为成果记录（时间、事项、结果）：展示这个人在这段绩效周期里做了什么，
/// 与前台结果对齐，同一份契约、同一种展示。
/// 参考指标（数字资产贡献）与评估结果为辅助呈现。
class PerformanceScreen extends StatefulWidget {
  final String performanceId;

  const PerformanceScreen({super.key, this.performanceId = 'perf_001'});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  Future<Performance>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPerformance();
  }

  Future<Performance> _loadPerformance() async {
    final raw = await rootBundle.loadString('assets/mock/records.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final perf = list
        .cast<Map<String, dynamic>>()
        .map(Performance.fromJson)
        .firstWhere((p) => p.id == widget.performanceId);
    return perf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绩效')),
      body: FutureBuilder<Performance>(
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

  Widget _buildContent(BuildContext context, Performance perf) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, perf),
        const SizedBox(height: 24),
        Text('行为成果记录', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final r in perf.records) _buildRecordCard(context, r),
        if (perf.metric != null) ...[
          const SizedBox(height: 24),
          Text('参考指标', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildMetricCard(context, perf.metric!),
        ],
        if (perf.assessment != null) ...[
          const SizedBox(height: 24),
          Text('评估结果', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildAssessmentCard(context, perf.assessment!),
        ],
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Performance perf) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '绩效记录',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _headerRow('员工', '${perf.employee}（${perf.identity}）'),
            _headerRow('绩效周期', perf.cycle),
            _headerRow('编号', perf.id),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, PerformanceRecord r) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPractice = r.type == 'practice';
    return Card(
      child: ListTile(
        leading: Icon(
          isPractice ? Icons.workspace_premium : Icons.history,
          color: colorScheme.primary,
        ),
        title: Text(r.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.time,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(r.result),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, Metric metric) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in metric.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        item.source,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ),
                    Expanded(child: Text(item.value)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '参考指标不作为唯一或主要考核依据。',
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Assessment assessment) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grading, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '绩效等级：${assessment.level}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(assessment.comment),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    assessment.assessor.characters.first,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '评估人：${assessment.assessor}',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
