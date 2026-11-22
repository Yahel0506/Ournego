import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    // Runs each Patrol test in its own instrumentation process.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

// The upload key is local-only or supplied temporarily by the Android CI job.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val uploadKeystorePath = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keystoreProperties.getProperty(it).isNullOrBlank() } &&
    uploadKeystorePath?.isFile == true

val checkReleaseSigning = tasks.register("checkReleaseSigning") {
    group = "verification"
    description = "Checks that a release build has a configured upload key."
    doLast {
        check(hasReleaseSigning) {
            "Release builds require a valid android/key.properties and an existing upload keystore. " +
                "See docs/development/release-process.md for setup and recovery instructions."
        }
    }
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
        // Profile prefers the upload key for Google Sign-In, with debug as a
        // local-only fallback. Release builds require the upload key below.
        val profileSigning = if (hasReleaseSigning) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
        // Debug builds install next to the release app (their own id and
        // launcher name) so a debug run never replaces or wipes the release
        // install. Google Sign-In needs an Android OAuth client for
        // com.ournego.app.debug with the debug key's SHA-1.
        getByName("debug") {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Ournego Debug"
        }
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        getByName("profile") {
            signingConfig = profileSigning
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(checkReleaseSigning)
    }
}

flutter {
    source = "../.."
}
