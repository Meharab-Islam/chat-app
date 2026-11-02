import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../auth/view_models/auth_view_model.dart';

class SplashView extends StatefulWidget {
  final VoidCallback? onComplete;
  const SplashView({super.key, this.onComplete});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;
  String _statusText = 'Checking authentication...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final startTime = DateTime.now();
    const minDuration = Duration(milliseconds: 1800);
    final authVM = context.read<AuthViewModel>();
    final isAuth = authVM.isAuthenticated;
    final userName = authVM.currentUser?.name.split(' ').first;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _statusText = isAuth
          ? (userName != null ? 'Welcome back, $userName!' : 'Session verified')
          : 'Initializing experience...';
    });

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      context.read<AuthViewModel>().completeInitialization();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0D0F15), Color(0xFF090A0E)]
                : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(scale: _scaleAnimation, child: child),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 110.r,
                          height: 110.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withAlpha(isDark ? 35 : 22),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 84.r,
                      height: 84.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, primary.withAlpha(220)],
                        ),
                        borderRadius: BorderRadius.circular(22.r),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withAlpha(isDark ? 75 : 90),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.forum_rounded,
                        size: 44.r,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Minimal Chat',
                      style: AppTypography.headingLarge(textPrimary).copyWith(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Fast, Private & Secure Messaging',
                      style: AppTypography.bodyMedium(textSecondary)
                          .copyWith(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 110.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: LinearProgressIndicator(
                          minHeight: 3.5.h,
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(20)
                              : Colors.black.withAlpha(12),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13.r,
                          color: textSecondary.withAlpha(180),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            fontSize: 11.sp,
                            letterSpacing: 0.3,
                            color: textSecondary.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
