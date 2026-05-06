plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
    // For Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.urbanpulse.app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.urbanpulse.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    
    // 1. Authentication (For Sign-in/Sign-up)
    implementation("com.google.firebase:firebase-auth")

    // 2. Cloud Storage (For uploading report images)
    implementation("com.google.firebase:firebase-storage")

    // 3. Cloud Messaging (For Live Notifications/Status Updates)
    implementation("com.google.firebase:firebase-messaging")

    // Add the SDK for Google Analytics
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
