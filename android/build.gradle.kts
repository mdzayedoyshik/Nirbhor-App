allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use absolutePath (not canonicalPath) so the path is not re-resolved
// through the OS mount table — avoids /media/zayed/Project on mounted drives.
val newBuildDir: File = File(rootProject.projectDir.absolutePath, "../build").normalize()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: File = File(newBuildDir, project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
