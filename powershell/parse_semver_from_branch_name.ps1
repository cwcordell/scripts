# Validate then parse the semantic version from a provided release branch name

# Function to validate the branch name
function Validate-BranchName {
    param (
        [string]$BranchName
    )

    if ($BranchName -match '^(R|r)elease/(R|r)?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*$') {
        return $BranchName
    } else {
        return ""
    }
}

# Function to parse the version number from the branch name
function Parse-ReleaseVersion {
    param (
        [string]$BranchName
    )

    $semver = $BranchName.ToLower() -replace '^release/r([0-9]*\.[0-9]*(\.[0-9]*)*)$', '$1'
    if ($semver -match '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*$') {
        return $semver
    } else {
        return "error"
    }
}

# Function to print usage
function Print-Usage {
    Write-Host
    Write-Host "Usage: .\parse_semver_from_branch_name.ps1 [OPTIONS] BRANCH_NAME"
    Write-Host
    Write-Host "A script to validate and parse the semantic version from a branch, intended for a release,"
    Write-Host "where the name is in the form 'Release/R#.#.#', e.g. 'Release/R5.2.1'."
    Write-Host
    Write-Host "Options:"
    Write-Host "  -Verbose        Verbose output, prints errors and echos the raw version on success"
    Write-Host "  -Output         Set parsed semver as output in Azure Pipelines"
    Write-Host "  -Test           Run tests"
    Write-Host "  -Help           Print usage"
    Write-Host
    Write-Host "Branch Name:"
    Write-Host "The branch name to validate and parse, e.g. 'Release/R5.2.1'."
    Write-Host "The branch name must begin with 'Release/' or 'release/', may have an optional semver prefix of 'R' or 'r',"
    Write-Host "and must end with a semver containing a major and minor value with an optional patch value."
    Write-Host
}

# Function to run tests
function Run-Tests {
    $validPrefixes = @("Release/R", "release/R", "Release/r", "release/r")
    $invalidPrefixes = @("R", "r", "R/", "r/", "R/r", "r/R", "RELEASE/", "RELEASE", "REleasE/", "REleasE", "RELEASE/R", "REleasE/R", "Release/ R", "Release/R", "Release/v", "Release/V", " ", "/", ".", "v")
    $validSemvers = @("5.2.1", "5.2", "0.0.0", "0.0", "0.0.1", "1.1.0", "255.256.257", "5.2.1.1")
    $invalidSemvers = @("5", "5.", "5.2.", "0")

    $invalidBranchNames = @()
    foreach ($prefix in $invalidPrefixes) {
        foreach ($semver in $invalidSemvers) {
            $invalidBranchNames += "$prefix$semver"
        }
        foreach ($semver in $validSemvers) {
            $invalidBranchNames += "$prefix$semver"
        }
    }
    foreach ($prefix in $validPrefixes) {
        foreach ($semver in $invalidSemvers) {
            $invalidBranchNames += "$prefix$semver"
        }
    }

    $validErrors = 0
    $validTestCount = 0
    Write-Host "Running valid branch name test cases ..."
    foreach ($prefix in $validPrefixes) {
        foreach ($semver in $validSemvers) {
            $validTestCount += 2
            $branchName = "$prefix$semver"

            $validateResult = Validate-BranchName -BranchName $branchName
            if (-not $validateResult) {
                $validErrors += 1
                Write-Host "`t- Test failed: Validate-BranchName($branchName) returned as invalid but expected valid"
            }

            $parseResult = Parse-ReleaseVersion -BranchName $branchName
            if ($parseResult -ne $semver) {
                $validErrors += 1
                Write-Host "`t- Test failed: Parse-ReleaseVersion($branchName) returned $parseResult but expected $semver"
            }
        }
    }

    if ($validErrors -eq 0) {
        Write-Host "OK"
    }

    $invalidErrors = 0
    Write-Host "Running invalid branch name test cases ..."
    foreach ($branchName in $invalidBranchNames) {
        $result = Validate-BranchName -BranchName $branchName
        if ($result) {
            $invalidErrors += 1
            Write-Host "`t- Test failed: Validate-BranchName($branchName) returned as valid but expected invalid"
        }
    }

    if ($invalidErrors -eq 0) {
        Write-Host "OK"
    }

    Write-Host
    Write-Host "Tests results: $($validErrors + $invalidErrors) failed of $($validTestCount + $invalidBranchNames.Count) tests"
    Write-Host

    if ($validErrors + $invalidErrors -gt 0) {
        exit 1
    } else {
        exit 0
    }
}

# Main function
function Main {
    param (
        [switch]$Verbose,
        [switch]$Output,
        [switch]$Test,
        [switch]$Help,
        [string]$BranchName
    )

    if ($Help) {
        Print-Usage
        return
    }

    if ($Test) {
        Run-Tests
        return
    }

    if (-not $BranchName) {
        Print-Usage
        return
    }

    $validatedBranchName = Validate-BranchName -BranchName $BranchName
    if (-not $validatedBranchName) {
        if ($Verbose) {
            Write-Host "Invalid branch name: $BranchName"
        }
        exit 1
    }

    $parsedVersion = Parse-ReleaseVersion -BranchName $BranchName
    if ($parsedVersion -eq "error") {
        if ($Verbose) {
            Write-Host "Failed to parse version from branch name: $BranchName"
        }
        exit 1
    }

    if ($Verbose) {
        Write-Host "Parsed version: $parsedVersion"
    }

    if ($Output) {
        Write-Output $parsedVersion
    }
}

# Entry point
Main @args