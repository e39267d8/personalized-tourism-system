param(
    [ValidateSet("Auto", "Full", "Update")]
    [string]$Mode = "Auto",

    [string]$Database = "tourism_system",
    [string]$User = "postgres",
    [string]$HostName = "127.0.0.1",
    [int]$Port = 5432,

    [string]$PsqlPath = "",
    [string]$CreatedbPath = "",

    [switch]$SkipCreateDatabase,
    [switch]$SkipInternalNavigation,
    [switch]$SkipRepair
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-Executable {
    param(
        [string]$Name,
        [string]$OverridePath
    )

    if ($OverridePath) {
        if (-not (Test-Path $OverridePath)) {
            throw "Configured path for $Name does not exist: $OverridePath"
        }
        return (Resolve-Path $OverridePath).Path
    }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $commonPaths = @(
        "C:\Program Files\PostgreSQL\16\bin\$Name.exe",
        "C:\Program Files\PostgreSQL\15\bin\$Name.exe",
        "C:\Program Files\PostgreSQL\14\bin\$Name.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    throw "Cannot find $Name. Add PostgreSQL bin to PATH or pass -${Name}Path."
}

function Escape-SqlLiteral {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Invoke-PsqlScalar {
    param(
        [string]$DbName,
        [string]$Sql
    )

    $output = & $script:Psql `
        -h $HostName `
        -p $Port `
        -U $User `
        -d $DbName `
        -t `
        -A `
        -c $Sql

    if ($LASTEXITCODE -ne 0) {
        throw "psql scalar query failed against database '$DbName'."
    }

    $line = $output | Where-Object { $_ -match "\S" } | Select-Object -First 1
    if ($null -eq $line) {
        return ""
    }
    return $line.Trim()
}

function Invoke-PsqlFile {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        throw "Required SQL file not found: $RelativePath"
    }

    Write-Host ""
    Write-Host "==> psql -d $Database -f $RelativePath"

    & $script:Psql `
        -h $HostName `
        -p $Port `
        -U $User `
        -d $Database `
        -v ON_ERROR_STOP=1 `
        -f $fullPath

    if ($LASTEXITCODE -ne 0) {
        throw "SQL import failed: $RelativePath"
    }
}

function Invoke-PsqlFileIfPresent {
    param([string]$RelativePath)

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (Test-Path $fullPath) {
        Invoke-PsqlFile $RelativePath
    } else {
        Write-Host "Skip missing optional SQL file: $RelativePath"
    }
}

$script:Psql = Resolve-Executable -Name "psql" -OverridePath $PsqlPath
$Createdb = Resolve-Executable -Name "createdb" -OverridePath $CreatedbPath

Write-Host "TourPilot database setup"
Write-Host "Repository : $RepoRoot"
Write-Host "Database   : $Database"
Write-Host "User       : $User"
Write-Host "Host       : ${HostName}:$Port"
Write-Host "psql       : $script:Psql"

$dbNameSql = Escape-SqlLiteral $Database
$dbExists = Invoke-PsqlScalar -DbName "postgres" -Sql "SELECT 1 FROM pg_database WHERE datname = '$dbNameSql';"

if ($dbExists -ne "1") {
    if ($SkipCreateDatabase) {
        throw "Database '$Database' does not exist and -SkipCreateDatabase was set."
    }

    Write-Host ""
    Write-Host "==> createdb $Database"
    & $Createdb -h $HostName -p $Port -U $User $Database
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create database '$Database'."
    }
}

$hasScenicSpots = Invoke-PsqlScalar `
    -DbName $Database `
    -Sql "SELECT CASE WHEN to_regclass('public.scenic_spots') IS NULL THEN '0' ELSE '1' END;"

$selectedMode = $Mode
if ($Mode -eq "Auto") {
    if ($hasScenicSpots -eq "1") {
        $selectedMode = "Update"
    } else {
        $selectedMode = "Full"
    }
}

Write-Host "Mode       : $selectedMode"

if ($selectedMode -eq "Full") {
    Invoke-PsqlFile "database\schema.sql"
    Invoke-PsqlFile "database\imports\amap_pois.sql"

    if (-not $SkipInternalNavigation) {
        Invoke-PsqlFileIfPresent "database\internal_navigation_schema.sql"
        Invoke-PsqlFileIfPresent "database\imports\internal_navigation.sql"
    }

    Invoke-PsqlFile "database\indoor_navigation_schema.sql"
    Invoke-PsqlFile "database\seed_demo.sql"
    Invoke-PsqlFile "database\seed_indoor_navigation.sql"

    if (-not $SkipRepair) {
        Invoke-PsqlFileIfPresent "database\maintenance\repair_data_quality.sql"
    }

    Invoke-PsqlFileIfPresent "database\verify_demo.sql"
} else {
    Invoke-PsqlFile "database\indoor_navigation_schema.sql"
    Invoke-PsqlFile "database\seed_indoor_navigation.sql"
}

Write-Host ""
Write-Host "==> Indoor navigation verification"

$verifySql = @"
SELECT
    b.id AS building_id,
    b.scenic_spot_id,
    s.name AS scenic_spot,
    b.name AS building_name,
    b.provider,
    (SELECT COUNT(*) FROM indoor_floors f WHERE f.building_id = b.id) AS floor_count,
    (SELECT COUNT(*) FROM indoor_features feat WHERE feat.building_id = b.id) AS feature_count,
    (SELECT COUNT(*) FROM indoor_edges e WHERE e.building_id = b.id) AS edge_count
FROM indoor_buildings b
JOIN scenic_spots s ON s.id = b.scenic_spot_id
WHERE b.source = 'manual-curated'
  AND b.source_ref = 'red-building:indoor-building:main'
ORDER BY b.id;
"@

& $script:Psql `
    -h $HostName `
    -p $Port `
    -U $User `
    -d $Database `
    -c $verifySql

if ($LASTEXITCODE -ne 0) {
    throw "Indoor navigation verification query failed."
}

$spotId = Invoke-PsqlScalar `
    -DbName $Database `
    -Sql "SELECT scenic_spot_id FROM indoor_buildings WHERE source = 'manual-curated' AND source_ref = 'red-building:indoor-building:main' LIMIT 1;"

if (-not $spotId) {
    throw "Indoor seed was not found after setup. Check AMap POI import and seed_indoor_navigation.sql."
}

Write-Host ""
Write-Host "Setup complete."
Write-Host "Indoor navigation expected page: http://127.0.0.1:3000/spots/$spotId"
Write-Host "Backend API check after server starts:"
Write-Host "Invoke-WebRequest http://127.0.0.1:8080/api/v1/scenic-spots/$spotId/indoor-buildings"
