import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Runs each Patrol test in its own instrumentation process.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

// Release signing comes from android/key.properties (git-ignored). Without it
// the release build falls back to the debug key so local builds keep working.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.ournego.app"
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
        applicationId = "com.ournego.app"
        manifestPlaceholders["appName"] = "Ournego"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // clearPackageData is left off on purpose: with it the runner wipes the
        // data of the app installed on the device between tests.
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // Profile signs with the release key on purpose: Google Sign-In only
        // accepts the SHA-1 fingerprints registered as Android OAuth clients,
        // and the debug key (different on every machine) is not one of them.
        // Without key.properties both fall back to the debug key.
        val releaseSigning = signingConfigs.findByName("release")
            ?: signingConfigs.getByName("debug")
        // Debug builds install next to the release app (their own id and
        // launcher name) so a debug run never replaces or wipes the release
        // install. Google Sign-In needs an Android OAuth client for
        // com.ournego.app.debug with the debug key's SHA-1.
        getByName("debug") {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Ournego Debug"
        }
        release {
            signingConfig = releaseSigning
        }
        getByName("profile") {
            signingConfig = releaseSigning
        }
    }
}

flutter {
    source = "../.."
}
