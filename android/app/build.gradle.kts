plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.food_flow"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.food_flow"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("KEY_ALIAS")
                ?: project.findProperty("keyAlias") as String?
                        ?: "upload"
            keyPassword = System.getenv("KEY_PASSWORD")
                ?: project.findProperty("keyPassword") as String?
                        ?: "foodflow2025"
            storeFile = file(
                System.getenv("STORE_FILE")
                    ?: project.findProperty("storeFile") as String?
                    ?: "upload-keystore.jks"
            )
            storePassword = System.getenv("STORE_PASSWORD")
                ?: project.findProperty("storePassword") as String?
                        ?: "foodflow2025"
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
            isJniDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
            // REMOVED: applicationIdSuffix = ".debug"
            // This was causing Firebase error: No matching client found for package name 'com.example.food_flow.debug'
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            isDebuggable = false
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }

    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += listOf("InvalidPackage", "MissingTranslation")
    }

    buildFeatures {
        viewBinding = true
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Firebase BoM - Using stable version 33.7.0
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // Firebase KTX
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-storage-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")

    // Google Play Services - Compatible versions
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("com.google.android.gms:play-services-maps:19.0.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // AndroidX - Stable versions
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime-ktx:2.10.0")

    // Kotlin - Compatible with your setup
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
}
