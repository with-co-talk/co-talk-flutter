import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// 개인정보 처리방침 페이지
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _PolicyHeader(
              icon: Icons.privacy_tip_outlined,
              eyebrow: 'PRIVACY',
              title: '개인정보 처리방침',
              effectiveDate: '2024년 1월 1일부터 적용',
            ),
            SizedBox(height: 8),
            _PolicyCard(
              children: [
                _Section(
                  '1. 개인정보의 처리 목적',
                  'Co-Talk(이하 "회사")은 다음의 목적을 위하여 개인정보를 처리합니다:\n\n'
                      '• 회원 가입 및 관리: 회원제 서비스 이용에 따른 본인확인, 개인식별, 불량회원의 부정이용 방지\n'
                      '• 서비스 제공: 메시징 서비스, 친구 관리, 프로필 관리 등 서비스 제공\n'
                      '• 고객 지원: 민원 처리, 고지사항 전달',
                ),
                _Section(
                  '2. 수집하는 개인정보 항목',
                  '회사는 서비스 제공을 위해 다음의 개인정보를 수집합니다:\n\n'
                      '• 필수항목: 이메일 주소, 비밀번호, 닉네임\n'
                      '• 선택항목: 프로필 사진, 상태 메시지, 배경 이미지\n'
                      '• 자동수집항목: 기기정보, 접속 IP, 접속 일시',
                ),
                _Section(
                  '3. 개인정보의 보유 및 이용기간',
                  '회사는 회원 탈퇴 시 또는 개인정보 수집 및 이용목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.\n\n'
                      '다만, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 회사는 관계법령에서 정한 일정한 기간 동안 회원정보를 보관합니다:\n\n'
                      '• 계약 또는 청약철회 등에 관한 기록: 5년\n'
                      '• 소비자의 불만 또는 분쟁처리에 관한 기록: 3년\n'
                      '• 접속에 관한 기록: 3개월',
                ),
                _Section(
                  '4. 개인정보의 파기',
                  '회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 '
                      '지체 없이 해당 개인정보를 파기합니다.\n\n'
                      '전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제하며, '
                      '종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각하여 파기합니다.',
                ),
                _Section(
                  '5. 개인정보의 제3자 제공',
                  '회사는 원칙적으로 정보주체의 개인정보를 제3자에게 제공하지 않습니다.\n\n'
                      '다만, 다음의 경우에는 예외로 합니다:\n'
                      '• 정보주체가 사전에 동의한 경우\n'
                      '• 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우',
                ),
                _Section(
                  '6. 정보주체의 권리',
                  '정보주체는 회사에 대해 언제든지 다음의 권리를 행사할 수 있습니다:\n\n'
                      '• 개인정보 열람 요구\n'
                      '• 오류 등이 있을 경우 정정 요구\n'
                      '• 삭제 요구\n'
                      '• 처리정지 요구\n\n'
                      '위 권리 행사는 서비스 내 설정 메뉴 또는 고객센터를 통해 하실 수 있습니다.',
                ),
                _Section(
                  '7. 개인정보 보호책임자',
                  '회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n'
                      '개인정보 보호책임자\n'
                      '• 담당부서: 개인정보보호팀\n'
                      '• 연락처: privacy@cotalk.com',
                ),
                _Section(
                  '8. 개인정보 처리방침 변경',
                  '이 개인정보 처리방침은 2024년 1월 1일부터 적용됩니다.\n\n'
                      '이전의 개인정보 처리방침은 아래에서 확인하실 수 있습니다.',
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 문서 상단 헤더 — 보라 틴트 아이콘 + 적용일 칩.
class _PolicyHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String effectiveDate;

  const _PolicyHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.effectiveDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 15,
                  color: context.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  effectiveDate,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 본문 섹션들을 담는 카드.
class _PolicyCard extends StatelessWidget {
  final List<Widget> children;

  const _PolicyCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.20 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 섹션 제목 + 본문 한 묶음. 제목 앞 보라 마커, 줄간격 1.6.
class _Section extends StatelessWidget {
  final String title;
  final String content;
  final bool isLast;

  const _Section(this.title, this.content, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.brandGradient,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: isLast ? 20 : 0),
        if (!isLast) ...[
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: context.dividerColor.withValues(alpha: 0.5),
          ),
        ],
      ],
    );
  }
}
