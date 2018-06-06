# PaketBuildDemo
An example of how to use Paket to use shared build files repo

## Steps

1. Installing paket
As per Paket installation instructions: https://fsprojects.github.io/Paket/installation.html#Installation-per-repository
``` bash
mkdir .paket
# copy packet bootstrapper from the internetz to the .paket directory
#https://github.com/fsprojects/Paket/releases/download/5.170.2/paket.bootstrapper.exe

```

2. Define paket dependencies
Paket relies on the file to exist in order to restore dependencies. The file has to be at a solution root (OPTIONALLY the whole Paket infrastructure can be placed into the `build` folder and be executed there)

```
touch paket.dependencies
```

Reference fake and our custom build scripts there

``` paket
source https://api.nuget.org/v3/index.json

nuget FAKE ~> 4.64

github iblazhko/build-scripts-poc build.fsx
```

3. Create build script placeholder
``` bash
mkdir build
touch build.ps1
```

``` powershell
Param(
    [ValidateNotNullOrEmpty()]
    [string]$Target="Default",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration="Release",

    [ValidateNotNullOrEmpty()]
    [string]$BuildVersion="0.0.0-unversioned",

    [ValidateNotNullOrEmpty()]
    [ValidateSet("any", "win-x64", "win", "linux-x64")]
    [string]$Runtime="linux-x64", 

    [ValidateNotNullOrEmpty()]
    [ValidateSet("AppDomain", "Docker")]
    [string]$SutStartMode="AppDomain"

)

$buildDir=$PSScriptRoot
$buildLog=[System.IO.Path]::Combine($buildDir, "reports", "build.log")

$solutionDir=(Get-Item $buildDir).Parent.FullName

$paketDir=[System.IO.Path]::Combine($solutionDir, ".paket")
$paketBootstrapper=[System.IO.Path]::Combine($paketDir, "paket.bootstrapper.exe")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$packagesDir =[System.IO.Path]::Combine($solutionDir, "packages")
$fake=[System.IO.Path]::Combine($packagesDir, "FAKE", "tools", "FAKE.exe")

$buildScript=[System.IO.Path]::Combine($solutionDir, "paket-files", "iblazhko", "build-scripts-poc", "build.fsx" )

Write-Host -ForegroundColor Green "*** Building $Configuration in $solutionDir ***"

Write-Host -ForegroundColor Green "*** Initializing paket ***"
& "$paketBootstrapper"
& "$paket" install

Write-Host -ForegroundColor Green "***  Run FAKE targets ***"
& "$fake" "$buildScript" "$Target" --logfile "$buildLog" Configuration="$Configuration" BuildVersion="$BuildVersion" Runtime="$Runtime" SutStartMode="$SutStartMode"

if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}
```

Note that `$buildScript` is now pointing to the default buildscript file provided from the reference repository

4. ...

5. PROFIT!