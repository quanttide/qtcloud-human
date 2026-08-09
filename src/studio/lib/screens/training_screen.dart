import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/training.dart';

/// 培训页面。
///
/// 主体 = 主线任务进度：管理培训人员的进度——任务、起止时间、状态，
/// 以真实业务为教材，进度即授权阶段；带教反馈辅助呈现。
class TrainingScreen extends StatefulWidget {
  final String trainingId;

  const TrainingScreen({super.key, this.trainingId = 'train_001'});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  Future<Training>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTraining();
  }

  Future<Training> _loadTraining() async {
    final raw = await rootBundle.loadString('assets/mock/training.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final training = list
        .cast<Map<String, dynamic>>()
        .map(Training.fromJson)
        .firstWhere((t) => t.id == widget.trainingId);
    return training;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('培训')),
      body: FutureBuilder<Training>(
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

  Widget _buildContent(BuildContext context, Training training) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, training),
        const SizedBox(height: 24),
        Text('主线任务进度', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final t in training.tasks) _buildTaskCard(context, t),
        const SizedBox(height: 24),
        Text('带教反馈', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        _buildFeedbackCard(context, training.feedback),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Training training) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '培训进度',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _headerRow(
              context,
              '学员',
              '${training.trainee}（${training.identity}）',
            ),
            _headerRow(context, '培训阶段', training.phase),
            _headerRow(context, '带教人', training.mentor),
            _headerRow(context, '周期', training.cycle),
            _headerRow(context, '编号', training.id),
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

  Widget _buildTaskCard(BuildContext context, TrainingTask t) {
    final colorScheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (t.status) {
      TaskStatus.done => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      TaskStatus.doing => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      TaskStatus.todo => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
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
                    t.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.dateText,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            if (t.note != null) ...[
              const SizedBox(height: 6),
              Text(t.note!, style: TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, TrainingFeedback feedback) {
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
                  Icons.record_voice_over,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('带教反馈', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(feedback.content),
            if (feedback.next != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '下一步：${feedback.next}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    feedback.mentor.characters.first,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '带教人：${feedback.mentor}',
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
