param(
    [string[]] $SourceRoots = @(
        "..\drakes-slimefun-labs\sources",
        "..\standalone-audit"
    ),
    [string] $OutputPath = ".\catalog\detected-plugin-jars.json",
    [string] $RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

try {
    $RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
    $detected = New-Object System.Collections.Generic.List[object]

    foreach ($root in $SourceRoots) {
        $fullRoot = if ([System.IO.Path]::IsPathRooted($root)) {
            if (Test-Path -LiteralPath $root) { (Resolve-Path -LiteralPath $root).Path } else { $null }
        } else {
            $candidate = Join-Path $RepositoryRoot $root
            if (Test-Path -LiteralPath $candidate) { (Resolve-Path -LiteralPath $candidate).Path } else { $null }
        }

        if (-not $fullRoot) {
            Write-Host "[WARN] No existe source root: $root"
            continue
        }

        Write-Host "[INFO] Buscando jars en $fullRoot"
        Get-ChildItem -LiteralPath $fullRoot -Recurse -Filter "*.jar" |
            Where-Object {
                $_.FullName -match "\\target\\" -and
                $_.Name -notmatch "^(original-|.*-sources\\.jar$|.*-javadoc\\.jar$)"
            } |
            ForEach-Object {
                $relative = [System.IO.Path]::GetRelativePath($RepositoryRoot, $_.FullName)
                $artifactId = $_.BaseName -replace "-\\d.*$", ""
                $detected.Add([pscustomobject]@{
                    artifactId = $artifactId
                    version = "TODO-DRAKE-SNAPSHOT"
                    file = $relative
                    description = "TODO: revisar version y uso antes de publicar."
                })
            }
    }

    $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    } else {
        Join-Path $RepositoryRoot $OutputPath
    }

    $payload = [pscustomobject]@{
        repositoryId = "drakescraft-labs-local"
        groupId = "com.github.drakescraft_labs"
        artifacts = $detected
    } | ConvertTo-Json -Depth 5

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outputFullPath, $payload, $encoding)
    Write-Host "[SUCCESS] Catalogo generado: $outputFullPath"
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
