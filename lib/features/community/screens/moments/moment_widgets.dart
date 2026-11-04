import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../widgets/hobby_button.dart';

class PrivateMomentPhoto extends StatefulWidget {
  const PrivateMomentPhoto({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<PrivateMomentPhoto> createState() => _PrivateMomentPhotoState();
}

class _PrivateMomentPhotoState extends State<PrivateMomentPhoto> {
  late MemoryImage _image;
  @override
  void initState() {
    super.initState();
    _image = MemoryImage(widget.bytes);
  }

  @override
  void didUpdateWidget(covariant PrivateMomentPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      unawaited(_image.evict());
      _image = MemoryImage(widget.bytes);
    }
  }

  @override
  void dispose() {
    unawaited(_image.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: Image(
        image: _image,
        fit: BoxFit.contain,
        gaplessPlayback: false,
        semanticLabel: context.tr('Photo shared with this group'),
        errorBuilder: (_, _, _) => const Center(
          child: AppText(
            'Cannot display this photo. Choose another photo or retry.',
          ),
        ),
      ),
    ),
  );
}

class MomentTimeLeft extends StatelessWidget {
  const MomentTimeLeft({super.key, required this.expiresAt, required this.now});
  final DateTime expiresAt, now;
  @override
  Widget build(BuildContext context) {
    final seconds = expiresAt.difference(now).inSeconds;
    return AppText(
      seconds <= 0
          ? 'Moment expired'
          : 'Time left: ${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class MomentErrorPanel extends StatelessWidget {
  const MomentErrorPanel({
    super.key,
    required this.message,
    required this.retry,
  });
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: AppText(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      const SizedBox(height: 12),
      HobbyButton(
        label: 'Retry',
        onPressed: retry,
        variant: HobbyButtonVariant.outline,
      ),
    ],
  );
}

class MomentExpiredPanel extends StatelessWidget {
  const MomentExpiredPanel({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.hourglass_empty_outlined, size: 48),
        SizedBox(height: 16),
        AppText(
          'This moment has expired or is no longer available.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
