import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/auth/domain/usecases/has_profile_usecase.dart';
import 'package:ournego/features/auth/presentation/pages/complete_profile_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/pages/business_panel_screen.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/map/presentation/pages/map_screen.dart';
import 'package:ournego/features/business/presentation/pages/register_business_screen.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/features/navigation/presentation/widgets/navigation_bar_widget.dart';
import 'package:shake/shake.dart';
import 'package:url_launcher/url_launcher.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  ShakeDetector? _detector;

  @override
  void initState() {
    final authRepository = ref.read(authRepositoryProvider);
    final hasProfile = HasProfileUsecase(
      repository: authRepository,
    ).checkHasProfile();

    hasProfile.then((result) {
      result.fold((failure) {}, (hasProfile) {
        if (!hasProfile) {
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CompleteProfileScreen()),
          );
        }
      });
    });

    super.initState();

    _detector = ShakeDetector.autoStart(
      onPhoneShake: (shakeEvent) {
        showDialog(
          context: context,
          builder: (context) => FeedbackDialogWidget(),
        );
      },
      shakeThresholdGravity: 2.7,
    );
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(pageControllerProvider);
    final isOwnerAsync = ref.watch(isOwnerProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: isOwnerAsync.when(
        data: (isOwner) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView(
                      physics: ScrollPhysics(
                        parent: NeverScrollableScrollPhysics(),
                      ),
                      controller: controller,
                      onPageChanged: (index) {
                        ref
                            .read(navigationIndexProvider.notifier)
                            .setIndex(index);
                      },
                      children: [
                        Placeholder(),
                        MapScreen(),
                        isOwner
                            ? BusinessPanelScreen()
                            : RegisterBusinessScreen(),
                      ],
                    ),
                  ),
                  SizedBox(height: 56),
                ],
              ),
              AppNavigationBar(),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('Error al cargar datos')),
      ),
    );
  }
}
