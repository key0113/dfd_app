import 'dart:developer';
import 'package:get/get.dart';
import 'package:newdfd/controller/loading_controller.dart';

class SharedController extends GetxService {
  static SharedController get manager {
    return Get.find<SharedController>();
  }

  SharedController() {
    Get.put(LoadingController());
    log('SharedController', name: 'SharedController init');
  }

  static LoadingController get loadingController {
    return Get.find<LoadingController>();
  }
}
