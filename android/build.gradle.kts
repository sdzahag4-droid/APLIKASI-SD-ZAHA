allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate { proj: org.gradle.api.Project ->
        if (proj.hasProperty("android")) {
            val androidExtension = proj.extensions.findByName("android")
            if (androidExtension != null) {
                try {
                    val method = androidExtension.javaClass.getMethod("compileSdkVersion", Int::class.java)
                    method.invoke(androidExtension, 34)
                } catch (e: Exception) {
                    // Abaikan jika tidak mendukung
                }
            }
        }
    }
}