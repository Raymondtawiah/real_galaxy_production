plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.enochsarkodie.realgalaxyfc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.enochsarkodie.realgalaxyfc"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Production signing configuration
            signingConfig = signingConfigs.create("release") {
                storeFile = file("real-galaxy-key.keystore")
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "realgalaxyfc26"
                keyAlias = System.getenv("KEY_ALIAS") ?: "real-galaxy"
                keyPassword = System.getenv("KEYSTORE_PASSWORD") ?: "realgalaxyfc26"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}

flutter {
    source = "../.."
}
