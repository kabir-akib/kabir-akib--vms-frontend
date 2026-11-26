import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';

/// Reusable operational status badge chip with Stark Group styling.
class StatusBadge extends StatelessWidget {
  final VehicleStatus status;
  final bool showDescriptionTooltip;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDescriptionTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color dot;

    switch (status) {
      case VehicleStatus.active:
        bg = AppColors.statusActiveBg;
        text = AppColors.statusActiveText;
        dot = AppColors.statusActiveDot;
        break;
      case VehicleStatus.maintenance:
        bg = AppColors.statusMaintenanceBg;
        text = AppColors.statusMaintenanceText;
        dot = AppColors.statusMaintenanceDot;
        break;
      case VehicleStatus.inactive:
        bg = AppColors.statusInactiveBg;
        text = AppColors.statusInactiveText;
        dot = AppColors.statusInactiveDot;
        break;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: text.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (showDescriptionTooltip) {
      return Tooltip(
        message: status.description,
        child: badge,
      );
    }

    return badge;
  }
}
