import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 招聘筛选模块：投递邮件初筛（mock 数据见 assets/mock/emails.json）。
///
/// 降级为工作台次要模块，经由侧边导航栏进入。

enum DetectResult { only, has_ }

enum EmailStatus { pending, passed, rejected }

class Email {
  final int id;
  final String from;
  final String name;
  final String subject;
  final String body;
  final bool hasCover;
  final bool hasBody;
  final bool hasResume;
  final String extra;
  final List<String> tags;
  late final DetectResult detected;
  EmailStatus status;

  Email({
    required this.id,
    required this.from,
    required this.name,
    required this.subject,
    required this.body,
    required this.hasCover,
    required this.hasBody,
    required this.hasResume,
    required this.extra,
    required this.tags,
    this.status = EmailStatus.pending,
  }) {
    detected = (hasCover || (hasBody && body.length > 20))
        ? DetectResult.has_
        : DetectResult.only;
    if (detected == DetectResult.only) status = EmailStatus.rejected;
  }

  factory Email.fromJson(Map<String, dynamic> json) => Email(
    id: json['id'] as int,
    from: json['from'] as String,
    name: json['name'] as String,
    subject: json['subject'] as String,
    body: (json['body'] as String?) ?? '',
    hasCover: (json['hasCover'] as bool?) ?? false,
    hasBody: (json['hasBody'] as bool?) ?? false,
    hasResume: (json['hasResume'] as bool?) ?? false,
    extra: (json['extra'] as String?) ?? '',
    tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
  );
}

class RecruitmentPage extends StatefulWidget {
  const RecruitmentPage({super.key});
  @override
  State<RecruitmentPage> createState() => _RecruitmentPageState();
}

class _RecruitmentPageState extends State<RecruitmentPage> {
  Future<List<Email>>? _future;
  late List<Email> _emails;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _future = _loadEmails();
  }

  Future<List<Email>> _loadEmails() async {
    final raw = await rootBundle.loadString('assets/mock/emails.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final emails = list
        .cast<Map<String, dynamic>>()
        .map(Email.fromJson)
        .toList();
    _selectedId = emails.isNotEmpty ? emails.first.id : null;
    return emails;
  }

  int get _total => _emails.length;
  int get _onlyCount =>
      _emails.where((e) => e.detected == DetectResult.only).length;
  int get _hasCount =>
      _emails.where((e) => e.detected == DetectResult.has_).length;
  int get _processed =>
      _emails.where((e) => e.status != EmailStatus.pending).length;

  Email? get _selected => _emails.where((e) => e.id == _selectedId).firstOrNull;

  void _mark(int id, EmailStatus status) {
    setState(() {
      final e = _emails.where((x) => x.id == id).firstOrNull;
      if (e != null) e.status = status;
    });
  }

  Color _detectColor(DetectResult d) => d == DetectResult.only
      ? const Color(0xFF991B1B)
      : const Color(0xFF166534);

  Color _detectBg(DetectResult d) => d == DetectResult.only
      ? const Color(0xFFFEE2E2)
      : const Color(0xFFDCFCE7);

  String _detectLabel(DetectResult d) => d == DetectResult.only ? '仅简历' : '有正文';

  String _statusLabel(EmailStatus s) => s == EmailStatus.pending
      ? '待处理'
      : s == EmailStatus.passed
      ? '已通过'
      : '已拒绝';

  IconData _detectIcon(DetectResult d) => d == DetectResult.only
      ? Icons.description_outlined
      : Icons.email_outlined;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('招聘筛选网关'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '只发简历的挡住',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Email>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          _emails = snapshot.data!;
          return Column(
            children: [
              _buildStats(),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: 360, child: _buildEmailList()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildDetail()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _statItem('总邮件', _total.toString()),
          _statItem(
            '仅简历',
            _onlyCount.toString(),
            color: const Color(0xFF991B1B),
          ),
          _statItem(
            '有正文',
            _hasCount.toString(),
            color: const Color(0xFF166534),
          ),
          _statItem('自动处理', '$_processed/$_total'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '收件箱',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '${_emails.length} 封',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _emails.length,
            itemBuilder: (_, i) => _buildEmailTile(_emails[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTile(Email e) {
    final sel = e.id == _selectedId;
    final dc = _detectColor(e.detected);
    return InkWell(
      onTap: () => setState(() => _selectedId = e.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFEFF6FF) : null,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _detectIcon(e.detected),
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              e.subject,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _detectBg(e.detected),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _detectLabel(e.detected),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: dc,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ...e.tags.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(e.status),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final e = _selected;
    if (e == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.email_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('选择一封邮件查看', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    final dc = _detectColor(e.detected);
    final dbg = _detectBg(e.detected);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dbg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _detectLabel(e.detected),
                  style: TextStyle(fontWeight: FontWeight.w600, color: dc),
                ),
              ),
              const Spacer(),
              Text(
                e.status == EmailStatus.passed
                    ? '✅ 已通过'
                    : e.status == EmailStatus.rejected
                    ? '🗑 已拒绝'
                    : '',
                style: TextStyle(
                  fontSize: 13,
                  color: e.status == EmailStatus.passed
                      ? const Color(0xFF166534)
                      : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            e.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '<${e.from}>',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            e.subject,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              e.body.isEmpty ? '（无正文内容）' : e.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: e.body.isEmpty ? Colors.grey.shade400 : null,
                fontStyle: e.body.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_file, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '简历.pdf${e.extra.isNotEmpty ? ' + ${e.extra}' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dbg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dc.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.detected == DetectResult.only ? '🗑 自动拒绝' : '✅ 自动通过',
                  style: TextStyle(fontWeight: FontWeight.w700, color: dc),
                ),
                const SizedBox(height: 4),
                Text(
                  e.detected == DetectResult.only
                      ? '仅含简历附件，无正文/自荐内容。不符合筛选条件。'
                      : '邮件包含正文或自荐信，进入人工流程。',
                  style: TextStyle(fontSize: 13, color: dc),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed:
                    e.status == EmailStatus.passed ||
                        e.status == EmailStatus.rejected
                    ? null
                    : () => _mark(e.id, EmailStatus.passed),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('通过'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    e.status == EmailStatus.rejected ||
                        e.status == EmailStatus.passed
                    ? null
                    : () => _mark(e.id, EmailStatus.rejected),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('拒绝'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
