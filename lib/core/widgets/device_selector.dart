import 'package:material_ui/material_ui.dart';

import '../../models/device_model.dart';
import '../theme/app_theme.dart';

class DeviceSelectorRow extends StatelessWidget {
  const DeviceSelectorRow({
    super.key,
    required this.devices,
    required this.selectedId,
    required this.onChanged,
  });

  final List<IoTDevice> devices;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();
    final safeValue = devices.any((d) => d.id == selectedId)
        ? selectedId
        : devices.first.id;

    return Row(
      children: [
        Text(
          'Perangkat',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.ink,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                items: devices
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(
                          d.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
