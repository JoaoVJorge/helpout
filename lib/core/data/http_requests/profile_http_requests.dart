import "package:help_out/core/domain/entities/app_config_entity.dart";
import "package:help_out/core/domain/enums/http_method.dart";
import "package:help_out/core/services/http/app_http_request.dart";

class GetProfileHttpRequest extends AppHttpRequest {
  @override
  String get path => "/users/me";

  @override
  HttpMethod get method => HttpMethod.get;
}

class UpdateProfileHttpRequest extends AppHttpRequest {
  UpdateProfileHttpRequest({required this.config});

  final AppConfigEntity config;

  @override
  String get path => "/users/me";

  @override
  HttpMethod get method => HttpMethod.put;

  @override
  Map<String, dynamic>? get body => {
    "userName": config.userName,
    "nickName": config.nickName,
    "email": config.email,
    "birthDate": config.birthDate,
    "accentColorValue": config.accentColorValue,
    "avatarIconIndex": config.avatarIconIndex,
    "notificationsEnabled": config.notificationsEnabled,
    "languageCode": config.languageCode,
    "isDarkMode": config.isDarkMode,
  };
}
