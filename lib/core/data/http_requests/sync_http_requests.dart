import "package:help_out/core/domain/enums/http_method.dart";
import "package:help_out/core/services/http/app_http_request.dart";

class SyncPullHttpRequest extends AppHttpRequest {
  SyncPullHttpRequest({this.since});

  final String? since;

  @override
  String get path => "/sync";

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  Map<String, dynamic> get queryParameters => since == null ? {} : {"since": since};
}

class SyncPushHttpRequest extends AppHttpRequest {
  SyncPushHttpRequest({required this.payload});

  final Map<String, dynamic> payload;

  @override
  String get path => "/sync";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => payload;
}
