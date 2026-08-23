allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val subproject = this
    subproject.afterEvaluate {
        if (subproject.plugins.hasPlugin("com.android.application") || subproject.plugins.hasPlugin("com.android.library")) {
            subproject.extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
                buildToolsVersion("36.0.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}