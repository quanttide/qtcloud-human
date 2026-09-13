import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/browser_launcher.dart';
import '../platform/resume_preview_frame.dart';
import '../services/recruitment_api_client.dart';

const _apiBaseUrl = String.fromEnvironment('QTCLOUD_HUMAN_API_BASE_URL');
const _operator = String.fromEnvironment(
  'QTCLOUD_HUMAN_OPERATOR',
  defaultValue: 'studio-user',
);
const _compactWorkspaceBreakpoint = 900.0;
const _compactInboxHeight = 280.0;

/// 招聘筛选模块：投递邮件初筛，通过 provider API 调用 qtrecurit 能力。
enum DetectResult { only, has_ }

enum EmailStatus { pending, passed, rejected }

enum InboxFilter { all, unprocessed, hasBody, processed }

class Email {
  final int id;
  final String candidateId;
  final String from;
  final String name;
  final String subject;
  final String body;
  final bool hasCover;
  final bool hasBody;
  final bool hasResume;
  final List<RecruitmentResumeAttachment> resumeAttachments;
  final String extra;
  final String position;
  final String stage;
  final String lastAction;
  final DateTime? receivedAt;
  final List<String> tags;
  late final DetectResult detected;
  EmailStatus status;

  Email({
    required this.id,
    required this.candidateId,
    required this.from,
    required this.name,
    required this.subject,
    required this.body,
    required this.hasCover,
    required this.hasBody,
    required this.hasResume,
    required this.resumeAttachments,
    required this.extra,
    required this.position,
    required this.stage,
    required this.lastAction,
    required this.receivedAt,
    required this.tags,
    this.status = EmailStatus.pending,
  }) {
    detected = (hasCover || (hasBody && body.length > 20))
        ? DetectResult.has_
        : DetectResult.only;
    if (detected == DetectResult.only && status == EmailStatus.pending) {
      status = EmailStatus.rejected;
    }
  }

  factory Email.fromCandidate(RecruitmentCandidate candidate, int index) {
    return Email(
      id: index + 1,
      candidateId: candidate.id,
      from: candidate.email,
      name: _displayName(candidate),
      subject: candidate.subject.isEmpty ? '候选人投递' : candidate.subject,
      body: candidate.body,
      hasCover: candidate.hasCoverLetter,
      hasBody: candidate.body.trim().isNotEmpty,
      hasResume: candidate.hasResume || candidate.resumeAttachments.isNotEmpty,
      resumeAttachments: candidate.resumeAttachments,
      extra: candidate.lastAction.isEmpty ? '' : '最近动作：${candidate.lastAction}',
      position: candidate.position,
      stage: candidate.stage,
      lastAction: candidate.lastAction,
      receivedAt: candidate.receivedAt,
      tags: [
        candidate.stage,
        if (candidate.lastAction.isNotEmpty) candidate.lastAction,
      ],
      status: _emailStatusFromCandidate(candidate.status),
    );
  }
}

class _ResumePreview {
  const _ResumePreview({
    required this.key,
    required this.fileName,
    required this.contentType,
    required this.url,
    required this.bytes,
    required this.expiresAt,
  });

  final String key;
  final String fileName;
  final String contentType;
  final String url;
  final Uint8List bytes;
  final DateTime? expiresAt;
}

class RecruitmentPage extends StatefulWidget {
  const RecruitmentPage({super.key, this.apiClient, this.onDownloadResume});

  final RecruitmentApiClient? apiClient;
  final void Function(String url, String fileName)? onDownloadResume;

  @override
  State<RecruitmentPage> createState() => _RecruitmentPageState();
}

class _RecruitmentPageState extends State<RecruitmentPage> {
  late final RecruitmentApiClient? _apiClient;
  final TextEditingController _interviewPositionController =
      TextEditingController();
  final TextEditingController _interviewTimeController = TextEditingController(
    text: _defaultInterviewTime(),
  );

  Future<List<Email>>? _future;
  late List<Email> _emails;
  int? _selectedId;
  bool _emailsInitialized = false;
  InboxFilter _filter = InboxFilter.all;
  bool _dryRun = true;
  bool _reportLoading = false;
  bool _inboxSyncLoading = false;
  bool _providerStatusLoading = false;
  int? _markingEmailId;
  String? _reportMarkdown;
  String? _reportStatus;
  String? _lastActionMessage;
  String? _lastActionError;
  String? _openingAttachmentKey;
  _ResumePreview? _resumePreview;
  RecruitmentProviderStatus? _providerStatus;
  RecruitmentAction? _runningAction;
  bool _actionConfirmationOpen = false;

  @override
  void initState() {
    super.initState();
    _apiClient =
        widget.apiClient ??
        (_apiBaseUrl.isEmpty
            ? null
            : RecruitmentApiClient(baseUrl: _apiBaseUrl, operator: _operator));
    _future = _loadEmails();
  }

  @override
  void dispose() {
    _interviewPositionController.dispose();
    _interviewTimeController.dispose();
    super.dispose();
  }

  Future<List<Email>> _loadEmails() async {
    if (_apiClient == null) {
      throw const RecruitmentApiException(
        '未配置 provider API，无法拉取真实招聘邮件。请设置 QTCLOUD_HUMAN_API_BASE_URL。',
      );
    }
    final candidates = await _apiClient.listCandidates();
    final emails = _emailsFromCandidates(candidates);
    _selectedId = emails.isNotEmpty ? emails.first.id : null;
    _syncInterviewInputs(emails.isNotEmpty ? emails.first : null);
    return emails;
  }

  void _setEmailsFromCandidates(List<RecruitmentCandidate> candidates) {
    final emails = _emailsFromCandidates(candidates);
    _emails = emails;
    _emailsInitialized = true;
    _selectFirstVisibleEmail();
  }

  List<Email> _emailsFromCandidates(List<RecruitmentCandidate> candidates) {
    final sortedCandidates = candidates.asMap().entries.toList()
      ..sort((a, b) {
        final timeComparison = _compareCandidatesByLatestReceived(
          a.value,
          b.value,
        );
        if (timeComparison != 0) {
          return timeComparison;
        }
        return a.key.compareTo(b.key);
      });
    return sortedCandidates
        .asMap()
        .entries
        .map((entry) => Email.fromCandidate(entry.value.value, entry.key))
        .toList();
  }

  int _compareCandidatesByLatestReceived(
    RecruitmentCandidate a,
    RecruitmentCandidate b,
  ) {
    final aTime = a.receivedAt;
    final bTime = b.receivedAt;
    if (aTime == null && bTime == null) {
      return 0;
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    if (aTime.isAtSameMomentAs(bTime)) {
      return 0;
    }
    return bTime.compareTo(aTime);
  }

  /// 列表顺序沿用既有约定：按 received_at 倒序，等时间时保持 provider 顺序。
  /// 「待处理优先」不在这里做——那属于筛选默认值的产品决定。
  List<Email> get _visibleEmails {
    switch (_filter) {
      case InboxFilter.all:
        return _emails;
      case InboxFilter.unprocessed:
        return _emails.where((e) => e.status == EmailStatus.pending).toList();
      case InboxFilter.hasBody:
        return _emails.where((e) => e.detected == DetectResult.has_).toList();
      case InboxFilter.processed:
        return _emails.where((e) => e.status != EmailStatus.pending).toList();
    }
  }

  int get _total => _emails.length;
  int get _unprocessedCount =>
      _emails.where((e) => e.status == EmailStatus.pending).length;
  int get _hasCount =>
      _emails.where((e) => e.detected == DetectResult.has_).length;
  int get _processed =>
      _emails.where((e) => e.status != EmailStatus.pending).length;

  Email? get _selected => _emails.where((e) => e.id == _selectedId).firstOrNull;

  void _setFilter(InboxFilter filter) {
    setState(() {
      _filter = filter;
      _selectFirstVisibleEmail();
    });
  }

  void _selectFirstVisibleEmail() {
    final visibleEmails = _visibleEmails;
    final selectedIsVisible = visibleEmails.any((e) => e.id == _selectedId);
    if (!selectedIsVisible) {
      _selectedId = visibleEmails.isNotEmpty ? visibleEmails.first.id : null;
      _resumePreview = null;
    }
    _syncInterviewInputs(_selected);
  }

  Future<void> _mark(Email email, EmailStatus status) async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法保存人工审核结果。';
      });
      return;
    }
    setState(() {
      _markingEmailId = email.id;
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final updated = await _apiClient.updateCandidateStatus(
        candidateId: email.candidateId,
        status: status.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final target = _emails
            .where((x) => x.candidateId == email.candidateId)
            .firstOrNull;
        if (target != null) {
          target.status = _emailStatusFromCandidate(updated.status);
        }
        _lastActionMessage = '人工审核结果已保存：${_statusLabel(status)}';
        _selectFirstVisibleEmail();
      });
    } on RecruitmentApiException catch (error) {
      if (mounted) {
        setState(() => _lastActionError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _markingEmailId = null);
      }
    }
  }

  void _selectEmail(Email email) {
    setState(() {
      _selectedId = email.id;
      _resumePreview = null;
      _lastActionError = null;
      _lastActionMessage = null;
      _syncInterviewInputs(email);
    });
  }

  void _reconsider(Email email) {
    setState(() {
      email.status = EmailStatus.pending;
      _resumePreview = null;
      _lastActionError = null;
      _lastActionMessage = '已重新进入人工审核，请选择通过或拒绝。';
      _syncInterviewInputs(email);
    });
  }

  void _syncInterviewInputs(Email? email) {
    _interviewPositionController.text = email?.position ?? '';
    if (_interviewTimeController.text.trim().isEmpty) {
      _interviewTimeController.text = _defaultInterviewTime();
    }
  }

  Future<void> _createReport() async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法生成真实招聘报告。';
      });
      return;
    }
    setState(() {
      _reportLoading = true;
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final report = await _apiClient.createReport(days: 30, dryRun: _dryRun);
      setState(() {
        _reportMarkdown = report.markdown;
        _reportStatus = report.status;
        _lastActionMessage = report.status == 'dry_run'
            ? '报告 dry_run 已生成，未读取真实邮箱。'
            : '招聘统计报告已生成。';
      });
    } on RecruitmentApiException catch (error) {
      setState(() => _lastActionError = error.message);
    } finally {
      if (mounted) {
        setState(() => _reportLoading = false);
      }
    }
  }

  Future<void> _syncInbox() async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法拉取真实招聘邮件。';
      });
      return;
    }
    setState(() {
      _inboxSyncLoading = true;
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final result = await _apiClient.syncInbox(dryRun: _dryRun);
      if (result.status == 'dry_run') {
        setState(() {
          _lastActionMessage = '收件箱 dry_run 已完成，未读取真实邮箱。';
        });
      } else {
        final candidates = await _apiClient.listCandidates();
        setState(() {
          _setEmailsFromCandidates(candidates);
          _lastActionMessage =
              '收件箱同步完成：扫描 ${result.scanned} 封，新增 ${result.imported} 位候选人。';
        });
      }
    } on RecruitmentApiException catch (error) {
      setState(() => _lastActionError = error.message);
    } finally {
      if (mounted) {
        setState(() => _inboxSyncLoading = false);
      }
    }
  }

  Future<void> _checkProviderStatus() async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法检测 provider 环境。';
      });
      return;
    }
    setState(() {
      _providerStatusLoading = true;
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final status = await _apiClient.checkProviderStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _providerStatus = status;
        _lastActionMessage = status.ready
            ? 'provider 环境可用：${status.mailbox}'
            : 'provider 环境未就绪：${status.message}';
      });
    } on RecruitmentApiException catch (error) {
      if (mounted) {
        setState(() => _lastActionError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _providerStatusLoading = false);
      }
    }
  }

  Future<void> _runCandidateAction(
    Email email,
    RecruitmentAction action,
    Map<String, Object?> params,
  ) async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法执行招聘动作。';
      });
      return;
    }
    setState(() {
      _runningAction = action;
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final result = await _apiClient.runAction(
        candidateId: email.candidateId,
        action: action,
        dryRun: _dryRun,
        params: params,
      );
      setState(() {
        _lastActionMessage = '${_actionLabel(action)}：${result.message}';
      });
    } on RecruitmentApiException catch (error) {
      setState(() => _lastActionError = error.message);
    } finally {
      if (mounted) {
        setState(() => _runningAction = null);
      }
    }
  }

  Future<void> _confirmAndRunCandidateAction(
    Email email,
    RecruitmentAction action,
  ) async {
    if (_runningAction != null || _actionConfirmationOpen) {
      return;
    }
    final params = _paramsForAction(email, action);
    setState(() => _actionConfirmationOpen = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(_dryRun ? '确认${_actionLabel(action)}' : '确认真实发送'),
          content: _actionConfirmationContent(email, action),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_dryRun ? '确认预览' : '确认发送'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _runCandidateAction(email, action, params);
      }
    } finally {
      if (mounted) {
        setState(() => _actionConfirmationOpen = false);
      }
    }
  }

  Widget _actionConfirmationContent(Email email, RecruitmentAction action) {
    final details = <String>[
      '候选人：${email.name}',
      '收件人：${email.from}',
      if (email.position.trim().isNotEmpty) '岗位：${email.position.trim()}',
      if (action == RecruitmentAction.createInterviewNotice)
        '面试时间：${_interviewTimeController.text.trim()}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_dryRun ? '当前为演练模式，不会真实发送邮件。' : '当前将执行真实招聘动作，请确认以下信息。'),
        const SizedBox(height: 12),
        ...details.map(
          (detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(detail),
          ),
        ),
      ],
    );
  }

  Future<void> _previewResumeAttachment(
    Email email,
    int attachmentIndex,
    RecruitmentResumeAttachment attachment,
  ) async {
    await _loadResumeAttachment(
      email,
      attachmentIndex,
      attachment,
      openDownload: false,
    );
  }

  Future<void> _downloadResumeAttachment(
    Email email,
    int attachmentIndex,
    RecruitmentResumeAttachment attachment,
  ) async {
    final key = _attachmentKey(email, attachmentIndex);
    final preview = _resumePreview;
    if (preview?.key == key &&
        (preview?.expiresAt == null ||
            preview!.expiresAt!.isAfter(DateTime.now().toUtc()))) {
      _downloadResumeUrl(_downloadUrl(preview!.url), attachment.fileName);
      if (mounted) {
        setState(() {
          _lastActionMessage = '已开始下载：${attachment.fileName}';
          _lastActionError = null;
        });
      }
      return;
    }
    await _loadResumeAttachment(
      email,
      attachmentIndex,
      attachment,
      openDownload: true,
    );
  }

  Future<void> _loadResumeAttachment(
    Email email,
    int attachmentIndex,
    RecruitmentResumeAttachment attachment, {
    required bool openDownload,
  }) async {
    if (_apiClient == null) {
      setState(() {
        _lastActionError = '未配置 provider API，无法打开简历附件。';
      });
      return;
    }
    final key = _attachmentKey(email, attachmentIndex);
    setState(() {
      _openingAttachmentKey = key;
      if (!openDownload) {
        _resumePreview = null;
      }
      _lastActionError = null;
      _lastActionMessage = null;
    });
    try {
      final view = await _apiClient.createResumeView(
        candidateId: email.candidateId,
        attachmentIndex: attachmentIndex,
      );
      if (openDownload) {
        final downloadUrl = _downloadUrl(view.url);
        _downloadResumeUrl(downloadUrl, attachment.fileName);
        if (mounted) {
          setState(() {
            _lastActionMessage = '已开始下载：${attachment.fileName}';
          });
        }
        return;
      }
      final previewBytes = await _apiClient.fetchResumeBytes(view.url);
      if (!mounted) {
        return;
      }
      setState(() {
        _resumePreview = _ResumePreview(
          key: key,
          fileName: attachment.fileName,
          contentType: attachment.contentType,
          url: view.url,
          bytes: previewBytes,
          expiresAt: view.expiresAt,
        );
        _lastActionMessage = '已生成简历预览：${attachment.fileName}';
      });
    } on RecruitmentApiException catch (error) {
      if (mounted) {
        setState(() => _lastActionError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _openingAttachmentKey = null);
      }
    }
  }

  void _downloadResumeUrl(String url, String fileName) {
    (widget.onDownloadResume ?? downloadBrowserFile)(url, fileName);
  }

  String _downloadUrl(String url) {
    final uri = Uri.parse(url);
    return uri
        .replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            'download': '1',
          },
        )
        .toString();
  }

  Map<String, Object?> _paramsForAction(Email email, RecruitmentAction action) {
    switch (action) {
      case RecruitmentAction.sendSurvey:
        return const <String, Object?>{};
      case RecruitmentAction.sendTrainingInvite:
        return const <String, Object?>{};
      case RecruitmentAction.sendExam:
        return const <String, Object?>{};
      case RecruitmentAction.createInterviewNotice:
        return <String, Object?>{
          'position': _interviewPositionController.text.trim().isEmpty
              ? '待确认岗位'
              : _interviewPositionController.text.trim(),
          'time': _interviewTimeController.text.trim().isEmpty
              ? _defaultInterviewTime()
              : _interviewTimeController.text.trim(),
        };
    }
  }

  String _detectLabel(DetectResult d) => d == DetectResult.only ? '仅简历' : '有正文';

  String _statusLabel(EmailStatus s) => s == EmailStatus.pending
      ? '待处理'
      : s == EmailStatus.passed
      ? '已通过'
      : '已拒绝';

  /// 状态语义色：只有终态给颜色，待处理保持中性。
  Color _statusColor(EmailStatus s) => s == EmailStatus.passed
      ? const Color(0xFF166534)
      : s == EmailStatus.rejected
      ? const Color(0xFF991B1B)
      : const Color(0xFF5F5E5A);

  /// 审核是否已有结论。终态候选人不再接受「通过 / 拒绝」。
  bool _reviewDone(Email e) => e.status != EmailStatus.pending;

  /// 单一准入点：当前状态下允许执行的流程动作（发送类）。
  ///
  /// 界面上所有「能不能发」的判断都从这里取，不再各自比对 status。
  /// 后续把规则迁到 provider 时，只需把这个函数换成读取 allowed_actions。
  ///
  /// 目前规则：仅「已通过」可发。待处理尚未做决定，已拒绝属终态，
  /// 两者都不允许外发。
  List<RecruitmentAction> _allowedFlowActions(Email e) {
    if (e.status != EmailStatus.passed) {
      return const <RecruitmentAction>[];
    }
    return const <RecruitmentAction>[
      RecruitmentAction.sendSurvey,
      RecruitmentAction.sendTrainingInvite,
      RecruitmentAction.sendExam,
      RecruitmentAction.createInterviewNotice,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('招聘筛选网关'),
        centerTitle: false,
        actions: [_buildOpsActions()],
      ),
      body: FutureBuilder<List<Email>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${_safeError(snapshot.error)}'));
          }
          if (!_emailsInitialized) {
            _emails = snapshot.data!;
            _emailsInitialized = true;
          }
          return Column(
            children: [
              _buildStats(),
              if (_providerStatus != null)
                _buildProviderStatusBar(_providerStatus!),
              _buildFeedbackBar(),
              Expanded(child: _buildEmailWorkspace()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmailWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _compactWorkspaceBreakpoint) {
          return Column(
            key: const ValueKey('compact-email-workspace'),
            children: [
              SizedBox(height: _compactInboxHeight, child: _buildEmailList()),
              const Divider(height: 1),
              Expanded(child: _buildDetail()),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 360, child: _buildEmailList()),
            const VerticalDivider(width: 1),
            Expanded(child: _buildDetail()),
          ],
        );
      },
    );
  }

  Widget _buildOpsActions() {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        key: const ValueKey('ops-actions'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            const Text('运维', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          _opsActionButton(
            key: const ValueKey('ops-detect-action'),
            icon: Icons.health_and_safety_outlined,
            label: _providerStatusLoading
                ? (compact ? '检测中' : '检测中…')
                : (compact ? '检测' : '检测环境'),
            tooltip: '检测环境',
            onPressed: _providerStatusLoading ? null : _checkProviderStatus,
          ),
          _opsActionButton(
            key: const ValueKey('ops-sync-action'),
            icon: Icons.sync_outlined,
            label: _inboxSyncLoading
                ? (compact ? '拉取中' : '拉取中…')
                : (compact ? '拉取' : '拉取新邮件'),
            tooltip: '拉取新邮件',
            onPressed: _inboxSyncLoading ? null : _syncInbox,
          ),
          _opsActionButton(
            key: const ValueKey('ops-report-action'),
            icon: Icons.description_outlined,
            label: _reportLoading
                ? (compact ? '生成中' : '生成中…')
                : (compact ? '报告' : '生成报告'),
            tooltip: '生成报告',
            onPressed: _reportLoading || _inboxSyncLoading
                ? null
                : _createReport,
          ),
        ],
      ),
    );
  }

  Widget _opsActionButton({
    required Key key,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildFeedbackBar() {
    if (_lastActionMessage == null &&
        _lastActionError == null &&
        _reportMarkdown == null) {
      return const SizedBox.shrink();
    }
    final isError = _lastActionError != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        isError
            ? _lastActionError!
            : _lastActionMessage ?? '报告状态：$_reportStatus',
        style: TextStyle(
          color: isError ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProviderStatusBar(RecruitmentProviderStatus status) {
    final color = status.ready
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final bg = status.ready ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            status.ready ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: color,
          ),
          Text(
            status.ready ? 'provider 环境可用' : 'provider 环境未就绪',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (status.mailbox.isNotEmpty)
            Text(
              'HR 邮箱：${status.mailbox}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          if (status.operator.isNotEmpty)
            Text(
              '当前账号：${status.operator}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          if (status.message.isNotEmpty)
            Text(
              status.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ...status.components.map(_providerStatusChip),
        ],
      ),
    );
  }

  Widget _providerStatusChip(RecruitmentProviderStatusComponent component) {
    final ok = component.status == 'ok';
    final bg = ok ? const Color(0xFFEFF6FF) : const Color(0xFFFFF1F2);
    final fg = ok ? const Color(0xFF1E40AF) : const Color(0xFF991B1B);
    final label = [
      _providerComponentLabel(component.name),
      if (component.version.isNotEmpty) component.version,
      if (component.message.isNotEmpty) component.message,
    ].join(' · ');
    return _tag(label, bg, fg);
  }

  Widget _buildStats() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _statItem(
            '待处理',
            '$_unprocessedCount/$_total',
            filter: InboxFilter.unprocessed,
          ),
          _statItem('全部', _total.toString(), filter: InboxFilter.all),
          _statItem('有正文', '$_hasCount/$_total', filter: InboxFilter.hasBody),
          _statItem(
            '已处理',
            '$_processed/$_total',
            filter: InboxFilter.processed,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {required InboxFilter filter}) {
    final selected = _filter == filter;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('inbox-filter-${filter.name}'),
          onTap: () => _setFilter(filter),
          mouseCursor: SystemMouseCursors.click,
          child: Semantics(
            button: true,
            label: '$label $value',
            selected: selected,
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF222222)
                          : const Color(0xFF5F5E5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? const Color(0xFF5F5E5A)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                '${_visibleEmails.length} 封',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _visibleEmails.length,
            itemBuilder: (_, i) => _buildEmailTile(_visibleEmails[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTile(Email e) {
    final sel = e.id == _selectedId;
    final pending = e.status == EmailStatus.pending;
    final statusColor = _statusColor(e.status);
    return InkWell(
      onTap: () => _selectEmail(e),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFEFF6FF) : null,
          border: Border(
            // 终态才给色条；待处理保持中性，不预支结论。
            left: BorderSide(
              color: pending ? Colors.transparent : statusColor,
              width: 2,
            ),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.name,
              style: TextStyle(
                fontWeight: pending ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              e.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              _tileStatusLine(e),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 列表行的状态文案：状态领读，阶段与初筛判定降为附注，
  /// 不再各自占一枚彩色标签。
  String _tileStatusLine(Email e) {
    final parts = <String>[_statusLabel(e.status)];
    final stage = _stageLabel(e.stage);
    if (stage.isNotEmpty) {
      parts.add(stage);
    }
    parts.add(_detectLabel(e.detected));
    return parts.join(' · ');
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'survey_sent':
        return '问卷已发';
      case 'invite_sent':
        return '实训邀约已发';
      case 'exam_sent':
        return '笔试已发';
      case 'interview_draft':
        return '面试通知草稿';
      case 'new':
      case '':
        return '';
      default:
        return stage;
    }
  }

  Widget _tag(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
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
            Text(
              _emails.isEmpty ? '暂无候选人，请先拉取新邮件' : '选择一封邮件查看',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_reviewDone(e)) ...[
                const SizedBox(width: 12),
                _tag(
                  _statusLabel(e.status),
                  _statusBg(e.status),
                  _statusColor(e.status),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.position.isEmpty ? '<${e.from}>' : '<${e.from}> · ${e.position}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            e.subject,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          // 决定与动作紧贴标题：不再被正文和附件压在下面。
          _buildActionArea(e),
          const SizedBox(height: 20),
          _bodyCard(e),
          const SizedBox(height: 12),
          _attachmentsCard(e),
          if (_resumePreview != null) ...[
            const SizedBox(height: 12),
            _resumePreviewCard(_resumePreview!),
          ],
          if (_reportMarkdown != null) ...[
            const SizedBox(height: 20),
            _buildReportPreview(),
          ],
        ],
      ),
    );
  }

  Widget _bodyCard(Email e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '邮件正文',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.body.isEmpty ? '（无正文内容）' : e.body,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: e.body.isEmpty ? Colors.grey.shade400 : null,
              fontStyle: e.body.isEmpty ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentsCard(Email e) {
    final attachments = e.resumeAttachments;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('简历附件', style: TextStyle(fontWeight: FontWeight.w700)),
              if (e.extra.isNotEmpty) ...[
                const SizedBox(width: 8),
                _tag(e.extra, const Color(0xFFF1F5F9), const Color(0xFF334155)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (attachments.isEmpty)
            Text(
              e.hasResume ? '已检测到简历附件，但 provider 未返回文件名或预览地址。' : '未检测到简历附件。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          else
            ...attachments.asMap().entries.map(
              (entry) => _attachmentRow(e, entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _attachmentRow(
    Email email,
    int attachmentIndex,
    RecruitmentResumeAttachment attachment,
  ) {
    final key = _attachmentKey(email, attachmentIndex);
    final opening = _openingAttachmentKey == key;
    final previewReady = _resumePreview?.key == key;
    final isWord = _isWordAttachment(attachment);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _attachmentIcon(attachment),
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _attachmentMeta(
                    attachment,
                    opening: opening,
                    previewReady: previewReady,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            children: [
              if (!isWord)
                OutlinedButton.icon(
                  onPressed: opening
                      ? null
                      : () => _previewResumeAttachment(
                          email,
                          attachmentIndex,
                          attachment,
                        ),
                  icon: opening
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          previewReady
                              ? Icons.refresh
                              : Icons.visibility_outlined,
                          size: 16,
                        ),
                  label: Text(opening ? '处理中' : (previewReady ? '重新预览' : '预览')),
                ),
              OutlinedButton.icon(
                onPressed: opening
                    ? null
                    : () => _downloadResumeAttachment(
                        email,
                        attachmentIndex,
                        attachment,
                      ),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('下载'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isWordAttachment(RecruitmentResumeAttachment attachment) {
    final fileName = attachment.fileName.toLowerCase().trim();
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return true;
    }
    final contentType = attachment.contentType
        .toLowerCase()
        .split(';')
        .first
        .trim();
    return contentType == 'application/msword' ||
        contentType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }

  IconData _attachmentIcon(RecruitmentResumeAttachment attachment) {
    final name = attachment.fileName.toLowerCase();
    if (name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.article_outlined;
    }
    return Icons.description_outlined;
  }

  String _attachmentMeta(
    RecruitmentResumeAttachment attachment, {
    required bool opening,
    required bool previewReady,
  }) {
    final parts = <String>[
      if (attachment.contentType.isNotEmpty) attachment.contentType,
      if (attachment.sizeBytes != null) _formatBytes(attachment.sizeBytes!),
      if (opening)
        '正在处理附件'
      else if (previewReady)
        '已生成临时预览，可手动下载'
      else
        '点击预览或下载',
    ];
    return parts.join(' · ');
  }

  String _attachmentKey(Email email, int attachmentIndex) {
    return '${email.candidateId}:$attachmentIndex';
  }

  Widget _resumePreviewCard(_ResumePreview preview) {
    final isPdf = _isPdfResume(preview.fileName, preview.contentType);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.article_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              const Text('简历预览', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  preview.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              TextButton.icon(
                onPressed: () => _downloadResumeUrl(
                  _downloadUrl(preview.url),
                  preview.fileName,
                ),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('下载附件'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPdf
                ? 'PDF 已在下方内嵌预览，下载需要手动点击。'
                : '当前格式暂不支持内嵌预览，请点击“下载附件”后用本机 Office 查看。',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (preview.expiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '临时链接 5 分钟内有效。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 10),
          if (isPdf)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                key: const ValueKey('resume-preview-frame'),
                height: 640,
                child: ResumePreviewFrame(
                  bytes: preview.bytes,
                  contentType: preview.contentType,
                  title: preview.fileName,
                ),
              ),
            )
          else
            _resumeDownloadPlaceholder(preview),
        ],
      ),
    );
  }

  Widget _resumeDownloadPlaceholder(_ResumePreview preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.file_download_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前格式暂不支持内嵌预览，请点击“下载附件”手动下载 ${preview.fileName}。',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// 动作区：同一个位置上的三种形态。
  /// 待处理只做决定，已通过只走流程，已拒绝只留依据。
  Widget _buildActionArea(Email e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _actionAreaBg(e),
            border: Border.all(color: _actionAreaBorder(e)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '当前可做',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
              ),
              const SizedBox(height: 10),
              _actionAreaBody(e),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _dryRunBanner(),
      ],
    );
  }

  Color _actionAreaBg(Email e) => e.status == EmailStatus.rejected
      ? const Color(0xFFFCEBEB)
      : const Color(0xFFF1EFE8);

  Color _actionAreaBorder(Email e) => e.status == EmailStatus.rejected
      ? const Color(0xFFF09595)
      : const Color(0xFFD3D1C7);

  Color _statusBg(EmailStatus s) => s == EmailStatus.passed
      ? const Color(0xFFDCFCE7)
      : s == EmailStatus.rejected
      ? const Color(0xFFFEE2E2)
      : const Color(0xFFF1EFE8);

  Widget _actionAreaBody(Email e) {
    if (e.status == EmailStatus.rejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '终态邮件不再提供外发动作。',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          Text(
            '依据：${_screeningReason(e)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _reconsider(e),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('重新审核'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5F5E5A),
            ),
          ),
        ],
      );
    }
    if (e.status == EmailStatus.pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildManualButtons(e),
          const SizedBox(height: 8),
          Text(
            '做出结论后，才出现对应的流程动作。',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );
    }
    return _buildFlowActions(e);
  }

  String _screeningReason(Email e) =>
      e.detected == DetectResult.only ? '仅含简历附件，无正文或自荐内容' : '邮件包含正文或自荐信，进入人工流程';

  Widget _buildManualButtons(Email e) {
    final marking = _markingEmailId == e.id;
    return Row(
      children: [
        FilledButton.icon(
          onPressed: marking ? null : () => _mark(e, EmailStatus.passed),
          icon: marking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(marking ? '保存中' : '通过'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF166534),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: marking ? null : () => _mark(e, EmailStatus.rejected),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('拒绝'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF991B1B),
          ),
        ),
      ],
    );
  }

  /// 已通过候选人的流程动作。动作清单取自 _allowedFlowActions，
  /// 界面不再自己比对状态决定能不能发。
  Widget _buildFlowActions(Email e) {
    final actions = _allowedFlowActions(e);
    if (actions.isEmpty) {
      return Text(
        '当前状态没有可执行的流程动作。',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _interviewPositionController,
                decoration: const InputDecoration(
                  labelText: '面试岗位',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _interviewTimeController,
                decoration: const InputDecoration(
                  labelText: '面试时间',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map((a) => _actionButton(e, a, _actionIcon(a), _actionLabel(a)))
              .toList(),
        ),
      ],
    );
  }

  /// 演练模式就近贴在动作旁边，而不是藏在顶栏。
  Widget _dryRunBanner() {
    final on = _dryRun;
    final fg = on ? const Color(0xFF854F0B) : const Color(0xFF991B1B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFFAEEDA) : const Color(0xFFFEE2E2),
        border: Border.all(
          color: on ? const Color(0xFFEF9F27) : const Color(0xFFF09595),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            on ? Icons.visibility_outlined : Icons.warning_amber_outlined,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              on ? '演练模式 · 不会真实发送' : '真实发送已开启',
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ),
          TextButton(
            key: const ValueKey('dry-run-toggle'),
            onPressed: () => setState(() => _dryRun = !on),
            style: TextButton.styleFrom(
              foregroundColor: fg,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(on ? '关闭演练' : '开启演练'),
          ),
        ],
      ),
    );
  }

  IconData _actionIcon(RecruitmentAction action) {
    switch (action) {
      case RecruitmentAction.sendSurvey:
        return Icons.assignment_outlined;
      case RecruitmentAction.sendTrainingInvite:
        return Icons.group_add_outlined;
      case RecruitmentAction.sendExam:
        return Icons.quiz_outlined;
      case RecruitmentAction.createInterviewNotice:
        return Icons.event_available_outlined;
    }
  }

  Widget _actionButton(
    Email e,
    RecruitmentAction action,
    IconData icon,
    String label,
  ) {
    final running = _runningAction == action;
    return FilledButton.icon(
      onPressed: _runningAction != null || _actionConfirmationOpen
          ? null
          : () => _confirmAndRunCandidateAction(e, action),
      icon: running
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(running ? '执行中' : label),
    );
  }

  Widget _buildReportPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '报告预览（$_reportStatus）',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _reportMarkdown!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(RecruitmentAction action) {
    switch (action) {
      case RecruitmentAction.sendSurvey:
        return '发送问卷';
      case RecruitmentAction.sendTrainingInvite:
        return '发送实训邀约';
      case RecruitmentAction.sendExam:
        return '发送笔试';
      case RecruitmentAction.createInterviewNotice:
        return '生成面试通知';
    }
  }

  String _safeError(Object? error) {
    if (error is RecruitmentApiException) {
      return error.message;
    }
    return '招聘服务暂不可用，请稍后重试';
  }
}

String _displayName(RecruitmentCandidate candidate) {
  final name = candidate.name.trim();
  if (name.isNotEmpty && !_hasGarbledText(name)) {
    return name;
  }
  final fromSubject = _nameFromSubject(candidate.subject);
  if (fromSubject != null) {
    return fromSubject;
  }
  return candidate.email;
}

bool _hasGarbledText(String value) {
  return value.contains('\u{FFFD}') || value.contains('�');
}

EmailStatus _emailStatusFromCandidate(String status) {
  switch (status.trim().toLowerCase()) {
    case 'passed':
      return EmailStatus.passed;
    case 'rejected':
      return EmailStatus.rejected;
    default:
      return EmailStatus.pending;
  }
}

String? _nameFromSubject(String subject) {
  final parts = RegExp(r'\[([^\]]+)\]')
      .allMatches(subject)
      .map((match) => match.group(1)?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return parts[1];
  }
  return null;
}

bool _isPdfResume(String fileName, String contentType) {
  final lowerName = fileName.trim().toLowerCase();
  final lowerType = contentType.trim().toLowerCase();
  return lowerName.endsWith('.pdf') || lowerType == 'application/pdf';
}

String _providerComponentLabel(String name) {
  switch (name) {
    case 'qtrecurit':
      return 'qtrecurit CLI';
    case 'hr_mailbox':
      return 'HR 邮箱认证';
    default:
      return name.isEmpty ? 'provider 检测项' : name;
  }
}

String _defaultInterviewTime() {
  final date = DateTime.now().add(const Duration(days: 3));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day 10:00';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
