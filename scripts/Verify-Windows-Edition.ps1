#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Verifies Microsoft Inbox Apps and framework dependencies
    provisioned in the Windows reference image.

.DESCRIPTION
    Verification utility for:
    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom

    This script checks:

      - 14 expected main Microsoft Inbox Apps
      - Reference versions of the 14 main Apps
      - 18 expected framework / architecture combinations
      - Installed Store Apps that are not provisioned
      - HEVC presence
      - Overall Appx provisioning state

    This script is READ-ONLY.

    It does NOT:
      - Install Appx packages
      - Remove Appx packages
      - Modify provisioned packages
      - Change Windows configuration

.NOTES
    Reference configuration:

      Windows 10
      Version 22H2
      Build 19045.7725
      x64
      zh-TW

    Important:
    The project's 22H2 / Build 19045.7725 configuration is a
    custom LTSC-2021-based image.

    It is not an official Microsoft LTSC 22H2 release.
#>

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

# ============================================================
# 2. Header
# ============================================================

Write-Section "Microsoft Inbox Apps Verification"

Write-Host "Mode       : Read-only verification"
Write-Host "PowerShell : $($PSVersionTable.PSVersion)"
Write-Host "User       : $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host ""

# ============================================================
# 3. Expected main Inbox Apps
# ============================================================

$ExpectedApps = @(

    [PSCustomObject]@{
        Name    = "Microsoft.WindowsStore"
        Version = "11910.1002.513.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.StorePurchaseApp"
        Version = "11811.1001.1813.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.DesktopAppInstaller"
        Version = "2019.125.2243.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.WindowsCalculator"
        Version = "2020.1906.55.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.ScreenSketch"
        Version = "2019.904.1644.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.WindowsCamera"
        Version = "2018.826.98.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.Windows.Photos"
        Version = "2019.19071.12548.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.ZuneMusic"
        Version = "2019.19071.19011.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.AV1VideoExtension"
        Version = "1.1.30781.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.VP9VideoExtensions"
        Version = "1.0.22681.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.HEIFImageExtension"
        Version = "1.0.22742.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.WebpImageExtension"
        Version = "1.0.22753.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.WebMediaExtensions"
        Version = "1.0.20875.0"
    },

    [PSCustomObject]@{
        Name    = "Microsoft.MPEG2VideoExtension"
        Version = "1.0.22661.0"
    }
)

# ============================================================
# 4. Expected framework / architecture combinations
# ============================================================

$ExpectedFrameworks = @(

    # .NET Native Framework

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x86"
    },

    # .NET Native Runtime

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x86"
    },

    # Microsoft UI XAML

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.0"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.0"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.1"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.1"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.3"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.UI.Xaml.2.3"
        Architecture = "x86"
    },

    # Microsoft Visual C++ Libraries

    [PSCustomObject]@{
        Name         = "Microsoft.VCLibs.140.00"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.VCLibs.140.00"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x64"
    },

    [PSCustomObject]@{
        Name         = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x86"
    }
)

# ============================================================
# 5. Read provisioned packages
# ============================================================

Write-Section "Provisioned Package Database"

try {

    $Provisioned = @(
        Get-AppxProvisionedPackage -Online -ErrorAction Stop
    )

    Write-Host "[OK] Provisioned package database loaded."
    Write-Host ""
    Write-Host "Provisioned packages detected : $($Provisioned.Count)"
}
catch {

    Write-Host "[FAIL] Unable to read provisioned Appx packages."
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Verification cannot continue safely."

    exit 1
}

# ============================================================
# 6. Verify main Inbox Apps
# ============================================================

Write-Section "Main Inbox Apps"

$AppResults = @()

foreach ($Expected in $ExpectedApps) {

    $Found = @(
        $Provisioned |
        Where-Object {
            $_.DisplayName -eq $Expected.Name
        }
    )

    if ($Found.Count -eq 0) {

        $AppResults += [PSCustomObject]@{
            Name            = $Expected.Name
            ExpectedVersion = $Expected.Version
            DetectedVersion = "-"
            Status          = "MISSING"
        }

        continue
    }

    $ExactVersion = @(
        $Found |
        Where-Object {
            $_.Version.ToString() -eq $Expected.Version
        }
    )

    if ($ExactVersion.Count -gt 0) {

        $AppResults += [PSCustomObject]@{
            Name            = $Expected.Name
            ExpectedVersion = $Expected.Version
            DetectedVersion = $Expected.Version
            Status          = "OK"
        }
    }
    else {

        $DetectedVersions = @(
            $Found |
            ForEach-Object {
                $_.Version.ToString()
            } |
            Sort-Object -Unique
        )

        $AppResults += [PSCustomObject]@{
            Name            = $Expected.Name
            ExpectedVersion = $Expected.Version
            DetectedVersion = ($DetectedVersions -join ", ")
            Status          = "VERSION DIFFERENT"
        }
    }
}

$AppResults |
    Format-Table `
        Name,
        ExpectedVersion,
        DetectedVersion,
        Status `
        -AutoSize

# ============================================================
# 7. Main App summary
# ============================================================

$MainOK = @(
    $AppResults |
    Where-Object {
        $_.Status -eq "OK"
    }
).Count

$MainMissing = @(
    $AppResults |
    Where-Object {
        $_.Status -eq "MISSING"
    }
).Count

$MainVersionDifferent = @(
    $AppResults |
    Where-Object {
        $_.Status -eq "VERSION DIFFERENT"
    }
).Count

Write-Host ""
Write-Host "Main Apps expected          : $($ExpectedApps.Count)"
Write-Host "Main Apps exact match       : $MainOK"
Write-Host "Main Apps missing           : $MainMissing"
Write-Host "Main Apps version different : $MainVersionDifferent"

# ============================================================
# 8. Verify frameworks
# ============================================================

Write-Section "Frameworks / Dependencies"

$FrameworkResults = @()

foreach ($Expected in $ExpectedFrameworks) {

    $Found = @(
        $Provisioned |
        Where-Object {

            $DetectedArchitecture =
                Convert-AppxArchitecture $_.Architecture

            (
                $_.DisplayName -eq $Expected.Name
            ) -and (
                $DetectedArchitecture -eq $Expected.Architecture
            )
        }
    )

    if ($Found.Count -gt 0) {

        $Versions = @(
            $Found |
            ForEach-Object {
                $_.Version.ToString()
            } |
            Sort-Object -Unique
        )

        $FrameworkResults += [PSCustomObject]@{
            Name         = $Expected.Name
            Architecture = $Expected.Architecture
            Version      = ($Versions -join ", ")
            Status       = "OK"
        }
    }
    else {

        $FrameworkResults += [PSCustomObject]@{
            Name         = $Expected.Name
            Architecture = $Expected.Architecture
            Version      = "-"
            Status       = "MISSING"
        }
    }
}

$FrameworkResults |
    Format-Table `
        Name,
        Architecture,
        Version,
        Status `
        -AutoSize

# ============================================================
# 9. Framework summary
# ============================================================

$FrameworkOK = @(
    $FrameworkResults |
    Where-Object {
        $_.Status -eq "OK"
    }
).Count

$FrameworkMissing = @(
    $FrameworkResults |
    Where-Object {
        $_.Status -eq "MISSING"
    }
).Count

Write-Host ""
Write-Host "Framework combinations expected : $($ExpectedFrameworks.Count)"
Write-Host "Framework combinations found    : $FrameworkOK"
Write-Host "Framework combinations missing  : $FrameworkMissing"

# ============================================================
# 10. Installed Store Apps not provisioned
# ============================================================

Write-Section "Installed Store Apps Not Provisioned"

$RemainingCheckSucceeded = $false
$Remaining = @()

try {

    $ProvisionedNames = @(
        $Provisioned |
        Select-Object -ExpandProperty DisplayName -Unique
    )

    $AllUserPackages = @(
        Get-AppxPackage -AllUsers -ErrorAction Stop
    )

    $Remaining = @(
        $AllUserPackages |
        Where-Object {

            $_.SignatureKind -eq "Store" -and
            -not $_.NonRemovable -and
            $_.Name -notin $ProvisionedNames
        }
    )

    $RemainingCheckSucceeded = $true

    if ($Remaining.Count -eq 0) {

        Write-Host "[OK] No installed Store Apps were found"
        Write-Host "     without corresponding provisioning."
        Write-Host ""
        Write-Host "Remaining count = 0"
    }
    else {

        Write-Host "[WARNING] Installed Store Apps exist that are"
        Write-Host "          not provisioned into the image."
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
}
catch {

    $RemainingCheckSucceeded = $false

    Write-Host "[FAIL] Unable to complete the AllUsers Appx comparison."
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Remaining Store App state is UNKNOWN."
    Write-Host ""
    Write-Host "This result must NOT be interpreted as:"
    Write-Host ""
    Write-Host "Remaining count = 0"
}

# ============================================================
# 11. HEVC check
# ============================================================

Write-Section "HEVC"

$HEVC = @(
    $Provisioned |
    Where-Object {
        $_.DisplayName -match "(?i)HEVC"
    }
)

if ($HEVC.Count -eq 0) {

    Write-Host "[INFO] HEVC is not provisioned."
    Write-Host ""
    Write-Host "This matches the reference package set"
    Write-Host "documented by this project."
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

# ============================================================
# 12. Overall verification state
# ============================================================

$CriticalFailure = $false

if ($MainMissing -gt 0) {
    $CriticalFailure = $true
}

if ($FrameworkMissing -gt 0) {
    $CriticalFailure = $true
}

if (-not $RemainingCheckSucceeded) {
    $CriticalFailure = $true
}

if (
    $RemainingCheckSucceeded -and
    $Remaining.Count -gt 0
) {
    $CriticalFailure = $true
}

# Version differences are informational rather than critical.
$ReferenceVersionMismatch =
    ($MainVersionDifferent -gt 0)

# ============================================================
# 13. Verification summary
# ============================================================

Write-Section "Verification Summary"

Write-Host "Main Apps:"
Write-Host "  Expected              : $($ExpectedApps.Count)"
Write-Host "  Exact version match   : $MainOK"
Write-Host "  Missing               : $MainMissing"
Write-Host "  Different version     : $MainVersionDifferent"

Write-Host ""

Write-Host "Frameworks:"
Write-Host "  Expected combinations : $($ExpectedFrameworks.Count)"
Write-Host "  Found                 : $FrameworkOK"
Write-Host "  Missing               : $FrameworkMissing"

Write-Host ""

Write-Host "Installed but not provisioned Store Apps:"

if ($RemainingCheckSucceeded) {

    Write-Host "  Verification          : SUCCESS"
    Write-Host "  Remaining count       : $($Remaining.Count)"
}
else {

    Write-Host "  Verification          : FAILED"
    Write-Host "  Remaining count       : UNKNOWN"
}

Write-Host ""

# ============================================================
# 14. Final result
# ============================================================

if (-not $CriticalFailure) {

    Write-Host "============================================================"
    Write-Host " PASS"
    Write-Host "============================================================"
    Write-Host ""

    Write-Host "[PASS] All 14 required Main Inbox Apps are present."
    Write-Host "[PASS] All 18 Framework / Architecture combinations are present."
    Write-Host "[PASS] Installed-vs-Provisioned Store App verification succeeded."
    Write-Host "[PASS] Remaining Store App count = 0"

    if (-not $ReferenceVersionMismatch) {

        Write-Host "[PASS] All Main App versions exactly match"
        Write-Host "       the documented project reference versions."
    }
    else {

        Write-Host ""
        Write-Host "[INFO] One or more Main App versions differ from"
        Write-Host "       the documented project reference versions."
        Write-Host ""
        Write-Host "       This is not treated as a provisioning failure"
        Write-Host "       because the required packages are present."
    }

    Write-Host ""
    Write-Host "The Appx provisioning state is suitable for"
    Write-Host "final review before Sysprep."

    $ExitCode = 0
}
else {

    Write-Host "============================================================"
    Write-Host " FAIL"
    Write-Host "============================================================"
    Write-Host ""

    if ($MainMissing -gt 0) {

        Write-Host "[FAIL] Missing Main Inbox Apps:"
        Write-Host ""

        $AppResults |
            Where-Object {
                $_.Status -eq "MISSING"
            } |
            ForEach-Object {
                Write-Host "       $($_.Name)"
            }

        Write-Host ""
    }

    if ($FrameworkMissing -gt 0) {

        Write-Host "[FAIL] Missing Framework combinations:"
        Write-Host ""

        $FrameworkResults |
            Where-Object {
                $_.Status -eq "MISSING"
            } |
            ForEach-Object {
                Write-Host "       $($_.Name) [$($_.Architecture)]"
            }

        Write-Host ""
    }

    if (-not $RemainingCheckSucceeded) {

        Write-Host "[FAIL] Installed-vs-Provisioned Store App"
        Write-Host "       comparison could not be completed."
        Write-Host ""
        Write-Host "       Remaining count is UNKNOWN."
        Write-Host ""
    }
    elseif ($Remaining.Count -gt 0) {

        Write-Host "[FAIL] Installed Store Apps exist that are"
        Write-Host "       not provisioned into the image."
        Write-Host ""
        Write-Host "       Remaining count = $($Remaining.Count)"
        Write-Host ""
    }

    Write-Host "Do not treat this provisioning state as validated."
    Write-Host ""
    Write-Host "Review the reported problems before running"
    Write-Host "the final Sysprep operation."

    $ExitCode = 1
}

# ============================================================
# 15. Notes
# ============================================================

Write-Section "Notes"

Write-Host "This script performs verification only."
Write-Host ""
Write-Host "It does not:"
Write-Host "  - install Appx packages"
Write-Host "  - remove Appx packages"
Write-Host "  - modify provisioned packages"
Write-Host ""
Write-Host "Project reference configuration:"
Write-Host ""
Write-Host "  Main Inbox Apps                  : 14"
Write-Host "  Framework/architecture entries  : 18"
Write-Host "  Remaining Store Apps            : 0"
Write-Host ""
Write-Host "HEVC is not part of the project's"
Write-Host "reference Inbox Apps package set."
Write-Host ""
Write-Host "A different App version does not automatically mean"
Write-Host "that the package is broken."
Write-Host ""
Write-Host "VERSION DIFFERENT means:"
Write-Host ""
Write-Host "  Package is present"
Write-Host "  Provisioning is present"
Write-Host "  Version differs from the documented reference build"
Write-Host ""
Write-Host "Reference project build:"
Write-Host ""
Write-Host "  Windows 10 Version 22H2"
Write-Host "  Build 19045.7725"
Write-Host ""
Write-Host "This 22H2 configuration is a custom LTSC-2021-based"
Write-Host "project image and is not an official Microsoft"
Write-Host "LTSC 22H2 release."
Write-Host ""

exit $ExitCode
