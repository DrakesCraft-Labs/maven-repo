param(
    [Parameter(Mandatory = $true)]
    [string] $ArtifactFile,

    [Parameter(Mandatory = $true)]
    [string] $ArtifactId,

    [Parameter(Mandatory = $true)]
    [string] $Version,

    [string] $GroupId = "com.github.drakescraft_labs",
    [string] $RepositoryId = "drakescraft-labs-local",
    [string] $Description = "Artefacto Drake publicado para compilar plugins de DrakesCraft.",
    [string] $SourcesFile,
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Resolve-DrakePath {
    param([Parameter(Mandatory = $true)][string] $Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $RepositoryRoot $Path)).Path
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Value
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Update-MavenChecksums {
    param([Parameter(Mandatory = $true)][string] $Root)

    Write-Host "[INFO] Normalizando XML/POM a LF y recalculando checksums..."
    $encoding = New-Object System.Text.UTF8Encoding($false)

    Get-ChildItem -LiteralPath (Join-Path $Root "com") -Recurse -File |
        Where-Object { $_.Extension -in ".pom", ".xml" } |
        ForEach-Object {
            $text = [System.IO.File]::ReadAllText($_.FullName) -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($_.FullName, $text, $encoding)
        }

    Get-ChildItem -LiteralPath (Join-Path $Root "com") -Recurse -File |
        Where-Object { $_.Name -notmatch "\.(md5|sha1)$" } |
        ForEach-Object {
            $sha1 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1).Hash.ToLowerInvariant()
            $md5 = (Get-FileHash -LiteralPath $_.FullName -Algorithm MD5).Hash.ToLowerInvariant()
            [System.IO.File]::WriteAllText($_.FullName + ".sha1", $sha1, $encoding)
            [System.IO.File]::WriteAllText($_.FullName + ".md5", $md5, $encoding)
        }
}

try {
    $RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    $artifactPath = Resolve-DrakePath -Path $ArtifactFile
    $repoUri = (New-Object System.Uri($RepositoryRoot + [System.IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    $tempDir = Join-Path $env:TEMP ("drake-publish-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    $pomPath = Join-Path $tempDir "$ArtifactId.pom"
    $pom = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$GroupId</groupId>
  <artifactId>$ArtifactId</artifactId>
  <version>$Version</version>
  <packaging>jar</packaging>
  <name>$ArtifactId</name>
  <description>$Description</description>
</project>
"@
    Write-Utf8NoBom -Path $pomPath -Value $pom

    $mvnArgs = @(
        "deploy:deploy-file",
        "-Durl=$repoUri",
        "-DrepositoryId=$RepositoryId",
        "-DpomFile=$pomPath",
        "-Dfile=$artifactPath"
    )

    if ($SourcesFile) {
        $sourcesPath = Resolve-DrakePath -Path $SourcesFile
        $mvnArgs += "-Dsources=$sourcesPath"
    }

    Write-Host "[INFO] Publicando $GroupId`:$ArtifactId`:$Version"
    & mvn @mvnArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Maven deploy-file fallo para $ArtifactId"
    }

    Update-MavenChecksums -Root $RepositoryRoot
    Write-Host "[SUCCESS] Publicado $ArtifactId en $RepositoryRoot"
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
} finally {
    if ($tempDir -and (Test-Path -LiteralPath $tempDir)) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}
