import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plan.dart';

/// 计划页面。
///
/// 主体 = 计划列表：招聘计划、培训计划、绩效计划、薪酬结算计划等，
/// 计划定义周期与目标，进度可追踪。
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  Future<List<Plan>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPlans();
  }

  Future<List<Plan>> _loadPlans() async {
    final raw = await rootBundle.loadString('assets/mock/plans.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(Plan.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计划')),
      body: FutureBuilder<List<Plan>>(
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

  Widget _buildContent(BuildContext context, List<Plan> plans) {
    final textTheme = Theme.of(context).textTheme;
    final doing = plans.where((p) => p.status == PlanStatus.doing).length;
    final done = plans.where((p) => p.status == PlanStatus.done).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, doing, done),
        const SizedBox(height: 24),
        Text('计划列表', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final p in plans) _buildPlanCard(context, p),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, int doing, int done) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event_note, size: 32, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('计划总览', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '进行中 $doing 项 · 已完成 $done 项',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan p) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (p.status) {
      PlanStatus.done => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      PlanStatus.doing => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      PlanStatus.draft => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.type,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              p.cycle,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(p.progress, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
