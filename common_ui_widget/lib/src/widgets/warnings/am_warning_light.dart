import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'am_warning_light_assets.dart';

import 'am_warning_light_catalog.dart';

/// Presentation input: reports keep their own domain and persistence types.
class AmWarningLightData {
  const AmWarningLightData({
    required this.code,
    required this.color,
    this.flashing = false,
    this.onboardMessage = '',
    this.description = '',
  });
  final String code;
  final String color;
  final bool flashing;
  final String onboardMessage;
  final String description;
  String get message => onboardMessage.trim().isNotEmpty
      ? onboardMessage.trim()
      : description.trim();
  String get assetPath =>
      'assets/warning_lights/${amWarningLightAssets[code] ?? 'warning.svg'}';
  String get variantLabel => '$label\n${flashing ? 'Lampeggiante' : 'Fissa'}';
  String get colorLabel => switch (color) {
    'red' => 'rossa',
    'amber' => 'gialla',
    'blue' => 'blu',
    'green' => 'verde',
    'white' => 'bianca',
    _ => 'colore non ricordato',
  };
  String get label => amWarningLightCatalog[code]?.$1 ?? 'Altra spia';
  Color get tint => switch (color) {
    'red' => const Color(0xFFFF4D57),
    'amber' => const Color(0xFFFFBB33),
    'green' => const Color(0xFF35C878),
    'blue' => const Color(0xFF59A8FF),
    _ => const Color(0xFFE0E5EC),
  };
}

class AmWarningLight extends StatefulWidget {
  const AmWarningLight({required this.light, this.size = 24, super.key});
  final AmWarningLightData light;
  final double size;
  @override
  State<AmWarningLight> createState() => _AmWarningLightState();
}

class _AmWarningLightState extends State<AmWarningLight>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _opacity = Tween<double>(begin: 0.25, end: 1).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AmWarningLight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    // Animate only observations marked as flashing; respect reduced motion.
    if (widget.light.flashing && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    triggerMode: TooltipTriggerMode.tap,
    showDuration: const Duration(seconds: 8),
    message: [
      '${widget.light.label} · ${widget.light.colorLabel} · ${widget.light.flashing ? "lampeggiante" : "fissa"}',
      if (widget.light.message.trim().isNotEmpty) widget.light.message.trim(),
    ].join('\n'),
    child: Semantics(
      label:
          '${widget.light.label}, ${widget.light.colorLabel}, ${widget.light.flashing ? "lampeggiante" : "fissa"}',
      child: FadeTransition(
        opacity: _opacity,
        child: SvgPicture.asset(
          widget.light.assetPath,
          package: 'common_ui_widget',
          colorFilter: ColorFilter.mode(widget.light.tint, BlendMode.srcIn),
          width: widget.size,
          height: widget.size,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

class AmWarningLights extends StatelessWidget {
  const AmWarningLights({
    required this.lights,
    this.size = 24,
    this.compact = false,
    super.key,
  });
  final List<AmWarningLightData> lights;
  final double size;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    // The same observation can occur in multiple open reports; render it once.
    final groups = <String, List<AmWarningLightData>>{};
    for (final light in lights) {
      groups
          .putIfAbsent(
            '${light.code}/${light.color}/${light.flashing}',
            () => [],
          )
          .add(light);
    }
    // One icon per appearance; board messages take precedence across its reports.
    final unique = [
      for (final group in groups.values)
        AmWarningLightData(
          code: group.first.code,
          color: group.first.color,
          flashing: group.first.flashing,
          onboardMessage: group
              .map((light) => light.onboardMessage.trim())
              .where((message) => message.isNotEmpty)
              .toSet()
              .join('\n\n'),
          description: group
              .map((light) => light.description.trim())
              .where((message) => message.isNotEmpty)
              .toSet()
              .join('\n\n'),
        ),
    ];
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final light in unique)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AmWarningLight(light: light, size: size),
              ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final light in unique) AmWarningLight(light: light, size: size),
      ],
    );
  }
}
