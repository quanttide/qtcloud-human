import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/compensation.dart';

/// 薪酬页面。
///
/// 主体 = 有效工时记录（日期、任务、小时数）：弹性薪资按有效工时结算，
/// 时薪水平由职级决定，结算结果可回溯。
class CompensationScreen extends StatefulWidget {
  final String compensationId;

  const CompensationScreen({super.key, this.compensationId = 'comp_001'});

  @override
  State<CompensationScreen> createState() => _CompensationScreenState();
}

class _CompensationScreenState extends State<CompensationScreen> {
  Future<Compensation>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCompensation();
  }

  Future<Compensation> _loadCompensation() async {
    final raw = await rootBundle.loadString('assets/mock/compensation.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final comp = list
        .cast<Map<String, dynamic>>()
        .map(Compensation.fromJson)
        .firstWhere((c) => c.id == widget.compensationId);
    return comp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('薪酬')),
      body: FutureBuilder<Compensation>(
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

  Widget _buildContent(BuildContext context, Compensation comp) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, comp),
        const SizedBox(height: 24),
        Text('有效工时记录', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final w in comp.workRecords) _buildWorkRecordCard(context, w),
        const SizedBox(height: 24),
        Text('时薪对照', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildRateCard(context, comp),
        const SizedBox(height: 24),
        Text('结算结果', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildSettlementCard(context, comp),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Compensation comp) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '薪酬记录',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _headerRow(context, '员工', '${comp.employee}（${comp.identity}）'),
            _headerRow(context, '职级', 'L${comp.rankLevel} ${comp.rankName}'),
            _headerRow(context, '薪酬周期', comp.cycle),
            _headerRow(
              context,
              '时薪',
              '¥${comp.hourlyRate.toStringAsFixed(0)}/h',
            ),
            _headerRow(context, '编号', comp.id),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(BuildContext context, String label, String value) {
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

  Widget _buildWorkRecordCard(BuildContext context, WorkRecord w) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.schedule, color: colorScheme.primary),
        title: Text(w.task),
        subtitle: Text(
          '${w.date} · 有效工时 ${w.hours.toStringAsFixed(1)}h',
          style: TextStyle(color: colorScheme.outline, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRateCard(BuildContext context, Compensation comp) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '职级决定时薪水平',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final r in comp.rates)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: r.level == comp.rankLevel
                      ? colorScheme.primaryContainer
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'L${r.level} ${r.name}',
                        style: TextStyle(
                          fontWeight: r.level == comp.rankLevel
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '¥${r.rate.toStringAsFixed(0)}/h',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '当前职级 L${comp.rankLevel} ${comp.rankName}，时薪 ¥${comp.hourlyRate.toStringAsFixed(0)}/h。',
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, Compensation comp) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = comp.settlement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('弹性薪资结算', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _settlementRow(
              context,
              '总有效工时',
              '${s.totalHours.toStringAsFixed(1)}h',
            ),
            _settlementRow(
              context,
              '时薪',
              '¥${comp.hourlyRate.toStringAsFixed(0)}/h',
            ),
            _settlementRow(context, '应发金额', '¥${comp.grossText}'),
            if (s.adjustment != 0)
              _settlementRow(
                context,
                '调整',
                '¥${s.adjustment.toStringAsFixed(2)}',
              ),
            const Divider(height: 20),
            Row(
              children: [
                const SizedBox(width: 80),
                Expanded(
                  child: Text(
                    '实发金额',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '¥${_fmt(s.net)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '弹性薪资按有效工时结算，不做固定月薪。',
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settlementRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
