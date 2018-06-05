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

# Write-Host -ForegroundColor Green "***    FAKE it ***"
# & "$fake" "$buildScript" "$Target" --logfile "$buildLog" Configuration="$Configuration" BuildVersion="$BuildVersion" Runtime="$Runtime" SutStartMode="$SutStartMode"

if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}