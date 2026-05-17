import 'dart:convert';
import 'dart:io';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // TODO: replace with your real Cloudinary details
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'YOUR_UNSIGNED_UPLOAD_PRESET';

  Future<CloudinaryResult> uploadCourseFormPdf({
  required File file,
  required String studentMatric,
  required String semester,
  required String session,
  String? fileTag, // NEW: used for resubmissions so it won't overwrite old file
}) async {
  final sanitizedMatric = studentMatric.replaceAll('/', '_');
  final sanitizedSession = session.replaceAll('/', '_');

  final baseId = '${sanitizedSession}_${semester.replaceAll(' ', '_')}';
  final publicId = (fileTag == null || fileTag.trim().isEmpty) ? baseId : '${baseId}_$fileTag';

  return _uploadFile(
    file: file,
    resourceType: 'raw',
    folder: 'smart_clearance/course_forms/$sanitizedMatric',
    publicId: publicId,
  );
}
  Future<CloudinaryResult> uploadProfilePhoto({
    required File file,
    required String userId,
  }) async {
    return _uploadFile(
      file: file,
      resourceType: 'image',
      folder: 'smart_clearance/profiles',
      publicId: 'profile_$userId',
    );
  }

  Future<CloudinaryResult> uploadPaymentReceipt({
    required File file,
    required String studentMatric,
    required String rrr,
  }) async {
    final sanitizedMatric = studentMatric.replaceAll('/', '_');

    // receipts can be image or pdf; keep it simple for MVP: treat as image
    return _uploadFile(
      file: file,
      resourceType: 'image',
      folder: 'smart_clearance/receipts/$sanitizedMatric',
      publicId: 'receipt_$rrr',
    );
  }

  Future<CloudinaryResult> _uploadFile({
    required File file,
    required String resourceType,
    required String folder,
    required String publicId,
  }) async {
    try {
      if (!await file.exists()) {
        return const CloudinaryResult(
          success: false,
          error: 'File not found. Please select again.',
        );
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return const CloudinaryResult(
          success: false,
          error: 'File is too large. Max allowed is 10MB.',
        );
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final boundary =
          'SmartClearanceBoundary${DateTime.now().millisecondsSinceEpoch}';

      final request = await HttpClient().postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      // Build multipart body
      final bodyBytes = <int>[];

      void addField(String name, String value) {
        bodyBytes.addAll('--$boundary\r\n'.codeUnits);
        bodyBytes.addAll(
          'Content-Disposition: form-data; name="$name"\r\n\r\n'.codeUnits,
        );
        bodyBytes.addAll('$value\r\n'.codeUnits);
      }

      // Fields required for unsigned upload
      addField('upload_preset', _uploadPreset);
      addField('folder', folder);
      addField('public_id', publicId);

      // File part
      final filename = file.path.split(Platform.pathSeparator).last;
      final fileBytes = await file.readAsBytes();

      bodyBytes.addAll('--$boundary\r\n'.codeUnits);
      bodyBytes.addAll(
        'Content-Disposition: form-data; name="file"; filename="$filename"\r\n'
            .codeUnits,
      );
      bodyBytes.addAll('Content-Type: application/octet-stream\r\n\r\n'.codeUnits);
      bodyBytes.addAll(fileBytes);
      bodyBytes.addAll('\r\n'.codeUnits);

      // Close boundary
      bodyBytes.addAll('--$boundary--\r\n'.codeUnits);

      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseText) as Map<String, dynamic>;
        return CloudinaryResult(
          success: true,
          url: decoded['secure_url'] as String?,
          publicId: decoded['public_id'] as String?,
        );
      }

      // Cloudinary returns useful error JSON, try to read it
      try {
        final decoded = jsonDecode(responseText) as Map<String, dynamic>;
        final err = decoded['error']?['message']?.toString();
        return CloudinaryResult(
          success: false,
          error: err ?? 'Upload failed (HTTP ${response.statusCode}).',
        );
      } catch (_) {
        return CloudinaryResult(
          success: false,
          error: 'Upload failed (HTTP ${response.statusCode}).',
        );
      }
    } catch (e) {
      return const CloudinaryResult(
        success: false,
        error: 'Upload failed. Check your connection and try again.',
      );
    }
  }
}

class CloudinaryResult {
  final bool success;
  final String? url;
  final String? publicId;
  final String? error;

  const CloudinaryResult({
    required this.success,
    this.url,
    this.publicId,
    this.error,
  });

  bool get hasUrl => success && url != null && url!.isNotEmpty;
}
