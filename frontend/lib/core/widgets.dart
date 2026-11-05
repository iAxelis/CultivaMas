import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import 'theme.dart';

final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
final moneyExact = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
final shortDate = DateFormat('dd MMM yyyy', 'es_MX');
final quantity = NumberFormat('#,##0.##', 'es_MX');

enum AppGlyphType { dashboard, sprout, add, more, records, sales, chart, edit, delete }

class AppGlyph extends StatelessWidget {
  const AppGlyph(this.type, {this.size = 24, this.color, super.key});

  final AppGlyphType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      AppGlyphType.dashboard => Icons.dashboard_outlined,
      AppGlyphType.sprout => Icons.eco_outlined,
      AppGlyphType.add => Icons.add_circle_outline_rounded,
      AppGlyphType.more => Icons.more_horiz_rounded,
      AppGlyphType.records => Icons.receipt_long_outlined,
      AppGlyphType.sales => Icons.storefront_rounded,
      AppGlyphType.chart => Icons.bar_chart_rounded,
      AppGlyphType.edit => Icons.edit_outlined,
      AppGlyphType.delete => Icons.delete_outline_rounded,
    };
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) action!,
      ],
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox(this.icon, {this.color = AppColors.darkGreen, super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class PlainLeadingIcon extends StatelessWidget {
  const PlainLeadingIcon(this.icon, {this.color = AppColors.green, super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.color, {this.icon = Icons.circle, super.key});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

({String label, Color color, IconData icon}) cycleStatusStyle(CycleStatus status) {
  return switch (status) {
    CycleStatus.activo => (
        label: 'Activo',
        color: AppColors.green,
        icon: Icons.play_circle_rounded
      ),
    CycleStatus.planificado => (
        label: 'Planificado',
        color: AppColors.tertiaryInk,
        icon: Icons.schedule_rounded
      ),
    CycleStatus.suspendido => (
        label: 'Suspendido',
        color: AppColors.amber,
        icon: Icons.pause_circle_rounded
      ),
    CycleStatus.finalizado => (
        label: 'Finalizado',
        color: AppColors.blue,
        icon: Icons.check_circle_rounded
      ),
    CycleStatus.cerrado => (
        label: 'Cerrado',
        color: AppColors.red,
        icon: Icons.lock_rounded
      ),
  };
}

({String label, Color color}) paymentStatusStyle(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.pendiente => (label: 'Pendiente', color: AppColors.tertiaryInk),
    PaymentStatus.parcial => (label: 'Parcial', color: AppColors.amber),
    PaymentStatus.pagada => (label: 'Pagada', color: AppColors.green),
    PaymentStatus.vencida => (label: 'Vencida', color: AppColors.red),
  };
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.note,
    this.color = AppColors.green,
    super.key,
  });

  final String label;
  final String value;
  final String? note;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBox(icon, color: color),
            const SizedBox(height: 16),
            Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                value,
                key: ValueKey(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.eyebrow,
    required this.value,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String value;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.text,
    this.title,
    this.tone = AppColors.blue,
    this.icon = Icons.info_rounded,
    super.key,
  });

  final String? title;
  final String text;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: TextStyle(color: tone, fontWeight: FontWeight.w700)),
                if (title != null) const SizedBox(height: 3),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FieldBlock extends StatelessWidget {
  const FieldBlock({
    required this.label,
    required this.help,
    required this.child,
    super.key,
  });

  final String label;
  final String help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 6),
        Text(help, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.greenSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.green, size: 34),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class MiniBar extends StatelessWidget {
  const MiniBar({
    required this.label,
    required this.value,
    required this.progress,
    this.color = AppColors.green,
    super.key,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0, 1),
            backgroundColor: AppColors.border,
            color: color,
          ),
        ),
      ],
    );
  }
}
