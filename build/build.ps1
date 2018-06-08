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

$repositoryDir=(Get-Item $buildDir).Parent.FullName
$solutionName="Paket.Build.Demo"

$paketDir=[System.IO.Path]::Combine($repositoryDir, ".paket")
$paketBootstrapper=[System.IO.Path]::Combine($paketDir, "paket.bootstrapper.exe")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$packagesDir =[System.IO.Path]::Combine($repositoryDir, "packages")
$fake=[System.IO.Path]::Combine($packagesDir, "FAKE", "tools", "FAKE.exe")

# Default script is used for now
$buildScript=[System.IO.Path]::Combine($repositoryDir, "paket-files", "ninjaboy", "build-scripts-poc", "build.fsx" )

Write-Host -ForegroundColor Green "*** Building $Configuration in $repositoryDir for solution $solutionName***"

Write-Host -ForegroundColor Green "*** Initializing paket ***"
& "$paketBootstrapper"

if ($LASTEXITCODE -ne 0)
{
    trace "Could not resolve initialize Paket"
    Exit $LASTEXITCODE
}

Write-Host -ForegroundColor Green "*** Getting build tools ***"
& "$paket" install

if ($LASTEXITCODE -ne 0)
{
    trace "Could not resolve some of the Paket dependencies"
    Exit $LASTEXITCODE
}

Write-Host -ForegroundColor Green "*** FAKE it ***"
& "$fake" "$buildScript" "$Target" `
            RepositoryDir="$repositoryDir" `
            SolutionName="$solutionName" `
            Configuration="$Configuration" `
            BuildVersion="$BuildVersion" `
            Runtime="$Runtime" `
            SutStartMode="$SutStartMode" `
            --logfile "$buildLog"

if ($LASTEXITCODE -ne 0)
{
    Exit $LASTEXITCODE
}