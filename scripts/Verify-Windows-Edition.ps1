#Requires -Version 5.1

<#
.SYNOPSIS
    Verifies Windows edition, version, build, architecture, and activation status.

.DESCRIPTION
    This script is intended for the
    Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom project.

    It distinguishes between:
      EnterpriseS
      IoTEnterpriseS

    and reports activation separately from the Windows Edition.

.NOTES
    Project:
    Windows 10 IoT Enterprise LTSC 2021 22H2 zh-TW Custom

    Important:
    Windows Edition and Windows Activation are separate concepts.
#>

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "============================================================"
Write-Host " Windows Edition / Build Verification"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# 1. Read Windows registry information
# ------------------------------------------------------------

$cv = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$ProductName = $cv.ProductName
$DisplayVersion = $cv.DisplayVersion
$ReleaseId = $cv.ReleaseId
$CurrentBuild = $cv.CurrentBuild
$UBR = $cv.UBR

if ($null -ne $UBR) {
    $FullBuild = "$CurrentBuild.$UBR"
}
else {
    $FullBuild = $CurrentBuild
}

if ([string]::IsNullOrWhiteSpace($DisplayVersion)) {
    $DisplayVersion = $ReleaseId
}

# ------------------------------------------------------------
# 2. Architecture
# ------------------------------------------------------------

$Architecture = $env:PROCESSOR_ARCHITECTURE

switch ($Architecture) {
    "AMD64" { $ArchitectureDisplay = "x64" }
    "x86"   { $ArchitectureDisplay = "x86" }
    "ARM64" { $ArchitectureDisplay = "ARM64" }
    default { $ArchitectureDisplay = $Architecture }
}

# ------------------------------------------------------------
# 3. Get actual Windows Edition ID from DISM
# ------------------------------------------------------------

$DismOutput = dism.exe /Online /Get-CurrentEdition 2>&1

$EditionID = $null

foreach ($Line in $DismOutput) {
    if ($Line -match "Current Edition\s*:\s*(.+)$") {
        $EditionID = $Matches[1].Trim()
        break
    }

    # Traditional Chinese DISM output
    if ($Line -match "目前版本\s*:\s*(.+)$") {
        $EditionID = $Matches[1].Trim()
        break
    }
}

if ([string]::IsNullOrWhiteSpace($EditionID)) {
    # Registry fallback
    $EditionID = $cv.EditionID
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
        $EditionStatus = "Check Edition ID manually"
    }
}

# ------------------------------------------------------------
# 5. Activation information
# ------------------------------------------------------------

$ActivationText = ""

try {
    $LicenseProducts = Get-CimInstance SoftwareLicensingProduct |
        Where-Object {
            $_.PartialProductKey -and
            $_.Name -like "Windows*"
        }

    $LicensedProduct = $LicenseProducts |
        Sort-Object LicenseStatus -Descending |
        Select-Object -First 1

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
    else {
        $ActivationText = "Unable to determine"
    }
}
catch {
    $ActivationText = "Unable to determine"
}

# ------------------------------------------------------------
# 6. Output
# ------------------------------------------------------------

Write-Host "Product Name      : $ProductName"
Write-Host "Edition ID        : $EditionID"
Write-Host "Edition           : $EditionDescription"
Write-Host "Edition Status    : $EditionStatus"
Write-Host "Version           : $DisplayVersion"
Write-Host "OS Build          : $FullBuild"
Write-Host "Architecture      : $ArchitectureDisplay"
Write-Host "Activation        : $ActivationText"

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Project interpretation"
Write-Host "------------------------------------------------------------"

if ($EditionID -eq "EnterpriseS") {

    Write-Host ""
    Write-Host "Current Edition is EnterpriseS."
    Write-Host ""
    Write-Host "This corresponds to:"
    Write-Host "Windows 10 Enterprise LTSC"
    Write-Host ""
    Write-Host "If Windows 10 IoT Enterprise LTSC is the licensed target,"
    Write-Host "the applicable legitimate IoT licensing conversion has"
    Write-Host "not yet changed the Edition ID to IoTEnterpriseS."
}

elseif ($EditionID -eq "IoTEnterpriseS") {

    Write-Host ""
    Write-Host "Current Edition is IoTEnterpriseS."
    Write-Host ""
    Write-Host "This corresponds to:"
    Write-Host "Windows 10 IoT Enterprise LTSC"
}

else {

    Write-Host ""
    Write-Host "The detected Edition is not one of the primary Editions"
    Write-Host "documented by this project."
}

# ------------------------------------------------------------
# 7. Project-build check
# ------------------------------------------------------------

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host " Custom project build check"
Write-Host "------------------------------------------------------------"
Write-Host ""

if (($DisplayVersion -eq "22H2") -and ($FullBuild -eq "19045.7725")) {

    Write-Host "[OK] Version matches project target:"
    Write-Host "     Windows 10 22H2 / Build 19045.7725"
}
else {

    Write-Host "[INFO] Current system does not exactly match:"
    Write-Host "       Windows 10 22H2 / Build 19045.7725"
    Write-Host ""
    Write-Host "Detected:"
    Write-Host "Version : $DisplayVersion"
    Write-Host "Build   : $FullBuild"
}

Write-Host ""
Write-Host "============================================================"
Write-Host " Notes"
Write-Host "============================================================"
Write-Host ""
Write-Host "Edition and Activation are checked separately."
Write-Host ""
Write-Host "EnterpriseS    = Windows 10 Enterprise LTSC"
Write-Host "IoTEnterpriseS = Windows 10 IoT Enterprise LTSC"
Write-Host ""
Write-Host "The project's 22H2 / 19045.7725 state is a custom build."
Write-Host "It is not an official Microsoft LTSC 22H2 release."
Write-Host ""
