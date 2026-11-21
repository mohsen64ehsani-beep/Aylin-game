
// ---- Release signing (appended by CI) ----
val keystoreProps = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) java.io.FileInputStream(f).use { load(it) }
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProps["keyAlias"] as String
            keyPassword = keystoreProps["keyPassword"] as String
            storeFile = file(keystoreProps["storeFile"] as String)
            storePassword = keystoreProps["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
