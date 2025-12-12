import 'package:get/get.dart';

class LoadingController extends GetxController {
  bool _isLoading = false;
  bool get isLoading {
    return _isLoading;
  }

  setIsLoading({required isLoading}) {
    _isLoading = isLoading;
    update();
  }

  Future setLoadingAsync(Future Function() job) async {
    setIsLoading(isLoading: true);
    final result = await job();
    setIsLoading(isLoading: false);
    return result;
  }

  setIsLoadingAsync({required Future Function() wait}) async {
    if (!_isLoading) {
      _isLoading = true;
      update();
    }
    await wait();
    if (_isLoading) {
      _isLoading = false;
      update();
    }
  }

  toggle() {
    _isLoading = !_isLoading;
    update();
  }
}
