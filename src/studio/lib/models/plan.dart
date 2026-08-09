library;

import 'package:flutter/foundation.dart';

/// 计划数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 计划涵盖各模块：招聘计划、培训计划、绩效计划、薪酬计划等，
/// 计划定义周期与目标，执行记录落在各模块，进度回填到计划。

/// 计划状态：草稿 / 进行中 / 已完成。
enum PlanStatus { draft, doing, done }

/// 计划：类型、标题、周期、状态与进度。
@immutable
class Plan {
  final String id;
  final String type;
  final String title;
  final String cycle;
  final PlanStatus status;
  final String progress;

  const Plan({
    required this.id,
    required this.type,
    required this.title,
    required this.cycle,
    required this.status,
    required this.progress,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    cycle: json['cycle'] as String,
    status: PlanStatus.values.byName(json['status'] as String),
    progress: json['progress'] as String,
  );

  String get statusLabel => switch (status) {
    PlanStatus.draft => '草稿',
    PlanStatus.doing => '进行中',
    PlanStatus.done => '已完成',
  };
}
