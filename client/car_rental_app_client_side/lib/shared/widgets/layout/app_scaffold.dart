import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/booking/providers/booking_provider.dart';
import '../../../../features/booking/widgets/timeline/booking_progress_indicator.dart';

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool showProgress;
  final String? title;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.showProgress = true,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);

    return ColoredBox(
      color: AppColors.slate900,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                appBar:
                    appBar ??
                    (title != null
                        ? AppBar(title: Text(title!), actions: actions)
                        : null),
                bottomNavigationBar: bottomNavigationBar,
                body: Column(
                  children: [
                    if (showProgress)
                      BookingProgressIndicator(
                        currentStep: flowState.currentStep,
                      ),
                    Expanded(
                      child: SafeArea(top: false, bottom: false, child: body),
                    ),
                  ],
                ),
              ),
              if (flowState.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
