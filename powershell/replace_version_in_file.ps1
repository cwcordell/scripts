# Usage: .\replace_version_in_file.ps1 -FilePath <file_path> -NewVersion <new_version>
# Example: .\replace_version_in_file.ps1 -FilePath "path\to\file.js" -NewVersion "4.2.0"

param (
    [string]$FilePath,
    [string]$NewVersion
)

if (-not $FilePath -or -not $NewVersion) {
    Write-Host "Usage: .\replace_version_in_file.ps1 -FilePath <file_path> -NewVersion <new_version>"
    exit 1
}

Write-Host "Displaying $FilePath before update..."
Get-Content $FilePath
Write-Host

Write-Host "Updating $FilePath with new $NewVersion version ..."

(Get-Content $FilePath) -replace "export const AIS_RELEASEVERSION = '.*';", "export const AIS_RELEASEVERSION = '$NewVersion';" | Set-Content $FilePath

# Check if the file was updated properly
if (Select-String -Path $FilePath -Pattern "export const AIS_RELEASEVERSION = '$NewVersion';") {
    Write-Host "Version updated to $NewVersion in $FilePath"
} else {
    Write-Host "Failed to update the version in $FilePath"
    exit 1
}

Write-Host
Write-Host "Displaying $FilePath after update..."
Get-Content $FilePath
