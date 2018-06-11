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

$paketUri = "https://github.com/fsprojects/Paket/releases/download/5.172.2/paket.bootstrapper.exe"
$paketDir=[System.IO.Path]::Combine($buildDir, ".paket")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$packagesDir =[System.IO.Path]::Combine($buildDir, "packages")
$fake=[System.IO.Path]::Combine($packagesDir, "FAKE", "tools", "FAKE.exe")

# Custom build script is used!
$buildScript=[System.IO.Path]::Combine($buildDir, "build-custom.fsx" )

Push-Location -Path $buildDir
try {
    Write-Host -ForegroundColor Green "*** Building $Configuration in $repositoryDir for solution $solutionName***"

    Write-Host -ForegroundColor Green "*** Getting paket ***"
    if(![System.IO.File]::Exists($paket)){
        if(!(test-path $paketDir)) {
              New-Item -ItemType Directory -Force -Path $paketDir
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $paketUri -OutFile $paket
        if ($LASTEXITCODE -ne 0)
        {
            trace "Could not resolve some of the Paket dependencies"
            Exit $LASTEXITCODE
        }
    }

    Write-Host -ForegroundColor Green "*** Initializing paket ***"
    & "$paket" update
    
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
}
finally {
    Pop-Location
}
