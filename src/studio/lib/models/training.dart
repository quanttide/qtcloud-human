library;

import 'package:flutter/foundation.dart';

/// 培训数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 页面主体 = 主线任务进度（TrainingTask：任务、起止时间、状态），
/// 以真实业务为教材，进度即授权阶段；带教反馈（Feedback）辅助呈现。

/// 主线任务状态：未开始 / 进行中 / 已完成。
enum TaskStatus { todo, doing, done }

/// 主线任务：真实业务任务，兼具业务价值与学习功能。
@immutable
class TrainingTask {
  final String id;
  final String title;
  final String? startDate;
  final String? endDate;
  final TaskStatus status;
  final String? note;

  const TrainingTask({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    required this.status,
    this.note,
  });

  factory TrainingTask.fromJson(Map<String, dynamic> json) => TrainingTask(
    id: json['id'] as String,
    title: json['title'] as String,
    startDate: json['startDate'] as String?,
    endDate: json['endDate'] as String?,
    status: TaskStatus.values.byName(json['status'] as String),
    note: json['note'] as String?,
  );

  String get statusLabel => switch (status) {
    TaskStatus.todo => '未开始',
    TaskStatus.doing => '进行中',
    TaskStatus.done => '已完成',
  };

  String get dateText {
    if (startDate == null && endDate == null) return '待安排';
    if (startDate == endDate || endDate == null) return startDate ?? '';
    return '$startDate 至 $endDate';
  }
}

/// 带教反馈：署名反馈与阶段小结。
@immutable
class TrainingFeedback {
  final String mentor;
  final String content;
  final String? next;

  const TrainingFeedback({
    required this.mentor,
    required this.content,
    this.next,
  });

  factory TrainingFeedback.fromJson(Map<String, dynamic> json) =>
      TrainingFeedback(
        mentor: json['mentor'] as String,
        content: json['content'] as String,
        next: json['next'] as String?,
      );
}

/// 培训进度聚合：一个人的培训主线任务进度、阶段与带教反馈。
@immutable
class Training {
  final String id;
  final String trainee;
  final String identity;
  final String phase;
  final String cycle;
  final String mentor;
  final List<TrainingTask> tasks;
  final TrainingFeedback feedback;

  const Training({
    required this.id,
    required this.trainee,
    required this.identity,
    required this.phase,
    required this.cycle,
    required this.mentor,
    required this.tasks,
    required this.feedback,
  });

  factory Training.fromJson(Map<String, dynamic> json) => Training(
    id: json['id'] as String,
    trainee: json['trainee'] as String,
    identity: json['identity'] as String,
    phase: json['phase'] as String,
    cycle: json['cycle'] as String,
    mentor: json['mentor'] as String,
    tasks: (json['tasks'] as List<dynamic>)
        .map((e) => TrainingTask.fromJson(e as Map<String, dynamic>))
        .toList(),
    feedback: TrainingFeedback.fromJson(
      json['feedback'] as Map<String, dynamic>,
    ),
  );
}
