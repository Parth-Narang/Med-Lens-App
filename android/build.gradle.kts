plugins {
    // We do NOT put versions here because they are inherited or injected
    id("com.android.application") apply false
    id("com.android.library") apply false
    
    // REMOVED: version "2.1.0" to prevent the "different version (1.9.24)" conflict
    id("org.jetbrains.kotlin.android") apply false 
    
    id("dev.flutter.flutter-gradle-plugin") apply false 
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}