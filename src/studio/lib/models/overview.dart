library;

import 'package:flutter/foundation.dart';

/// 总览仪表盘数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 聚合各模块关键指标与最新动态，与模块 mock 同源。

/// 关键指标：模块、标签、数值与补充说明。
@immutable
class Stat {
  final String id;
  final String module;
  final String label;
  final String value;
  final String detail;

  const Stat({
    required this.id,
    required this.module,
    required this.label,
    required this.value,
    required this.detail,
  });

  factory Stat.fromJson(Map<String, dynamic> json) => Stat(
    id: json['id'] as String,
    module: json['module'] as String,
    label: json['label'] as String,
    value: json['value'] as String,
    detail: json['detail'] as String,
  );
}

/// 最近动态：模块、标题与时间。
@immutable
class Activity {
  final String id;
  final String module;
  final String title;
  final String time;

  const Activity({
    required this.id,
    required this.module,
    required this.title,
    required this.time,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    module: json['module'] as String,
    title: json['title'] as String,
    time: json['time'] as String,
  );
}

/// 总览聚合：数据时点、指标列表与动态列表。
@immutable
class Overview {
  final String id;
  final String asOf;
  final List<Stat> stats;
  final List<Activity> activities;

  const Overview({
    required this.id,
    required this.asOf,
    required this.stats,
    required this.activities,
  });

  factory Overview.fromJson(Map<String, dynamic> json) => Overview(
    id: json['id'] as String,
    asOf: json['asOf'] as String,
    stats: (json['stats'] as List<dynamic>)
        .map((e) => Stat.fromJson(e as Map<String, dynamic>))
        .toList(),
    activities: (json['activities'] as List<dynamic>)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
