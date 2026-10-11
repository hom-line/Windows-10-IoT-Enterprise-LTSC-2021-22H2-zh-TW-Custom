# Build Guide / 建置指南

This document describes the actual reference-image build workflow used by this project.

本文件記錄本專案實際使用的 Windows 10 LTSC 參考映像製作流程，包括：

- Windows 10 LTSC 2021 21H2 preparation
- Audit Mode
- 21H2 servicing
- Offline 22H2 Enablement Package installation through WinPE
- Build verification
- Base WIM capture
- Microsoft Inbox Apps provisioning
- Sysprep
- Final WIM capture
- Installation-media validation
- Edition and activation verification

---

# 1. Project Scope / 專案範圍

The project starts from Windows 10 Enterprise LTSC 2021 installation media.

本專案以 Windows 10 Enterprise LTSC 2021 安裝媒體作為建置基底。

```text
Base product        : Windows 10 Enterprise LTSC 2021
Base version        : Windows 10 version 21H2
Base build family   : 19044
Base Edition ID     : EnterpriseS

Architecture        : x64
Language            : zh-TW

Custom version      : Windows 10 version 22H2
Custom build        : 19045.7725

Licensed target     : Windows 10 IoT Enterprise LTSC
Target Edition ID   : IoTEnterpriseS
```

> [!IMPORTANT]
> Windows 10 IoT Enterprise LTSC 2021 was officially released as
> Windows 10 version 21H2 / Build 19044.
>
> 本專案所使用的 `22H2 / Build 19045.7725` 為自訂 servicing 後的系統狀態。
>
> 本專案不宣稱 Microsoft 曾正式發布
> `Windows 10 IoT Enterprise LTSC 2021 22H2`。

---

# 2. Official LTSC vs. Custom 22H2 State / 官方 LTSC 與自訂 22H2

Microsoft's official Windows 10 IoT Enterprise LTSC 2021 release is:

```text
Version : 21H2
Build   : 19044
```

The custom image documented by this project is:

```text
Version : 22H2
Build   : 19045.7725
```

Therefore:

```text
Official LTSC 2021
21H2 / 19044
        │
        │ Project-specific servicing
        ▼
Custom LTSC-2021-based image
22H2 / 19045.7725
```

The second state is a project-specific customized configuration.

It must not be described as an official Microsoft LTSC 22H2 release.

---

# 3. Edition Model / Edition 模型

The installation-media base used by this project is:

```text
EnterpriseS
```

This corresponds to:

```text
Windows 10 Enterprise LTSC
```

The licensed IoT target Edition is:

```text
IoTEnterpriseS
```

The intended licensing relationship is:

```text
Windows 10 Enterprise LTSC
EnterpriseS
        │
        │ Valid Windows IoT Enterprise LTSC licensing
        ▼
Windows 10 IoT Enterprise LTSC
IoTEnterpriseS
```

Edition and activation are separate concepts.

For example:

```text
EnterpriseS + Activated
```

is still Windows 10 Enterprise LTSC.

Likewise:

```text
IoTEnterpriseS + Not Activated
```

is still the IoT Enterprise LTSC Edition.

Check the current Edition with:

```cmd
dism /online /Get-CurrentEdition
```

Check activation separately with:

```cmd
slmgr /xpr
```

---

# 4. Build Workflow / 建置流程總覽

The actual workflow used by this project is:

```text
Windows 10 Enterprise LTSC 2021
21H2 / EnterpriseS
        │
        ▼
Clean installation
        │
        ▼
Enter Audit Mode
Ctrl + Shift + F3
        │
        ▼
Install all applicable 21H2 updates
        │
        ▼
Restart until servicing is complete
        │
        ▼
Shut down Windows
        │
        ▼
Boot into Windows PE
        │
        ▼
Apply Windows 10 22H2 Enablement Package
to the offline Windows installation
        │
        ▼
Shut down WinPE
        │
        ▼
Boot Windows normally
        │
        ▼
Verify Version 22H2
        │
        ▼
Verify Build 19045.x
        │
        ▼
Service to project target Build 19045.7725
        │
        ▼
Optional clean 22H2 Base WIM capture
        │
        ▼
Deploy Base image / continue customization
        │
        ▼
Provision Microsoft Inbox Apps
        │
        ▼
Verify Appx provisioning state
        │
        ▼
Sysprep
/generalize /oobe /shutdown
        │
        ▼
Boot directly into Windows PE
        │
        ▼
Capture final WIM
        │
        ▼
Build installation media
        │
        ▼
Clean VM installation test
        │
        ▼
Verify Edition / Build / Apps
```

---

# 5. Create the Reference System / 建立參考系統

Install Windows 10 Enterprise LTSC 2021 x64 zh-TW in a clean virtual machine.

建議 Reference Image 建置環境不要加入：

```text
Personal Microsoft account
Personal files
Browser profiles
Saved passwords
Personal certificates
Temporary user accounts
Third-party activation tools
Private product keys
Private KMS configuration
```

The goal is to keep the reference installation as clean and reproducible as possible.

---

# 6. Enter Audit Mode / 進入 Audit Mode

At the Windows OOBE screen press:

```text
Ctrl + Shift + F3
```

Windows restarts and enters Audit Mode using the built-in:

```text
Administrator
```

account.

Audit Mode allows the operating system to be serviced without creating a normal end-user account.

The Sysprep dialog may automatically appear after each Audit Mode startup.

Before the reference image is ready, simply close the Sysprep dialog.

Normal Audit Mode restarts can be performed with:

```cmd
shutdown /r /t 0
```

Do not create a normal user account during reference-image preparation.

---

# 7. Fully Service Windows 10 21H2 / 將 21H2 更新完成

Before enabling Windows 10 22H2, first update the original 21H2 installation.

在正常 Windows / Audit Mode 中執行 Windows Update，安裝建置當時所有適用於該系統的重要：

```text
Servicing Stack Updates
Cumulative Updates
.NET updates
Required servicing prerequisites
```

Restart when required.

Repeat servicing until the system has completed all required pending updates.

The purpose of this step is to make sure the 21H2 installation already contains the servicing level required by the 22H2 Enablement Package.

> [!NOTE]
> "Latest" in this document means the latest applicable servicing level
> available when this project image was prepared.
>
> It does not mean that Build 19045.7725 is permanently the latest Windows build.

After servicing is complete:

```cmd
shutdown /s /t 0
```

---

# 8. Boot into Windows PE / 啟動 WinPE

Do not immediately boot the installed Windows system again.

Boot the machine into Windows PE or the Windows Setup recovery environment.

Typical WinPE command prompt:

```text
X:\Sources>
```

Drive letters in WinPE may differ from normal Windows.

Therefore, identify the installed Windows partition first.

Examples:

```cmd
dir C:\Windows
dir D:\Windows
dir E:\Windows
```

Use the partition that contains the actual offline Windows installation.

For the following examples:

```text
<WindowsDrive>
```

means the drive containing the offline Windows installation.

---

# 9. Offline 22H2 Enablement / 離線啟用 22H2

Windows 10 versions 21H2 and 22H2 share a common core.

The Windows 10 22H2 Enablement Package activates the dormant 22H2 feature set and changes the version/build family from:

```text
21H2 / 19044
```

to:

```text
22H2 / 19045
```

This project applies the 22H2 Enablement Package while Windows is offline in WinPE.

> [!WARNING]
> This is a project-specific servicing procedure.
>
> Microsoft officially identifies Windows 10 IoT Enterprise LTSC 2021
> as version 21H2 / Build 19044.
>
> Although Windows 10 21H2 and 22H2 share the same core and the
> Windows 10 22H2 Enablement Package is documented by Microsoft,
> this project does not claim that applying it to an LTSC 2021
> installation creates an officially released or officially supported
> "LTSC 2021 22H2" product.

---

## 9.1 Verify the Offline Windows Image

Before applying any package:

```cmd
dism /Image:<WindowsDrive>:\ /Get-CurrentEdition
```

Expected project base:

```text
Current Edition : EnterpriseS
```

You can also verify the offline Windows directory:

```cmd
dir <WindowsDrive>:\Windows
```

---

## 9.2 Apply the 22H2 Enablement Package

The package used for Windows 10 22H2 enablement is commonly identified as:

```text
KB5015684
```

Apply the appropriate x64 package to the offline Windows image.

General syntax:

```cmd
dism /Image:<WindowsDrive>:\ /Add-Package /PackagePath:"<Path-to-22H2-Enablement-Package>"
```

Example format:

```cmd
dism /Image:C:\ /Add-Package /PackagePath:"D:\Packages\<22H2-package>.cab"
```

Do not copy the example drive letters blindly.

Always verify:

```text
Windows partition
Package location
Package architecture
```

before running DISM.

DISM should complete successfully before continuing.

---

## 9.3 Shut Down WinPE

After the package has been successfully applied:

```cmd
wpeutil shutdown
```

or use the equivalent WinPE shutdown method.

---

# 10. First Boot after 22H2 Enablement / 升級後第一次啟動

Boot the installed Windows system normally.

Windows may perform configuration work during the first boot.

After reaching the desktop, verify:

```cmd
winver
```

Successful conversion should show:

```text
Version 22H2
```

The build family should now be:

```text
19045.x
```

This confirms that:

```text
21H2 / 19044
        ↓
22H2 Enablement
        ↓
22H2 / 19045
```

was successful.

---

# 11. Service to Project Build 19045.7725 / 更新至專案組建

After confirming 22H2, continue servicing until the project target build is reached:

```text
Version 22H2
OS Build 19045.7725
```

Verify with:

```cmd
winver
```

and:

```cmd
ver
```

Windows Settings may also be used:

```text
Settings
→ System
→ About
→ Windows specifications
```

Expected project result:

```text
Version               : 22H2
OS Build               : 19045.7725
```

---

# 12. Optional 22H2 Base WIM / 建立乾淨 22H2 Base WIM

Before adding Microsoft Inbox Apps or other customizations, this project can capture a clean 22H2 Base WIM.

This avoids repeating:

```text
21H2 installation
→ servicing
→ WinPE 22H2 enablement
→ additional servicing
```

if later customization fails.

Before capture, run:

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

After Sysprep shuts down the machine:

**Do not boot the reference Windows installation again.**

Boot directly into WinPE.

---

# 13. Capture the Base WIM / 擷取 Base WIM

Assume:

```text
C:\ = Sysprepped Windows partition
D:\ = image storage
```

Verify these letters in WinPE before proceeding.

Create a DISM scratch directory:

```cmd
md D:\DismScratch
```

Example:

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_LTSC_2021_Custom_22H2_Base_19045.7725.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 LTSC 2021 Custom 22H2 Base" ^
 /Description:"Windows 10 LTSC 2021 custom 22H2 base, build 19045.7725" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

> [!NOTE]
> `/Name` and `/Description` are WIM display metadata.
>
> They do not determine the actual Windows Edition.

Verify:

```cmd
dism /Get-ImageInfo ^
 /ImageFile:D:\Win10_LTSC_2021_Custom_22H2_Base_19045.7725.wim ^
 /Index:1
```

Expected base metadata:

```text
Architecture        : x64
Version             : 10.0.19045
ServicePack Build   : 7725
Edition             : EnterpriseS
Installation        : Client
Product Type        : WinNT
System Root         : WINDOWS
Language            : zh-TW
```

---

# 14. Restore or Deploy the Base Image / 使用 Base WIM

The clean Base WIM can be used for subsequent builds.

After deploying the Base image:

```text
Boot Windows
        ↓
Enter / remain in Audit Mode
        ↓
Continue customization
```

This allows the Inbox Apps stage to be repeated without rebuilding 21H2 → 22H2 from the beginning.

---

# 15. Microsoft Inbox Apps Provisioning / Provision Microsoft Inbox Apps

The project provisions selected Microsoft Inbox Apps into the reference image.

The package source used by the tested build contains:

```text
amd64fre
x86fre
```

Required Frameworks / Dependencies are provisioned first.

Main applications are provisioned afterward.

General order:

```text
Framework dependencies
        ↓
Main Inbox Apps
        ↓
Provisioning verification
        ↓
Sysprep
```

Detailed package information is documented separately in:

```text
docs/INBOX-APPS.md
```

---

# 16. Verify Provisioned Apps / 驗證 Provisioning

Check provisioned packages:

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, Version, Architecture |
    Sort-Object DisplayName
```

The project also checks for Store-signed apps installed for users but not provisioned into the image:

```powershell
$provNames = @(
    Get-AppxProvisionedPackage -Online |
    Select-Object -ExpandProperty DisplayName
)

$Remaining = @(
    Get-AppxPackage -AllUsers |
    Where-Object {
        $_.SignatureKind -eq "Store" -and
        -not $_.NonRemovable -and
        $_.Name -notin $provNames
    }
)

$Remaining |
    Select-Object Name,Version,Architecture,IsFramework,PackageFullName |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Remaining count = $($Remaining.Count)"
```

The successfully tested build reached:

```text
Frameworks / Dependencies : 18 successful
Main Inbox Apps            : 14 successful
Remaining Store Apps       : 0
```

A non-zero result should be investigated before Sysprep.

---

# 17. Final Sysprep / 最終 Sysprep

After all servicing and Inbox Apps provisioning are complete:

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

Parameters:

```text
/generalize
```

prepares the installation as a generalized reference image.

```text
/oobe
```

configures the next Windows boot to enter OOBE.

```text
/shutdown
```

shuts down the machine after Sysprep completes.

---

## 17.1 Critical Rule after Sysprep

After Sysprep automatically shuts down:

```text
DO NOT BOOT WINDOWS AGAIN
```

Boot directly into WinPE.

Booting the generalized Windows installation before capture can modify the reference state.

---

# 18. Final WIM Capture / 最終 WIM 擷取

In WinPE, identify the Windows and output drives again.

Example:

```text
C:\ = Sysprepped Windows
D:\ = capture destination
```

Create the Scratch directory if required:

```cmd
md D:\DismScratch
```

Recommended example:

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_LTSC_2021_Custom_22H2_19045.7725.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 LTSC 2021 Custom 22H2" ^
 /Description:"Windows 10 LTSC 2021 custom reference image, build 19045.7725" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

If the WinPE DISM version does not support a particular optional capture switch, remove only the unsupported switch and retry.

Do not change the capture source unless the Windows partition has been verified.

---

# 19. Verify Final WIM Metadata / 驗證最終 WIM

Run:

```cmd
dism /Get-ImageInfo ^
 /ImageFile:D:\Win10_LTSC_2021_Custom_22H2_19045.7725.wim ^
 /Index:1
```

The image should contain complete metadata.

Expected deployment-base characteristics:

```text
Architecture        : x64
Version             : 10.0.19045
ServicePack Build   : 7725
Edition             : EnterpriseS
Installation        : Client
Product Type        : WinNT
Product Suite       : Terminal Server
System Root         : WINDOWS
Language            : zh-TW
```

A WIM containing multiple important fields such as:

```text
Edition      : <undefined>
Installation : <undefined>
Language     : <undefined>
```

should not be treated as a validated release image.

---

# 20. WIM Name Is Not the Windows Edition / WIM 名稱不等於 Edition

For example, a WIM may contain:

```text
Name    : Windows 10 IoT Enterprise LTSC
Edition : EnterpriseS
```

These two values describe different things.

```text
Name
```

is a WIM display label.

```text
Edition
```

is the actual Windows Edition ID.

Therefore:

```text
/Name:"Windows 10 IoT Enterprise LTSC"
```

does not convert:

```text
EnterpriseS
```

into:

```text
IoTEnterpriseS
```

Always verify the actual Edition with DISM.

For future captures, this project recommends neutral WIM names such as:

```text
Windows 10 LTSC 2021 Custom 22H2
```

to avoid confusion.

---

# 21. Do Not Force Offline IoT Edition Conversion / 不使用離線強制 IoT 轉換

This project tested an offline conversion from:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

DISM successfully changed the WIM Edition metadata.

However, when that modified WIM was inserted into the original Enterprise LTSC Setup media, Windows Setup reported:

```text
The product key entered does not match any of the Windows images
available for installation.
```

Therefore the standard project workflow does **not** use:

```text
Offline WIM
EnterpriseS
        ↓
Force Set-Edition
        ↓
IoTEnterpriseS
        ↓
Direct installation
```

Instead, the project keeps the installation image compatible with the original Enterprise LTSC Setup-media logic.

---

# 22. Build Installation Media / 建立安裝 ISO

Replace the appropriate:

```text
sources\install.wim
```

in a compatible Windows Setup source with the validated custom WIM.

Then rebuild the bootable ISO using an ISO-authoring tool that preserves:

```text
BIOS boot support
UEFI boot support
Windows Setup file structure
```

This repository does not redistribute the resulting Microsoft ISO or WIM.

---

# 23. Clean Installation Validation / 全新安裝測試

A new VM should always be used to test the final installation media.

Validation sequence:

```text
Boot custom ISO
        ↓
Windows Setup starts
        ↓
Image is detected
        ↓
Clean installation succeeds
        ↓
OOBE succeeds
        ↓
Desktop loads
        ↓
Verify Version
        ↓
Verify Edition
        ↓
Verify Inbox Apps
```

The ISO should not display errors such as:

```text
Windows cannot display the images available for installation.
```

or:

```text
The product key entered does not match any of the Windows images
available for installation.
```

---

# 24. Verify Installed Build / 驗證安裝後 Build

Run:

```cmd
winver
```

Expected custom-project result:

```text
Version 22H2
OS Build 19045.7725
```

The Settings page should report the same build.

---

# 25. Verify Installed Edition / 驗證 Edition

Run:

```cmd
dism /online /Get-CurrentEdition
```

Before an IoT licensing conversion, the deployment base may report:

```text
Current Edition : EnterpriseS
```

This means:

```text
Windows 10 Enterprise LTSC
```

After a valid and applicable Windows IoT Enterprise LTSC licensing conversion:

```text
Current Edition : IoTEnterpriseS
```

This means:

```text
Windows 10 IoT Enterprise LTSC
```

---

# 26. Verify Activation / 驗證啟用狀態

Activation is checked separately:

```cmd
slmgr /xpr
```

or:

```cmd
slmgr /dli
```

The repository does not contain:

```text
MAK keys
OEM keys
Private KMS keys
Activation cracks
Activation bypass tools
```

Users must provide their own legally obtained and applicable Windows licensing.

---

# 27. Support-Lifecycle Warning / 支援生命週期警告

The official Windows 10 IoT Enterprise LTSC 2021 lifecycle applies to Microsoft's official LTSC 2021 product configuration:

```text
Version : 21H2
Build   : 19044
```

This project changes the operating-system version/build state to:

```text
Version : 22H2
Build   : 19045.7725
```

Therefore, this repository does **not** claim that Microsoft's official LTSC 2021 support lifecycle applies unchanged to this customized 19045 image.

The 22H2 conversion documented here should be treated as:

```text
Project-specific customization
```

not:

```text
Official Microsoft LTSC 22H2 release
```

---

# 28. Release Validation Checklist / 發布前檢查

Before documenting a project build as validated, verify:

```text
[ ] Original installation source is known
[ ] Architecture is x64
[ ] Language is zh-TW
[ ] Audit Mode was used
[ ] No normal reference-image user account remains
[ ] 21H2 servicing completed before 22H2 enablement
[ ] WinPE offline 22H2 package installation completed successfully
[ ] Windows boots successfully after enablement
[ ] winver reports 22H2
[ ] Final build is 19045.7725
[ ] Required Inbox Apps are provisioned
[ ] Remaining Store App count is 0
[ ] Sysprep completed successfully
[ ] Windows was not booted again after final Sysprep
[ ] Final WIM contains complete metadata
[ ] Final WIM Edition is intentionally verified
[ ] Installation ISO boots successfully
[ ] Clean VM installation succeeds
[ ] DISM Edition is verified after installation
[ ] Activation is verified separately from Edition
[ ] No product keys are stored in the repository
[ ] No Microsoft ISO/WIM is redistributed
```

---

# 29. Project Build Summary / 專案建置摘要

The final build process can be summarized as:

```text
Windows 10 Enterprise LTSC 2021
21H2 / 19044 / EnterpriseS
        ↓
Audit Mode
        ↓
Update 21H2 to required servicing level
        ↓
Shutdown
        ↓
WinPE
        ↓
Offline Windows 10 22H2 Enablement Package
        ↓
Shutdown
        ↓
Normal Windows boot
        ↓
Verify 22H2 / 19045
        ↓
Service to 19045.7725
        ↓
Optional Base WIM
        ↓
Provision Microsoft Inbox Apps
        ↓
Verify packages
        ↓
Sysprep /generalize /oobe /shutdown
        ↓
WinPE
        ↓
Capture final WIM
        ↓
Build installation ISO
        ↓
Clean VM test
        ↓
EnterpriseS installation base
        ↓
Valid IoT licensing conversion when applicable
        ↓
IoTEnterpriseS
```

---

# 30. Distribution Notice / 散佈聲明

This repository documents a Windows image-building workflow.

It does not distribute:

```text
Microsoft Windows ISO files
install.wim
install.esd
Microsoft proprietary Inbox App packages
Microsoft product keys
Activation bypass tools
```

Users must obtain Windows installation media, Microsoft application packages, and Windows IoT Enterprise licensing through appropriately authorized channels.

---

# Related Documentation / 相關文件

- [Project README](../README.md)
- [Edition and Licensing](EDITION.md)
- [Microsoft Inbox Apps](INBOX-APPS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
