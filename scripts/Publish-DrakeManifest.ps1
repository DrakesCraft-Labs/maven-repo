param(
    [string] $ManifestPath = ".\catalog\drake-artifacts.json",
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

try {
    $RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    $manifestFullPath = if ([System.IO.Path]::IsPathRooted($ManifestPath)) {
        (Resolve-Path -LiteralPath $ManifestPath).Path
    } else {
        (Resolve-Path -LiteralPath (Join-Path $RepositoryRoot $ManifestPath)).Path
    }

    $manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
    $groupId = if ($manifest.groupId) { $manifest.groupId } else { "com.github.drakescraft_labs" }
    $repositoryId = if ($manifest.repositoryId) { $manifest.repositoryId } else { "drakescraft-labs-local" }

    foreach ($artifact in $manifest.artifacts) {
        $args = @{
            RepositoryRoot = $RepositoryRoot
            GroupId = $groupId
            RepositoryId = $repositoryId
            ArtifactFile = $artifact.file
            ArtifactId = $artifact.artifactId
            Version = $artifact.version
            Description = $artifact.description
        }

        if ($artifact.sources) {
            $args.SourcesFile = $artifact.sources
        }

        & (Join-Path $PSScriptRoot "Publish-DrakeArtifact.ps1") @args
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo publicando $($artifact.artifactId)"
        }
    }

    Write-Host "[SUCCESS] Manifest publicado completo: $manifestFullPath"
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
