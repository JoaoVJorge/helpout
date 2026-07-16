import "package:help_out/core/domain/enums/http_method.dart";
import "package:help_out/core/services/http/app_http_request.dart";

class RequestOtpHttpRequest extends AppHttpRequest {
  RequestOtpHttpRequest({required this.phoneNumber});

  final String phoneNumber;

  @override
  String get path => "/auth/otp/request";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => {"phoneNumber": phoneNumber};
}

class VerifyOtpHttpRequest extends AppHttpRequest {
  VerifyOtpHttpRequest({required this.phoneNumber, required this.code});

  final String phoneNumber;
  final String code;

  @override
  String get path => "/auth/otp/verify";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => {"phoneNumber": phoneNumber, "code": code};
}

class RefreshTokenHttpRequest extends AppHttpRequest {
  RefreshTokenHttpRequest({required this.refreshToken});

  final String refreshToken;

  @override
  String get path => "/auth/refresh";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => {"refreshToken": refreshToken};
}
