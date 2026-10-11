# Build Guide / 建置指南

This document describes the reference-image workflow used by this project.

本文件記錄本專案實際使用的 Windows 10 LTSC 參考映像製作流程，包括 Audit Mode、系統更新、Microsoft Inbox Apps Provisioning、Sysprep、WinPE Capture，以及最終映像驗證。

---

# 中文

## 1. 建置目標

本專案的建置目標為建立一個：

```text
Architecture : x64
Language     : zh-TW
Base         : Windows 10 Enterprise LTSC 2021
Base Edition : EnterpriseS
Custom Build : 19045.7725
Target       : Windows 10 IoT Enterprise LTSC 2021
```

的乾淨參考映像。

本專案最終使用的自訂系統版本為：

```text
Windows 10
Version 22H2
OS Build 19045.7725
```

> [!IMPORTANT]
> Windows 10 Enterprise LTSC 2021 / Windows 10 IoT Enterprise LTSC 2021 官方版本基於 Windows 10 21H2。
>
> 本專案的 `19045.7725 / 22H2` 是自訂更新後的映像狀態，並不是 Microsoft 官方發布的「LTSC 22H2」。

---

## 2. Edition 模型

本專案使用 Windows 10 Enterprise LTSC 2021 Volume License 安裝媒體作為基底。

原始映像 Edition：

```text
EnterpriseS
```

安裝後可使用：

```cmd
dism /online /Get-CurrentEdition
```

確認。

基底狀態：

```text
Current Edition : EnterpriseS
```

在使用者擁有合法 Windows 10 IoT Enterprise LTSC 授權並完成相應 Edition Conversion 後，目標 Edition 為：

```text
IoTEnterpriseS
```

因此本專案採用：

```text
EnterpriseS
     │
     │ Valid IoT Enterprise LTSC licensing
     ▼
IoTEnterpriseS
```

的部署模型。

> [!NOTE]
> Edition Conversion 與 Windows Activation 應分開理解。
>
> `EnterpriseS` / `IoTEnterpriseS` 表示 Windows Edition。
>
> Activation 狀態則另外使用 `slmgr` 驗證。

---

## 3. 建置流程總覽

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
Update and service reference system
        │
        ▼
Custom Build 19045.7725
        │
        ├───────────────┐
        │               │
        ▼               │
Optional Base WIM       │
Capture                 │
        │               │
        └───────────────┘
                │
                ▼
Provision Microsoft Inbox Apps
                │
                ▼
Verify provisioned packages
                │
                ▼
Sysprep /generalize /oobe /shutdown
                │
                ▼
Boot directly into WinPE
                │
                ▼
Capture Windows partition
                │
                ▼
Final install.wim
                │
                ▼
Build installation ISO
                │
                ▼
Clean VM installation test
                │
                ▼
Verify Edition / Build / Apps
```

---

# 4. 建立乾淨參考系統

使用乾淨的 Windows 10 Enterprise LTSC 2021 x64 zh-TW 安裝媒體建立 VM。

建議在正式建立 Reference Image 時：

- 不建立一般使用者帳號
- 不安裝不必要的第三方軟體
- 不登入個人 Microsoft Account
- 不加入個人檔案
- 不加入產品金鑰到公開腳本或 Repository

在 Windows OOBE 畫面按：

```text
Ctrl + Shift + F3
```

進入 Audit Mode。

---

# 5. Audit Mode

Audit Mode 會使用 Windows 內建：

```text
Administrator
```

帳號登入，而不需要先建立普通使用者帳號。

每次進入 Audit Mode 時可能會自動出現：

```text
System Preparation Tool
Sysprep
```

在映像尚未準備完成之前，關閉該視窗即可。

需要重新啟動時可使用：

```cmd
shutdown /r /t 0
```

在整個 Reference Image 建置期間，應持續保持 Audit Mode 工作流程。

---

# 6. 系統更新

將參考系統更新至本專案所使用的：

```text
Version : 22H2
Build   : 19045.7725
```

完成後使用：

```cmd
winver
```

確認 Build。

也可以使用：

```cmd
dism /online /Get-CurrentEdition
```

確認目前 Edition。

在基底階段預期：

```text
Current Edition : EnterpriseS
```

> [!WARNING]
> 本專案的 22H2 狀態屬於自訂建置流程。
>
> 不應將其描述為 Microsoft 官方發布的 Windows 10 LTSC 22H2。

---
## 6.1 Upgrade from 21H2 to 22H2 / 21H2 升級至 22H2

The original Windows 10 LTSC 2021 reference system used by this project
starts from Windows 10 version 21H2.

本專案使用的原始 Windows 10 LTSC 2021 參考系統起始版本為：

```text
Version : 21H2
Build   : 19044
```

The 21H2 system is first fully serviced with the latest applicable Windows
updates before performing the 22H2 enablement process.

首先在正常 Windows 環境中，將 Windows 10 21H2 更新至當時可取得的最新更新狀態。

建置流程：

```text
Windows 10 LTSC 2021
21H2 / Build 19044
        │
        ▼
Install the latest applicable Windows updates
將 21H2 更新至最新狀態
        │
        ▼
Restart as required
確認所有更新完成
        │
        ▼
Shut down Windows
關閉系統
        │
        ▼
Boot into Windows PE
進入 WinPE
        │
        ▼
Apply the Windows 10 22H2 Enablement Package
to the offline Windows installation
對離線 Windows 安裝 22H2 Enablement Package
        │
        ▼
Complete offline servicing
        │
        ▼
Shut down WinPE
        │
        ▼
Boot Windows normally
        │
        ▼
Verify with winver
        │
        ▼
Version 22H2
```

### Step 1 — Fully update Windows 10 21H2

Before applying the 22H2 Enablement Package, boot the reference system
normally and install all applicable Windows updates.

在進行 22H2 升級之前，先正常啟動 Windows 10 21H2，並完成 Windows Update。

完成後確認系統沒有待處理的重要更新或尚未完成的重新啟動。

Then shut down the system.

完成後關機。

---

### Step 2 — Boot into Windows PE

Boot the reference machine directly into Windows PE.

將參考系統開機進入：

```text
Windows PE
```

Do not boot into the installed Windows system during this step.

此階段不進入原本的 Windows 系統。

---

### Step 3 — Apply the 22H2 Enablement Package offline

In Windows PE, identify the drive letter of the offline Windows installation.

在 WinPE 中先確認 Windows 分割區的磁碟代號。

For example:

```text
C:\Windows
```

Then apply the Windows 10 22H2 Enablement Package to the offline image.

再將 Windows 10 22H2 Enablement Package 套用至該離線 Windows 系統。

> [!NOTE]
> Drive letters in Windows PE may differ from those used in the normal
> Windows environment. Always verify the Windows partition before servicing.

完成套件安裝後，確認 DISM servicing 成功，再關閉 WinPE。

---

### Step 4 — Boot Windows normally

After offline servicing is complete:

```text
Shut down WinPE
        ↓
Boot the installed Windows system
```

第一次啟動時，Windows 會完成必要的版本切換與設定。

---

### Step 5 — Verify 22H2

After Windows starts successfully, run:

```cmd
winver
```

The upgrade is considered successful when Windows reports:

```text
Version 22H2
```

For this project, the final serviced reference system reports:

```text
Version 22H2
OS Build 19045.7725
```

The OS build can also be verified with:

```cmd
ver
```

or through:

```text
Settings
→ System
→ About
→ Windows specifications
```

---

### Upgrade verification

Successful conversion:

```text
Before:
Version 21H2
Build 19044.x

After:
Version 22H2
Build 19045.x
```

The final project image was later serviced to:

```text
Build 19045.7725
```

> [!IMPORTANT]
> This is a custom servicing procedure applied to the LTSC 2021 base.
>
> It does not mean Microsoft released an official
> "Windows 10 IoT Enterprise LTSC 2021 22H2" product.
# 7. 建立乾淨 22H2 Base WIM

在加入額外 Inbox Apps 之前，可先建立乾淨的 Base WIM。

這樣日後若 Provisioning 或其他自訂步驟出現問題，不需要重新從原始 21H2 開始。

完成系統更新後執行：

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

系統關機後：

**不要再次進入 Windows。**

直接開機進入 Windows PE / Windows Setup Environment。

---

## 7.1 WinPE Capture

假設：

```text
C:\ = Windows partition
D:\ = image storage
```

先建立 Scratch directory：

```cmd
md D:\DismScratch
```

範例 Capture：

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_LTSC_22H2_Base_19045.7725.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 Enterprise LTSC 2021 Custom Base" ^
 /Description:"Windows 10 Enterprise LTSC 2021 custom 22H2 base, build 19045.7725" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

完成後驗證：

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_LTSC_22H2_Base_19045.7725.wim /Index:1
```

應確認：

```text
Architecture : x64
Version      : 10.0.19045
Build        : 7725
Edition      : EnterpriseS
Installation : Client
Language     : zh-TW
```

---

# 8. Microsoft Inbox Apps

本專案使用 Microsoft Inbox Apps 套件進行 App Provisioning。

在乾淨的 Reference Image 中進入 Audit Mode 後，再 Provision 必要套件。

使用：

```powershell
Get-AppxProvisionedPackage -Online
```

可以檢查目前已 Provision 的 App。

---

## 8.1 Provisioned Applications

本專案測試使用的主要 App 包括：

| Application | Version |
|---|---:|
| Microsoft Store | 11910.1002.513.0 |
| Store Purchase App | 11811.1001.1813.0 |
| Desktop App Installer | 2019.125.2243.0 |
| Calculator | 2020.1906.55.0 |
| ScreenSketch | 2019.904.1644.0 |
| Camera | 2018.826.98.0 |
| Photos | 2019.19071.12548.0 |
| ZuneMusic | 2019.19071.19011.0 |
| AV1 Video Extension | 1.1.30781.0 |
| VP9 Video Extension | 1.0.22681.0 |
| HEIF Image Extension | 1.0.22742.0 |
| WebP Image Extension | 1.0.22753.0 |
| Web Media Extension | 1.0.20875.0 |
| MPEG-2 Video Extension | 1.0.22661.0 |

Required dependencies include:

```text
Microsoft.NET.Native.Framework 1.7
Microsoft.NET.Native.Framework 2.2
Microsoft.NET.Native.Runtime 1.7
Microsoft.NET.Native.Runtime 2.2

Microsoft.UI.Xaml 2.0
Microsoft.UI.Xaml 2.1
Microsoft.UI.Xaml 2.3

Microsoft.VCLibs 14.00
Microsoft.VCLibs 14.00 Desktop
```

Both x64 and required x86 dependencies are provisioned where applicable.

---

## 8.2 HEVC

HEVC was not included in the Microsoft Inbox Apps source used by this project.

Therefore HEVC is not pre-provisioned into the reference image.

Users should obtain HEVC separately through an appropriately licensed Microsoft distribution channel if required.

---

# 9. Inbox Apps 驗證

完成 Provisioning 後，可以使用：

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, Version |
    Sort-Object DisplayName
```

檢查 App。

也可以使用：

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

本專案建置時的理想驗證結果：

```text
Remaining count = 0
```

---

# 10. Final Sysprep

所有更新與 App Provisioning 完成後，確認沒有一般使用者帳號或不必要的使用者資料。

執行：

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

參數：

```text
/generalize
```

移除裝置特定資訊並準備 Reference Image。

```text
/oobe
```

下一次啟動進入 Windows OOBE。

```text
/shutdown
```

完成後自動關機。

---

## 10.1 非常重要

Sysprep 完成並關機後：

```text
DO NOT boot the reference Windows installation again.
```

必須直接進入 WinPE。

否則 Windows 再次啟動後可能改變已 Generalize 的 Reference Image 狀態。

---

# 11. Final WIM Capture

進入 Windows PE。

假設：

```text
C:\ = Sysprepped Windows
D:\ = output drive
```

建立 Scratch directory：

```cmd
md D:\DismScratch
```

擷取：

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_Custom_19045.7725.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 IoT Enterprise LTSC" ^
 /Description:"Windows 10 LTSC 2021 custom reference image, build 19045.7725" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

> [!NOTE]
> WIM 的 `/Name` 與 `/Description` 是映像顯示資訊。
>
> 它們不會自行改變真正的 Windows Edition。
>
> 真正的 Edition 應以 DISM `Edition` / `Current Edition` 為準。

---

# 12. WIM 驗證

執行：

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_Custom_19045.7725.wim /Index:1
```

本專案的 Enterprise LTSC deployment-base WIM 應具有完整 metadata，例如：

```text
Architecture : x64
Version      : 10.0.19045
Build        : 7725
Edition      : EnterpriseS
Installation : Client
Product Type : WinNT
System Root  : WINDOWS
Language     : zh-TW
```

若出現大量：

```text
<undefined>
```

或缺少 Edition / Installation / Language 等資訊，不建議直接用於正式 ISO。

---

# 13. 不建議直接強制修改 Offline WIM Edition

本專案曾測試將 Offline WIM：

```text
EnterpriseS
```

直接使用 DISM 改為：

```text
IoTEnterpriseS
```

WIM metadata 可以成功變更。

但將該映像直接放回原始 Enterprise LTSC Setup media 後，實際測試出現：

```text
The product key entered does not match any of the Windows images
available for installation.
```

因此，本專案目前不採用：

```text
Force offline EnterpriseS
        ↓
IoTEnterpriseS
```

作為標準 ISO 建置方式。

建議保留與原始 Setup media 相容的：

```text
EnterpriseS
```

安裝映像，再依照合法 IoT Enterprise LTSC 授權流程完成目標 Edition 轉換。

---

# 14. 建立 ISO

將完成的 `install.wim` 放回相容的 Windows Setup media：

```text
sources\install.wim
```

再建立新的 bootable ISO。

本 Repository 不提供 Microsoft Windows ISO 或 WIM 二進位檔。

---

# 15. Clean Installation Test

正式發布文件前，建議建立全新 VM 測試：

```text
Boot ISO
    ↓
Windows Setup
    ↓
Clean installation
    ↓
OOBE
    ↓
Desktop
```

確認 Setup 沒有：

```text
No images are available for installation
```

或：

```text
The product key entered does not match any of the Windows images
available for installation.
```

等錯誤。

---

# 16. 安裝完成後驗證

## Edition

```cmd
dism /online /Get-CurrentEdition
```

Enterprise LTSC 基底：

```text
Current Edition : EnterpriseS
```

完成合法 IoT Enterprise LTSC Edition Conversion 後：

```text
Current Edition : IoTEnterpriseS
```

---

## Build

```cmd
winver
```

本專案目標：

```text
Version 22H2
OS Build 19045.7725
```

---

## Activation

```cmd
slmgr /xpr
```

或：

```cmd
slmgr /dli
```

Activation 與 Edition 應分開驗證。

---

# 17. 不應加入 Reference Image 的內容

正式 Golden / Reference Image 不建議包含：

```text
Personal Microsoft account
Personal files
Passwords
Browser profiles
Private certificates
Private activation infrastructure
MAK keys
OEM keys
Private KMS configuration
Temporary test accounts
```

---

# 18. 發布前檢查

在建立 GitHub Release documentation 前，至少確認：

```text
[ ] Correct Windows architecture
[ ] Correct zh-TW language
[ ] Build 19045.7725
[ ] Complete WIM metadata
[ ] Windows Setup installs successfully
[ ] No temporary user account
[ ] Required Inbox Apps are provisioned
[ ] Sysprep completed successfully
[ ] Clean VM installation completed
[ ] Edition verified with DISM
[ ] No product keys stored in scripts
[ ] No Microsoft ISO/WIM distributed in repository
```

---

# English

## 1. Purpose

This document describes the reference-image build workflow used by this project.

The project starts from:

```text
Windows 10 Enterprise LTSC 2021
Architecture : x64
Language     : zh-TW
Edition ID   : EnterpriseS
```

and creates a customized reference image at:

```text
Windows 10 Version 22H2
OS Build 19045.7725
```

The licensed target edition is Windows 10 IoT Enterprise LTSC 2021:

```text
IoTEnterpriseS
```

> [!IMPORTANT]
> Windows 10 Enterprise LTSC 2021 and Windows 10 IoT Enterprise LTSC 2021 are officially based on Windows 10 21H2.
>
> The 22H2 / Build 19045.7725 state documented here is a custom project build and is not an official Microsoft LTSC 22H2 release.

---

## 2. Reference-image workflow

```text
Windows 10 Enterprise LTSC 2021
        │
        ▼
Clean installation
        │
        ▼
Audit Mode
        │
        ▼
System servicing
        │
        ▼
Build 19045.7725
        │
        ▼
Microsoft Inbox Apps provisioning
        │
        ▼
Package verification
        │
        ▼
Sysprep
/generalize /oobe /shutdown
        │
        ▼
Windows PE
        │
        ▼
DISM image capture
        │
        ▼
Custom WIM
        │
        ▼
Installation media
        │
        ▼
Clean VM validation
```

---

## 3. Audit Mode

At the Windows OOBE screen:

```text
Ctrl + Shift + F3
```

Audit Mode allows the reference system to be serviced without creating a normal end-user account.

The built-in Administrator account is used during reference-image preparation.

---

## 4. Version verification

Use:

```cmd
winver
```

Expected custom build:

```text
Version 22H2
OS Build 19045.7725
```

Check Edition with:

```cmd
dism /online /Get-CurrentEdition
```

The deployment base is expected to report:

```text
Current Edition : EnterpriseS
```

---

## 5. Microsoft Inbox Apps

Microsoft Inbox Apps and their required dependencies are provisioned into the reference image before Sysprep.

Provisioned packages can be inspected with:

```powershell
Get-AppxProvisionedPackage -Online
```

HEVC is not included in the package source used by this project and is therefore not pre-provisioned.

---

## 6. Sysprep

After servicing and provisioning are complete:

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

After shutdown:

**Do not boot the reference Windows installation again.**

Boot directly into Windows PE.

---

## 7. Capture

Example:

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_Custom_19045.7725.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 IoT Enterprise LTSC" ^
 /Description:"Windows 10 LTSC 2021 custom reference image, build 19045.7725" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

Verify the captured image:

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_Custom_19045.7725.wim /Index:1
```

The image should contain complete metadata.

---

## 8. Edition handling

The installation base uses:

```text
EnterpriseS
```

The licensed IoT Enterprise LTSC target is:

```text
IoTEnterpriseS
```

These should not be confused with activation state.

The actual Edition should be checked with:

```cmd
dism /online /Get-CurrentEdition
```

---

## 9. Offline Edition modification

Testing confirmed that DISM can alter the offline WIM Edition from:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

However, using the resulting image directly with the original Enterprise LTSC Setup media caused a product-key/image mismatch during Windows Setup.

For this reason, forced offline Edition conversion is not used as the standard deployment workflow in this project.

---

## 10. Final validation

A fresh VM installation should verify:

```text
Windows Setup succeeds
Correct architecture
Correct language
Build 19045.7725
Required Inbox Apps
Complete WIM metadata
No temporary reference-image user
Correct Windows Edition
```

Edition:

```cmd
dism /online /Get-CurrentEdition
```

Build:

```cmd
winver
```

Activation:

```cmd
slmgr /xpr
```

---

# Legal / Distribution Note

This repository documents a build workflow.

It does not distribute:

```text
Microsoft Windows ISO files
install.wim
install.esd
Microsoft proprietary App packages
Product keys
Activation bypass tools
```

Users must obtain Microsoft Windows installation media, Microsoft packages and Windows IoT Enterprise licensing through properly authorized channels.

---

# Related Documentation

- [Project README](../README.md)
- [Edition and Licensing](EDITION.md)
- [Inbox Apps](INBOX-APPS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
