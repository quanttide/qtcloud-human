// 开发预览入口：用假数据直接渲染招聘筛选网关，跳过认证与 provider。
//
// 用途：改完界面后在本机看真实渲染效果，不用连生产环境。
// 运行：flutter run -d web-server --web-port=8080 -t lib/dev_preview.dart
//
// 这不是产品代码，不影响正式入口 lib/main.dart。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'screens/recruitment_screen.dart';
import 'services/recruitment_api_client.dart';

const _previewCandidates = <Map<String, Object?>>[
  {
    'id': 'cand_zhang',
    'name': '张洁茹',
    'email': 'zhangjieru@example.com',
    'subject': '[产品经理] - [张洁茹] - [某大学] - [3个月]',
    'body': 'HR 您好，我想投递产品经理岗位，附件是我的简历，期待您的回复。',
    'position': '产品经理',
    'stage': 'new',
    'status': 'pending',
    'has_resume': true,
    'has_cover_letter': true,
    'resume_attachments': [
      {
        'file_name': '张洁茹 产品经理 18355571546.pdf',
        'content_type': 'application/pdf',
        'url': 'https://files.example.test/resumes/zhang.pdf',
      },
    ],
    'received_at': '2026-09-09T10:00:00Z',
    'updated_at': '2026-09-09T10:00:00Z',
  },
  {
    'id': 'cand_sun',
    'name': '孙洪超',
    'email': 'sunhongchao@example.com',
    'subject': '[数据工程师] - [孙洪超] - [烟台南山学院] - [6个月]',
    'body': 'HR 您好，我投递数据工程师岗位，附件是简历。',
    'position': '数据工程师',
    'stage': 'survey_sent',
    'status': 'passed',
    'has_resume': true,
    'has_cover_letter': true,
    'last_action': 'send_survey',
    'resume_attachments': [
      {
        'file_name': '数据工程师-孙洪超-烟台南山学院-6个月.docx',
        'content_type':
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'url': 'https://files.example.test/resumes/sun.docx',
      },
    ],
    'received_at': '2026-09-08T10:00:00Z',
    'updated_at': '2026-09-08T10:00:00Z',
  },
  {
    'id': 'cand_ling',
    'name': '玲玲',
    'email': 'lingling@example.com',
    'subject': '[产品经理] - [玲玲] - [中国科学技术大学] - [3个月]',
    'body': '',
    'position': '产品经理',
    'stage': 'new',
    'status': 'rejected',
    'has_resume': true,
    'has_cover_letter': false,
    'resume_attachments': [
      {
        'file_name': '玲玲-中国科学技术大学-产品经理.pdf',
        'content_type': 'application/pdf',
        'url': 'https://files.example.test/resumes/ling.pdf',
      },
    ],
    'received_at': '2026-09-07T10:00:00Z',
    'updated_at': '2026-09-07T10:00:00Z',
  },
];

void main() {
  final client = RecruitmentApiClient(
    baseUrl: 'https://preview.example.test',
    operator: 'preview',
    httpClient: MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(jsonEncode(_previewCandidates)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  runApp(
    MaterialApp(
      title: '招聘筛选网关 · 预览',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: RecruitmentPage(apiClient: client),
    ),
  );
}
