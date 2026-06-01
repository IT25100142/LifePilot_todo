allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    val configureNdk: () -> Unit = {
        try {
            val androidExtension = extensions.getByType<com.android.build.gradle.BaseExtension>()
            androidExtension.ndkVersion = "27.0.12077973"
        } catch (e: Exception) {
            // Ignore if the project is not an Android project or doesn't have the extension
        }
    }
    if (state.executed) {
        configureNdk()
    } else {
        afterEvaluate {
            configureNdk()
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
