import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

/// 개인정보 처리방침 페이지
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.settings);
            }
          },
        ),
        title: const Text('개인정보 처리방침'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('1. 개인정보의 처리 목적'),
            _SectionContent(
              'Co-Talk(이하 "회사")은 다음의 목적을 위하여 개인정보를 처리합니다:\n\n'
              '• 회원 가입 및 관리: 회원제 서비스 이용에 따른 본인확인, 개인식별, 불량회원의 부정이용 방지\n'
              '• 서비스 제공: 메시징 서비스, 친구 관리, 프로필 관리 등 서비스 제공\n'
              '• 고객 지원: 민원 처리, 고지사항 전달',
            ),
            SizedBox(height: 24),
            _SectionTitle('2. 수집하는 개인정보 항목'),
            _SectionContent(
              '회사는 서비스 제공을 위해 다음의 개인정보를 수집합니다:\n\n'
              '• 필수항목: 이메일 주소, 비밀번호, 닉네임\n'
              '• 선택항목: 프로필 사진, 상태 메시지, 배경 이미지\n'
              '• 자동수집항목: 기기정보, 접속 IP, 접속 일시',
            ),
            SizedBox(height: 24),
            _SectionTitle('3. 개인정보의 보유 및 이용기간'),
            _SectionContent(
              '회사는 회원 탈퇴 시 또는 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.\n\n'
              '다만, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 회사는 관계법령에서 정한 일정한 기간 동안 회원정보를 보관합니다:\n\n'
              '• 계약 또는 청약철회 등에 관한 기록: 5년\n'
              '• 소비자의 불만 또는 분쟁처리에 관한 기록: 3년\n'
              '• 접속에 관한 기록: 3개월',
            ),
            SizedBox(height: 24),
            _SectionTitle('4. 개인정보의 파기'),
            _SectionContent(
              '회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 '
              '지체 없이 해당 개인정보를 파기합니다.\n\n'
              '전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제하며, '
              '종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각하여 파기합니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('5. 개인정보의 제3자 제공'),
            _SectionContent(
              '회사는 원칙적으로 정보주체의 개인정보를 제3자에게 제공하지 않습니다.\n\n'
              '다만, 다음의 경우에는 예외로 합니다:\n'
              '• 정보주체가 사전에 동의한 경우\n'
              '• 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우',
            ),
            SizedBox(height: 24),
            _SectionTitle('6. 정보주체의 권리'),
            _SectionContent(
              '정보주체는 회사에 대해 언제든지 다음의 권리를 행사할 수 있습니다:\n\n'
              '• 개인정보 열람 요구\n'
              '• 오류 등이 있을 경우 정정 요구\n'
              '• 삭제 요구\n'
              '• 처리정지 요구\n\n'
              '위 권리 행사는 서비스 내 설정 메뉴 또는 고객센터를 통해 하실 수 있습니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('7. 개인정보 보호책임자'),
            _SectionContent(
              '회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n'
              '개인정보 보호책임자\n'
              '• 담당부서: 개인정보보호팀\n'
              '• 연락처: privacy@cotalk.com',
            ),
            SizedBox(height: 24),
            _SectionTitle('8. 개인정보 처리방침 변경'),
            _SectionContent(
              '이 개인정보 처리방침은 2024년 1월 1일부터 적용됩니다.\n\n'
              '이전의 개인정보 처리방침은 아래에서 확인하실 수 있습니다.',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String content;

  const _SectionContent(this.content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
      ),
    );
  }
}
