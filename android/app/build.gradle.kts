import java.util.Properties


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.antidoom"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.antidoom"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing comes from android/key.properties (gitignored). Without it,
    // release builds fall back to the debug key so `flutter run --release` works.
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // Two builds from one codebase:
    //   foss: GitHub/F-Droid. No ads, no purchases, no internet permission.
    //   play: Google Play. AdMob banner + one "Remove ads" purchase.
    // Pick one with `flutter run --flavor foss` / `flutter build appbundle --flavor play`.
    flavorDimensions += "distribution"
    productFlavors {
        create("foss") {
            dimension = "distribution"
        }
        create("play") {
            dimension = "distribution"
            // AdMob IDs from android/admob.properties (gitignored):
            //   admobAppId=ca-app-pub-...~...     admobBannerId=ca-app-pub-.../...
            // or the ADMOB_APP_ID / ADMOB_BANNER_ID env vars in CI. Without them,
            // Google's public test IDs are used, so dev builds never show live ads.
            val admobProperties = Properties()
            val admobFile = rootProject.file("admob.properties")
            if (admobFile.exists()) admobFile.inputStream().use { admobProperties.load(it) }
            manifestPlaceholders["admobAppId"] =
                (admobProperties["admobAppId"] as String?)
                    ?: System.getenv("ADMOB_APP_ID")
                    ?: "ca-app-pub-3940256099942544~3347511713"
            // Read by the app at runtime (MainActivity "admobBannerId").
            resValue(
                "string",
                "admob_banner_id",
                (admobProperties["admobBannerId"] as String?)
                    ?: System.getenv("ADMOB_BANNER_ID")
                    ?: "ca-app-pub-3940256099942544/6300978111",
            )
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
