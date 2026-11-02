import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => context.read<OnboardingController>().complete();

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = context.read<LocaleController>();
    final last = _page == _count - 1;

    final art = <Widget>[
      const _ArtMascot(badge: Icons.checklist_rounded),
      const _ArtTiles(),
      const _ArtMascot(hearts: true),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  for (final code in ['en', 'id'])
                    TextButton(
                      onPressed: () => locale.setLanguage(code),
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(
                          fontWeight:
                              s.lang == code ? FontWeight.w900 : FontWeight.w500,
                          decoration:
                              s.lang == code ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(s.t('skip'),
                        style: const TextStyle(color: AppColors.brownSoft)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 280, child: Center(child: art[i])),
                      const SizedBox(height: 28),
                      Text(s.t('onb${i + 1}_t'),
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(
                        s.t('onb${i + 1}_b'),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: AppColors.brownSoft, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.peachDeep : AppColors.peach,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        last ? AppColors.safe : AppColors.peachDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(last ? s.t('get_started') : s.t('next'),
                      style: const TextStyle(fontSize: 17)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mascot, optionally with a checklist badge (page 1) or hearts (page 3).
class _ArtMascot extends StatelessWidget {
  const _ArtMascot({this.badge, this.hearts = false});
  final IconData? badge;
  final bool hearts;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Image.asset('assets/images/mascot.png', width: 250),
        if (badge != null)
          Positioned(
            right: 0,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(badge, size: 38, color: AppColors.brown),
            ),
          ),
        if (hearts) ...[
          const Positioned(
              right: 14,
              top: 10,
              child: Icon(Icons.favorite_rounded,
                  size: 26, color: AppColors.peachDeep)),
          Positioned(
              left: 8,
              bottom: 24,
              child: Icon(Icons.favorite_rounded,
                  size: 18, color: AppColors.peachDeep.withValues(alpha: 0.6))),
        ],
      ],
    );
  }
}

/// Page 2: the things Nesty keeps track of.
class _ArtTiles extends StatelessWidget {
  const _ArtTiles();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color color) => Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 54, color: color),
        );

    return SizedBox(
      width: 250,
      height: 250,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          tile(Icons.lightbulb_rounded, AppColors.low),
          tile(Icons.water_drop_rounded, AppColors.waterDeep),
          tile(Icons.local_laundry_service_rounded, AppColors.lavenderDeep),
          tile(Icons.shopping_basket_rounded, AppColors.peachDeep),
        ],
      ),
    );
  }
}
