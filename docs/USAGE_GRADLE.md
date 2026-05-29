# Uso Desde Gradle

Este repositorio Maven tambien funciona para proyectos Gradle. No hace falta un repo separado para Gradle: Gradle consume repositorios Maven sin problema.

## Groovy DSL

```groovy
repositories {
    maven {
        name = "drakescraftLabs"
        url = uri("https://drakescraft-labs.github.io/maven-repo/")
        mavenContent {
            includeGroup("com.github.drakescraft_labs")
        }
    }
}

dependencies {
    compileOnly("com.github.drakescraft_labs:slimefun-core:11.0-Drake-1.21.1-SNAPSHOT")
    implementation("com.github.drakescraft_labs:dough-core:1.3.1-DRAKE-v11-SNAPSHOT")
}
```

## Kotlin DSL

```kotlin
repositories {
    maven {
        name = "drakescraftLabs"
        url = uri("https://drakescraft-labs.github.io/maven-repo/")
        mavenContent {
            includeGroup("com.github.drakescraft_labs")
        }
    }
}

dependencies {
    compileOnly("com.github.drakescraft_labs:slimefun-core:11.0-Drake-1.21.1-SNAPSHOT")
    implementation("com.github.drakescraft_labs:dough-core:1.3.1-DRAKE-v11-SNAPSHOT")
}
```

## Smoke Test

Usa una cache temporal para confirmar que el proyecto no depende de tu maquina:

```powershell
$gradleHome = Join-Path $env:TEMP ('drake-gradle-clean-' + [Guid]::NewGuid().ToString('N'))
$env:GRADLE_USER_HOME = $gradleHome
gradle build --refresh-dependencies
Remove-Item -LiteralPath $gradleHome -Recurse -Force
```
