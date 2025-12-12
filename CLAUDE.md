# dfd 하이브리드 앱 마이그레이션 프로젝트

## 프로젝트 목표
showgle(A 업체)의 Flutter 앱을 복사하여 DFD(B 업체)용 앱으로 변환

## 작업 환경 및 상황
- **작업자**: 은영 (PHP/CI 웹 개발자, 앱 개발 경험 없음)
- **팀 구성**: 1인 개발 (웹/앱 모두 담당)
- **Git 사용**: ❌ 사용 안 함 (수동 백업으로 관리)
- **현재 상황**: 
  - A업체 앱은 정상 작동 중
  - B업체 웹사이트 운영 중 (PHP/CI)
  - 기존 B업체 앱이 너무 오래되어 리뉴얼 필요

## 기술 스택
- **Flutter**: 3.7.12 (FVM 사용, 버전 변경 금지)
- **Dart**: 2.19.6
- **웹**: PHP, CodeIgniter, MySQL
- **주요 패키지**:
  - flutter_inappwebview: 웹뷰
  - firebase_messaging: 푸시 알림
  - firebase_dynamic_links: 딥링크
  - get: 상태 관리

## 프로젝트 구조
```
작업폴더/
├── A_app_original/         # ⚠️ 원본 A앱 (절대 수정 금지)
├── B_app/                  # 🔧 현재 작업 중인 폴더
├── B_app_backup_20250117_1000/  # 백업1: 최초 복사본
├── B_app_backup_20250117_1400/  # 백업2: 패키지명 변경 후
├── B_app_working_v1/       # ✅ 잘 돌아가는 버전
└── B_app_final/           # 🎉 최종 완성본

B_app/ 내부 구조:
├── .env                    # 환경변수 (BASE_URL, APP_NAME 등)
├── pubspec.yaml           # 프로젝트 설정, 패키지 의존성
├── lib/
│   ├── main.dart          # 앱 진입점
│   └── (웹뷰, Firebase 관련 코드들)
├── android/
│   └── app/
│       ├── build.gradle   # applicationId 설정
│       ├── google-services.json  # Firebase 설정
│       └── src/main/
│           ├── AndroidManifest.xml  # 패키지명, 권한
│           └── res/values/strings.xml  # 앱 이름
└── ios/
    └── Runner/
        ├── Info.plist     # iOS 앱 설정
        └── GoogleService-Info.plist  # Firebase 설정
```

## ✅ 작업 체크리스트

### 📝 1단계: 텍스트 일괄 변경
- [ ] URL 변경: `https://sgm.showgle.co.kr/` → `https://mapp.dfdgroup.com/`
- [ ] 회사명: `showgle` → `dfd`
- [ ] 앱 이름: `showgle` → `dfd`
- [ ] 패키지명: `com.mylabs.app.newshowgle` → `com.newdfd.membership`

### 📄 2단계: 설정 파일 수정
- [ ] `.env` 파일
```
  BASE_URL=https://mapp.dfdgroup.com/
  APP_NAME=dfd
```
- [ ] `pubspec.yaml`
```yaml
  name: b_company_app  # newshowgle에서 변경
  description: B Company App
```
- [ ] `android/app/build.gradle`
```gradle
  applicationId "com.newdfd.membership"
```

## 💾 백업 전략 (Git 없음)

### 백업 시점
1. **작업 시작 전**: 원본 보존
2. **큰 변경 전**: 단계별 백업
3. **성공 버전**: 따로 보관

### 백업 명령어
```bash
# 백업 생성
cp -r dfd_app/ dfd_app_backup_$(date +%Y%m%d_%H%M)/

# 백업에서 복구
rm -rf dfd_app/
cp -r dfd_app_backup_20250117_1400/ dfd_app/

# 중요 파일만 백업
cp .env .env.backup
cp android/app/build.gradle build.gradle.backup
```

## ⚠️ 절대 하면 안 되는 것들
1. ❌ Flutter 버전 업그레이드
2. ❌ 패키지 버전 변경 (pubspec.yaml)
3. ❌ 백업 없이 대량 수정
4. ❌ showgle_app_original 폴더 수정
5. ❌ 핵심 로직 코드 수정

## 📋 변경 이력 (CHANGES.md)
매 작업마다 아래 형식으로 기록:
```
## 2025-01-17 15:00
- 작업: 패키지명 변경
- 변경 파일: build.gradle, AndroidManifest.xml
- 백업 위치: dff_app_backup_20250117_1500/
- 테스트 결과: 빌드 성공, 실행 정상
```