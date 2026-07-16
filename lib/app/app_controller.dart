import "dart:async";

import "package:dartz/dartz.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:help_out/app/app_constants.dart";
import "package:help_out/app/app_navigator.dart";
import "package:help_out/app/app_routes.dart";
import "package:help_out/core/domain/entities/app_config_entity.dart";
import "package:help_out/core/domain/errors/app_error.dart";
import "package:help_out/core/domain/use_cases/fetch_profile_from_backend_use_case.dart";
import "package:help_out/core/domain/use_cases/get_app_config_use_case.dart";
import "package:help_out/core/domain/use_cases/save_app_config_use_case.dart";
import "package:help_out/core/domain/use_cases/sync_profile_to_backend_use_case.dart";
import "package:help_out/core/services/local_storage/app_local_storage_service.dart";
import "package:help_out/core/services/sync/sync_service.dart";
import "package:help_out/theme/accent_presets.dart";

class AppController extends GetxController with WidgetsBindingObserver {
  AppController({
    required this._getAppConfigUseCase,
    required this._saveAppConfigUseCase,
    required this._syncProfileToBackendUseCase,
    required this._appNavigator,
    required this._syncService,
    required this._fetchProfileFromBackendUseCase,
    required this._localStorageService,
  });

  final GetAppConfigUseCase _getAppConfigUseCase;
  final SaveAppConfigUseCase _saveAppConfigUseCase;
  final SyncProfileToBackendUseCase _syncProfileToBackendUseCase;
  final AppNavigator _appNavigator;
  final SyncService _syncService;
  final FetchProfileFromBackendUseCase _fetchProfileFromBackendUseCase;
  final AppLocalStorageService _localStorageService;

  final RxBool isDarkMode = false.obs;
  final Rx<Color> accentColor = AppAccentPresets.defaultAccent.obs;
  final RxString userName = "".obs;
  final RxString nickName = "".obs;
  final Rx<String?> email = Rx<String?>(null);
  final Rx<String?> phoneNumber = Rx<String?>(null);
  final Rx<String?> birthDate = Rx<String?>(null);
  final RxInt avatarIconIndex = 0.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxString languageCode = "en".obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (userName.value.isEmpty) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        _syncService.pull();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _syncService.push();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> initialize() async {
    await Future.wait([_loadAppConfig(), Future.delayed(AppConstants.splashScreenDuration)]);
    await _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    if (userName.value.isEmpty) {
      await _appNavigator.offAllNamed(AppRoutes.login);
    } else {
      await _appNavigator.offAllNamed(AppRoutes.mainNavigation);
      unawaited(_syncService.pull());
    }
  }

  /// Called right after phone verification confirms an existing account, so a
  /// reinstall/new device picks up the profile the backend already has
  /// instead of showing an empty one until the next manual edit.
  Future<void> reloadProfileFromBackend() async {
    final Either<AppError, AppConfigEntity> result = await _fetchProfileFromBackendUseCase();
    await result.fold((error) async {}, (config) async {
      _applyConfig(config);
      await _saveAppConfigUseCase(config);
    });
  }

  Future<void> _loadAppConfig() async {
    final Either<AppError, AppConfigEntity> result = await _getAppConfigUseCase();
    result.fold((error) => null, _applyConfig);
  }

  void _applyConfig(AppConfigEntity config) {
    isDarkMode.value = config.isDarkMode;
    accentColor.value = Color(config.accentColorValue);
    userName.value = config.userName;
    nickName.value = config.nickName;
    email.value = config.email;
    phoneNumber.value = config.phoneNumber;
    birthDate.value = config.birthDate;
    avatarIconIndex.value = config.avatarIconIndex;
    notificationsEnabled.value = config.notificationsEnabled;
    languageCode.value = config.languageCode;
    // The saved language only reaches here after GetMaterialApp's first
    // build (see the comment in setLanguageCode), so it must be applied
    // explicitly too, not just left to the `locale:` constructor param.
    Get.updateLocale(Locale(config.languageCode));
  }

  AppConfigEntity get _currentConfig => AppConfigEntity(
    isDarkMode: isDarkMode.value,
    userName: userName.value,
    nickName: nickName.value,
    email: email.value,
    phoneNumber: phoneNumber.value,
    birthDate: birthDate.value,
    accentColorValue: accentColor.value.toARGB32(),
    avatarIconIndex: avatarIconIndex.value,
    notificationsEnabled: notificationsEnabled.value,
    languageCode: languageCode.value,
  );

  Future<void> setDarkMode(bool value) async {
    isDarkMode.value = value;
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<void> setAccentColor(Color value) async {
    accentColor.value = value;
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<void> setUserName(String value) async {
    userName.value = value;
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<void> setAvatarIconIndex(int value) async {
    avatarIconIndex.value = value;
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<void> setLanguageCode(String value) async {
    languageCode.value = value;
    // GetMaterialApp only reads its `locale:` constructor param once, on the
    // very first build (see GetBuilder<GetMaterialController>'s initState in
    // the get package) — later rebuilds with a new `locale:` value are
    // ignored. Get.updateLocale is GetX's own API for propagating a runtime
    // locale change and forcing the app to rebuild with it.
    await Get.updateLocale(Locale(value));
    await _saveAppConfigUseCase(_currentConfig);
  }

  Future<Either<AppError, void>> updateProfile({
    required String userName,
    required String nickName,
    String? email,
    String? phoneNumber,
    String? birthDate,
  }) async {
    this.userName.value = userName;
    this.nickName.value = nickName;
    this.email.value = email;
    this.phoneNumber.value = phoneNumber;
    this.birthDate.value = birthDate;

    await _saveAppConfigUseCase(_currentConfig);
    return _syncProfileToBackendUseCase(_currentConfig);
  }

  Future<void> logOut() async {
    userName.value = "";
    nickName.value = "";
    email.value = null;
    phoneNumber.value = null;
    birthDate.value = null;
    avatarIconIndex.value = 0;
    // Wipes auth tokens and sync bookkeeping too, so a different account
    // logging in on this device doesn't inherit stale credentials or merge
    // its data with what the previous account had synced.
    await _localStorageService.clearStorage();
    await _saveAppConfigUseCase(_currentConfig);
    await _appNavigator.offAllNamed(AppRoutes.login);
  }
}
