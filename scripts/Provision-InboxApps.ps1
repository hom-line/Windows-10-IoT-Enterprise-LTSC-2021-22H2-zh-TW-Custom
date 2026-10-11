#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Provisions the Microsoft Inbox Apps used by this project.

.DESCRIPTION
    Provisioning utility for:
    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom

    Reference configuration:
      - Windows 10 x64
      - 18 framework / architecture combinations
      - 14 main Microsoft Inbox Apps

    The script:
      - DOES NOT remove existing Appx packages
      - DOES NOT remove existing frameworks
      - provisions frameworks first
      - provisions main apps second
      - uses Microsoft Offline License XML files for main apps
      - creates a transcript log
      - stops when required source files are missing or ambiguous

.PARAMETER SourceRoot
    Root of the mounted Microsoft Inbox Apps media.

    Expected structure:

        <SourceRoot>\
        ├── amd64fre
        └── x86fre

    Example:

        G:\

    If omitted, the script attempts to detect exactly one mounted drive
    containing both folders.

.PARAMETER LogPath
    Optional custom transcript path.

.EXAMPLE
    .\Provision-InboxApps.ps1 -SourceRoot "G:\"

.EXAMPLE
    .\Provision-InboxApps.ps1

.NOTES
    This script modifies the running Windows installation.

    Use it on the intended reference image, preferably in Audit Mode.

    This repository does not distribute Microsoft Inbox App packages
    or Microsoft license files.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

# ============================================================
# 1. General helpers
# ============================================================

function Write-Section {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " $Title"
    Write-Host "============================================================"
    Write-Host ""
}

function Normalize-Architecture {
    param (
        $Architecture
    )

    if ($null -eq $Architecture) {
        return ""
    }

    $Text = $Architecture.ToString().ToLowerInvariant()

    switch -Regex ($Text) {
        "^(9|x64|amd64)$" {
            return "x64"
        }

        "^(0|x86)$" {
            return "x86"
        }

        "^(12|arm64)$" {
            return "arm64"
        }

        "^(11|neutral)$" {
            return "neutral"
        }

        default {
            return $Text
        }
    }
}

function Get-ProvisionedPackages {
    return @(
        Get-AppxProvisionedPackage -Online
    )
}

function Get-ProvisionedMatch {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$Architecture
    )

    $Packages = Get-ProvisionedPackages

    if ([string]::IsNullOrWhiteSpace($Architecture)) {

        return @(
            $Packages |
            Where-Object {
                $_.DisplayName -eq $DisplayName
            }
        )
    }

    return @(
        $Packages |
        Where-Object {

            $_.DisplayName -eq $DisplayName -and
            (Normalize-Architecture $_.Architecture) -eq $Architecture
        }
    )
}

# ============================================================
# 2. Locate source media
# ============================================================

function Find-InboxAppsSource {

    if (-not [string]::IsNullOrWhiteSpace($SourceRoot)) {

        $ResolvedRoot = $SourceRoot.TrimEnd("\")

        if (-not (Test-Path "$ResolvedRoot\amd64fre")) {
            throw "amd64fre was not found under: $ResolvedRoot"
        }

        if (-not (Test-Path "$ResolvedRoot\x86fre")) {
            throw "x86fre was not found under: $ResolvedRoot"
        }

        return $ResolvedRoot
    }

    $Candidates = @()

    foreach ($Drive in Get-PSDrive -PSProvider FileSystem) {

        if ([string]::IsNullOrWhiteSpace($Drive.Root)) {
            continue
        }

        try {

            $AMD64Path = Join-Path $Drive.Root "amd64fre"
            $X86Path   = Join-Path $Drive.Root "x86fre"

            if (
                (Test-Path $AMD64Path) -and
                (Test-Path $X86Path)
            ) {
                $Candidates += $Drive.Root.TrimEnd("\")
            }
        }
        catch {
            # Ignore inaccessible drives.
        }
    }

    if ($Candidates.Count -eq 0) {

        throw @"
Unable to locate Microsoft Inbox Apps media.

Expected folders:

    amd64fre
    x86fre

Specify the source explicitly, for example:

    .\Provision-InboxApps.ps1 -SourceRoot "G:\"
"@
    }

    if ($Candidates.Count -gt 1) {

        $List = $Candidates -join ", "

        throw @"
Multiple possible Inbox Apps sources were detected:

    $List

Specify the correct source explicitly with -SourceRoot.
"@
    }

    return $Candidates[0]
}

# ============================================================
# 3. Strict package-file discovery
# ============================================================

function Find-PackageFile {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$IncludeRegex,

        [Parameter(Mandatory = $false)]
        [string]$ExcludeRegex
    )

    $AllowedExtensions = @(
        ".appx",
        ".appxbundle",
        ".msix",
        ".msixbundle"
    )

    $Files = @(
        Get-ChildItem `
            -Path $Folder `
            -File `
            -Recurse `
            -ErrorAction Stop |
        Where-Object {

            $ExtensionOK =
                $AllowedExtensions -contains
                $_.Extension.ToLowerInvariant()

            $IncludeOK =
                $_.Name -match $IncludeRegex

            $ExcludeOK = $true

            if (-not [string]::IsNullOrWhiteSpace($ExcludeRegex)) {
                $ExcludeOK = $_.Name -notmatch $ExcludeRegex
            }

            $ExtensionOK -and
            $IncludeOK -and
            $ExcludeOK
        }
    )

    if ($Files.Count -eq 0) {

        throw @"
Required package was not found.

Folder:
$Folder

Match:
$IncludeRegex
"@
    }

    if ($Files.Count -gt 1) {

        $FoundFiles = (
            $Files |
            ForEach-Object { $_.FullName }
        ) -join "`r`n"

        throw @"
More than one matching package was found.

The script will not guess which package should be used.

Matches:
$FoundFiles
"@
    }

    return $Files[0].FullName
}

function Find-LicenseFile {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    $EscapedName = [regex]::Escape($PackageName)

    $Candidates = @(
        Get-ChildItem `
            -Path $Folder `
            -File `
            -Recurse `
            -Filter "*.xml" `
            -ErrorAction Stop |
        Where-Object {
            $_.Name -match "(?i)^$EscapedName"
        }
    )

    if ($Candidates.Count -eq 0) {

        throw @"
No license XML was found for:

$PackageName

Search folder:
$Folder
"@
    }

    if ($Candidates.Count -eq 1) {
        return $Candidates[0].FullName
    }

    # Prefer an XML file explicitly containing License/Licence.
    $Preferred = @(
        $Candidates |
        Where-Object {
            $_.Name -match "(?i)licen[cs]e"
        }
    )

    if ($Preferred.Count -eq 1) {
        return $Preferred[0].FullName
    }

    $FoundFiles = (
        $Candidates |
        ForEach-Object { $_.FullName }
    ) -join "`r`n"

    throw @"
More than one possible license XML was found for:

$PackageName

The script will not guess which license should be used.

Matches:
$FoundFiles
"@
}

# ============================================================
# 4. Framework definition
# ============================================================

$FrameworkDefinitions = @(

    # --------------------------------------------------------
    # .NET Native Framework 1.7
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Framework\.1\.7.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Framework\.1\.7.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # .NET Native Framework 2.2
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Framework\.2\.2.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Framework\.2\.2.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # .NET Native Runtime 1.7
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Runtime\.1\.7.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Runtime\.1\.7.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # .NET Native Runtime 2.2
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Runtime\.2\.2.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.NET\.Native\.Runtime\.2\.2.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # Microsoft UI XAML 2.0
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.0"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.0.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.0"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.0.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # Microsoft UI XAML 2.1
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.1"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.1.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.1"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.1.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # Microsoft UI XAML 2.3
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.3"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.3.*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.UI.Xaml.2.3"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.UI\.Xaml\.2\.3.*"
        ExcludeRegex = ""
    },

    # --------------------------------------------------------
    # Microsoft VCLibs 14.00
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.VCLibs.140.00"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.VCLibs.*14\.00.*"
        ExcludeRegex = "(?i)Desktop|UWPDesktop"
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.VCLibs.140.00"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.VCLibs.*14\.00.*"
        ExcludeRegex = "(?i)Desktop|UWPDesktop"
    },

    # --------------------------------------------------------
    # Microsoft VCLibs 14.00 Desktop
    # --------------------------------------------------------

    [PSCustomObject]@{
        DisplayName  = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x64"
        Folder       = "amd64fre"
        IncludeRegex = "(?i)^Microsoft\.VCLibs.*14\.00.*(Desktop|UWPDesktop).*"
        ExcludeRegex = ""
    },

    [PSCustomObject]@{
        DisplayName  = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x86"
        Folder       = "x86fre"
        IncludeRegex = "(?i)^Microsoft\.VCLibs.*14\.00.*(Desktop|UWPDesktop).*"
        ExcludeRegex = ""
    }
)

# ============================================================
# 5. Main App definition
# ============================================================

$AppDefinitions = @(

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsStore"
        ExpectedVersion = "11910.1002.513.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.StorePurchaseApp"
        ExpectedVersion = "11811.1001.1813.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.DesktopAppInstaller"
        ExpectedVersion = "2019.125.2243.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsCalculator"
        ExpectedVersion = "2020.1906.55.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.ScreenSketch"
        ExpectedVersion = "2019.904.1644.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsCamera"
        ExpectedVersion = "2018.826.98.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.Windows.Photos"
        ExpectedVersion = "2019.19071.12548.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.ZuneMusic"
        ExpectedVersion = "2019.19071.19011.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.AV1VideoExtension"
        ExpectedVersion = "1.1.30781.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.VP9VideoExtensions"
        ExpectedVersion = "1.0.22681.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.HEIFImageExtension"
        ExpectedVersion = "1.0.22742.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WebpImageExtension"
        ExpectedVersion = "1.0.22753.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WebMediaExtensions"
        ExpectedVersion = "1.0.20875.0"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.MPEG2VideoExtension"
        ExpectedVersion = "1.0.22661.0"
    }
)

# ============================================================
# 6. Provisioning functions
# ============================================================

function Install-FrameworkPackage {

    param (
        [Parameter(Mandatory = $true)]
        $Definition,

        [Parameter(Mandatory = $true)]
        [string]$AMD64Folder,

        [Parameter(Mandatory = $true)]
        [string]$X86Folder
    )

    $Existing = @(
        Get-ProvisionedMatch `
            -DisplayName $Definition.DisplayName `
            -Architecture $Definition.Architecture
    )

    if ($Existing.Count -gt 0) {

        $Versions = (
            $Existing |
            ForEach-Object {
                $_.Version.ToString()
            } |
            Sort-Object -Unique
        ) -join ", "

        Write-Host "[SKIP] $($Definition.DisplayName) [$($Definition.Architecture)]"
        Write-Host "       Already provisioned: $Versions"

        return "Skipped"
    }

    if ($Definition.Folder -eq "amd64fre") {
        $SearchFolder = $AMD64Folder
    }
    elseif ($Definition.Folder -eq "x86fre") {
        $SearchFolder = $X86Folder
    }
    else {
        throw "Unknown framework source folder: $($Definition.Folder)"
    }

    $PackagePath = Find-PackageFile `
        -Folder $SearchFolder `
        -IncludeRegex $Definition.IncludeRegex `
        -ExcludeRegex $Definition.ExcludeRegex

    Write-Host "[ADD ] $($Definition.DisplayName) [$($Definition.Architecture)]"
    Write-Host "       $PackagePath"

    Add-AppxProvisionedPackage `
        -Online `
        -PackagePath $PackagePath `
        -SkipLicense `
        -ErrorAction Stop |
        Out-Null

    $Verify = @(
        Get-ProvisionedMatch `
            -DisplayName $Definition.DisplayName `
            -Architecture $Definition.Architecture
    )

    if ($Verify.Count -eq 0) {
        throw "Framework provisioning verification failed: $($Definition.DisplayName)"
    }

    Write-Host "[ OK ] Provisioned successfully."
    Write-Host ""

    return "Added"
}

function Install-MainApp {

    param (
        [Parameter(Mandatory = $true)]
        $Definition,

        [Parameter(Mandatory = $true)]
        [string]$AMD64Folder
    )

    $Existing = @(
        Get-ProvisionedMatch `
            -DisplayName $Definition.DisplayName
    )

    if ($Existing.Count -gt 0) {

        $Versions = (
            $Existing |
            ForEach-Object {
                $_.Version.ToString()
            } |
            Sort-Object -Unique
        ) -join ", "

        Write-Host "[SKIP] $($Definition.DisplayName)"
        Write-Host "       Already provisioned: $Versions"

        if ($Versions -notcontains $Definition.ExpectedVersion) {

            Write-Host "       Reference version: $($Definition.ExpectedVersion)"
            Write-Host "       Existing package is not removed or downgraded."
        }

        Write-Host ""

        return "Skipped"
    }

    $EscapedName = [regex]::Escape($Definition.DisplayName)

    $PackagePath = Find-PackageFile `
        -Folder $AMD64Folder `
        -IncludeRegex "(?i)^$EscapedName.*"

    $LicensePath = Find-LicenseFile `
        -Folder $AMD64Folder `
        -PackageName $Definition.DisplayName

    Write-Host "[ADD ] $($Definition.DisplayName)"
    Write-Host "       Package : $PackagePath"
    Write-Host "       License : $LicensePath"

    Add-AppxProvisionedPackage `
        -Online `
        -PackagePath $PackagePath `
        -LicensePath $LicensePath `
        -ErrorAction Stop |
        Out-Null

    $Verify = @(
        Get-ProvisionedMatch `
            -DisplayName $Definition.DisplayName
    )

    if ($Verify.Count -eq 0) {
        throw "Application provisioning verification failed: $($Definition.DisplayName)"
    }

    $DetectedVersions = (
        $Verify |
        ForEach-Object {
            $_.Version.ToString()
        } |
        Sort-Object -Unique
    )

    Write-Host "[ OK ] Provisioned successfully."
    Write-Host "       Detected version: $($DetectedVersions -join ', ')"

    if ($Definition.ExpectedVersion -notin $DetectedVersions) {

        Write-Host "[INFO] Version differs from project reference:"
        Write-Host "       Reference : $($Definition.ExpectedVersion)"
        Write-Host "       Detected  : $($DetectedVersions -join ', ')"
    }

    Write-Host ""

    return "Added"
}

# ============================================================
# 7. Main execution
# ============================================================

$TranscriptStarted = $false

try {

    Write-Section "Microsoft Inbox Apps Provisioning"

    # --------------------------------------------------------
    # Verify OS architecture
    # --------------------------------------------------------

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "This project provisioning script requires x64 Windows."
    }

    Write-Host "Operating system : x64"
    Write-Host "PowerShell       : $($PSVersionTable.PSVersion)"
    Write-Host "User             : $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
    Write-Host ""

    # --------------------------------------------------------
    # Resolve source
    # --------------------------------------------------------

    $ResolvedSource = Find-InboxAppsSource

    $AMD64Folder = Join-Path $ResolvedSource "amd64fre"
    $X86Folder   = Join-Path $ResolvedSource "x86fre"

    Write-Host "Inbox Apps source:"
    Write-Host "  $ResolvedSource"
    Write-Host ""

    Write-Host "amd64fre:"
    Write-Host "  $AMD64Folder"
    Write-Host ""

    Write-Host "x86fre:"
    Write-Host "  $X86Folder"
    Write-Host ""

    if (-not (Test-Path $AMD64Folder)) {
        throw "amd64fre source directory is missing."
    }

    if (-not (Test-Path $X86Folder)) {
        throw "x86fre source directory is missing."
    }

    # --------------------------------------------------------
    # Transcript
    # --------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($LogPath)) {

        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

        $LogPath = Join-Path `
            (Get-Location).Path `
            "InboxApps_Provision_$Timestamp.log"
    }

    Start-Transcript `
        -Path $LogPath `
        -Force |
        Out-Null

    $TranscriptStarted = $true

    Write-Host "Log:"
    Write-Host "  $LogPath"
    Write-Host ""

    Write-Host "IMPORTANT:"
    Write-Host "  Existing Appx packages are NOT removed."
    Write-Host "  Existing frameworks are NOT removed."
    Write-Host "  Existing provisioned packages are skipped."
    Write-Host ""

    # --------------------------------------------------------
    # Counters
    # --------------------------------------------------------

    $FrameworkAdded   = 0
    $FrameworkSkipped = 0

    $AppAdded         = 0
    $AppSkipped       = 0

    # ========================================================
    # 8. Provision frameworks
    # ========================================================

    Write-Section "Step 1 - Frameworks / Dependencies"

    foreach ($Framework in $FrameworkDefinitions) {

        $Result = Install-FrameworkPackage `
            -Definition $Framework `
            -AMD64Folder $AMD64Folder `
            -X86Folder $X86Folder

        if ($Result -eq "Added") {
            $FrameworkAdded++
        }
        elseif ($Result -eq "Skipped") {
            $FrameworkSkipped++
        }
    }

    # ========================================================
    # 9. Provision main apps
    # ========================================================

    Write-Section "Step 2 - Main Inbox Apps"

    foreach ($App in $AppDefinitions) {

        $Result = Install-MainApp `
            -Definition $App `
            -AMD64Folder $AMD64Folder

        if ($Result -eq "Added") {
            $AppAdded++
        }
        elseif ($Result -eq "Skipped") {
            $AppSkipped++
        }
    }

    # ========================================================
    # 10. Final basic verification
    # ========================================================

    Write-Section "Step 3 - Provisioning Summary"

    $FinalProvisioned = @(
        Get-AppxProvisionedPackage -Online
    )

    Write-Host "Framework definitions : $($FrameworkDefinitions.Count)"
    Write-Host "  Added               : $FrameworkAdded"
    Write-Host "  Already present     : $FrameworkSkipped"
    Write-Host ""

    Write-Host "Main App definitions  : $($AppDefinitions.Count)"
    Write-Host "  Added               : $AppAdded"
    Write-Host "  Already present     : $AppSkipped"
    Write-Host ""

    # --------------------------------------------------------
    # Confirm expected main apps exist
    # --------------------------------------------------------

    $MissingApps = @()

    foreach ($App in $AppDefinitions) {

        $Found = @(
            $FinalProvisioned |
            Where-Object {
                $_.DisplayName -eq $App.DisplayName
            }
        )

        if ($Found.Count -eq 0) {
            $MissingApps += $App.DisplayName
        }
    }

    # --------------------------------------------------------
    # Confirm framework combinations exist
    # --------------------------------------------------------

    $MissingFrameworks = @()

    foreach ($Framework in $FrameworkDefinitions) {

        $Found = @(
            $FinalProvisioned |
            Where-Object {

                $_.DisplayName -eq $Framework.DisplayName -and
                (Normalize-Architecture $_.Architecture) -eq
                    $Framework.Architecture
            }
        )

        if ($Found.Count -eq 0) {

            $MissingFrameworks +=
                "$($Framework.DisplayName) [$($Framework.Architecture)]"
        }
    }

    Write-Host "Main Apps:"
    Write-Host "  Expected : 14"
    Write-Host "  Missing  : $($MissingApps.Count)"
    Write-Host ""

    Write-Host "Framework combinations:"
    Write-Host "  Expected : 18"
    Write-Host "  Missing  : $($MissingFrameworks.Count)"
    Write-Host ""

    if ($MissingApps.Count -gt 0) {

        Write-Host "[ERROR] Missing main Apps:"
        foreach ($Name in $MissingApps) {
            Write-Host "  $Name"
        }

        throw "Main Inbox App verification failed."
    }

    if ($MissingFrameworks.Count -gt 0) {

        Write-Host "[ERROR] Missing framework combinations:"
        foreach ($Name in $MissingFrameworks) {
            Write-Host "  $Name"
        }

        throw "Framework verification failed."
    }

    # ========================================================
    # 11. Installed-but-not-provisioned check
    # ========================================================

    Write-Section "Step 4 - Installed Store Apps Not Provisioned"

    $ProvisionedNames = @(
        $FinalProvisioned |
        Select-Object -ExpandProperty DisplayName -Unique
    )

    $Remaining = @(
        Get-AppxPackage -AllUsers |
        Where-Object {
            $_.SignatureKind -eq "Store" -and
            -not $_.NonRemovable -and
            $_.Name -notin $ProvisionedNames
        }
    )

    if ($Remaining.Count -eq 0) {

        Write-Host "[PASS] Remaining count = 0"
    }
    else {

        Write-Host "[WARNING] Installed Store Apps exist that are"
        Write-Host "          not provisioned for the image."
        Write-Host ""

        $Remaining |
            Select-Object `
                Name,
                Version,
                Architecture,
                IsFramework,
                PackageFullName |
            Format-Table -AutoSize

        Write-Host ""
        Write-Host "Remaining count = $($Remaining.Count)"
    }

    # ========================================================
    # 12. HEVC information
    # ========================================================

    Write-Section "HEVC"

    $HEVC = @(
        $FinalProvisioned |
        Where-Object {
            $_.DisplayName -match "HEVC"
        }
    )

    if ($HEVC.Count -eq 0) {

        Write-Host "[INFO] HEVC is not provisioned."
        Write-Host "       This matches the project reference package set."
    }
    else {

        Write-Host "[INFO] HEVC package detected:"
        Write-Host ""

        $HEVC |
            Select-Object `
                DisplayName,
                Version,
                Architecture,
                PackageName |
            Format-Table -AutoSize
    }

    # ========================================================
    # 13. Final result
    # ========================================================

    Write-Section "Final Result"

    Write-Host "[PASS] All required Framework combinations are present."
    Write-Host "[PASS] All required Main Inbox Apps are present."
    Write-Host ""

    if ($Remaining.Count -eq 0) {

        Write-Host "[PASS] Remaining Store App count = 0"
        Write-Host ""
        Write-Host "Reference-image Appx provisioning is ready"
        Write-Host "for final verification and Sysprep."
    }
    else {

        Write-Host "[WARNING] Provisioning completed, but the system"
        Write-Host "          still contains installed Store Apps that"
        Write-Host "          are not provisioned."
        Write-Host ""
        Write-Host "Investigate these packages before final Sysprep."
    }

    Write-Host ""
    Write-Host "Recommended final verification:"
    Write-Host ""
    Write-Host "  .\Verify-InboxApps.ps1"
    Write-Host ""
}
catch {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " PROVISIONING FAILED"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host $_.Exception.Message
    Write-Host ""

    Write-Host "No automatic package removal or rollback was performed."
    Write-Host ""
    Write-Host "Correct the reported problem and run the script again."
    Write-Host "Already provisioned packages will be skipped."

    throw
}
finally {

    if ($TranscriptStarted) {

        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Do not mask the original provisioning result.
        }
    }
}
