// Create or Import wallet screen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/deep_space_theme.dart';
import '../../../ui/molecules/p_card.dart';
import '../../../ui/atoms/p_input.dart';
import '../../../ui/organisms/p_app_bar.dart';
import '../../../ui/organisms/p_scaffold.dart';
import '../../../core/ffi/ffi_bridge.dart';
import '../../../core/providers/wallet_providers.dart';
import '../onboarding_flow.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../../../core/i18n/arb_text_localizer.dart';
import '../../settings/providers/developer_mode_provider.dart';

/// Create or Import screen
class CreateOrImportScreen extends ConsumerStatefulWidget {
  const CreateOrImportScreen({super.key});

  @override
  ConsumerState<CreateOrImportScreen> createState() =>
      _CreateOrImportScreenState();
}

class _CreateOrImportScreenState extends ConsumerState<CreateOrImportScreen> {
  final _endpointController = TextEditingController();
  final _overwinterController = TextEditingController();
  final _saplingController = TextEditingController();
  final _orchardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(onboardingControllerProvider.notifier);
      notifier.reset(startAt: OnboardingStep.createOrImport);

      final state = ref.read(onboardingControllerProvider);
      _endpointController.text = state.customEndpoint ?? '';
      _updateHeightControllers(state);
    });
  }

  void _updateHeightControllers(OnboardingState state) {
    if (state.network == PirateNetwork.regtest) {
      _overwinterController.text = (state.overwinterHeight ?? 1).toString();
      _saplingController.text = (state.saplingHeight ?? 1).toString();
      // Pirate Chain is Sapling-only; a standard regtest node activates only
      // Overwinter + Sapling. Leave Orchard empty (disabled) by default so the
      // wallet builds v4 Sapling transactions the node accepts. Users running
      // an NU5-enabled regtest node can enter an Orchard activation height.
      _orchardController.text = state.orchardHeight?.toString() ?? '';
    } else if (state.network == PirateNetwork.testnet) {
      _overwinterController.text = (state.overwinterHeight ?? 207500).toString();
      _saplingController.text = (state.saplingHeight ?? 280000).toString();
      _orchardController.text = (state.orchardHeight ?? 61).toString();
    } else {
      _overwinterController.text = '';
      _saplingController.text = '';
      _orchardController.text = '';
    }
  }

  void _saveHeights() {
    final overwinter = int.tryParse(_overwinterController.text);
    final sapling = int.tryParse(_saplingController.text);
    final orchard = int.tryParse(_orchardController.text);

    ref.read(onboardingControllerProvider.notifier).setActivationHeights(
      overwinter: overwinter,
      sapling: sapling,
      orchard: orchard,
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _overwinterController.dispose();
    _saplingController.dispose();
    _orchardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final totalSteps = onboardingState.mode == OnboardingMode.import ? 5 : 6;

    return PScaffold(
      title: 'New Wallet'.tr,
      appBar: PAppBar(
        title: 'New Wallet'.tr,
        subtitle: 'Create or import a wallet'.tr,
        onBack: () {
          ref.read(onboardingControllerProvider.notifier).previousStep();
          context.pop();
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.screenPadding(
            MediaQuery.of(context).size.width,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressIndicator(
                currentStep: 1,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Create or Import Wallet'.tr,
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Choose how you'd like to set up your wallet",
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (ref.watch(developerModeProvider)) ...[
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Text(
                      'Network:'.tr,
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ...PirateNetwork.values.map((n) {
                      final isSelected = onboardingState.network == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(n.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(onboardingControllerProvider.notifier)
                                  .setNetwork(n);
                              _updateHeightControllers(
                                ref.read(onboardingControllerProvider),
                              );
                            }
                          },
                          selectedColor: AppColors.accentPrimary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                if (onboardingState.network != PirateNetwork.mainnet) ...[
                  const SizedBox(height: AppSpacing.lg),
                  PInput(
                    controller: _endpointController,
                    label: 'Lightwalletd Endpoint'.tr,
                    hint: onboardingState.network == PirateNetwork.regtest
                        ? '127.0.0.1:9067'
                        : '64.23.167.130:8067',
                    onChanged: (value) {
                      ref
                          .read(onboardingControllerProvider.notifier)
                          .setCustomEndpoint(value.trim());
                    },
                    prefixIcon: const Icon(Icons.dns_outlined),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PInput(
                          label: 'Overwinter Height'.tr,
                          hint: '207500',
                          controller: _overwinterController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _saveHeights(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PInput(
                          label: 'Sapling Height'.tr,
                          hint: '280000',
                          controller: _saplingController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _saveHeights(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PInput(
                    label: 'Orchard Height'.tr,
                    hint: '61',
                    controller: _orchardController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveHeights(),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xxl),
              PCard(
                child: InkWell(
                  onTap: () async {
                    ref.read(onboardingControllerProvider.notifier)
                      ..reset(startAt: OnboardingStep.createOrImport)
                      ..setMode(OnboardingMode.create)
                      ..nextStep();
                    final hasPassphrase = await FfiBridge.hasAppPassphrase();
                    final isUnlocked = ref.read(appUnlockedProvider);
                    if (!context.mounted) return;
                    if (hasPassphrase && !isUnlocked) {
                      unawaited(
                        context.push(
                          '/unlock?redirect=/onboarding/backup-warning',
                        ),
                      );
                      return;
                    }
                    if (hasPassphrase) {
                      unawaited(context.push('/onboarding/backup-warning'));
                      return;
                    }
                    unawaited(context.push('/onboarding/passphrase'));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentPrimary,
                                    AppColors.accentSecondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 32,
                                semanticLabel: 'Create new wallet'.tr,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create New Wallet'.tr,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Generate a new secure wallet'.tr,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PCard(
                child: InkWell(
                  onTap: () async {
                    ref.read(onboardingControllerProvider.notifier)
                      ..reset(startAt: OnboardingStep.createOrImport)
                      ..setMode(OnboardingMode.import)
                      ..nextStep();
                    final hasPassphrase = await FfiBridge.hasAppPassphrase();
                    final isUnlocked = ref.read(appUnlockedProvider);
                    if (!context.mounted) return;
                    if (hasPassphrase && !isUnlocked) {
                      unawaited(
                        context.push(
                          '/unlock?redirect=/onboarding/import-seed',
                        ),
                      );
                      return;
                    }
                    unawaited(context.push('/onboarding/import-seed'));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.file_download_outlined,
                                color: AppColors.accentPrimary,
                                size: 32,
                                semanticLabel: 'Import existing wallet'.tr,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import Existing Wallet'.tr,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Restore from 24-word seed phrase'.tr,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PCard(
                child: InkWell(
                  onTap: () async {
                    ref.read(onboardingControllerProvider.notifier)
                      ..reset(startAt: OnboardingStep.createOrImport)
                      ..setMode(OnboardingMode.watchOnly);
                    final hasPassphrase = await FfiBridge.hasAppPassphrase();
                    final isUnlocked = ref.read(appUnlockedProvider);
                    if (hasPassphrase && !isUnlocked) {
                      if (!context.mounted) return;
                      unawaited(
                        context.push('/unlock?redirect=/onboarding/import-ivk'),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    unawaited(context.push('/onboarding/import-ivk'));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 32,
                                semanticLabel: 'Import view only wallet'.tr,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'View only'.tr,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Import viewing key'.tr,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your seed phrase is the only way to recover your wallet. Keep it safe!'
                            .tr,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
