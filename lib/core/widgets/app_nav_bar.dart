import 'package:flutter/material.dart';
import '../../config/constants.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.menu_book_rounded, label: 'Guide', index: 1, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.card_giftcard, label: 'Bonus', index: 2, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.build_circle, label: 'Strumenti', index: 3, current: currentIndex, onTap: onTap),
          _NavItemSbroglia(index: 4, current: currentIndex, onTap: onTap),
          _NavItem(icon: Icons.person_rounded, label: 'Profilo', index: 5, current: currentIndex, onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 28,
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 9),
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.navInactive,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab speciale Sbroglia.AI con badge colorato
class _NavItemSbroglia extends StatelessWidget {
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItemSbroglia({
    required this.index,
    required this.current,
    required this.onTap,
  });

  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 28,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 7),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                          )
                        : null,
                    color: isActive ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    size: 20,
                    color: isActive ? Colors.white : AppColors.navInactive,
                  ),
                ),
                if (!isActive)
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isActive ? const Color(0xFF6A1B9A) : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
