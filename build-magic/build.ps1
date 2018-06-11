
$buildDir=$PSScriptRoot
$paketDir=[System.IO.Path]::Combine($buildDir, ".paket")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")
$command = [System.IO.Path]::Combine($buildDir, "paket-files", "ninjaboy", "build-scripts-poc", "build-runner.ps1")

try {
    Push-Location -Path $buildDir
    & "$paket" update

    if ($LASTEXITCODE -ne 0)
    {
        trace "Could not resolve some of the Paket dependencies"
        Exit $LASTEXITCODE
    }

    & $command @args
    
    if ($LASTEXITCODE -ne 0)
    {
        Exit $LASTEXITCODE
    }    
}
finally {
    Pop-Location
}

