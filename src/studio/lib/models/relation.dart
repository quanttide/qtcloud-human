library;

import 'package:flutter/foundation.dart';

/// 员工关系数据模型（v0.1 本地 assets mock 演示，契约先行）。
///
/// 页面主体 = 生命周期事件（RelationRecord：类型、标题、时间、状态），
/// 覆盖入职、试用期、调动、晋升、降职、离职；当前状态辅助呈现。

/// 生命周期事件类型。
enum RelationType {
  onboard,
  probation,
  transfer,
  promotion,
  demotion,
  resignation;

  String get label => switch (this) {
    RelationType.onboard => '入职',
    RelationType.probation => '试用期',
    RelationType.transfer => '调动',
    RelationType.promotion => '晋升',
    RelationType.demotion => '降职',
    RelationType.resignation => '离职',
  };
}

/// 生命周期事件：员工关系中的一次状态变化。
@immutable
class RelationRecord {
  final String id;
  final RelationType type;
  final String title;
  final String date;
  final String status; // done | doing | todo
  final String? note;

  const RelationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.status,
    this.note,
  });

  factory RelationRecord.fromJson(Map<String, dynamic> json) => RelationRecord(
    id: json['id'] as String,
    type: RelationType.values.byName(json['type'] as String),
    title: json['title'] as String,
    date: json['date'] as String,
    status: json['status'] as String,
    note: json['note'] as String?,
  );
}

/// 员工关系聚合：当前状态、关键日期与生命周期事件链。
@immutable
class EmployeeRelation {
  final String id;
  final String employee;
  final String identity;
  final String status; // probation | active | departed
  final String statusLabel;
  final String hireDate;
  final String? probationEnd;
  final List<RelationRecord> records;
  final String statusNote;
  final String? next;

  const EmployeeRelation({
    required this.id,
    required this.employee,
    required this.identity,
    required this.status,
    required this.statusLabel,
    required this.hireDate,
    this.probationEnd,
    required this.records,
    required this.statusNote,
    this.next,
  });

  factory EmployeeRelation.fromJson(Map<String, dynamic> json) =>
      EmployeeRelation(
        id: json['id'] as String,
        employee: json['employee'] as String,
        identity: json['identity'] as String,
        status: json['status'] as String,
        statusLabel: json['statusLabel'] as String,
        hireDate: json['hireDate'] as String,
        probationEnd: json['probationEnd'] as String?,
        records: (json['records'] as List<dynamic>)
            .map((e) => RelationRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusNote: json['statusNote'] as String,
        next: json['next'] as String?,
      );
}
