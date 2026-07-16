import "package:dartz/dartz.dart";
import "package:help_out/core/data/http_requests/group_http_requests.dart";
import "package:help_out/core/domain/entities/friend_option.dart";
import "package:help_out/core/domain/entities/group_entity.dart";
import "package:help_out/core/domain/enums/group_theme_type.dart";
import "package:help_out/core/domain/errors/app_error.dart";
import "package:help_out/core/services/http/http_client_service.dart";

class GroupsDataSource {
  GroupsDataSource({required this._httpClientService});

  final HttpClientService _httpClientService;

  Future<Either<AppError, List<GroupEntity>>> getGroups() async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(GetGroupsHttpRequest());

    return result.fold(Left.new, (data) {
      final List<dynamic> groups = data["groups"] as List<dynamic>? ?? [];
      return Right(groups.map((item) => GroupEntity.fromMap(item as Map<String, dynamic>)).toList());
    });
  }

  Future<Either<AppError, List<FriendOption>>> getInvitableFriends() async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(GetFriendsHttpRequest());

    return result.fold(Left.new, (data) {
      final List<dynamic> friends = data["friends"] as List<dynamic>? ?? [];
      return Right(
        friends
            .map(
              (item) => (
                id: (item as Map<String, dynamic>)["id"] as String,
                name: item["name"] as String,
              ),
            )
            .toList(),
      );
    });
  }

  Future<Either<AppError, void>> addFriend(String phoneNumber) async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(
      AddFriendHttpRequest(phoneNumber: phoneNumber),
    );
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<Either<AppError, GroupEntity>> createGroup({
    required String name,
    required GroupThemeType theme,
    required List<FriendOption> invitedFriends,
  }) async {
    final Either<AppError, Map<String, dynamic>> result = await _httpClientService.request(
      CreateGroupHttpRequest(
        name: name,
        theme: theme.name,
        memberIds: invitedFriends.map((friend) => friend.id).toList(),
      ),
    );

    return result.fold(Left.new, (data) => Right(GroupEntity.fromMap(data)));
  }
}
