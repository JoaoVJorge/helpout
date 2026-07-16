import "package:dartz/dartz.dart";
import "package:help_out/core/data/repositories/profile_sync_repository.dart";
import "package:help_out/core/domain/entities/app_config_entity.dart";
import "package:help_out/core/domain/errors/app_error.dart";

class FetchProfileFromBackendUseCase {
  FetchProfileFromBackendUseCase({required this._profileSyncRepository});

  final ProfileSyncRepository _profileSyncRepository;

  Future<Either<AppError, AppConfigEntity>> call() => _profileSyncRepository.fetchProfile();
}
