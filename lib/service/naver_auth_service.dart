import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:newdfd/utils/app_logger.dart';

class NaverAuthService {
  static final NaverAuthService shared = NaverAuthService._internal();
  NaverAuthService._internal();

  // 네이버 로그인 (앱만)
  Future<Map<String, dynamic>?> signInWithNaver() async {
    try {
      print('🟢🟢🟢 네이버 로그인 함수 시작');
      logInfo('네이버 로그인 시작', name: 'NAVER_LOGIN');

      // 1. 로그인 수행
      final NaverLoginResult result = await FlutterNaverLogin.logIn();

      print('🟢 네이버 로그인 결과 Status: ${result.status}');

      if (result.status == NaverLoginStatus.loggedIn) {

        // ★ [핵심 수정] result 변수 대신, 현재 토큰을 강제로 다시 조회합니다.
        // 일부 상황에서 로그인 결과 객체(result) 안의 토큰이 비어있는 문제를 방지합니다.
        NaverAccessToken resToken = await FlutterNaverLogin.currentAccessToken;
        String token = resToken.accessToken;

        // [DEBUG] 토큰 확인
        print("------- [DEBUG] Flutter Naver Token Check (재조회) -------");
        print("Token Type: ${resToken.tokenType}");
        print("Token Value: $token");
        print("-------------------------------------------------");

        if (token.isNotEmpty) {
          return {
            'access_token': token,  // PHP 핸들러가 찾는 키 이름 (access_token)
            'expiresAt': resToken.expiresAt,
            'tokenType': resToken.tokenType,
            'email': result.account.email,
            'name': result.account.name
          };
        } else {
          print("Error: 재조회했으나 토큰이 여전히 비어있음. (strings.xml 설정 확인 필요)");
          return null;
        }
      } else {
        print("Error: 네이버 로그인 실패 / 취소. Status: ${result.status}");
        print("Msg: ${result.errorMessage}");
        return null;
      }

    } catch (error) {
      print('🔴🔴🔴 네이버 로그인 에러: $error');
      return null;
    }
  }

  // 네이버 로그아웃
  Future<bool> signOut() async {
    try {
      await FlutterNaverLogin.logOut();
      logSuccess('네이버 로그아웃 성공', name: 'NAVER_LOGIN');
      return true;
    } catch (error) {
      logError('네이버 로그아웃 실패: $error', name: 'NAVER_LOGIN');
      return false;
    }
  }
}