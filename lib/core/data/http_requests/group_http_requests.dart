import "package:help_out/core/domain/enums/http_method.dart";
import "package:help_out/core/services/http/app_http_request.dart";

class GetFriendsHttpRequest extends AppHttpRequest {
  @override
  String get path => "/friends";

  @override
  HttpMethod get method => HttpMethod.get;
}

class AddFriendHttpRequest extends AppHttpRequest {
  AddFriendHttpRequest({required this.phoneNumber});

  final String phoneNumber;

  @override
  String get path => "/friends";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => {"phoneNumber": phoneNumber};
}

class GetGroupsHttpRequest extends AppHttpRequest {
  @override
  String get path => "/groups";

  @override
  HttpMethod get method => HttpMethod.get;
}

class CreateGroupHttpRequest extends AppHttpRequest {
  CreateGroupHttpRequest({required this.name, required this.theme, required this.memberIds});

  final String name;
  final String theme;
  final List<String> memberIds;

  @override
  String get path => "/groups";

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic>? get body => {"name": name, "theme": theme, "memberIds": memberIds};
}
