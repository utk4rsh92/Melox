allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        // Fix 1: Force Java 17 on all subprojects
        if (project.extensions.findByName("android") != null) {
            val androidExt = project.extensions.findByName("android")!!

            // Force Java compile options to 17
            try {
                val compileOptions = androidExt.javaClass
                    .getMethod("getCompileOptions")
                    .invoke(androidExt)
                compileOptions?.let {
                    it.javaClass.getMethod(
                        "setSourceCompatibility", JavaVersion::class.java
                    ).invoke(it, JavaVersion.VERSION_17)
                    it.javaClass.getMethod(
                        "setTargetCompatibility", JavaVersion::class.java
                    ).invoke(it, JavaVersion.VERSION_17)
                }
            } catch (e: Exception) { }

            // Fix 2: Namespace for AGP 8+
            val namespace = try {
                androidExt.javaClass.getMethod("getNamespace")
                    .invoke(androidExt) as? String
            } catch (e: Exception) { null }

            if (namespace.isNullOrEmpty()) {
                try {
                    androidExt.javaClass
                        .getMethod("setNamespace", String::class.java)
                        .invoke(
                            androidExt,
                            "com.example.${project.name.replace("-", "_")}"
                        )
                } catch (e: Exception) { }
            }
        }

        // Fix 3: Force Kotlin to JVM 17 on all subprojects
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
            compilerOptions {
                jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }

        // Fix 4: Force Java tasks to 17 as well
        tasks.withType<JavaCompile> {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}