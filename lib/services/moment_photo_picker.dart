import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_moment.dart';
import 'moment_repository.dart';

class PlatformMomentPhotoPicker implements MomentPhotoPicker {
  PlatformMomentPhotoPicker({
    required this.isOwner,
    ImagePicker? picker,
    SharedPreferencesAsync? preferences,
  }) : _picker = picker ?? ImagePicker(),
       _preferences = preferences ?? SharedPreferencesAsync();
  final bool Function(String uid) isOwner;
  final ImagePicker _picker;
  final SharedPreferencesAsync _preferences;
  static const _pickerOwner = 'moment_picker_owner';

  Future<MomentPhoto> _read(XFile file, String uid) async {
    if (!isOwner(uid)) {
      throw const MomentFailure(
        'cancelled',
        'Your account changed. Please try again.',
      );
    }
    if (await file.length() > MomentPhoto.maxBytes) {
      throw const MomentFailure(
        'invalid-photo',
        'Choose an image smaller than 5 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    if (!isOwner(uid)) {
      throw const MomentFailure(
        'cancelled',
        'Your account changed. Please try again.',
      );
    }
    return MomentPhoto.checked(bytes);
  }

  @override
  Future<MomentPhoto?> pick(String uid, MomentPhotoSource source) async {
    try {
      if (!isOwner(uid)) {
        throw const MomentFailure(
          'cancelled',
          'Your account changed. Please try again.',
        );
      }
      await _preferences.setString(_pickerOwner, uid);
      final file = await _picker.pickImage(
        source: source == MomentPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      return file == null ? null : await _read(file, uid);
    } on PlatformException {
      throw const MomentFailure(
        'photo-permission',
        'Cannot open photos or camera. Check permission in Android Settings.',
      );
    } finally {
      if (await _preferences.getString(_pickerOwner) == uid) {
        await _preferences.remove(_pickerOwner);
      }
    }
  }

  @override
  Future<MomentPhoto?> recover(String uid) async {
    final owner = await _preferences.getString(_pickerOwner);
    if (owner == null) return null;
    try {
      final response = await _picker.retrieveLostData();
      // Lost-data storage is global to the Android picker; never attach an old
      // account's pending photo to the newly signed-in account.
      if (owner != uid || !isOwner(uid)) return null;
      if (response.exception != null) {
        throw const MomentFailure(
          'photo-permission',
          'The photo could not be recovered. Choose it again.',
        );
      }
      final files = response.files;
      return files == null || files.isEmpty
          ? null
          : await _read(files.first, uid);
    } on PlatformException {
      throw const MomentFailure(
        'photo-permission',
        'The photo could not be recovered. Choose it again.',
      );
    } finally {
      if (await _preferences.getString(_pickerOwner) == owner) {
        await _preferences.remove(_pickerOwner);
      }
    }
  }
}
