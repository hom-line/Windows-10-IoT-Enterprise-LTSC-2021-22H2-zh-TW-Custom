#Requires -Version 5.1

<#
.SYNOPSIS
    Verifies Windows edition, version, build, architecture,
    and activation status.

.DESCRIPTION
    Verification utility for:
    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom

    Edition and Activation are checked independently.

    Primary Edition IDs:
      EnterpriseS
      IoTEnterpriseS

.NOTES
    The project's 22H2 / Build 19045.7725 configuration is a
    custom LTSC-2021-based image and is not an official
    Microsoft LTSC 22H2 release.
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================"
Write-Host " Windows Edition / Build Verification"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# 1. Windows registry information
# ------------------------------------------------------------

try {
    $cv = Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    $RegistryProductName = $cv.ProductName
    $DisplayVersion      = $cv.DisplayVersion
    $ReleaseId           = $cv.ReleaseId
    $CurrentBuild        = $cv.CurrentBuild
    $UBR                 = $cv.UBR

    if ($null -ne $UBR) {
        $FullBuild = "$CurrentBuild.$UBR"
    }
    else {
        $FullBuild = $CurrentBuild
    }

    if ([string]::IsNullOrWhiteSpace($DisplayVersion)) {
        $DisplayVersion = $ReleaseId
    }
}
catch {
    Write-Host "[ERROR] Unable to read Windows version information."
    Write-Host $_.Exception.Message
    exit 1
}

# ------------------------------------------------------------
# 2. Operating-system architecture
# ------------------------------------------------------------

try {
    $OS = Get-CimInstance Win32_OperatingSystem
    $ArchitectureDisplay = $OS.OSArchitecture
}
catch {
    if ([Environment]::Is64BitOperatingSystem) {
        $ArchitectureDisplay = "64-bit"
    }
    else {
        $ArchitectureDisplay = "32-bit"
    }
}

# ------------------------------------------------------------
# 3. Actual Windows Edition
# ------------------------------------------------------------

$EditionID = $null
$EditionSource = $null

try {
    $WindowsEdition = Get-WindowsEdition -Online -ErrorAction Stop
    $EditionID = $WindowsEdition.Edition
    $EditionSource = "Get-WindowsEdition"
}
catch {
    # Registry fallback if DISM PowerShell module is unavailable
    try {
        $EditionID = $cv.EditionID
        $EditionSource = "Registry fallback"
    }
    catch {
        $EditionID = "Unknown"
        $EditionSource = "Unavailable"
    }
}

# ------------------------------------------------------------
# 4. Interpret Edition
# ------------------------------------------------------------

switch ($EditionID) {

    "EnterpriseS" {
        $EditionDescription = "Windows 10 Enterprise LTSC"
        $EditionStatus = "Enterprise LTSC base"
    }

    "IoTEnterpriseS" {
        $EditionDescription = "Windows 10 IoT Enterprise LTSC"
        $EditionStatus = "IoT Enterprise LTSC"
    }

    default {
        $EditionDescription = "Other / Unknown Windows Edition"
        $EditionStatus = "Manual verification recommended"
    }
}

# ------------------------------------------------------------
# 5. Windows activation status
# ------------------------------------------------------------

$ActivationText = "Unable to determine"

try {

    # Microsoft Windows licensing Application ID
    $WindowsApplicationID =
        "55c92734-d682-4d71-983e-d6ec3f16059f"

    $LicenseProducts = @(
        Get-CimInstance SoftwareLicensingProduct |
        Where-Object {
            $_.ApplicationID -eq $WindowsApplicationID -and
            $_.PartialProductKey -and
            $_.Name -like "Windows*"
        }
    )

    # Prefer an actually licensed Windows product if one exists.
    $LicensedProduct = $LicenseProducts |
        Where-Object { $_.LicenseStatus -eq 1 } |
        Select-Object -First 1

    # Otherwise report the first applicable Windows licensing record.
    if ($null -eq $LicensedProduct) {
        $LicensedProduct = $LicenseProducts |
            Select-Object -First 1
    }

    if ($null -ne $LicensedProduct) {

        switch ($LicensedProduct.LicenseStatus) {
            0 { $ActivationText = "Unlicensed" }
            1 { $ActivationText = "Licensed / Activated" }
            2 { $ActivationText = "OOB Grace" }
            3 { $ActivationText = "OOT Grace" }
            4 { $ActivationText = "Non-Genuine Grace" }
            5 { $ActivationText = "Notification" }
            6 { $ActivationText = "Extended Grace" }
            default { $ActivationText = "Unknown" }
        }
    }
}
catch {
    $ActivationText = "Unable to determine"
}

# ------------------------------------------------------------
# 6. Main output
# ------------------------------------------------------------

Write-Host "Registry Product : $RegistryProductName"
Write-Host "Edition ID       : $EditionID"
Write-Host "Edition           : $EditionDescription"
Write-Host "Edition Status    : $EditionStatus"
Write-Host "Edition Source    : $EditionSource"
Write-Host "Version           : $DisplayVersion"
Write-Host "OS Build          : $FullBuild"
Write-Host "Architecture      : $ArchitectureDisplay"
Write-Host "Activation        : $ActivationText"

# ------------------------------------------------------------
# 7. Edition interpretation
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Edition interpretation"
Write-Host "------------------------------------------------------------"
Write-Host ""

switch ($EditionID) {

    "EnterpriseS" {

        Write-Host "[INFO] Current Edition ID is EnterpriseS."
        Write-Host ""
        Write-Host "Windows Edition:"
        Write-Host "Windows 10 Enterprise LTSC"
        Write-Host ""
        Write-Host "If Windows 10 IoT Enterprise LTSC is the licensed target,"
        Write-Host "the applicable IoT Edition conversion has not changed"
        Write-Host "the Edition ID to IoTEnterpriseS."
    }

    "IoTEnterpriseS" {

        Write-Host "[OK] Current Edition ID is IoTEnterpriseS."
        Write-Host ""
        Write-Host "Windows Edition:"
        Write-Host "Windows 10 IoT Enterprise LTSC"
    }

    default {

        Write-Host "[INFO] Edition ID:"
        Write-Host $EditionID
        Write-Host ""
        Write-Host "This Edition is outside the two primary Editions"
        Write-Host "documented by this project."
    }
}

# ------------------------------------------------------------
# 8. Custom project build verification
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Custom project build check"
Write-Host "------------------------------------------------------------"
Write-Host ""

if (
    $DisplayVersion -eq "22H2" -and
    $FullBuild -eq "19045.7725"
) {

    Write-Host "[OK] Exact project reference build detected."
    Write-Host ""
    Write-Host "Version : 22H2"
    Write-Host "Build   : 19045.7725"
}
elseif (
    $DisplayVersion -eq "22H2" -and
    $CurrentBuild -eq "19045"
) {

    Write-Host "[INFO] Windows 10 22H2 / Build 19045 detected."
    Write-Host ""
    Write-Host "The system belongs to the same 22H2 build family,"
    Write-Host "but does not exactly match the project's"
    Write-Host "reference revision 19045.7725."
    Write-Host ""
    Write-Host "Detected build: $FullBuild"
}
else {

    Write-Host "[INFO] Current system does not match the"
    Write-Host "project's Windows 10 22H2 / Build 19045 family."
    Write-Host ""
    Write-Host "Detected version : $DisplayVersion"
    Write-Host "Detected build   : $FullBuild"
}

# ------------------------------------------------------------
# 9. Final notes
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================"
Write-Host " Notes"
Write-Host "============================================================"
Write-Host ""

Write-Host "Edition and Activation are independent."
Write-Host ""
Write-Host "EnterpriseS"
Write-Host "  = Windows 10 Enterprise LTSC"
Write-Host ""
Write-Host "IoTEnterpriseS"
Write-Host "  = Windows 10 IoT Enterprise LTSC"
Write-Host ""
Write-Host "Registry ProductName is informational only."
Write-Host "Edition ID is used as the primary Edition identifier."
Write-Host ""
Write-Host "The project's 22H2 / 19045.7725 configuration is custom."
Write-Host "It is not an official Microsoft LTSC 22H2 release."
Write-Host ""
