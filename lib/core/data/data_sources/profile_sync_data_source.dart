import "package:dartz/dartz.dart";
import "package:help_out/core/data/http_requests/profile_http_requests.dart";
import "package:help_out/core/domain/entities/app_config_entity.dart";
import "package:help_out/core/domain/errors/app_error.dart";
import "package:help_out/core/services/http/http_client_service.dart";

class ProfileSyncDataSource {
  ProfileSyncDataSource({required this._httpClientService});

  final HttpClientService _httpClientService;

  Future<Either<AppError, void>> syncProfile(AppConfigEntity config) async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(
      UpdateProfileHttpRequest(config: config),
    );
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<Either<AppError, AppConfigEntity>> fetchProfile() async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(GetProfileHttpRequest());
    return result.fold(Left.new, (data) => Right(AppConfigEntity.fromMap(data)));
  }
}
