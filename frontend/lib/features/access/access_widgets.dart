import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme.dart';

class AccessScaffold extends StatelessWidget {
  const AccessScaffold({
    this.eyebrow,
    this.appName,
    this.title,
    this.description,
    required this.child,
    this.compactBrand = false,
    this.brandTopPadding,
    this.logoOffsetX = -3,
    this.surfaceTopGap = 12,
    this.onBack,
    super.key,
  });

  final String? eyebrow;
  final String? appName;
  final String? title;
  final String? description;
  final Widget child;
  final bool compactBrand;
  final double? brandTopPadding;
  final double logoOffsetX;
  final double surfaceTopGap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AccessBrand(
                        appName: appName,
                        eyebrow: eyebrow,
                        title: title,
                        description: description,
                        compact: compactBrand,
                        topPadding: brandTopPadding,
                        logoOffsetX: logoOffsetX,
                      ),
                      AccessSurface(
                        topGap: surfaceTopGap,
                        child: child,
                      ),
                    ],
                  ),
                  if (onBack != null)
                    Positioned(
                      top: 4,
                      left: 8,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 44),
                        ),
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Volver'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccessBrand extends StatelessWidget {
  const AccessBrand({
    this.eyebrow,
    this.appName,
    this.title,
    this.description,
    this.compact = false,
    this.topPadding,
    this.logoOffsetX = 0,
    super.key,
  });

  final String? eyebrow;
  final String? appName;
  final String? title;
  final String? description;
  final bool compact;
  final double? topPadding;
  final double logoOffsetX;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding ?? (compact ? 52 : 34),
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 92 : 128,
            height: compact ? 92 : 128,
            alignment: Alignment.center,
            padding: EdgeInsets.all(compact ? 9 : 12),
            child: Center(
              child: Transform.translate(
                offset: Offset(logoOffsetX, 0),
                child: SvgPicture.asset(
                  'assets/brand-logo.svg',
                  semanticsLabel: 'Logo de la aplicación',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          if (appName != null) ...[
            const SizedBox(height: 10),
            Text(
              appName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
          ],
          if (eyebrow != null) ...[
            SizedBox(height: appName == null ? 16 : 10),
            Text(
              eyebrow!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 30 : 38,
                height: 1.04,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ],
          if (description != null) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AccessSurface extends StatelessWidget {
  const AccessSurface({
    required this.child,
    this.topGap = 12,
    super.key,
  });

  final Widget child;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, topGap, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .14),
            blurRadius: 36,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
