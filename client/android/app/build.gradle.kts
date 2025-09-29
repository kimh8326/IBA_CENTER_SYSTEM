plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pilates.center.client"
    compileSdk = flutter.compileSdkVersion
    // NDK 비활성화 - 순수 Dart/Flutter 앱으로 빌드

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.pilates.center.client"
        minSdk = 21  // Android 5.0 이상 지원
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // NDK 관련 설정 제거
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
