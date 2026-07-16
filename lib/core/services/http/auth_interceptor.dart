import "package:dio/dio.dart";
import "package:help_out/core/services/local_storage/app_local_storage_service.dart";
import "package:help_out/core/services/local_storage/local_storage_keys.dart";

/// Attaches the stored access token to every non-auth request and transparently
/// refreshes it on a 401 using the stored refresh token, retrying the original
/// request once. Keeps token handling out of every data source.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._dio, required this._localStorageService});

  final Dio _dio;
  final AppLocalStorageService _localStorageService;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.startsWith("/auth")) {
      final String? token = await _localStorageService.read<String?>(LocalStorageKeys.accessToken);
      if (token != null) {
        options.headers["Authorization"] = "Bearer $token";
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final bool isUnauthorized = err.response?.statusCode == 401;
    final bool isAuthPath = err.requestOptions.path.startsWith("/auth");

    if (!isUnauthorized || isAuthPath || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final String? refreshToken = await _localStorageService.read<String?>(LocalStorageKeys.refreshToken);
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      final Response<Map<String, dynamic>> refreshResponse = await _dio.post<Map<String, dynamic>>(
        "/auth/refresh",
        data: {"refreshToken": refreshToken},
      );
      final Map<String, dynamic>? body = refreshResponse.data?["data"] as Map<String, dynamic>?;
      final String? newAccessToken = body?["accessToken"] as String?;
      final String? newRefreshToken = body?["refreshToken"] as String?;
      if (newAccessToken == null || newRefreshToken == null) {
        handler.next(err);
        return;
      }

      await _localStorageService.write(LocalStorageKeys.accessToken, newAccessToken);
      await _localStorageService.write(LocalStorageKeys.refreshToken, newRefreshToken);

      final RequestOptions retryOptions = err.requestOptions;
      retryOptions.headers["Authorization"] = "Bearer $newAccessToken";
      final Response<dynamic> retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
