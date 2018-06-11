
$buildDir=$PSScriptRoot

$paketUri = "https://github.com/fsprojects/Paket/releases/download/5.172.2/paket.bootstrapper.exe"
$paketDir=[System.IO.Path]::Combine($buildDir, ".paket")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$command = [System.IO.Path]::Combine($buildDir, "paket-files", "ninjaboy", "build-scripts-poc", "build-runner.ps1")

try {
    Push-Location -Path $buildDir

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

