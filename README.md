# PaketBuildDemo
An example of how to use Paket to use shared build files repo

## Steps

### Installing paket
As per Paket installation instructions: https://fsprojects.github.io/Paket/installation.html#Installation-per-repository

``` bash
mkdir .paket
# copy packet bootstrapper from the internetz to the .paket directory
#https://github.com/fsprojects/Paket/releases/download/5.170.2/paket.bootstrapper.exe
mv paket.bootstrapper.exe paket.exe
```

NOTE: we are going to be using paket in a _magic_ mode. More details: https://fsprojects.github.io/Paket/bootstrapper.html

### Define paket dependencies
Paket relies on the file to exist in order to restore dependencies. The file has to be at a solution root (OPTIONALLY the whole Paket infrastructure can be placed into the `build` folder and be executed there as it was made in this demo)

```
mkdir build
touch build/paket.dependencies
```

Reference fake and a desired custom build scripts in the newly created file (_NOTE: for the purpose of this demo a new repository with build scripts was created at: `https://github.com/ninjaboy/build-scripts-poc`_):

``` paket
source https://api.nuget.org/v3/index.json

nuget FAKE ~> 4.64

github ninjaboy/build-scripts-poc:master build.fsx
github ninjaboy/build-scripts-poc:master build-runner.fsx

```

We are goin to use FAKE tool to run our build files and we are referencing 2 fsharp buildfiles that we will be using as our default builds cripts

### Create build script placeholder

Create a simple build script that basically will run `paket` tool, which will restore our dependencies and then will execute `fake` passing referenced default `build-runner.fsx` as a build script with some set of predefined parameters like `Runtime`, `Configuration`, `SolutionName`, etc (See the referenced `build.fsx` for more details)

``` bash
mkdir build
cd build
touch build.ps1
```

Put the following content into the newly created file

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

$repositoryDir=(Get-Item $buildDir).Parent.FullName
$solutionName="Paket.Build.Demo"

$paketDir=[System.IO.Path]::Combine($buildDir, ".paket")
$paketBootstrapper=[System.IO.Path]::Combine($paketDir, "paket.bootstrapper.exe")
$paket=[System.IO.Path]::Combine($paketDir, "paket.exe")

$packagesDir =[System.IO.Path]::Combine($buildDir, "packages")
$fake=[System.IO.Path]::Combine($packagesDir, "FAKE", "tools", "FAKE.exe")

# Default script is used for now
$buildScript=[System.IO.Path]::Combine($buildDir, "paket-files", "ninjaboy", "build-scripts-poc", "build-runner.fsx" )

try {
    Push-Location -Path $buildDir
    Write-Host -ForegroundColor Green "*** Building $Configuration in $repositoryDir for solution $solutionName***"
    Write-Host -ForegroundColor Green "*** Initializing paket ***"
    & "$paketBootstrapper"
    if ($LASTEXITCODE -ne 0)
    {
        trace "Could not resolve initialize Paket"
        Exit $LASTEXITCODE
    }
    Write-Host -ForegroundColor Green "*** Getting build tools ***"
    & "$paket" update
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
}
finally {
    Pop-Location
}
```

### Run the build script
In it's simplest for the build script can be run as follows `.\build\build.ps1` which will run `FullBuild` target or specify the target to run `.\build\build.ps1 -target UnitTests`

This should build the solution and run `dotnet test` for the unit tests projects:
![build results](static/images/buildResults.png "Build results output")

## Custom build file
Now we may want to define our custom targets to do steps specific to our project that are different from what is proposed by default build files we are referencing

Here's how to achieve this:

### Create custom `build.fsx` file
In this example please follow to the `build-custom` directory for the examples

Note that new `build.ps1` file is now referring to the custom FAKE file:
`$buildScript=[System.IO.Path]::Combine($buildDir, "build-custom.fsx" )`

Note that the new `build-custom.fsx` file defines a new target dependency `CustomTarget` for a `build` target

### Run the customized build
Run the build as follows:
`.\build-custom\build.ps1 -target UnitTests`

You will see that the newly defined target was taken into account when building dependencies list:
![custom target](static/images/custom-build.png "Custom target is now taken into dependencies list")

## Magic mode
The simplest way to use the common build pipeline is the `magic mode`. (As a reference to paket `magic` mode)
With this approach only the minimum script is required to be created. Please follow to the `build-magic` folder for an example.

## Git private repository
It is highly likely that the shared build scripts may need to be kept in the private repository
As a part of this POC task the private repository has been created: `https://github.com/ninjaboy/build-scripts-poc-private`

Please follow to the `build-private` folder
In order for Paket to be able to access this repository an access key has to be specified.

### Getting Github personal access token
In order to allow Paket to access a certain private repository files the following steps need to be done

1. Login to the Github in Github from the account that owns private build scripts repository
2. Follow to `Account Settings -> Developer Settings -> Personal Access Tokens -> Generate New Token`
3. Choose `Full control of private repositories`. As we are talking about private repository access it seems (at least at the moment of writing this document) that you need to issue a token with full access to private github repositories for the account that is hosting build scripts repository. See the image below
![Github Generate New Token](static/images/generateNewToken.png "Github Generate New Token")
4. Copy the generated token and make sure to not lose it as you wont be able to see it's value next time
![Github toke](static/images/generateNewToken.png "Copy the token to a safe place")
5. Run the following command (from the root of this repository copy) on the machine which is intended to run build (e.g. your dev machine, build agent, etc): `.\build-private\.paket\paket.exe config add-token github-token 1aXXXXXXXXXXXXXXXXXXXXXXc7` (the last parameter is the value of the issued personal access token that you have generated in step 4)
2. Change `paket.dependencies` file to reflect access to private repositories, e.g. `github ninjaboy/build-scripts-poc-private:master build.fsx github-token` (See folder `build-private` of this repository for more details)
NOTE: any name can be used instead of `github-token` but make sure that this name is used in `paket.dependencies` file

# KNOWN PROBLEMS: 

No problems detected so far