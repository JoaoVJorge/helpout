import "package:dartz/dartz.dart";
import "package:help_out/core/data/http_requests/auth_http_requests.dart";
import "package:help_out/core/domain/entities/phone_verify_result.dart";
import "package:help_out/core/domain/errors/app_error.dart";
import "package:help_out/core/services/http/http_client_service.dart";
import "package:help_out/core/services/local_storage/app_local_storage_service.dart";
import "package:help_out/core/services/local_storage/local_storage_keys.dart";

class PhoneAuthDataSource {
  PhoneAuthDataSource({required this._httpClientService, required this._localStorageService});

  final HttpClientService _httpClientService;
  final AppLocalStorageService _localStorageService;

  Future<Either<AppError, void>> requestCode(String phoneNumber) async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(
      RequestOtpHttpRequest(phoneNumber: phoneNumber),
    );
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<Either<AppError, PhoneVerifyResult>> verifyCode({
    required String phoneNumber,
    required String code,
  }) async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(
      VerifyOtpHttpRequest(phoneNumber: phoneNumber, code: code),
    );

    return result.fold((error) async => Left(error), (data) async {
      final String accessToken = data["accessToken"] as String;
      final String refreshToken = data["refreshToken"] as String;
      final bool hasProfile = data["hasProfile"] as bool? ?? false;

      await _localStorageService.write(LocalStorageKeys.accessToken, accessToken);
      await _localStorageService.write(LocalStorageKeys.refreshToken, refreshToken);

      return Right((isValid: true, hasProfile: hasProfile));
    });
  }
}
