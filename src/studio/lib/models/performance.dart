library;

import 'package:flutter/foundation.dart';

/// 绩效记录数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 页面主体 = 行为成果记录（PerformanceRecord：时间、事项、结果），
/// 与前台 qtrecurit 的 BehaviorRecord 同构——同一份契约、同一种展示。
/// 参考指标（Metric）与评估结果（Assessment）辅助呈现。

/// 行为成果记录：这个人在绩效周期里做过什么，事实可回溯。
@immutable
class PerformanceRecord {
  final String id;
  final String type; // behavior | practice
  final String title;
  final String time;
  final String result;

  const PerformanceRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.time,
    required this.result,
  });

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) =>
      PerformanceRecord(
        id: json['id'] as String,
        type: (json['type'] as String?) ?? 'behavior',
        title: json['title'] as String,
        time: json['time'] as String,
        result: json['result'] as String,
      );
}

/// 参考指标条目：数字资产贡献统计（GitHub、Figma 等）。
@immutable
class MetricItem {
  final String source;
  final String value;

  const MetricItem({required this.source, required this.value});

  factory MetricItem.fromJson(Map<String, dynamic> json) => MetricItem(
    source: json['source'] as String,
    value: json['value'] as String,
  );
}

/// 参考指标：仅作参考，不作为唯一或主要依据。
@immutable
class Metric {
  final String label;
  final List<MetricItem> items;

  const Metric({required this.label, required this.items});

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
    label: json['label'] as String,
    items: (json['items'] as List<dynamic>)
        .map((e) => MetricItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// 评估结果：等级与署名评语。
@immutable
class Assessment {
  final String level;
  final String assessor;
  final String comment;

  const Assessment({
    required this.level,
    required this.assessor,
    required this.comment,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
    level: json['level'] as String,
    assessor: json['assessor'] as String,
    comment: json['comment'] as String,
  );
}

/// 绩效记录聚合：一个人在一段绩效周期里的行为成果、参考指标与评估结果。
@immutable
class Performance {
  final String id;
  final String employee;
  final String identity;
  final String cycle;
  final List<PerformanceRecord> records;
  final Metric? metric;
  final Assessment? assessment;

  const Performance({
    required this.id,
    required this.employee,
    required this.identity,
    required this.cycle,
    required this.records,
    this.metric,
    this.assessment,
  });

  factory Performance.fromJson(Map<String, dynamic> json) => Performance(
    id: json['id'] as String,
    employee: json['employee'] as String,
    identity: json['identity'] as String,
    cycle: json['cycle'] as String,
    records: (json['records'] as List<dynamic>)
        .map((e) => PerformanceRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    metric: json['metric'] == null
        ? null
        : Metric.fromJson(json['metric'] as Map<String, dynamic>),
    assessment: json['assessment'] == null
        ? null
        : Assessment.fromJson(json['assessment'] as Map<String, dynamic>),
  );
}
