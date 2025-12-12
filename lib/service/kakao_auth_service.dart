import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:newdfd/utils/app_logger.dart';

class KakaoAuthService {
  static final KakaoAuthService shared = KakaoAuthService._internal();
  KakaoAuthService._internal();

  Future<Map<String, dynamic>?> signInWithKakao() async {
    try {
      print('🔵 카카오톡 설치 확인 중...');
      bool isInstalled = await isKakaoTalkInstalled();
      print('🔵 카카오톡 설치됨: $isInstalled');

      OAuthToken token;

      print('🔵 로그인 시작 직전');

      if (isInstalled) {
        try {
          print('🔵 카카오톡으로 로그인 시작');
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          print('🟡 카카오톡 로그인 실패, 카카오 계정으로 재시도');
          // 카카오톡 로그인 실패 시 웹 로그인으로 fallback
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        print('🔵 카카오 계정으로 로그인 시작');
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      print('🔵 로그인 완료! await 통과함');
      print('🔵 토큰: ${token.accessToken.substring(0, 20)}...');

      print('🔵 사용자 정보 요청 중...');
      User user = await UserApi.instance.me();
      print('🔵 사용자 정보 받음: ${user.id}');

      return {
        'provider': 'kakao',
        'kakao_user_id': user.id.toString(),
        'email': user.kakaoAccount?.email ?? '',
        'nickname': user.kakaoAccount?.profile?.nickname ?? '',
        'profile_image': user.kakaoAccount?.profile?.profileImageUrl ?? '',
        'phone_number': user.kakaoAccount?.phoneNumber ?? '',
        'access_token': token.accessToken,
      };

    } catch (error) {
      print('🔴 카카오 로그인 실패!!!');
      print('🔴 에러 타입: ${error.runtimeType}');
      print('🔴 에러 내용: $error');
      return null;
    }
  }

  // 카카오 로그아웃
  Future<bool> signOut() async {
    try {
      await UserApi.instance.logout();
      logSuccess('카카오 로그아웃 성공', name: 'KAKAO_LOGIN');
      return true;
    } catch (error) {
      logError('카카오 로그아웃 실패: $error', name: 'KAKAO_LOGIN');
      return false;
    }
  }

  // 카카오 연결 끊기 (회원 탈퇴 시 사용)
  Future<bool> unlink() async {
    try {
      await UserApi.instance.unlink();
      logSuccess('카카오 연결 끊기 성공', name: 'KAKAO_LOGIN');
      return true;
    } catch (error) {
      logError('카카오 연결 끊기 실패: $error', name: 'KAKAO_LOGIN');
      return false;
    }
  }
}