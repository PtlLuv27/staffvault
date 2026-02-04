buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Essential for Firebase and Google Sign-in integration
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory logic to maintain organization
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

// Clean task updated for the new build directory structure
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}