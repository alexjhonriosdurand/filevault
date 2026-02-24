import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UploadResult {
  final bool success;
  final String? url;
  final String serviceName;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    required this.serviceName,
    this.error,
  });
}

class UploadService {
  // Selecciona el mejor servicio según el tamaño del archivo
  static Future<UploadResult> uploadSmart(
    String filePath,
    String fileName,
    int fileSize, {
    required Function(double) onProgress,
  }) async {
    // < 500 GB → intentar Catbox primero (permanente)
    // < 5 GB  → intentar Litterbox o Filebin
    // cualquier tamaño → Filebin o Transfer.sh como fallback

    final services = _getServicesForSize(fileSize);

    for (final service in services) {
      try {
        onProgress(0.05);
        final result = await _uploadToService(
          service, filePath, fileName, fileSize, onProgress,
        );
        if (result.success) return result;
      } catch (_) {}
    }

    return UploadResult(
      success: false,
      serviceName: 'Ninguno',
      error: 'Todos los servicios fallaron. Revisa tu conexión.',
    );
  }

  static List<String> _getServicesForSize(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb <= 500) return ['catbox', 'litterbox', 'filebin', 'transfersh'];
    if (gb <= 5) return ['litterbox', 'filebin', 'transfersh'];
    return ['filebin', 'transfersh'];
  }

  static Future<UploadResult> _uploadToService(
    String service,
    String filePath,
    String fileName,
    int fileSize,
    Function(double) onProgress,
  ) async {
    switch (service) {
      case 'catbox':
        return await _uploadCatbox(filePath, fileName, onProgress);
      case 'filebin':
        return await _uploadFilebin(filePath, fileName, onProgress);
      case 'transfersh':
        return await _uploadTransferSh(filePath, fileName, onProgress);
      case 'litterbox':
        return await _uploadLitterbox(filePath, fileName, onProgress);
      default:
        return UploadResult(success: false, serviceName: service, error: 'Servicio desconocido');
    }
  }

  // ─── Catbox.moe (200MB, permanente) ───────────────────────────────────────
  static Future<UploadResult> _uploadCatbox(
    String filePath, String fileName, Function(double) onProgress,
  ) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://catbox.moe/user.php'),
    );
    request.fields['reqtype'] = 'fileupload';
    request.files.add(await http.MultipartFile.fromPath(
      'fileToUpload', filePath,
      contentType: MediaType.parse(mimeType),
      filename: fileName,
    ));

    onProgress(0.3);
    final response = await request.send();
    final body = await response.stream.bytesToString();
    onProgress(1.0);

    if (response.statusCode == 200 && body.startsWith('https://')) {
      return UploadResult(success: true, url: body.trim(), serviceName: 'Catbox.moe');
    }
    return UploadResult(success: false, serviceName: 'Catbox.moe', error: body);
  }

  // ─── Litterbox (1GB, hasta 72h) ───────────────────────────────────────────
  static Future<UploadResult> _uploadLitterbox(
    String filePath, String fileName, Function(double) onProgress,
  ) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://litterbox.catbox.moe/resources/internals/api.php'),
    );
    request.fields['reqtype'] = 'fileupload';
    request.fields['time'] = '72h';
    request.files.add(await http.MultipartFile.fromPath(
      'fileToUpload', filePath,
      contentType: MediaType.parse(mimeType),
      filename: fileName,
    ));

    onProgress(0.3);
    final response = await request.send();
    final body = await response.stream.bytesToString();
    onProgress(1.0);

    if (response.statusCode == 200 && body.startsWith('https://')) {
      return UploadResult(success: true, url: body.trim(), serviceName: 'Litterbox (72h)');
    }
    return UploadResult(success: false, serviceName: 'Litterbox', error: body);
  }

  // ─── Filebin.net (sin límite, 6 días) ────────────────────────────────────
  static Future<UploadResult> _uploadFilebin(
    String filePath, String fileName, Function(double) onProgress,
  ) async {
    final binId = _randomBinId();
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    onProgress(0.4);

    final response = await http.post(
      Uri.parse('https://filebin.net/$binId/$fileName'),
      headers: {
        'Content-Type': mimeType,
        'Accept': 'application/json',
      },
      body: bytes,
    );

    onProgress(1.0);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final url = 'https://filebin.net/$binId/$fileName';
      return UploadResult(success: true, url: url, serviceName: 'Filebin (6 días)');
    }
    return UploadResult(
      success: false, serviceName: 'Filebin',
      error: 'Status: ${response.statusCode}',
    );
  }

  // ─── Transfer.sh (sin límite, 14 días) ───────────────────────────────────
  static Future<UploadResult> _uploadTransferSh(
    String filePath, String fileName, Function(double) onProgress,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    onProgress(0.4);

    final response = await http.put(
      Uri.parse('https://transfer.sh/$fileName'),
      headers: {'Content-Type': mimeType},
      body: bytes,
    );

    onProgress(1.0);

    if (response.statusCode == 200) {
      return UploadResult(
        success: true,
        url: response.body.trim(),
        serviceName: 'Transfer.sh (14 días)',
      );
    }
    return UploadResult(
      success: false, serviceName: 'Transfer.sh',
      error: 'Status: ${response.statusCode}',
    );
  }

  static String _randomBinId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
