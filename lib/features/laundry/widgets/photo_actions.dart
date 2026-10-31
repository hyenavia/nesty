import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/photo_service.dart';

/// Bottom sheet: camera or gallery. Returns the saved photo file name.
Future<String?> choosePhoto(BuildContext context) async {
  final s = context.s;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(s.t('laundry_take_photo')),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(s.t('laundry_pick_photo')),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(s.t('laundry_photo_note'),
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.brownSoft)),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return PhotoService.pick(source);
}

/// Small rounded receipt thumbnail; tap to view full size.
class OrderPhoto extends StatelessWidget {
  const OrderPhoto({super.key, required this.name, this.size = 56});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = PhotoService.fileFor(name);
    final exists = file.existsSync();
    return GestureDetector(
      onTap: () {
        final s = context.s;
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            clipBehavior: Clip.antiAlias,
            child: exists
                ? InteractiveViewer(child: Image.file(file))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(s.t('laundry_photo_missing')),
                  ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: exists
              ? Image.file(file, fit: BoxFit.cover, cacheWidth: 200)
              : Container(
                  color: AppColors.peach,
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.brownSoft),
                ),
        ),
      ),
    );
  }
}
