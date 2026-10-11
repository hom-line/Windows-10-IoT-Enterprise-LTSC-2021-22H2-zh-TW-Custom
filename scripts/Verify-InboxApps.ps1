#Requires -Version 5.1

<#
.SYNOPSIS
    Verifies Microsoft Inbox Apps and framework dependencies
    provisioned in the Windows reference image.

.DESCRIPTION
    Verification utility for:
    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom

    The script checks:
      - 14 expected main Inbox Apps
      - Expected package versions
      - 18 framework / architecture combinations
      - Installed Store apps that are not provisioned
      - Overall provisioning status

    This script is read-only.
    It does not install, remove, or modify Appx packages.

.NOTES
    Reference build:
      Windows 10 22H2
      Build 19045.7725
      x64
      zh-TW
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================"
Write-Host " Microsoft Inbox Apps Verification"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# 1. Administrator check
# ------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdmin = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "[WARNING] PowerShell is not running as Administrator."
    Write-Host "Some AllUsers package information may be incomplete."
    Write-Host ""
}

# ------------------------------------------------------------
# 2. Expected main Inbox Apps
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# 3. Expected framework / architecture combinations
# ------------------------------------------------------------

$ExpectedFrameworks = @(
    # .NET Native Framework
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Framework.1.7"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Framework.2.2"
        Architecture = "x86"
    },

    # .NET Native Runtime
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Runtime.1.7"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.NET.Native.Runtime.2.2"
        Architecture = "x86"
    },

    # Microsoft UI XAML
    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.0"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.0"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.1"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.1"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.3"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.UI.Xaml.2.3"
        Architecture = "x86"
    },

    # Microsoft Visual C++ Libraries
    [PSCustomObject]@{
        Name = "Microsoft.VCLibs.140.00"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.VCLibs.140.00"
        Architecture = "x86"
    },

    [PSCustomObject]@{
        Name = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x64"
    },
    [PSCustomObject]@{
        Name = "Microsoft.VCLibs.140.00.UWPDesktop"
        Architecture = "x86"
    }
)

# ------------------------------------------------------------
# 4. Read provisioned packages
# ------------------------------------------------------------

try {
    $Provisioned = @(
        Get-AppxProvisionedPackage -Online
    )
}
catch {
    Write-Host "[ERROR] Unable to read provisioned Appx packages."
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host "Provisioned packages detected : $($Provisioned.Count)"
Write-Host ""

# ------------------------------------------------------------
# 5. Verify main Inbox Apps
# ------------------------------------------------------------

Write-Host "------------------------------------------------------------"
Write-Host " Main Inbox Apps"
Write-Host "------------------------------------------------------------"
Write-Host ""

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

    # Prefer an exact expected version if multiple entries exist.
    $ExactVersion = $Found |
        Where-Object {
            $_.Version.ToString() -eq $Expected.Version
        } |
        Select-Object -First 1

    if ($null -ne $ExactVersion) {

        $AppResults += [PSCustomObject]@{
            Name            = $Expected.Name
            ExpectedVersion = $Expected.Version
            DetectedVersion = $ExactVersion.Version.ToString()
            Status          = "OK"
        }
    }
    else {

        $DetectedVersions = (
            $Found |
            ForEach-Object { $_.Version.ToString() } |
            Sort-Object -Unique
        ) -join ", "

        $AppResults += [PSCustomObject]@{
            Name            = $Expected.Name
            ExpectedVersion = $Expected.Version
            DetectedVersion = $DetectedVersions
            Status          = "VERSION DIFFERENT"
        }
    }
}

$AppResults |
    Format-Table Name, ExpectedVersion, DetectedVersion, Status -AutoSize

# ------------------------------------------------------------
# 6. Main App summary
# ------------------------------------------------------------

$MainOK = @(
    $AppResults |
    Where-Object { $_.Status -eq "OK" }
).Count

$MainMissing = @(
    $AppResults |
    Where-Object { $_.Status -eq "MISSING" }
).Count

$MainVersionDifferent = @(
    $AppResults |
    Where-Object { $_.Status -eq "VERSION DIFFERENT" }
).Count

Write-Host ""
Write-Host "Main Apps expected          : $($ExpectedApps.Count)"
Write-Host "Main Apps exact match       : $MainOK"
Write-Host "Main Apps missing           : $MainMissing"
Write-Host "Main Apps version different : $MainVersionDifferent"

# ------------------------------------------------------------
# 7. Normalize architecture
# ------------------------------------------------------------

function Convert-AppxArchitecture {

    param (
        $Architecture
    )

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

# ------------------------------------------------------------
# 8. Verify framework dependencies
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Frameworks / Dependencies"
Write-Host "------------------------------------------------------------"
Write-Host ""

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
                $DetectedArchitecture -eq
                $Expected.Architecture
            )
        }
    )

    if ($Found.Count -gt 0) {

        $Versions = (
            $Found |
            ForEach-Object {
                $_.Version.ToString()
            } |
            Sort-Object -Unique
        ) -join ", "

        $FrameworkResults += [PSCustomObject]@{
            Name         = $Expected.Name
            Architecture = $Expected.Architecture
            Version      = $Versions
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
    Format-Table Name, Architecture, Version, Status -AutoSize

# ------------------------------------------------------------
# 9. Framework summary
# ------------------------------------------------------------

$FrameworkOK = @(
    $FrameworkResults |
    Where-Object { $_.Status -eq "OK" }
).Count

$FrameworkMissing = @(
    $FrameworkResults |
    Where-Object { $_.Status -eq "MISSING" }
).Count

Write-Host ""
Write-Host "Framework combinations expected : $($ExpectedFrameworks.Count)"
Write-Host "Framework combinations found    : $FrameworkOK"
Write-Host "Framework combinations missing  : $FrameworkMissing"

# ------------------------------------------------------------
# 10. Installed but not provisioned Store apps
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Installed Store Apps Not Provisioned"
Write-Host "------------------------------------------------------------"
Write-Host ""

try {

    $ProvisionedNames = @(
        $Provisioned |
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

        Write-Host "[OK] No remaining Store apps detected."
        Write-Host ""
        Write-Host "Remaining count = 0"
    }
    else {

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

    Write-Host "[WARNING] Unable to complete AllUsers comparison."
    Write-Host $_.Exception.Message

    $Remaining = @()
}

# ------------------------------------------------------------
# 11. HEVC check
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " HEVC"
Write-Host "------------------------------------------------------------"
Write-Host ""

$HEVC = @(
    $Provisioned |
    Where-Object {
        $_.DisplayName -match "HEVC"
    }
)

if ($HEVC.Count -eq 0) {

    Write-Host "[INFO] HEVC is not provisioned."
    Write-Host ""
    Write-Host "This matches the reference configuration documented"
    Write-Host "by this project."
}
else {

    Write-Host "[INFO] HEVC package detected:"
    Write-Host ""

    $HEVC |
        Select-Object DisplayName,Version,Architecture,PackageName |
        Format-Table -AutoSize
}

# ------------------------------------------------------------
# 12. Overall result
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host " Verification Summary"
Write-Host "============================================================"
Write-Host ""

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
Write-Host "  Remaining count       : $($Remaining.Count)"

Write-Host ""

# ------------------------------------------------------------
# 13. Project reference validation
# ------------------------------------------------------------

$CriticalFailure = $false

if ($MainMissing -gt 0) {
    $CriticalFailure = $true
}

if ($FrameworkMissing -gt 0) {
    $CriticalFailure = $true
}

if ($Remaining.Count -gt 0) {
    $CriticalFailure = $true
}

if (-not $CriticalFailure) {

    Write-Host "[PASS] Required Inbox Apps and frameworks are provisioned."
    Write-Host ""

    if ($MainVersionDifferent -eq 0) {

        Write-Host "[PASS] All 14 main App versions exactly match"
        Write-Host "       the project reference configuration."
    }
    else {

        Write-Host "[INFO] Required Apps are present, but one or more"
        Write-Host "       versions differ from the project reference."
    }

    Write-Host ""
    Write-Host "[PASS] Remaining Store App count = 0"
}
else {

    Write-Host "[FAIL] Provisioning state does not match"
    Write-Host "       the required project configuration."
    Write-Host ""
    Write-Host "Review MISSING packages and Remaining Store Apps"
    Write-Host "before running final Sysprep."
}

# ------------------------------------------------------------
# 14. Notes
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host " Notes"
Write-Host "============================================================"
Write-Host ""

Write-Host "This script performs verification only."
Write-Host "It does not install, remove, or modify Appx packages."
Write-Host ""
Write-Host "Reference configuration:"
Write-Host "  14 main Inbox Apps"
Write-Host "  18 framework / architecture combinations"
Write-Host "  Remaining Store Apps = 0"
Write-Host ""
Write-Host "HEVC is not part of the project's reference package set."
Write-Host ""
Write-Host "A different App version does not automatically mean"
Write-Host "the package is broken. It means the installed version"
Write-Host "does not exactly match the documented reference build."
Write-Host ""
