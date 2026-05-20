import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';

class PairingService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> claimDevice({
    required String pairingCode,
    required String farmId,
    String? zoneId,
    String? nodeLabel,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/pairing/claim',
        data: {
          'pairing_code': pairingCode,
          'farm_id': farmId,
          'zone_id': zoneId,
          'node_label': nodeLabel,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to pair device';
    }
  }
}
