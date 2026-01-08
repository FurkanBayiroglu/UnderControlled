import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/premium/premium_service.dart';
import '../widgets/home_header.dart';
import '../widgets/main_action_card.dart';
import '../../../rooms/presentation/pages/create_room_page.dart';
import '../../../events/presentation/pages/room_list_page.dart';
import '../../../events/presentation/pages/ai_assistant_page.dart';
import '../../../premium/presentation/pages/premium_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final premiumService = context.watch<PremiumService>();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: HomeHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Premium Banner
                if (!premiumService.isPremium) ...[
                  _buildPremiumBanner(context, locale),
                  const SizedBox(height: 24),
                ],
                
                // Title
                Text(
                  locale.get('whatToDo'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Create Group - Create.json
                MainActionCard(
                  icon: Icons.rocket_launch_rounded,
                  title: locale.get('createGroup'),
                  subtitle: locale.get('startNewEvent'),
                  gradientColors: const [Color(0xFF3b82f6), Color(0xFF60a5fa)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomPage())),
                  lottieAsset: 'assets/animations/Create.json',
                ),
                const SizedBox(height: 12),
                
                // Join Groups - JoinGroups.json
                MainActionCard(
                  icon: Icons.explore_rounded,
                  title: locale.get('joinGroups'),
                  subtitle: locale.get('discoverGroups'),
                  gradientColors: const [Color(0xFF10b981), Color(0xFF34d399)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomListPage())),
                  lottieAsset: 'assets/animations/JoinGroups.json',
                ),
                const SizedBox(height: 12),
                
                // AI Assistant - AI_animation.json
                MainActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: locale.get('aiAssistant'),
                  subtitle: locale.get('aiAssistantDesc'),
                  gradientColors: const [Color(0xFF8b5cf6), Color(0xFFa78bfa)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage())),
                  badge: locale.get('new'),
                  isHighlighted: true,
                  lottieAsset: 'assets/animations/AI_animation.json',
                ),
                
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context, LocaleProvider locale) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf59e0b).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.get('goPremium'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locale.get('premiumSubtitle'),
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(
                locale.isTurkish ? 'İncele' : 'View',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFf59e0b)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}