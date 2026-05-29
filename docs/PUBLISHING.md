# Publicacion De Artefactos Drake

Este repo es la base publica de dependencias para los plugins de DrakesCraft Labs. La regla practica:

1. Compila el plugin o libreria en su repo fuente.
2. Publica el jar aqui con `scripts/Publish-DrakeArtifact.ps1` o con el manifest `catalog/drake-artifacts.json`.
3. Haz commit y push de los archivos generados en este repo.
4. En el plugin consumidor, apunta a `https://drakescraft-labs.github.io/maven-repo/`.
5. Valida con una cache Maven/Gradle temporal limpia.

## Publicar Un Artefacto

```powershell
.\scripts\Publish-DrakeArtifact.ps1 `
  -ArtifactFile "..\standalone-audit\NetworksV6-drake\target\NetworksV6-Drake-v11-SNAPSHOT.jar" `
  -ArtifactId "NetworksV6-drake" `
  -Version "11-SNAPSHOT" `
  -Description "Jar compilado de NetworksV6 Drake"
```

El script genera un POM minimo independiente, publica el jar en formato Maven y recalcula checksums.

## Publicar Desde Manifest

```powershell
.\scripts\Publish-DrakeManifest.ps1 -ManifestPath .\catalog\drake-artifacts.json
```

El manifest es la lista controlada de artefactos Drake que queremos exponer como base descargable. Se puede ir ampliando con los plugins del monorepo y los repos independientes.

## Politica

- Publica aqui solo artefactos que otros plugins necesiten o que queramos distribuir como base Drake controlada.
- Evita POMs que dependan de parents locales del reactor.
- Prefiere versiones con sufijo Drake cuando el codigo fue modificado por la organizacion.
- No publiques secretos, configs de servidor ni archivos de runtime.
