library;

import 'package:flutter/foundation.dart';

/// 薪酬数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 计费规则：有效工时 × 职级时薪 = 弹性薪资。
/// 页面主体 = 有效工时记录（WorkRecord：日期、任务、小时数），
/// 时薪水平由职级决定（RateTier），结算结果（Settlement）为推导值。

/// 有效工时记录：实际投入工作的时间，结算依据。
@immutable
class WorkRecord {
  final String id;
  final String date;
  final String task;
  final double hours;

  const WorkRecord({
    required this.id,
    required this.date,
    required this.task,
    required this.hours,
  });

  factory WorkRecord.fromJson(Map<String, dynamic> json) => WorkRecord(
    id: json['id'] as String,
    date: json['date'] as String,
    task: json['task'] as String,
    hours: (json['hours'] as num).toDouble(),
  );
}

/// 职级-时薪对照：职级等级决定时薪水平。
@immutable
class RateTier {
  final int level;
  final String name;
  final double rate;

  const RateTier({required this.level, required this.name, required this.rate});

  factory RateTier.fromJson(Map<String, dynamic> json) => RateTier(
    level: json['level'] as int,
    name: json['name'] as String,
    rate: (json['rate'] as num).toDouble(),
  );
}

/// 结算结果：总有效工时 × 时薪 = 应发，加调整项得实发。
@immutable
class Settlement {
  final double totalHours;
  final double gross;
  final double adjustment;
  final double net;

  const Settlement({
    required this.totalHours,
    required this.gross,
    required this.adjustment,
    required this.net,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
    totalHours: (json['totalHours'] as num).toDouble(),
    gross: (json['gross'] as num).toDouble(),
    adjustment: (json['adjustment'] as num).toDouble(),
    net: (json['net'] as num).toDouble(),
  );
}

/// 薪酬结算聚合：一个人在一段薪酬周期内的有效工时、时薪水平与结算结果。
@immutable
class Compensation {
  final String id;
  final String employee;
  final String identity;
  final int rankLevel;
  final String rankName;
  final String cycle;
  final double hourlyRate;
  final List<WorkRecord> workRecords;
  final List<RateTier> rates;
  final Settlement settlement;

  const Compensation({
    required this.id,
    required this.employee,
    required this.identity,
    required this.rankLevel,
    required this.rankName,
    required this.cycle,
    required this.hourlyRate,
    required this.workRecords,
    required this.rates,
    required this.settlement,
  });

  factory Compensation.fromJson(Map<String, dynamic> json) => Compensation(
    id: json['id'] as String,
    employee: json['employee'] as String,
    identity: json['identity'] as String,
    rankLevel: json['rankLevel'] as int,
    rankName: json['rankName'] as String,
    cycle: json['cycle'] as String,
    hourlyRate: (json['hourlyRate'] as num).toDouble(),
    workRecords: (json['workRecords'] as List<dynamic>)
        .map((e) => WorkRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    rates: (json['rates'] as List<dynamic>)
        .map((e) => RateTier.fromJson(e as Map<String, dynamic>))
        .toList(),
    settlement: Settlement.fromJson(json['settlement'] as Map<String, dynamic>),
  );

  /// 金额格式化：¥870.0 → ¥870
  String get grossText => _fmt(settlement.gross);

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
