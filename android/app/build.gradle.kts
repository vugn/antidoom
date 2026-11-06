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
            // AdMob app ID from android/admob.properties (gitignored) or the
            // ADMOB_APP_ID env var in CI; falls back to Google's public test ID.
            val admobProperties = Properties()
            val admobFile = rootProject.file("admob.properties")
            if (admobFile.exists()) admobFile.inputStream().use { admobProperties.load(it) }
            manifestPlaceholders["admobAppId"] =
                (admobProperties["admobAppId"] as String?)
                    ?: System.getenv("ADMOB_APP_ID")
                    ?: "ca-app-pub-3940256099942544~3347511713"
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
