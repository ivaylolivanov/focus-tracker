$CommonCompilerFlags = "-MT", "-nologo", "-Gm-", "-GR-", "-EHa-", "-Od", "-Oi", "-WX", "-W4", "-wd4201", "-wd4100", "-wd4189", "-wd4505", "-DWIN32_DEBUG=1", "-DWIN32_DEBUG_SOUND=0", "-FC", "-Z7";
$CommonLinkerFlags = "-incremental:no", "-opt:ref", "user32.lib", "gdi32.lib", "winmm.lib";

$VcvarsallFilename = "vcvarsall.bat";
$ProgramFiles = 'C:\Program Files';

function GetVcvarsallLocation
{
    $location = (Get-ChildItem -Path "$ProgramFiles" -Filter `
        "$VcvarsallFilename" -Recurse).FullName;

    if ($location -ne $null)
    {
        return $location;
    }

    Write-Host "Please install Visual Studio!";
    return $null;
}

function LoadVcVarsAll
{
    param([string]$vcVarsAll)

    $vcVarsAllEnvironment = & cmd /c "`"$vcVarsAll`" x64 && set";
    $vcVarsAllExpanded = $vcVarsAllEnvironment | ForEach-Object {
        $row = $_;
        if ($row -match '^([^=]+)=(.*)$')
        {
            $key = $matches[1].Trim();
            $value = $matches[2].Trim();
            [System.Collections.DictionaryEntry]::new($key, $value);
        }
    }

    foreach ($var in $vcVarsAllExpanded)
    {
        [System.Environment]::SetEnvironmentVariable(
            $var.Key,
            $var.Value,
            [System.EnvironmentVariableTarget]::Process);
    }

    return 0;
}

function GetCl64Location
{
   $location = (Get-ChildItem -Path "$ProgramFiles" -Filter "cl.exe" -Recurse `
       | Where-Object { $_.FullName -like "*x64*" } | Select-Object -First    `
       1).FullName;

    if ($location -ne $null)
    {
        return $location;
    }

    Write-Host "Failed to find the cl x64 compiler";
    return $null;
}

function IsInGitRepo
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Directory
    )

    try
    {
        Set-Location -Path $Directory -ErrorAction Stop;
        git rev-parse --is-inside-work-tree;

        return 0;
    }
    catch
    {
        return 1;
    }
}

function BuildProject
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$workingDirectory,
        [string]$entryPoint
    )

    $arguments = @(
        $CommonCompilerFlags
        "$entryPoint"
        "-Fefocus-track.exe"
        "/link"
        $CommonLinkerFlags
    );

    $compiler = GetCl64Location;
    if (-not $compiler)
    {
        Write-Host "Compiler not found, exitting...";
        return 1;
    }

    $setLocationStatus = Set-Location -Path "$workingDirectory";
    if ($setLocationStatus -ne $null)
    {
        Write-Host "Failed to change location to $workingDirectory";
        Set-Location -Path "$initialLocation";
        return 1;
    }

    & "$compiler" $arguments | ForEach-Object { Write-Host $_ };
    return 0;
}

function main
{
    $scriptDir = $PSScriptRoot;

    $vcVarsAll = GetVcvarsallLocation;
    if (-not $vcVarsAll)
    {
        Write-Host "Failed to export vc variables!";
        return 1;
    }

    LoadVcVarsAll "$vcVarsAll";

    $isInGitRepo = IsInGitRepo -Directory "$scriptDir";
    if (-not $isInGitRepo) { return 2; }

    $gitRoot = git rev-parse --show-toplevel;
    $workingDir = "${gitRoot}/build";
    $sourceDir = "${gitRoot}";
    $entryPointFilepath = "${sourceDir}/main.cpp";

    Remove-Item "${workingDir}\*.pdb" -Force -Verbose `
        -ErrorAction SilentlyContinue;
    New-Item -Path "$workingDir" -ItemType Directory -Force;

    $initialLocation = (Get-Location).Path;

    $buildStatus = BuildProject -workingDirectory "$workingDir" `
        -entryPoint "$entryPointFilepath";

    Set-Location -Path "$initialLocation";
    if ($buildStatus -ne $null) { return 3; }

    return 0;
}

main;
