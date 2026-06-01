import 'package:flutter/material.dart';

void main() => runApp(const RecruitmentApp());

class RecruitmentApp extends StatelessWidget {
  const RecruitmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '招聘筛选网关',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const RecruitmentPage(),
    );
  }
}

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
}

final List<Email> sampleEmails = [
  Email(id:1, from:'zhangming@gmail.com', name:'张明', subject:'应聘前端开发——简历', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:2, from:'lihua@163.com', name:'李华', subject:'简历-后端开发-3年', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:3, from:'wangfang@qq.com', name:'王芳', subject:'关于产品经理岗位的申请', body:'HR 你好，\n\n看到贵公司在招聘产品经理，我有 5 年电商产品经验，曾负责过 3 个从 0 到 1 的项目。简历在附件中，希望能获得面试机会。\n\n谢谢', hasCover:true, hasBody:true, hasResume:true, extra:'附简短自荐', tags:['有正文']),
  Email(id:4, from:'zhaolei@sina.com', name:'赵雷', subject:'求职', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:5, from:'chenjing@outlook.com', name:'陈静', subject:'数据分析师应聘', body:'附件是我的简历，请查阅。', hasCover:false, hasBody:true, hasResume:true, extra:'一句话正文', tags:['有正文']),
  Email(id:6, from:'liuyang@gmail.com', name:'刘洋', subject:'无标题', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件','无标题']),
  Email(id:7, from:'sunli@foxmail.com', name:'孙丽', subject:'UI 设计师简历', body:'您好，\n\n关注贵公司很久了，对 UI 设计师的职位非常感兴趣。我之前在两家互联网公司做过设计，擅长 B 端产品。简历和作品集在附件中。\n\n期待回复', hasCover:true, hasBody:true, hasResume:true, extra:'附作品集', tags:['有正文','附作品集']),
  Email(id:8, from:'zhoutao@126.com', name:'周涛', subject:'产品经理求职——行业研究背景', body:'HR 团队好，\n\n我过去 3 年在咨询公司做行业研究，转型产品经理是我的职业规划。附件是简历，正文简单说一下想法。\n\n周涛', hasCover:true, hasBody:true, hasResume:true, extra:'转型动机清晰', tags:['有正文']),
  Email(id:9, from:'wujie@qq.com', name:'吴杰', subject:'简历-前端', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:10, from:'zhengxin@gmail.com', name:'郑鑫', subject:'Java 开发求职', body:'HR 你好，附件是简历。', hasCover:false, hasBody:true, hasResume:true, extra:'简短正文', tags:['有正文']),
  Email(id:11, from:'huanglei@163.com', name:'黄磊', subject:'关于市场推广岗位', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:12, from:'xuting@outlook.com', name:'徐婷', subject:'运营岗位求职信', body:'HR 你好，\n\n我是一名有 4 年用户运营经验的从业者，擅长社群运营和用户增长。看了岗位描述觉得非常匹配，附件中是简历和过往案例。\n\n期待进一步沟通', hasCover:true, hasBody:true, hasResume:true, extra:'附案例', tags:['有正文','附案例']),
  Email(id:13, from:'fanqiang@qq.com', name:'樊强', subject:'简历', body:'', hasCover:false, hasBody:false, hasResume:true, extra:'', tags:['仅附件']),
  Email(id:14, from:'linmei@gmail.com', name:'林梅', subject:'应聘', body:'附件', hasCover:false, hasBody:false, hasResume:true, extra:'正文仅"附件"二字', tags:['仅附件','无意义正文']),
  Email(id:15, from:'caojun@163.com', name:'曹军', subject:'简历-产品经理-5年', body:'招聘经理，\n\n附件是我的简历。简单说一下自己的情况：过去 5 年一直在做 SaaS 产品，主导过 2 款产品的从 0 到 1。对贵公司的方向很认同，希望能聊聊。\n\n曹军', hasCover:true, hasBody:true, hasResume:true, extra:'详细自荐', tags:['有正文','详细自荐']),
];

class RecruitmentPage extends StatefulWidget {
  const RecruitmentPage({super.key});
  @override
  State<RecruitmentPage> createState() => _RecruitmentPageState();
}

class _RecruitmentPageState extends State<RecruitmentPage> {
  late List<Email> _emails;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _emails = sampleEmails.map((e) => Email(
      id: e.id, from: e.from, name: e.name, subject: e.subject,
      body: e.body, hasCover: e.hasCover, hasBody: e.hasBody,
      hasResume: e.hasResume, extra: e.extra, tags: List.from(e.tags),
      status: e.status,
    )).toList();
    _selectedId = _emails.isNotEmpty ? _emails[0].id : null;
  }

  int get _total => _emails.length;
  int get _onlyCount => _emails.where((e) => e.detected == DetectResult.only).length;
  int get _hasCount => _emails.where((e) => e.detected == DetectResult.has_).length;
  int get _processed => _emails.where((e) => e.status != EmailStatus.pending).length;

  Email? get _selected => _emails.where((e) => e.id == _selectedId).firstOrNull;

  void _mark(int id, EmailStatus status) {
    setState(() {
      final e = _emails.where((x) => x.id == id).firstOrNull;
      if (e != null) e.status = status;
    });
  }

  Color _detectColor(DetectResult d) =>
    d == DetectResult.only ? const Color(0xFF991B1B) : const Color(0xFF166534);

  Color _detectBg(DetectResult d) =>
    d == DetectResult.only ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

  String _detectLabel(DetectResult d) =>
    d == DetectResult.only ? '仅简历' : '有正文';

  String _statusLabel(EmailStatus s) =>
    s == EmailStatus.pending ? '待处理' : s == EmailStatus.passed ? '已通过' : '已拒绝';

  IconData _detectIcon(DetectResult d) =>
    d == DetectResult.only ? Icons.description_outlined : Icons.email_outlined;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('招聘筛选网关'),
        centerTitle: false,
        actions: [Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text('只发简历的挡住', style: TextStyle(fontSize: 13, color: Colors.white70)),
        )],
      ),
      body: Column(
        children: [
          _buildStats(),
          Expanded(child: Row(
            children: [
              SizedBox(width: 360, child: _buildEmailList()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildDetail()),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          _statItem('总邮件', _total.toString()),
          _statItem('仅简历', _onlyCount.toString(), color: const Color(0xFF991B1B)),
          _statItem('有正文', _hasCount.toString(), color: const Color(0xFF166534)),
          _statItem('自动处理', '$_processed/$_total'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color ?? Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    ));
  }

  Widget _buildEmailList() {
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('收件箱', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${_emails.length} 封', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
        ),
        Expanded(child: ListView.builder(
          itemCount: _emails.length,
          itemBuilder: (_, i) => _buildEmailTile(_emails[i]),
        )),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Icon(_detectIcon(e.detected), size: 18, color: Colors.grey.shade400),
          ]),
          const SizedBox(height: 2),
          Text(e.subject, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _detectBg(e.detected), borderRadius: BorderRadius.circular(4)),
              child: Text(_detectLabel(e.detected), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: dc)),
            ),
            const SizedBox(width: 6),
            ...e.tags.map((t) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(4)),
                child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
              ),
            )),
            const SizedBox(width: 6),
            Text(_statusLabel(e.status), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildDetail() {
    final e = _selected;
    if (e == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.email_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('选择一封邮件查看', style: TextStyle(color: Colors.grey.shade400)),
      ]));
    }

    final dc = _detectColor(e.detected);
    final dbg = _detectBg(e.detected);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: dbg, borderRadius: BorderRadius.circular(6)),
            child: Text(_detectLabel(e.detected), style: TextStyle(fontWeight: FontWeight.w600, color: dc)),
          ),
          const Spacer(),
          Text(e.status == EmailStatus.passed ? '✅ 已通过' : e.status == EmailStatus.rejected ? '🗑 已拒绝' : '',
              style: TextStyle(fontSize: 13, color: e.status == EmailStatus.passed ? const Color(0xFF166534) : const Color(0xFF991B1B))),
        ]),
        const SizedBox(height: 12),
        Text(e.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('<${e.from}>', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(e.subject, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(e.body.isEmpty ? '（无正文内容）' : e.body,
            style: TextStyle(fontSize: 14, height: 1.7, color: e.body.isEmpty ? Colors.grey.shade400 : null, fontStyle: e.body.isEmpty ? FontStyle.italic : null)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.attach_file, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          Text('简历.pdf${e.extra.isNotEmpty ? ' + ${e.extra}' : ''}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dbg, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dc.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.detected == DetectResult.only ? '🗑 自动拒绝' : '✅ 自动通过',
              style: TextStyle(fontWeight: FontWeight.w700, color: dc)),
            const SizedBox(height: 4),
            Text(e.detected == DetectResult.only ? '仅含简历附件，无正文/自荐内容。不符合筛选条件。' : '邮件包含正文或自荐信，进入人工流程。',
              style: TextStyle(fontSize: 13, color: dc)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(
            onPressed: e.status == EmailStatus.passed || e.status == EmailStatus.rejected ? null : () => _mark(e.id, EmailStatus.passed),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('通过'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF166534)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: e.status == EmailStatus.rejected || e.status == EmailStatus.passed ? null : () => _mark(e.id, EmailStatus.rejected),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('拒绝'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF991B1B)),
          ),
        ]),
      ]),
    );
  }
}
