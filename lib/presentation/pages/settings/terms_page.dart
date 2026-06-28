import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 이용약관 페이지
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
        title: Text(AppLocalizations.of(context)!.settingsTerms),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _TermsHeader(
              icon: Icons.description_outlined,
              eyebrow: 'TERMS OF SERVICE',
              title: '이용약관',
              effectiveDate: '2024년 1월 1일부터 시행',
            ),
            SizedBox(height: 8),
            _TermsCard(
              children: [
                _Section(
                  '제1조 (목적)',
                  '이 약관은 Co-Talk(이하 "서비스")가 제공하는 메시징 서비스의 이용 조건 및 절차, '
                      '회사와 회원 간의 권리, 의무 및 책임사항 등을 규정함을 목적으로 합니다.',
                ),
                _Section(
                  '제2조 (정의)',
                  '① "서비스"란 회사가 제공하는 모든 메시징 관련 서비스를 의미합니다.\n'
                      '② "회원"이란 서비스에 가입하여 이용하는 자를 의미합니다.\n'
                      '③ "아이디(ID)"란 회원 식별을 위해 회원이 설정하고 회사가 승인한 이메일 주소를 의미합니다.',
                ),
                _Section(
                  '제3조 (약관의 효력 및 변경)',
                  '① 이 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.\n'
                      '② 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 이 약관을 변경할 수 있습니다.\n'
                      '③ 변경된 약관은 공지 후 7일이 경과한 날부터 효력이 발생합니다.',
                ),
                _Section(
                  '제4조 (서비스의 제공)',
                  '회사는 다음과 같은 서비스를 제공합니다:\n'
                      '① 1:1 및 그룹 메시징 서비스\n'
                      '② 친구 관리 서비스\n'
                      '③ 프로필 관리 서비스\n'
                      '④ 기타 회사가 정하는 서비스',
                ),
                _Section(
                  '제5조 (회원가입)',
                  '① 서비스 이용을 원하는 자는 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 '
                      '이 약관에 동의한다는 의사표시를 함으로써 회원가입을 신청합니다.\n'
                      '② 회사는 제1항의 신청에 대하여 서비스 이용을 승낙함을 원칙으로 합니다.',
                ),
                _Section(
                  '제6조 (회원의 의무)',
                  '회원은 다음 행위를 하여서는 안 됩니다:\n'
                      '① 타인의 정보 도용\n'
                      '② 회사가 게시한 정보의 변경\n'
                      '③ 회사 및 제3자의 저작권 등 지적재산권 침해\n'
                      '④ 회사 및 제3자의 명예 손상 또는 업무 방해\n'
                      '⑤ 외설 또는 폭력적인 메시지 전송\n'
                      '⑥ 기타 불법적이거나 부당한 행위',
                ),
                _Section(
                  '제7조 (서비스 이용의 제한 및 중지)',
                  '회사는 회원이 제6조의 의무를 위반하거나 서비스의 정상적인 운영을 방해한 경우, '
                      '서비스 이용을 제한하거나 중지할 수 있습니다.',
                ),
                _Section(
                  '제8조 (면책조항)',
                  '① 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 '
                      '서비스 제공에 관한 책임이 면제됩니다.\n'
                      '② 회사는 회원의 귀책사유로 인한 서비스 이용 장애에 대하여 책임을 지지 않습니다.',
                ),
                _Section(
                  '부칙',
                  '이 약관은 2024년 1월 1일부터 시행합니다.',
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

/// 문서 상단 헤더 — 보라 틴트 아이콘 + 시행일 칩.
class _TermsHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String effectiveDate;

  const _TermsHeader({
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
class _TermsCard extends StatelessWidget {
  final List<Widget> children;

  const _TermsCard({required this.children});

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
