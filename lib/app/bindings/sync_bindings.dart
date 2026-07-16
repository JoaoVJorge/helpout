import "package:get/get.dart";
import "package:help_out/core/services/sync/sync_service.dart";

class SyncBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SyncService>(
      SyncService(
        httpClientService: Get.find(),
        subjectsRepository: Get.find(),
        dailyTasksRepository: Get.find(),
        scheduleRepository: Get.find(),
        localStorageService: Get.find(),
      ),
      permanent: true,
    );
  }
}
