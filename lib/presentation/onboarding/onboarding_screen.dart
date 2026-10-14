import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/native_bridge.dart';
import '../providers/app_state_provider.dart';
import '../widgets/language_selector_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning from system settings
      ref.read(appStateProvider.notifier).refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final permissions = appState.permissions;
    final l10n = context.l10n;

    final isAccessibilityGranted = permissions['accessibility'] ?? false;
    final isOverlayGranted = permissions['overlay'] ?? false;
    final isBatteryGranted = permissions['batteryOptimization'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Top Bar with Logo & Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/splash_mark_512.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.zenGreenSubtle,
                              child: const Center(
                                child: Text('🛡️', style: TextStyle(fontSize: 24)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AntiDoom',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n.onboardingPermissionsBadge,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const LanguageSwitchButton(compact: true),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                l10n.onboardingHeroTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.onboardingHeroSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Permissions List
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      title: l10n.permAccessibilityTitle,
                      desc: l10n.permAccessibilityDesc,
                      isGranted: isAccessibilityGranted,
                      grantBtnText: l10n.grantPermissionBtn,
                      onTap: () => NativeBridge.requestAccessibilityPermission(),
                    ),
                    const SizedBox(height: 14),
                    _buildPermissionItem(
                      title: l10n.permOverlayTitle,
                      desc: l10n.permOverlayDesc,
                      isGranted: isOverlayGranted,
                      grantBtnText: l10n.grantPermissionBtn,
                      onTap: () => NativeBridge.requestOverlayPermission(),
                    ),
                    const SizedBox(height: 14),
                    _buildPermissionItem(
                      title: l10n.permBatteryTitle,
                      desc: l10n.permBatteryDesc,
                      isGranted: isBatteryGranted,
                      grantBtnText: l10n.grantPermissionBtn,
                      onTap: () => NativeBridge.requestBatteryOptimization(),
                    ),
                  ],
                ),
              ),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(appRepositoryProvider);
                    await repo.setOnboardingCompleted(true);
                    // Automatically activate tracking if permissions granted
                    if (isAccessibilityGranted && isOverlayGranted) {
                      await ref.read(appStateProvider.notifier).toggleTracking(true);
                    }
                    widget.onComplete();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.zenGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    appState.areAllPermissionsGranted
                        ? l10n.startProtectingBtn
                        : l10n.continueToDashboardBtn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String desc,
    required bool isGranted,
    required String grantBtnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted ? AppColors.zenGreen.withValues(alpha: 0.4) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGranted ? AppColors.zenGreenSubtle : AppColors.surfaceElevated,
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isGranted ? AppColors.zenGreenLight : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              desc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isGranted)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(grantBtnText),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.zenGreenLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
