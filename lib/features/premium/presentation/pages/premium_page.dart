import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/premium/premium_model.dart';
import '../../../../core/premium/premium_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedIndex = 2; // Yıllık varsayılan

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final premiumService = context.watch<PremiumService>();
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.diamond_rounded, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          locale.get('premiumTitle'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locale.get('premiumSubtitle'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mevcut durum
                  if (premiumService.isPremium) ...[
                    _buildCurrentStatus(premiumService, locale, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Özellikler
                  Text(
                    locale.get('premiumFeatures'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturesList(locale, context),
                  
                  const SizedBox(height: 32),

                  // Paketler
                  Text(
                    locale.get('choosePlan'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...PremiumPackage.packages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final package = entry.value;
                    return _buildPackageCard(
                      package: package,
                      isSelected: _selectedIndex == index,
                      onTap: () => setState(() => _selectedIndex = index),
                      locale: locale,
                      context: context,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Satın al butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: premiumService.isLoading
                          ? null
                          : () => _handlePurchase(premiumService, locale),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: premiumService.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              premiumService.isPremium
                                  ? locale.get('extendPremium')
                                  : locale.get('getPremium'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bilgi notu
                  Center(
                    child: Text(
                      locale.get('premiumNote'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(PremiumService service, LocaleProvider locale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.get('youArePremium'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.status.daysRemaining} ${locale.get('daysRemaining')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '💎 ${locale.get('active')}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(LocaleProvider locale, BuildContext context) {
    final features = [
      {'icon': Icons.photo_camera_rounded, 'text': locale.get('featureProfilePhoto')},
      {'icon': Icons.meeting_room_rounded, 'text': locale.get('featureUnlimitedRooms')},
      {'icon': Icons.groups_rounded, 'text': locale.get('featureMoreParticipants')},
      {'icon': Icons.schedule_rounded, 'text': locale.get('featureMessageDelete')},
      {'icon': Icons.diamond_rounded, 'text': locale.get('featurePremiumBadge')},
      {'icon': Icons.visibility_off_rounded, 'text': locale.get('featureHideRead')},
      {'icon': Icons.trending_up_rounded, 'text': locale.get('featureProfileVisitors')},
      {'icon': Icons.star_rounded, 'text': locale.get('featurePrioritySupport')},
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f['icon'] as IconData, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                f['text'] as String,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPackageCard({
    required PremiumPackage package,
    required bool isSelected,
    required VoidCallback onTap,
    required LocaleProvider locale,
    required BuildContext context,
  }) {
    final name = locale.isTurkish ? package.name : package.nameEn;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow(context) : null,
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary(context),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Plan bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      if (package.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            locale.get('popular'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (package.discountPercent != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${locale.get('saveDiscount')} %${package.discountPercent!.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Fiyat
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${package.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  '₺${package.monthlyPrice.toStringAsFixed(0)}/${locale.get('month')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(PremiumService service, LocaleProvider locale) async {
    final package = PremiumPackage.packages[_selectedIndex];
    
    // Onay dialogu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          locale.get('confirmPurchase'),
          style: TextStyle(color: AppTheme.textPrimary(context)),
        ),
        content: Text(
          '${locale.isTurkish ? package.name : package.nameEn} - ₺${package.price.toStringAsFixed(2)}\n\n(Test Modu)',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locale.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(locale.get('confirm')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await service.purchasePremium(package);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? locale.get('purchaseSuccess') : locale.get('purchaseError'),
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
        
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }
}
