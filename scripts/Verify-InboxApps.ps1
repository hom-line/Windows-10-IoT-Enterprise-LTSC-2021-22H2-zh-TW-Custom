#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Provisions the Microsoft Inbox Apps used by this project.

.DESCRIPTION
    Provisioning utility for:

    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom

    Reference configuration:

      Windows 10
      Version 22H2
      Build family 19045
      Reference build 19045.7725
      Architecture x64
      Language zh-TW

    The script provisions:

      - 18 framework / architecture combinations
      - 14 main Microsoft Inbox Apps

    Safety design:

      - Full preflight validation before any package is added
      - Does NOT remove existing Appx packages
      - Does NOT remove existing frameworks
      - Does NOT downgrade existing provisioned packages
      - Existing provisioned packages are skipped
      - Missing or ambiguous source packages stop execution
      - Missing or ambiguous license files stop execution
      - Final Installed-vs-Provisioned Appx state is verified
      - Supports a read-only -PreflightOnly mode

.PARAMETER SourceRoot
    Root of the mounted Microsoft Inbox Apps media.

    Expected structure:

        <SourceRoot>\
        ├── amd64fre
        └── x86fre

    Example:

        G:\

    If omitted, the script searches mounted file-system drives and
    requires exactly one drive containing both folders.

.PARAMETER LogPath
    Optional transcript log path.

    It is recommended to store the log outside the reference Windows
    partition so that the log is not captured into the final WIM.

    Example:

        D:\Logs\InboxApps_Provision.log

    If omitted, a temporary log is created under the current user's
    TEMP directory.

.PARAMETER PreflightOnly
    Performs all source, package, license, architecture, and build
    checks without modifying the Windows image.

.PARAMETER AllowUnsupportedBuild
    Allows execution on a Windows build other than 19045.

    This is intended only for testing.
    The project's validated target build family is 19045.

.EXAMPLE
    .\Provision-InboxApps.ps1 -SourceRoot "G:\" -PreflightOnly

.EXAMPLE
    .\Provision-InboxApps.ps1 `
        -SourceRoot "G:\" `
        -LogPath "D:\Logs\InboxApps_Provision.log"

.NOTES
    This script modifies the running Windows installation unless
    -PreflightOnly is specified.

    The Microsoft Store and other Inbox Apps provisioned by this
    script are custom components of this project. They do not
    represent the default App configuration of an official
    Windows 10 IoT Enterprise LTSC 2021 installation.

    The project's 22H2 / Build 19045 configuration is a custom
    LTSC-2021-based image and is not an official Microsoft
    LTSC 22H2 release.

    This repository does not redistribute Microsoft Inbox App
    packages or Microsoft license files.
#>

[CmdletBinding()]
param (

    [Parameter(Mandatory = $false)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $false)]
    [string]$LogPath,

    [Parameter(Mandatory = $false)]
    [switch]$PreflightOnly,

    [Parameter(Mandatory = $false)]
    [switch]$AllowUnsupportedBuild
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"


# ============================================================
# 1. Helper functions
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


function Convert-AppxArchitecture {

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


function Get-CurrentProvisionedPackages {

    return @(
        Get-AppxProvisionedPackage `
            -Online `
            -ErrorAction Stop
    )
}


function Get-ProvisionedMatch {

    param (

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$Architecture
    )

    $Packages = Get-CurrentProvisionedPackages

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
            (Convert-AppxArchitecture $_.Architecture) -eq $Architecture
        }
    )
}


function Resolve-InboxAppsSource {

    param (
        [string]$RequestedRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedRoot)) {

        if (-not (Test-Path -LiteralPath $RequestedRoot)) {
            throw "SourceRoot does not exist: $RequestedRoot"
        }

        $ResolvedRoot = (Resolve-Path -LiteralPath $RequestedRoot).Path

        $AMD64Path = Join-Path $ResolvedRoot "amd64fre"
        $X86Path   = Join-Path $ResolvedRoot "x86fre"

        if (-not (Test-Path -LiteralPath $AMD64Path)) {
            throw "amd64fre was not found under: $ResolvedRoot"
        }

        if (-not (Test-Path -LiteralPath $X86Path)) {
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
                (Test-Path -LiteralPath $AMD64Path) -and
                (Test-Path -LiteralPath $X86Path)
            ) {
                $Candidates += $Drive.Root
            }
        }
        catch {
            # Ignore inaccessible drives during automatic detection.
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

        $CandidateText = $Candidates -join ", "

        throw @"
Multiple possible Inbox Apps sources were detected:

    $CandidateText

The script will not guess which source should be used.

Specify the correct source explicitly:

    .\Provision-InboxApps.ps1 -SourceRoot "G:\"
"@
    }

    return $Candidates[0]
}


function Find-SinglePackageFile {

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

    $Matches = @(
        Get-ChildItem `
            -LiteralPath $Folder `
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

    if ($Matches.Count -eq 0) {

        throw @"
Required package was not found.

Folder:
    $Folder

Pattern:
    $IncludeRegex
"@
    }

    if ($Matches.Count -eq 1) {
        return $Matches[0].FullName
    }

    # Prefer one bundle if both bundle and individual packages exist.
    $Bundles = @(
        $Matches |
        Where-Object {
            $_.Extension.ToLowerInvariant() -in @(
                ".appxbundle",
                ".msixbundle"
            )
        }
    )

    if ($Bundles.Count -eq 1) {
        return $Bundles[0].FullName
    }

    $MatchText = (
        $Matches |
        ForEach-Object {
            $_.FullName
        }
    ) -join "`r`n"

    throw @"
More than one matching package was found.

The script will not guess which package should be used.

Matches:

$MatchText
"@
}


function Find-SingleLicenseFile {

    param (

        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    $EscapedName = [regex]::Escape($DisplayName)

    $Candidates = @(
        Get-ChildItem `
            -LiteralPath $Folder `
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
No Microsoft Offline License XML was found for:

    $DisplayName

Search folder:

    $Folder
"@
    }

    if ($Candidates.Count -eq 1) {
        return $Candidates[0].FullName
    }

    # Prefer an XML explicitly containing "license" or "licence".
    $Preferred = @(
        $Candidates |
        Where-Object {
            $_.Name -match "(?i)licen[cs]e"
        }
    )

    if ($Preferred.Count -eq 1) {
        return $Preferred[0].FullName
    }

    $CandidateText = (
        $Candidates |
        ForEach-Object {
            $_.FullName
        }
    ) -join "`r`n"

    throw @"
More than one possible license XML was found for:

    $DisplayName

The script will not guess which license should be used.

Matches:

$CandidateText
"@
}


function Ensure-LogDirectory {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ([string]::IsNullOrWhiteSpace($Parent)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Parent)) {

        New-Item `
            -ItemType Directory `
            -Path $Parent `
            -Force |
        Out-Null
    }
}


# ============================================================
# 2. Framework definitions
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
# 3. Main App definitions
# ============================================================

$AppDefinitions = @(

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsStore"
        ExpectedVersion = "11910.1002.513.0"
        PackageRegex    = "(?i)^Microsoft\.WindowsStore_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.StorePurchaseApp"
        ExpectedVersion = "11811.1001.1813.0"
        PackageRegex    = "(?i)^Microsoft\.StorePurchaseApp_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.DesktopAppInstaller"
        ExpectedVersion = "2019.125.2243.0"
        PackageRegex    = "(?i)^Microsoft\.DesktopAppInstaller_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsCalculator"
        ExpectedVersion = "2020.1906.55.0"
        PackageRegex    = "(?i)^Microsoft\.WindowsCalculator_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.ScreenSketch"
        ExpectedVersion = "2019.904.1644.0"
        PackageRegex    = "(?i)^Microsoft\.ScreenSketch_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WindowsCamera"
        ExpectedVersion = "2018.826.98.0"
        PackageRegex    = "(?i)^Microsoft\.WindowsCamera_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.Windows.Photos"
        ExpectedVersion = "2019.19071.12548.0"
        PackageRegex    = "(?i)^Microsoft\.Windows\.Photos_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.ZuneMusic"
        ExpectedVersion = "2019.19071.19011.0"
        PackageRegex    = "(?i)^Microsoft\.ZuneMusic_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.AV1VideoExtension"
        ExpectedVersion = "1.1.30781.0"
        PackageRegex    = "(?i)^Microsoft\.AV1VideoExtension_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.VP9VideoExtensions"
        ExpectedVersion = "1.0.22681.0"
        PackageRegex    = "(?i)^Microsoft\.VP9VideoExtensions_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.HEIFImageExtension"
        ExpectedVersion = "1.0.22742.0"
        PackageRegex    = "(?i)^Microsoft\.HEIFImageExtension_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WebpImageExtension"
        ExpectedVersion = "1.0.22753.0"
        PackageRegex    = "(?i)^Microsoft\.WebpImageExtension_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.WebMediaExtensions"
        ExpectedVersion = "1.0.20875.0"
        PackageRegex    = "(?i)^Microsoft\.WebMediaExtensions_.*"
    },

    [PSCustomObject]@{
        DisplayName     = "Microsoft.MPEG2VideoExtension"
        ExpectedVersion = "1.0.22661.0"
        PackageRegex    = "(?i)^Microsoft\.MPEG2VideoExtension_.*"
    }
)


# ============================================================
# 4. Main execution
# ============================================================

$TranscriptStarted = $false
$ExitCode = 1

try {

    Write-Section "Microsoft Inbox Apps Provisioning"

    if ($PreflightOnly) {
        Write-Host "Mode : PRE-FLIGHT ONLY"
        Write-Host ""
        Write-Host "No Appx packages will be installed or modified."
    }
    else {
        Write-Host "Mode : PROVISIONING"
        Write-Host ""
        Write-Host "The running Windows reference image may be modified."
    }

    Write-Host ""


    # ========================================================
    # 5. Operating-system validation
    # ========================================================

    Write-Section "Preflight 1 - Operating System"

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "This project requires an x64 Windows operating system."
    }

    $CV = Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    $CurrentBuild   = [string]$CV.CurrentBuild
    $UBR            = $CV.UBR
    $DisplayVersion = $CV.DisplayVersion

    if ([string]::IsNullOrWhiteSpace($DisplayVersion)) {
        $DisplayVersion = $CV.ReleaseId
    }

    if ($null -ne $UBR) {
        $FullBuild = "$CurrentBuild.$UBR"
    }
    else {
        $FullBuild = $CurrentBuild
    }

    Write-Host "Architecture : x64"
    Write-Host "Version      : $DisplayVersion"
    Write-Host "Build        : $FullBuild"
    Write-Host ""

    if ($CurrentBuild -ne "19045") {

        if ($AllowUnsupportedBuild) {

            Write-Host "[WARNING] Unsupported build override enabled."
            Write-Host ""
            Write-Host "Detected build family : $CurrentBuild"
            Write-Host "Validated project     : 19045"
            Write-Host ""
        }
        else {

            throw @"
Unsupported Windows build family.

Detected:
    $CurrentBuild

Validated project build family:
    19045

This script is intended for the project's
Windows 10 22H2 / Build 19045 reference image.

For testing only, this check can be overridden with:

    -AllowUnsupportedBuild
"@
        }
    }
    else {

        Write-Host "[PASS] Windows build family = 19045"
    }


    # ========================================================
    # 6. Source-media validation
    # ========================================================

    Write-Section "Preflight 2 - Inbox Apps Source"

    $ResolvedSource =
        Resolve-InboxAppsSource `
            -RequestedRoot $SourceRoot

    $AMD64Folder =
        Join-Path $ResolvedSource "amd64fre"

    $X86Folder =
        Join-Path $ResolvedSource "x86fre"

    Write-Host "Source root:"
    Write-Host "  $ResolvedSource"
    Write-Host ""

    Write-Host "amd64fre:"
    Write-Host "  $AMD64Folder"
    Write-Host ""

    Write-Host "x86fre:"
    Write-Host "  $X86Folder"
    Write-Host ""

    Write-Host "[PASS] Required source directories detected."


    # ========================================================
    # 7. Configure transcript
    # ========================================================

    if ([string]::IsNullOrWhiteSpace($LogPath)) {

        $Timestamp =
            Get-Date -Format "yyyyMMdd_HHmmss"

        if ($PreflightOnly) {
            $LogName =
                "InboxApps_Preflight_$Timestamp.log"
        }
        else {
            $LogName =
                "InboxApps_Provision_$Timestamp.log"
        }

        $LogPath =
            Join-Path $env:TEMP $LogName

        Write-Host ""
        Write-Host "[INFO] No external LogPath was specified."
        Write-Host ""
        Write-Host "Temporary log:"
        Write-Host "  $LogPath"
        Write-Host ""
        Write-Host "For a reference-image build, consider using an"
        Write-Host "external data drive for the final provisioning log."
    }

    Ensure-LogDirectory -Path $LogPath

    Start-Transcript `
        -Path $LogPath `
        -Force |
    Out-Null

    $TranscriptStarted = $true

    Write-Host ""
    Write-Host "Transcript:"
    Write-Host "  $LogPath"


    # ========================================================
    # 8. Load current provisioning state
    # ========================================================

    Write-Section "Preflight 3 - Current Provisioning State"

    $InitialProvisioned =
        Get-CurrentProvisionedPackages

    Write-Host "Current provisioned packages:"
    Write-Host "  $($InitialProvisioned.Count)"
    Write-Host ""


    # ========================================================
    # 9. Resolve ALL framework source packages
    #    BEFORE making any system changes
    # ========================================================

    Write-Section "Preflight 4 - Framework Source Packages"

    $ResolvedFrameworks = @()

    foreach ($Definition in $FrameworkDefinitions) {

        if ($Definition.Folder -eq "amd64fre") {
            $Folder = $AMD64Folder
        }
        elseif ($Definition.Folder -eq "x86fre") {
            $Folder = $X86Folder
        }
        else {
            throw "Unknown source folder: $($Definition.Folder)"
        }

        $PackagePath =
            Find-SinglePackageFile `
                -Folder $Folder `
                -IncludeRegex $Definition.IncludeRegex `
                -ExcludeRegex $Definition.ExcludeRegex

        $ResolvedFrameworks +=
            [PSCustomObject]@{
                DisplayName  = $Definition.DisplayName
                Architecture = $Definition.Architecture
                PackagePath  = $PackagePath
            }

        Write-Host "[PASS] $($Definition.DisplayName) [$($Definition.Architecture)]"
    }

    Write-Host ""
    Write-Host "Framework source packages resolved:"
    Write-Host "  $($ResolvedFrameworks.Count) / 18"

    if ($ResolvedFrameworks.Count -ne 18) {
        throw "Framework preflight count is not 18."
    }


    # ========================================================
    # 10. Resolve ALL Main App packages and licenses
    #     BEFORE making any system changes
    # ========================================================

    Write-Section "Preflight 5 - Main App Packages and Licenses"

    $ResolvedApps = @()

    foreach ($Definition in $AppDefinitions) {

        $PackagePath =
            Find-SinglePackageFile `
                -Folder $AMD64Folder `
                -IncludeRegex $Definition.PackageRegex

        $LicensePath =
            Find-SingleLicenseFile `
                -Folder $AMD64Folder `
                -DisplayName $Definition.DisplayName

        $ResolvedApps +=
            [PSCustomObject]@{
                DisplayName     = $Definition.DisplayName
                ExpectedVersion = $Definition.ExpectedVersion
                PackagePath     = $PackagePath
                LicensePath     = $LicensePath
            }

        Write-Host "[PASS] $($Definition.DisplayName)"
    }

    Write-Host ""
    Write-Host "Main App packages resolved:"
    Write-Host "  $($ResolvedApps.Count) / 14"

    if ($ResolvedApps.Count -ne 14) {
        throw "Main App preflight count is not 14."
    }


    # ========================================================
    # 11. Preflight summary
    # ========================================================

    Write-Section "Preflight Summary"

    $ExistingFrameworkCount = 0

    foreach ($Framework in $ResolvedFrameworks) {

        $Existing = @(
            $InitialProvisioned |
            Where-Object {

                $_.DisplayName -eq $Framework.DisplayName -and
                (Convert-AppxArchitecture $_.Architecture) -eq
                    $Framework.Architecture
            }
        )

        if ($Existing.Count -gt 0) {
            $ExistingFrameworkCount++
        }
    }

    $ExistingAppCount = 0

    foreach ($App in $ResolvedApps) {

        $Existing = @(
            $InitialProvisioned |
            Where-Object {
                $_.DisplayName -eq $App.DisplayName
            }
        )

        if ($Existing.Count -gt 0) {
            $ExistingAppCount++
        }
    }

    Write-Host "Operating system:"
    Write-Host "  x64                         : PASS"
    Write-Host "  Build family                : $CurrentBuild"
    Write-Host ""

    Write-Host "Source:"
    Write-Host "  amd64fre                    : PASS"
    Write-Host "  x86fre                      : PASS"
    Write-Host ""

    Write-Host "Framework packages:"
    Write-Host "  Source packages found       : $($ResolvedFrameworks.Count) / 18"
    Write-Host "  Already provisioned        : $ExistingFrameworkCount / 18"
    Write-Host ""

    Write-Host "Main Apps:"
    Write-Host "  Packages + licenses found   : $($ResolvedApps.Count) / 14"
    Write-Host "  Already provisioned        : $ExistingAppCount / 14"
    Write-Host ""

    Write-Host "============================================================"
    Write-Host " PRE-FLIGHT PASSED"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host "All required package and license files were resolved"
    Write-Host "before any provisioning operation was started."


    # ========================================================
    # 12. Stop here when -PreflightOnly is used
    # ========================================================

    if ($PreflightOnly) {

        Write-Host ""
        Write-Host "[PASS] Preflight-only validation completed."
        Write-Host ""
        Write-Host "No Appx packages were installed, removed, or modified."
        Write-Host ""
        Write-Host "To perform provisioning, run the script again"
        Write-Host "without -PreflightOnly."

        $ExitCode = 0
    }
    else {

        # ====================================================
        # 13. Provision Frameworks
        # ====================================================

        Write-Section "Provisioning 1 - Frameworks / Dependencies"

        $FrameworkAdded = 0
        $FrameworkSkipped = 0

        foreach ($Framework in $ResolvedFrameworks) {

            $Existing = @(
                Get-ProvisionedMatch `
                    -DisplayName $Framework.DisplayName `
                    -Architecture $Framework.Architecture
            )

            if ($Existing.Count -gt 0) {

                $DetectedVersions = @(
                    $Existing |
                    ForEach-Object {
                        $_.Version.ToString()
                    } |
                    Sort-Object -Unique
                )

                Write-Host "[SKIP] $($Framework.DisplayName) [$($Framework.Architecture)]"
                Write-Host "       Existing version(s): $($DetectedVersions -join ', ')"
                Write-Host ""

                $FrameworkSkipped++
                continue
            }

            Write-Host "[ADD ] $($Framework.DisplayName) [$($Framework.Architecture)]"
            Write-Host "       $($Framework.PackagePath)"

            Add-AppxProvisionedPackage `
                -Online `
                -PackagePath $Framework.PackagePath `
                -SkipLicense `
                -ErrorAction Stop |
            Out-Null

            $Verify = @(
                Get-ProvisionedMatch `
                    -DisplayName $Framework.DisplayName `
                    -Architecture $Framework.Architecture
            )

            if ($Verify.Count -eq 0) {

                throw "Framework provisioning verification failed: $($Framework.DisplayName) [$($Framework.Architecture)]"
            }

            Write-Host "[ OK ] Provisioned successfully."
            Write-Host ""

            $FrameworkAdded++
        }


        # ====================================================
        # 14. Provision Main Apps
        # ====================================================

        Write-Section "Provisioning 2 - Main Inbox Apps"

        $AppAdded = 0
        $AppSkipped = 0

        foreach ($App in $ResolvedApps) {

            $Existing = @(
                Get-ProvisionedMatch `
                    -DisplayName $App.DisplayName
            )

            if ($Existing.Count -gt 0) {

                $DetectedVersions = @(
                    $Existing |
                    ForEach-Object {
                        $_.Version.ToString()
                    } |
                    Sort-Object -Unique
                )

                Write-Host "[SKIP] $($App.DisplayName)"
                Write-Host "       Existing version(s): $($DetectedVersions -join ', ')"

                if ($App.ExpectedVersion -notin $DetectedVersions) {

                    Write-Host "       Reference version : $($App.ExpectedVersion)"
                    Write-Host "       Existing package is NOT removed or downgraded."
                }

                Write-Host ""

                $AppSkipped++
                continue
            }

            Write-Host "[ADD ] $($App.DisplayName)"
            Write-Host "       Package : $($App.PackagePath)"
            Write-Host "       License : $($App.LicensePath)"

            Add-AppxProvisionedPackage `
                -Online `
                -PackagePath $App.PackagePath `
                -LicensePath $App.LicensePath `
                -ErrorAction Stop |
            Out-Null

            $Verify = @(
                Get-ProvisionedMatch `
                    -DisplayName $App.DisplayName
            )

            if ($Verify.Count -eq 0) {

                throw "Main App provisioning verification failed: $($App.DisplayName)"
            }

            $DetectedVersions = @(
                $Verify |
                ForEach-Object {
                    $_.Version.ToString()
                } |
                Sort-Object -Unique
            )

            Write-Host "[ OK ] Provisioned successfully."
            Write-Host "       Detected version(s): $($DetectedVersions -join ', ')"

            if ($App.ExpectedVersion -notin $DetectedVersions) {

                Write-Host "[INFO] Version differs from project reference."
                Write-Host "       Reference : $($App.ExpectedVersion)"
                Write-Host "       Detected  : $($DetectedVersions -join ', ')"
            }

            Write-Host ""

            $AppAdded++
        }


        # ====================================================
        # 15. Final Provisioned-package validation
        # ====================================================

        Write-Section "Verification 1 - Required Packages"

        $FinalProvisioned =
            Get-CurrentProvisionedPackages

        $MissingFrameworks = @()

        foreach ($Framework in $ResolvedFrameworks) {

            $Found = @(
                $FinalProvisioned |
                Where-Object {

                    $_.DisplayName -eq $Framework.DisplayName -and
                    (Convert-AppxArchitecture $_.Architecture) -eq
                        $Framework.Architecture
                }
            )

            if ($Found.Count -eq 0) {

                $MissingFrameworks +=
                    "$($Framework.DisplayName) [$($Framework.Architecture)]"
            }
        }

        $MissingApps = @()

        foreach ($App in $ResolvedApps) {

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

        Write-Host "Framework combinations:"
        Write-Host "  Expected : 18"
        Write-Host "  Missing  : $($MissingFrameworks.Count)"
        Write-Host ""

        Write-Host "Main Apps:"
        Write-Host "  Expected : 14"
        Write-Host "  Missing  : $($MissingApps.Count)"
        Write-Host ""

        if ($MissingFrameworks.Count -gt 0) {

            Write-Host "[FAIL] Missing Framework combinations:"
            Write-Host ""

            foreach ($Missing in $MissingFrameworks) {
                Write-Host "       $Missing"
            }

            throw "Framework post-provisioning verification failed."
        }

        if ($MissingApps.Count -gt 0) {

            Write-Host "[FAIL] Missing Main Apps:"
            Write-Host ""

            foreach ($Missing in $MissingApps) {
                Write-Host "       $Missing"
            }

            throw "Main App post-provisioning verification failed."
        }

        Write-Host "[PASS] All 18 Framework combinations are present."
        Write-Host "[PASS] All 14 Main Inbox Apps are present."


        # ====================================================
        # 16. Installed Store Apps not provisioned
        # ====================================================

        Write-Section "Verification 2 - Installed Store Apps Not Provisioned"

        $ProvisionedNames = @(
            $FinalProvisioned |
            Select-Object `
                -ExpandProperty DisplayName `
                -Unique
        )

        try {

            $AllUserPackages = @(
                Get-AppxPackage `
                    -AllUsers `
                    -ErrorAction Stop
            )

            $Remaining = @(
                $AllUserPackages |
                Where-Object {

                    $_.SignatureKind -eq "Store" -and
                    -not $_.NonRemovable -and
                    $_.Name -notin $ProvisionedNames
                }
            )
        }
        catch {

            throw @"
Unable to complete the Installed-vs-Provisioned Appx comparison.

The provisioning result cannot be considered validated.

Original error:
$($_.Exception.Message)
"@
        }

        if ($Remaining.Count -gt 0) {

            Write-Host "[FAIL] Installed Store Apps exist that are"
            Write-Host "       not provisioned into the image."
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

            throw "Remaining Store App count is not zero."
        }

        Write-Host "[PASS] Remaining Store App count = 0"


        # ====================================================
        # 17. HEVC information
        # ====================================================

        Write-Section "HEVC"

        $HEVC = @(
            $FinalProvisioned |
            Where-Object {
                $_.DisplayName -match "(?i)HEVC"
            }
        )

        if ($HEVC.Count -eq 0) {

            Write-Host "[INFO] HEVC is not provisioned."
            Write-Host ""
            Write-Host "This matches the project reference package set."
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


        # ====================================================
        # 18. Final summary
        # ====================================================

        Write-Section "Provisioning Summary"

        Write-Host "Frameworks:"
        Write-Host "  Expected        : 18"
        Write-Host "  Added           : $FrameworkAdded"
        Write-Host "  Already present : $FrameworkSkipped"
        Write-Host "  Missing         : 0"
        Write-Host ""

        Write-Host "Main Apps:"
        Write-Host "  Expected        : 14"
        Write-Host "  Added           : $AppAdded"
        Write-Host "  Already present : $AppSkipped"
        Write-Host "  Missing         : 0"
        Write-Host ""

        Write-Host "Installed Store Apps not provisioned:"
        Write-Host "  Remaining count : 0"
        Write-Host ""

        Write-Host "============================================================"
        Write-Host " PASS"
        Write-Host "============================================================"
        Write-Host ""

        Write-Host "[PASS] All required Frameworks are provisioned."
        Write-Host "[PASS] All required Main Inbox Apps are provisioned."
        Write-Host "[PASS] Remaining Store App count = 0."
        Write-Host ""
        Write-Host "The Appx provisioning state is ready for"
        Write-Host "independent verification with:"
        Write-Host ""
        Write-Host "    .\Verify-InboxApps.ps1"
        Write-Host ""
        Write-Host "Run final Sysprep only after verification succeeds."

        $ExitCode = 0
    }
}
catch {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " FAILED"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host $_.Exception.Message
    Write-Host ""

    if ($PreflightOnly) {

        Write-Host "Preflight failed."
        Write-Host ""
        Write-Host "No package provisioning was intentionally started."
    }
    else {

        Write-Host "Provisioning or validation failed."
        Write-Host ""
        Write-Host "No automatic Appx removal or rollback was performed."
        Write-Host ""
        Write-Host "Correct the reported problem and run the script again."
        Write-Host ""
        Write-Host "Packages already provisioned successfully will be"
        Write-Host "detected and skipped on the next run."
    }

    $ExitCode = 1
}
finally {

    if ($TranscriptStarted) {

        try {

            Write-Host ""
            Write-Host "Transcript:"
            Write-Host "  $LogPath"

            Stop-Transcript |
                Out-Null
        }
        catch {
            # Never hide the original provisioning result
            # because transcript shutdown failed.
        }
    }
}

exit $ExitCode
