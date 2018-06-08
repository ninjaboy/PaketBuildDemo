#load @"./paket-files/ninjaboy/build-scripts-poc/build.fsx"

open Fake
open System

open Build.Properties.Internal

module CustomTargets =

    Target "CustomTarget" (fun _ ->
        DotNetCli.RunCommand (fun p ->
             { p with
                 TimeOut = TimeSpan.FromMinutes 10.
             }) (sprintf "clean \"%s\"" solutionFile)
    )

// customization dependencies
"CustomTarget" ==> "Build"

// Start
RunTargetOrDefault "Default"