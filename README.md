## ⬇️ Download / 下載

### Windows 10 IoT Enterprise LTSC 2021 — Custom 22H2

| Item | Information |
|---|---|
| Version | `22H2` |
| OS Build | `19045.7725` |
| Architecture | `x64` |
| Language | `zh-TW` |
| Archive | `7-Zip multi-volume archive` |
| Extract Password / 解壓密碼 | **`7725`** |

### 📥 [Download v0.1.0 / 下載 v0.1.0](/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/tag/v0.1.0)

The installation image is distributed as a password-protected multi-volume 7-Zip archive.

安裝映像採用有密碼保護的 7-Zip 分卷格式提供。

Download **all five parts**:

```text
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.001
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.002
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.003
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.004
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.005
```

Place all five files in the **same folder**.

請將五個分卷全部下載並放在**同一個資料夾**。

Then open or extract only:

```text
zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.001
```

with **7-Zip**.

後續 `.002`、`.003`、`.004`、`.005` 會由 7-Zip 自動讀取，**不需要逐一解壓**。

### 🔑 Extract Password / 解壓密碼

```text
7725
```

### 🔐 File Integrity / 檔案完整性

Download:

```text
SHA256.txt
```

and verify the downloaded parts before extraction.

PowerShell example:

```powershell
Get-FileHash ".\zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.001" -Algorithm SHA256
```

Compare the calculated hash with the corresponding value in `SHA256.txt`.

### ⚠️ Important

> This project uses a custom LTSC-2021-based Windows 10 22H2 / Build 19045.7725 configuration.
>
> It is **not** an official Microsoft Windows 10 IoT Enterprise LTSC 2021 22H2 release.
>
> 本專案為基於 LTSC 2021 的自訂 Windows 10 22H2 / Build 19045.7725 組態，並非 Microsoft 官方發布的 LTSC 22H2 版本。

---

# Windows 10 IoT Enterprise LTSC 2021 22H2 zh-TW Custom

> Custom Windows 10 IoT Enterprise LTSC 2021 deployment and reference-image project  
> Windows 10 IoT Enterprise LTSC 2021 自訂部署與參考映像專案

---

# 中文說明

## 專案簡介

本專案記錄 Windows 10 IoT Enterprise LTSC 2021 的自訂部署、更新、應用程式 Provisioning、Sysprep 與 WIM 擷取流程。

此專案使用 Windows 10 Enterprise LTSC 2021 x64 Volume License 安裝媒體作為部署基底，原始 Edition ID 為：

```text
EnterpriseS
```

依照 Windows 10 IoT Enterprise LTSC 2021 Volume License 的授權部署方式，在套用合法的 Windows 10 IoT Enterprise LTSC 2021 授權金鑰後，系統可轉換為：

```text
IoTEnterpriseS
```

因此，本專案中的 Edition 邏輯為：

```text
Windows 10 Enterprise LTSC 2021
Edition ID: EnterpriseS
        │
        │ Apply a valid Windows 10 IoT Enterprise LTSC license
        ▼
Windows 10 IoT Enterprise LTSC 2021
Edition ID: IoTEnterpriseS
```

請注意：

**Edition Conversion（版本轉換）與 Activation（啟用）並不是完全相同的概念。**

Edition 應以以下指令確認：

```cmd
dism /online /Get-CurrentEdition
```

若顯示：

```text
Current Edition : EnterpriseS
```

代表目前系統仍為 Windows 10 Enterprise LTSC。

若顯示：

```text
Current Edition : IoTEnterpriseS
```

代表系統已轉換為 Windows 10 IoT Enterprise LTSC。

啟用狀態則可另外使用：

```cmd
slmgr /xpr
```

確認。

---

## 專案版本資訊

| 項目 | 內容 |
|---|---|
| Base OS | Windows 10 Enterprise LTSC 2021 |
| Base Edition ID | `EnterpriseS` |
| Target OS | Windows 10 IoT Enterprise LTSC 2021 |
| Target Edition ID | `IoTEnterpriseS` |
| Architecture | x64 |
| Language | zh-TW |
| Original LTSC Release | Windows 10 21H2 |
| Original LTSC Build | 19044 |
| Custom Build | 19045.7725 |
| Custom Branch | Windows 10 22H2 |
| Deployment Mode | Audit Mode + Sysprep |
| Image Format | WIM |
| Application Source | Microsoft Inbox Apps packages |

---

## 重要：這不是 Microsoft 官方 LTSC 22H2

Windows 10 IoT Enterprise LTSC 2021 官方版本基於：

```text
Windows 10 Version 21H2
Build 19044
```

本專案中的：

```text
Windows 10 Version 22H2
Build 19045.7725
```

是由 LTSC 2021 基底經過自訂更新與映像製作流程所建立的版本。

因此：

```text
Windows 10 IoT Enterprise LTSC 2021 22H2
```

是本專案用來描述自訂映像狀態的名稱，

**並不代表 Microsoft 曾正式發布「Windows 10 IoT Enterprise LTSC 2021 22H2」。**

本專案不是 Microsoft 官方發行版本。

---

# Edition 與授權邏輯

## 原始安裝狀態

Windows 10 Enterprise LTSC 2021 Volume License 安裝媒體中的安裝映像可能顯示：

```text
Edition : EnterpriseS
```

安裝完成後：

```cmd
dism /online /Get-CurrentEdition
```

可能顯示：

```text
Current Edition : EnterpriseS
```

此時 Windows 介面會顯示：

```text
Windows 10 Enterprise LTSC
```

---

## IoT Enterprise LTSC 轉換

使用者必須自行擁有適用且合法的 Windows 10 IoT Enterprise LTSC 授權。

套用相應授權後，Edition 可轉換為：

```text
IoTEnterpriseS
```

再次執行：

```cmd
dism /online /Get-CurrentEdition
```

應顯示：

```text
Current Edition : IoTEnterpriseS
```

此時 Windows 可辨識為：

```text
Windows 10 IoT Enterprise LTSC
```

---

## 不要以 Winver 作為唯一 Edition 判斷方式

建議使用：

```cmd
dism /online /Get-CurrentEdition
```

作為 Edition ID 的主要確認方式。

其次再使用：

```cmd
winver
```

確認版本及 Build。

最後使用：

```cmd
slmgr /xpr
```

確認授權啟用狀態。

---

# 建置流程

本專案的參考映像製作流程如下：

```text
Windows 10 Enterprise LTSC 2021
        │
        ▼
Install Windows
        │
        ▼
Enter Audit Mode
Ctrl + Shift + F3
        │
        ▼
Update / customize system
        │
        ▼
Build 19045.7725
        │
        ▼
Provision Microsoft Inbox Apps
        │
        ▼
Verify packages
        │
        ▼
Sysprep
/generalize /oobe /shutdown
        │
        ▼
Boot into WinPE
        │
        ▼
Capture Windows partition
        │
        ▼
install.wim
        │
        ▼
Build custom installation media
```

---

# Audit Mode

在 Windows OOBE 畫面按下：

```text
Ctrl + Shift + F3
```

即可進入 Audit Mode。

Audit Mode 的優點是：

- 不需要建立一般使用者帳號
- 使用 Windows 內建 Administrator
- 適合安裝更新與 Provision App
- 適合建立 Golden / Reference Image
- 可在完成後使用 Sysprep Generalize

在製作 Reference Image 時，不建議建立一般使用者帳號後再進行擷取。

---

# Microsoft Inbox Apps

本專案使用 Microsoft InboxApps 套件進行 Provisioning。

目前包含：

| Application | Version |
|---|---:|
| Microsoft Store | 11910.1002.513.0 |
| Store Purchase App | 11811.1001.1813.0 |
| Desktop App Installer | 2019.125.2243.0 |
| Calculator | 2020.1906.55.0 |
| ScreenSketch / Snipping Tool | 2019.904.1644.0 |
| Camera | 2018.826.98.0 |
| Photos | 2019.19071.12548.0 |
| Groove Music / ZuneMusic | 2019.19071.19011.0 |
| AV1 Video Extension | 1.1.30781.0 |
| VP9 Video Extension | 1.0.22681.0 |
| HEIF Image Extension | 1.0.22742.0 |
| WebP Image Extension | 1.0.22753.0 |
| Web Media Extension | 1.0.20875.0 |
| MPEG-2 Video Extension | 1.0.22661.0 |

必要 Framework 亦包括：

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

x64 與必要的 x86 dependencies 均依照套件需求 Provision。

---

## HEVC

目前使用的 Microsoft InboxApps 套件來源中沒有提供 HEVC 套件，因此本專案沒有將 HEVC 預先 Provision 到映像內。

使用者可依照自身授權與 Microsoft Store 提供方式自行取得。

---

# Provisioned App 驗證

可使用 PowerShell：

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, Version |
    Sort-Object DisplayName
```

確認 Provisioned Packages。

也可比較目前所有使用者 App 與 Provisioned App：

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

理想狀態：

```text
Remaining count = 0
```

---

# Sysprep

完成所有更新、Provisioning 與客製化後，可執行：

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

系統自動關機後：

**不要再次開機進入 Windows。**

應直接從 Windows PE 或 Windows Setup Environment 開機，然後擷取 Windows Partition。

---

# WIM Capture

範例：

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_Custom.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 IoT Enterprise LTSC" ^
 /Description:"Windows 10 IoT Enterprise LTSC Custom Image" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

完成後：

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_Custom.wim /Index:1
```

確認映像資訊。

---

# Edition 驗證

安裝後使用：

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

# Build 驗證

執行：

```cmd
winver
```

本專案自訂映像預期 Build：

```text
19045.7725
```

---

# Activation 驗證

可使用：

```cmd
slmgr /xpr
```

或：

```cmd
slmgr /dli
```

確認授權狀態。

本專案：

- 不提供產品金鑰
- 不包含 MAK
- 不包含私人 KMS 設定
- 不繞過 Windows Activation
- 不提供任何 Activation Crack

使用者必須自行取得合法 Windows 授權。

---

# 為什麼 install.wim 顯示 EnterpriseS？

這是本專案特別容易產生誤解的地方。

本專案的 Volume License 安裝基底為：

```text
Windows 10 Enterprise LTSC 2021
Edition ID: EnterpriseS
```

而目標授權 Edition 為：

```text
Windows 10 IoT Enterprise LTSC 2021
Edition ID: IoTEnterpriseS
```

因此：

```text
EnterpriseS
     │
     │ Valid IoT Enterprise LTSC license
     ▼
IoTEnterpriseS
```

並不應單純將 `install.wim` 中顯示 `EnterpriseS` 理解為部署流程錯誤。

真正的 Edition 應依照實際授權與 Edition Conversion 結果判斷。

---

# 為什麼不直接修改 WIM 為 IoTEnterpriseS？

測試中，將原始 `EnterpriseS` WIM 使用 DISM 離線轉換成：

```text
IoTEnterpriseS
```

雖然 DISM 可以成功修改 Edition metadata，但原始 Windows Setup 媒體仍可能使用原本 Enterprise LTSC 的 Edition / Product Key 選擇邏輯。

因此可能導致 Windows Setup 顯示類似：

```text
The product key entered does not match any of the Windows images
available for installation.
```

因此本專案不採用單純離線強制修改 WIM Edition 的方式作為標準部署流程。

---

# GitHub 發布方式

本 Repository 主要公開：

```text
Documentation
PowerShell scripts
DISM commands
Build notes
Package lists
Screenshots
Checksums
Testing notes
```

建議結構：

```text
.
├── README.md
├── LICENSE
├── scripts
│   ├── Provision-InboxApps.ps1
│   ├── Verify-InboxApps.ps1
│   └── Verify-Windows-Edition.ps1
├── docs
│   ├── BUILD.md
│   ├── EDITION.md
│   ├── INBOX-APPS.md
│   └── TROUBLESHOOTING.md
├── screenshots
└── checksums
    └── SHA256.txt
```

---

# Microsoft 安裝媒體

本 Repository 不提供或重新散佈：

```text
Windows ISO
install.wim
install.esd
Microsoft proprietary App packages
MAK product keys
OEM product keys
Volume License product keys
```

使用者應透過 Microsoft 或合法授權管道自行取得 Windows 安裝媒體、授權與必要套件。

---

# Disclaimer / 免責聲明

本專案：

- 非 Microsoft 官方專案
- 與 Microsoft Corporation 無關
- 不代表 Microsoft 官方 Windows Release
- 不提供 Windows 授權
- 不提供 Windows 產品金鑰
- 不提供啟用繞過方式

Microsoft、Windows、Windows IoT、Windows Enterprise 及其他 Microsoft 產品名稱為 Microsoft Corporation 的商標。

Repository 中自行撰寫的 scripts 與 documentation 可依本 Repository LICENSE 使用。

Microsoft 所有二進位檔案、Windows 元件與應用程式仍受 Microsoft 自身授權條款約束。

---

# English

## Overview

This repository documents a custom deployment and reference-image workflow for Windows 10 IoT Enterprise LTSC 2021.

The deployment starts from Windows 10 Enterprise LTSC 2021 x64 Volume License installation media.

The base Windows Edition ID is:

```text
EnterpriseS
```

With an appropriate and legally obtained Windows 10 IoT Enterprise LTSC 2021 license, the installed operating system can be transformed to:

```text
IoTEnterpriseS
```

The deployment model is therefore:

```text
Windows 10 Enterprise LTSC 2021
Edition ID: EnterpriseS
        │
        │ Apply a valid Windows 10 IoT Enterprise LTSC license
        ▼
Windows 10 IoT Enterprise LTSC 2021
Edition ID: IoTEnterpriseS
```

Edition conversion and Windows activation should be treated as separate concepts.

The current Edition can be verified with:

```cmd
dism /online /Get-CurrentEdition
```

An Enterprise LTSC installation reports:

```text
Current Edition : EnterpriseS
```

After a valid IoT Enterprise LTSC edition transformation:

```text
Current Edition : IoTEnterpriseS
```

Activation status can be checked separately with:

```cmd
slmgr /xpr
```

---

## Project information

| Item | Value |
|---|---|
| Base OS | Windows 10 Enterprise LTSC 2021 |
| Base Edition ID | `EnterpriseS` |
| Target OS | Windows 10 IoT Enterprise LTSC 2021 |
| Target Edition ID | `IoTEnterpriseS` |
| Architecture | x64 |
| Language | zh-TW |
| Official LTSC Release | Windows 10 21H2 |
| Official LTSC Base Build | 19044 |
| Custom Build | 19045.7725 |
| Custom Branch | Windows 10 22H2 |
| Deployment | Audit Mode + Sysprep |
| Image Format | WIM |
| App Source | Microsoft Inbox Apps packages |

---

## Important: This is not an official Microsoft LTSC 22H2 release

The official Windows 10 IoT Enterprise LTSC 2021 release is based on:

```text
Windows 10 Version 21H2
Build 19044
```

This project uses a customized image that has been updated to:

```text
Windows 10 Version 22H2
Build 19045.7725
```

Therefore, the term:

```text
Windows 10 IoT Enterprise LTSC 2021 22H2
```

is used only to describe the customized state of this project.

Microsoft did not release an official product named:

```text
Windows 10 IoT Enterprise LTSC 2021 22H2
```

This repository is not an official Microsoft Windows release.

---

# Edition and licensing model

The installation media used as the deployment base contains:

```text
Edition ID: EnterpriseS
```

After installation, the following command may report:

```cmd
dism /online /Get-CurrentEdition
```

```text
Current Edition : EnterpriseS
```

At this stage Windows identifies itself as:

```text
Windows 10 Enterprise LTSC
```

A user with a valid Windows 10 IoT Enterprise LTSC license may perform the supported licensing transformation.

After transformation:

```text
Current Edition : IoTEnterpriseS
```

Windows then identifies itself as:

```text
Windows 10 IoT Enterprise LTSC
```

---

# Build workflow

```text
Windows 10 Enterprise LTSC 2021
        │
        ▼
Install Windows
        │
        ▼
Enter Audit Mode
Ctrl + Shift + F3
        │
        ▼
Install updates and customize
        │
        ▼
Build 19045.7725
        │
        ▼
Provision Microsoft Inbox Apps
        │
        ▼
Verify provisioned packages
        │
        ▼
Sysprep
/generalize /oobe /shutdown
        │
        ▼
Boot Windows PE
        │
        ▼
Capture Windows partition
        │
        ▼
WIM reference image
```

---

# Audit Mode

At the Windows OOBE screen press:

```text
Ctrl + Shift + F3
```

Audit Mode allows the reference image to be prepared without creating a normal user account.

It uses the built-in Administrator account and is suitable for:

- Windows servicing
- Package provisioning
- Driver installation
- Customization
- Reference-image preparation
- Sysprep

---

# Microsoft Inbox Apps

The reference image provisions the following Microsoft applications:

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

Required frameworks include:

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

HEVC is not pre-provisioned because it was not present in the Microsoft Inbox Apps package source used for this project.

---

# Sysprep

After servicing and customization are complete:

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

After the system shuts down:

**Do not boot the reference Windows installation again.**

Boot directly into Windows PE and capture the Windows partition.

---

# Image capture

Example:

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_Custom.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 IoT Enterprise LTSC" ^
 /Description:"Windows 10 IoT Enterprise LTSC Custom Image" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

Verify:

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_Custom.wim /Index:1
```

---

# Validation

## Edition

```cmd
dism /online /Get-CurrentEdition
```

Possible base result:

```text
Current Edition : EnterpriseS
```

After the valid IoT licensing transformation:

```text
Current Edition : IoTEnterpriseS
```

## Windows build

```cmd
winver
```

Expected custom build:

```text
19045.7725
```

## Activation

```cmd
slmgr /xpr
```

or:

```cmd
slmgr /dli
```

---

# Why can the WIM report EnterpriseS?

The Volume License deployment base is:

```text
Windows 10 Enterprise LTSC 2021
EnterpriseS
```

The licensed target edition is:

```text
Windows 10 IoT Enterprise LTSC 2021
IoTEnterpriseS
```

The intended relationship is:

```text
EnterpriseS
     │
     │ Valid IoT Enterprise LTSC licensing
     ▼
IoTEnterpriseS
```

Therefore, an `EnterpriseS` base image does not by itself indicate that the deployment workflow is incorrect.

---

# Why not force the offline WIM to IoTEnterpriseS?

Testing showed that DISM can change an offline image from:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

However, the original Windows Setup media may continue to use the original Enterprise LTSC edition and product-key selection logic.

This can result in Setup errors such as:

```text
The product key entered does not match any of the Windows images
available for installation.
```

For this reason, this repository does not use a forced offline WIM Edition modification as its standard deployment method.

---

# Distribution policy

This repository is intended to distribute:

```text
Documentation
Scripts
Build instructions
Package manifests
Screenshots
Checksums
Testing information
```

It does not distribute:

```text
Microsoft Windows ISO files
install.wim
install.esd
Microsoft proprietary application packages
MAK keys
OEM product keys
Private volume-license keys
Activation bypass tools
```

Users must obtain Windows installation media, Windows IoT Enterprise licensing, and Microsoft packages from Microsoft or other properly authorized channels.

---

# Repository structure

```text
.
├── README.md
├── LICENSE
├── scripts
│   ├── Provision-InboxApps.ps1
│   ├── Verify-InboxApps.ps1
│   └── Verify-Windows-Edition.ps1
├── docs
│   ├── BUILD.md
│   ├── EDITION.md
│   ├── INBOX-APPS.md
│   └── TROUBLESHOOTING.md
├── screenshots
└── checksums
    └── SHA256.txt
```

---

# Disclaimer

This project is:

- not affiliated with Microsoft Corporation
- not an official Microsoft Windows release
- not a Windows licensing service
- not an activation bypass project

No Windows product keys are provided by this repository.

Microsoft, Windows, Windows IoT, Windows Enterprise and related names are trademarks of Microsoft Corporation.

Any repository license applies only to original scripts, documentation and other material authored for this project.

Microsoft binaries and software remain subject to Microsoft's applicable license terms.

---

# Suggested repository name

```text
Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom
```

Suggested release tag:

```text
v19045.7725
```

Suggested internal/private ISO filename:

```text
zh-tw_windows_10_iot_enterprise_ltsc_2021_22h2_x64_19045.7725_custom.iso
```

The ISO itself should not be included in public GitHub releases unless you separately have redistribution rights for all included Microsoft content.
