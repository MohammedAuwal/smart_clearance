import 'dart:io';
import 'package:cloudinary_flutter/cloudinary_flutter.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

class CloudinaryService {
  // Singleton pattern
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // ─── Your Cloudinary credentials ─────────────────────────────────────────
  // Replace these with your actual Cloudinary values from cloudinary.com
  // Dashboard -> Settings -> Access Keys
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'smart_clearance_preset';
  // Note: Upload preset must be set to "Unsigned" in your Cloudinary dashboard
  // Go to Settings -> Upload -> Upload Presets -> Add unsigned preset

  late final CloudinaryObject _cloudinary;

  // Call this once during app initialization in main.dart
  void initialize() {
    _cloudinary = CloudinaryObject.fromCloudName(cloudName: _cloudName);
  }

  // ─── Upload Course Form PDF ───────────────────────────────────────────────
  Future<CloudinaryResult> uploadCourseFormPdf({
    required File file,
    required String studentMatric,
    required String semester,
    required String session,
  }) async {
    // Build a clean folder path and filename
    // e.g. course_forms/U20_CSC_1045/2024_2025_First_Semester
    final sanitizedMatric = studentMatric.replaceAll('/', '_');
    final sanitizedSession = session.replaceAll('/', '_');
    final folder = 'smart_clearance/course_forms/$sanitizedMatric';
    final fileName =
        '${sanitizedSession}_${semester.replaceAll(' ', '_')}';

    return await _uploadFile(
      file: file,
      folder: folder,
      fileName: fileName,
      resourceType: 'raw', // PDF files use resource_type: raw in Cloudinary
    );
  }

  // ─── Upload Payment Receipt ───────────────────────────────────────────────
  Future<CloudinaryResult> uploadPaymentReceipt({
    required File file,
    required String studentMatric,
    required String rrr,
  }) async {
    final sanitizedMatric = studentMatric.replaceAll('/', '_');
    final folder = 'smart_clearance/receipts/$sanitizedMatric';
    final fileName = 'receipt_$rrr';

    return await _uploadFile(
      file: file,
      folder: folder,
      fileName: fileName,
      resourceType: 'image',
    );
  }

  // ─── Upload Profile Photo ─────────────────────────────────────────────────
  Future<CloudinaryResult> uploadProfilePhoto({
    required File file,
    required String userId,
  }) async {
    final folder = 'smart_clearance/profiles';
    final fileName = 'profile_$userId';

    return await _uploadFile(
      file: file,
      folder: folder,
      fileName: fileName,
      resourceType: 'image',
      // Apply transformation: resize to 400x400 and compress
      transformation: 'c_fill,g_face,h_400,w_400,q_auto',
    );
  }

  // ─── Upload QR Code Image ─────────────────────────────────────────────────
  Future<CloudinaryResult> uploadQrCode({
    required File file,
    required String formId,
  }) async {
    final folder = 'smart_clearance/qr_codes';
    final fileName = 'qr_$formId';

    return await _uploadFile(
      file: file,
      folder: folder,
      fileName: fileName,
      resourceType: 'image',
    );
  }

  // ─── Core Upload Function ─────────────────────────────────────────────────
  Future<CloudinaryResult> _uploadFile({
    required File file,
    required String folder,
    required String fileName,
    required String resourceType,
    String? transformation,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return CloudinaryResult(
          success: false,
          error: 'File not found. Please select the file again.',
        );
      }

      // Check file size (max 10MB for free plan)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return CloudinaryResult(
          success: false,
          error: 'File is too large. Maximum allowed size is 10MB.',
        );
      }

      final cloudinary = CldFlutter.instance;

      // Build the upload URL for unsigned uploads
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      // Use multipart form upload (works without API secret for unsigned presets)
      final request = await _buildMultipartRequest(
        uri: uri,
        file: file,
        folder: folder,
        fileName: fileName,
        transformation: transformation,
      );

      final streamedResponse = await request.send();
      final response = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        // Parse the Cloudinary response
        // The secure_url field contains the CDN URL of the uploaded file
        final urlMatch =
            RegExp(r'"secure_url":"([^"]+)"').firstMatch(response);
        final publicIdMatch =
            RegExp(r'"public_id":"([^"]+)"').firstMatch(response);

        if (urlMatch != null) {
          String url = urlMatch.group(1) ?? '';
          // Cloudinary escapes forward slashes in JSON, unescape them
          url = url.replaceAll(r'\/', '/');

          String publicId = publicIdMatch?.group(1) ?? '';
          publicId = publicId.replaceAll(r'\/', '/');

          return CloudinaryResult(
            success: true,
            url: url,
            publicId: publicId,
          );
        }
      }

      return CloudinaryResult(
        success: false,
        error: 'Upload failed. Server returned: ${streamedResponse.statusCode}',
      );
    } catch (e) {
      return CloudinaryResult(
        success: false,
        error: 'Upload failed. Please check your connection and try again.',
      );
    }
  }

  // ─── Build Multipart Request ──────────────────────────────────────────────
  Future<_MultipartRequest> _buildMultipartRequest({
    required Uri uri,
    required File file,
    required String folder,
    required String fileName,
    String? transformation,
  }) async {
    final request = _MultipartRequest('POST', uri);

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = folder;
    request.fields['public_id'] = fileName;

    if (transformation != null) {
      request.fields['transformation'] = transformation;
    }

    final fileBytes = await file.readAsBytes();
    final fileField = _MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: file.path.split('/').last,
    );

    request.files.add(fileField);

    return request;
  }

  // ─── Delete a File from Cloudinary ───────────────────────────────────────
  // Note: Deletion requires API secret which cannot be exposed in client apps
  // For MVP, we skip deletion. In production, do this via a backend function.
  // Unused files will be cleaned up via Cloudinary dashboard manually.

  // ─── Get Optimized Image URL ──────────────────────────────────────────────
  // Takes a Cloudinary URL and adds quality/resize transformations
  String getOptimizedImageUrl(String url, {int? width, int? height}) {
    if (!url.contains('cloudinary.com')) return url;

    final parts = url.split('/upload/');
    if (parts.length != 2) return url;

    String transformation = 'q_auto,f_auto';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';

    return '${parts[0]}/upload/$transformation/${parts[1]}';
  }
}

// ─── Cloudinary Result Wrapper ────────────────────────────────────────────────
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

  bool get hasUrl => success && url != null;
}

// ─── Minimal Multipart Helpers ────────────────────────────────────────────────
// We use dart:io HttpClient style classes here to avoid extra dependencies
// for simple multipart form uploads

class _MultipartRequest {
  final String method;
  final Uri url;
  final Map<String, String> fields = {};
  final List<_MultipartFile> files = [];
  final Map<String, String> headers = {};

  _MultipartRequest(this.method, this.url);

  Future<_StreamedResponse> send() async {
    final boundary = 'SmartClearanceBoundary${DateTime.now().millisecondsSinceEpoch}';
    final client = HttpClient();

    final request = await client.openUrl(method, url);
    request.headers.set(
      'Content-Type',
      'multipart/form-data; boundary=$boundary',
    );

    final bodyBytes = <int>[];

    // Add text fields
    for (final entry in fields.entries) {
      bodyBytes.addAll(
          '--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n'
              .codeUnits);
    }

    // Add files
    for (final file in files) {
      bodyBytes.addAll(
          '--$boundary\r\nContent-Disposition: form-data; name="${file.field}"; filename="${file.filename}"\r\nContent-Type: application/octet-stream\r\n\r\n'
              .codeUnits);
      bodyBytes.addAll(file.bytes);
      bodyBytes.addAll('\r\n'.codeUnits);
    }

    bodyBytes.addAll('--$boundary--\r\n'.codeUnits);

    request.contentLength = bodyBytes.length;
    request.add(bodyBytes);

    final response = await request.close();
    return _StreamedResponse(response);
  }
}

class _MultipartFile {
  final String field;
  final List<int> bytes;
  final String filename;

  _MultipartFile.fromBytes(this.field, this.bytes, {required this.filename});
}

class _StreamedResponse {
  final HttpClientResponse _response;

  _StreamedResponse(this._response);

  int get statusCode => _response.statusCode;

  Future<String> get stream async {
    final buffer = StringBuffer();
    await for (final chunk in _response.transform(
      const SystemEncoding().decoder,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  // Alias to match usage above
  Future<String> bytesToString() => stream;
}
