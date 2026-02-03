import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

/// 이용약관 페이지
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
        title: const Text('이용약관'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('제1조 (목적)'),
            _SectionContent(
              '이 약관은 Co-Talk(이하 "서비스")가 제공하는 메시징 서비스의 이용 조건 및 절차, '
              '회사와 회원 간의 권리, 의무 및 책임사항 등을 규정함을 목적으로 합니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('제2조 (정의)'),
            _SectionContent(
              '① "서비스"란 회사가 제공하는 모든 메시징 관련 서비스를 의미합니다.\n'
              '② "회원"이란 서비스에 가입하여 이용하는 자를 의미합니다.\n'
              '③ "아이디(ID)"란 회원 식별을 위해 회원이 설정하고 회사가 승인한 이메일 주소를 의미합니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('제3조 (약관의 효력 및 변경)'),
            _SectionContent(
              '① 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.\n'
              '② 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 이 약관을 변경할 수 있습니다.\n'
              '③ 변경된 약관은 공지 후 7일이 경과한 날부터 효력이 발생합니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('제4조 (서비스의 제공)'),
            _SectionContent(
              '회사는 다음과 같은 서비스를 제공합니다:\n'
              '① 1:1 및 그룹 메시징 서비스\n'
              '② 친구 관리 서비스\n'
              '③ 프로필 관리 서비스\n'
              '④ 기타 회사가 정하는 서비스',
            ),
            SizedBox(height: 24),
            _SectionTitle('제5조 (회원가입)'),
            _SectionContent(
              '① 서비스 이용을 원하는 자는 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 '
              '이 약관에 동의한다는 의사표시를 함으로써 회원가입을 신청합니다.\n'
              '② 회사는 제1항의 신청에 대하여 서비스 이용을 승낙함을 원칙으로 합니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('제6조 (회원의 의무)'),
            _SectionContent(
              '회원은 다음 행위를 하여서는 안 됩니다:\n'
              '① 타인의 정보 도용\n'
              '② 회사가 게시한 정보의 변경\n'
              '③ 회사 및 제3자의 저작권 등 지적재산권 침해\n'
              '④ 회사 및 제3자의 명예 손상 또는 업무 방해\n'
              '⑤ 외설 또는 폭력적인 메시지 전송\n'
              '⑥ 기타 불법적이거나 부당한 행위',
            ),
            SizedBox(height: 24),
            _SectionTitle('제7조 (서비스 이용의 제한 및 중지)'),
            _SectionContent(
              '회사는 회원이 제6조의 의무를 위반하거나 서비스의 정상적인 운영을 방해한 경우, '
              '서비스 이용을 제한하거나 중지할 수 있습니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('제8조 (면책조항)'),
            _SectionContent(
              '① 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 '
              '서비스 제공에 관한 책임이 면제됩니다.\n'
              '② 회사는 회원의 귀책사유로 인한 서비스 이용 장애에 대하여 책임을 지지 않습니다.',
            ),
            SizedBox(height: 24),
            _SectionTitle('부칙'),
            _SectionContent(
              '이 약관은 2024년 1월 1일부터 시행합니다.',
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
