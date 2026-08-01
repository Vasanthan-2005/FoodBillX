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

    // Fix: AGP 8.x namespace requirement for older pub.dev packages (e.g. isar_flutter_libs 3.1.0+1).
    // Must be registered here, before evaluationDependsOn forces eager project evaluation below.
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            val android = extensions.findByName("android") ?: return@afterEvaluate
            try {
                val getNs = android.javaClass.getMethod("getNamespace")
                val current = getNs.invoke(android) as? String
                if (current.isNullOrBlank()) {
                    android.javaClass.getMethod("setNamespace", String::class.java)
                        .invoke(android, group.toString())
                }
            } catch (_: Exception) {
                // namespace already set or API not available — safe to ignore
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
