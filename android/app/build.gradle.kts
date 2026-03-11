plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter plugin (keep this)
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 ADD THIS LINE
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.lifeline"
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
        applicationId = "com.example.lifeline"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {

    // 🔥 Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))

    // 🔥 Firebase Products
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

flutter {
    source = "../.."
}