import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/relation.dart';

/// 员工关系页面。
///
/// 主体 = 生命周期记录：入职、试用期、调动、晋升、降职、离职，
/// 当前状态与关键日期清晰，事件可回溯。
class RelationScreen extends StatefulWidget {
  final String relationId;

  const RelationScreen({super.key, this.relationId = 'rel_001'});

  @override
  State<RelationScreen> createState() => _RelationScreenState();
}

class _RelationScreenState extends State<RelationScreen> {
  Future<EmployeeRelation>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRelation();
  }

  Future<EmployeeRelation> _loadRelation() async {
    final raw = await rootBundle.loadString('assets/mock/relations.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final rel = list
        .cast<Map<String, dynamic>>()
        .map(EmployeeRelation.fromJson)
        .firstWhere((r) => r.id == widget.relationId);
    return rel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关系')),
      body: FutureBuilder<EmployeeRelation>(
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

  Widget _buildContent(BuildContext context, EmployeeRelation rel) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, rel),
        const SizedBox(height: 24),
        Text('生命周期记录', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final r in rel.records) _buildRecordCard(context, r),
        const SizedBox(height: 24),
        Text('状态说明', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildStatusCard(context, rel),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, EmployeeRelation rel) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = rel.status == 'probation'
        ? (const Color(0xFFFEF3C7), const Color(0xFF92400E))
        : rel.status == 'active'
        ? (const Color(0xFFDCFCE7), const Color(0xFF166534))
        : (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '员工关系',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
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
                    rel.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _headerRow(context, '员工', '${rel.employee}（${rel.identity}）'),
            _headerRow(context, '入职日', rel.hireDate),
            if (rel.probationEnd != null)
              _headerRow(context, '试用期至', rel.probationEnd!),
            _headerRow(context, '编号', rel.id),
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

  Widget _buildRecordCard(BuildContext context, RelationRecord r) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (r.status) {
      'done' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'doing' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    final statusLabel = switch (r.status) {
      'done' => '已完成',
      'doing' => '进行中',
      _ => '未开始',
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
                    r.type.label,
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
                    statusLabel,
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
            Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              r.date,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            if (r.note != null) ...[
              const SizedBox(height: 6),
              Text(r.note!, style: TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, EmployeeRelation rel) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('当前阶段', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(rel.statusNote),
            if (rel.next != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '下一步：${rel.next}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
