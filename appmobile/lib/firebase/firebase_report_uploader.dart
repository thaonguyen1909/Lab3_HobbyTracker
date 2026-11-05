import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/hobby_data.dart';
import '../services/device_services.dart';

class FirebaseReportUploader implements ReportUploader {
  FirebaseReportUploader(this.storage, this.auth);
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  @override
  Future<UploadReceipt> upload(
    String uid,
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    if (auth.currentUser?.uid != uid) {
      throw const DataFailure('Phiên đăng nhập đã thay đổi.');
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const DataFailure('PDF phải có dung lượng từ 1 byte đến 10 MB.');
    }
    final path = 'reports/$uid/${const Uuid().v4()}.pdf';
    final ref = storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) progress(s.bytesTransferred / s.totalBytes);
    }, onError: (Object _) {});
    try {
      await task;
      final url = await ref.getDownloadURL();
      return UploadReceipt(path, url);
    } catch (_) {
      throw const DataFailure(
        'Không tải được PDF lên Cloud Storage. Kiểm tra quyền, mạng và cấu hình dịch vụ.',
      );
    } finally {
      await sub.cancel();
    }
  }
}
