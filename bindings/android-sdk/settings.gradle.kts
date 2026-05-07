import org.gradle.api.initialization.resolve.RepositoriesMode

pluginManagement {
    repositories {
        google()
        maven {
            name = "Gradle Plugin Portal Kotlin DSL"
            url = uri("https://plugins.gradle.org/m2/")
            content {
                includeGroup("org.gradle.kotlin")
                includeGroup("org.gradle.kotlin.kotlin-dsl")
            }
        }
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "pirate-android-sdk"
include(":smoke-consumer")
