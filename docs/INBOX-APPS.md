# Microsoft Inbox Apps / Microsoft 內建應用程式

This document records the Microsoft Inbox Apps and framework dependencies used by this project.

本文件記錄本專案在 Windows 10 LTSC Reference Image 中實際 Provision 的 Microsoft Inbox Apps、Frameworks、Dependencies，以及驗證方式。

---

# 中文

## 1. 目的

Windows 10 Enterprise LTSC 2021 預設不包含部分一般 Windows 版本常見的 Microsoft Store / UWP 應用程式。

本專案使用 Microsoft 提供的 Inbox Apps 套件，在 Audit Mode 中將必要應用程式 Provision 到 Reference Image。

Provision 的目的不是只安裝到目前 Administrator 帳號，而是讓新建立的使用者在 OOBE 後也能取得相應 App。

主要使用：

```powershell
Add-AppxProvisionedPackage
```

而不是僅使用：

```powershell
Add-AppxPackage
```

---

## 2. Provisioning 環境

本專案完成 Provisioning 時的參考環境：

```text
Windows       : Windows 10 LTSC
Architecture  : x64
Language      : zh-TW
Version       : 22H2
Build         : 19045.7725
Deployment    : Audit Mode
Account       : Built-in Administrator
```

Microsoft Inbox Apps 套件來源包含：

```text
amd64fre
x86fre
```

x64 系統除了主要 x64 套件外，部分應用程式仍需要 x86 Framework dependencies，因此兩種架構的必要 Dependency 均予以 Provision。

---

# 3. 已 Provision 的主要應用程式

本專案成功 Provision 14 個主要 App。

| # | Application | Package / Component | Version |
|---:|---|---|---:|
| 1 | Microsoft Store | Microsoft.WindowsStore | 11910.1002.513.0 |
| 2 | Store Purchase App | Microsoft.StorePurchaseApp | 11811.1001.1813.0 |
| 3 | Desktop App Installer | Microsoft.DesktopAppInstaller | 2019.125.2243.0 |
| 4 | Calculator | Microsoft.WindowsCalculator | 2020.1906.55.0 |
| 5 | ScreenSketch | Microsoft.ScreenSketch | 2019.904.1644.0 |
| 6 | Camera | Microsoft.WindowsCamera | 2018.826.98.0 |
| 7 | Photos | Microsoft.Windows.Photos | 2019.19071.12548.0 |
| 8 | Music | Microsoft.ZuneMusic | 2019.19071.19011.0 |
| 9 | AV1 Video Extension | Microsoft.AV1VideoExtension | 1.1.30781.0 |
| 10 | VP9 Video Extension | Microsoft.VP9VideoExtensions | 1.0.22681.0 |
| 11 | HEIF Image Extension | Microsoft.HEIFImageExtension | 1.0.22742.0 |
| 12 | WebP Image Extension | Microsoft.WebpImageExtension | 1.0.22753.0 |
| 13 | Web Media Extension | Microsoft.WebMediaExtensions | 1.0.20875.0 |
| 14 | MPEG-2 Video Extension | Microsoft.MPEG2VideoExtension | 1.0.22661.0 |

---

# 4. Frameworks / Dependencies

在主要 App Provision 之前，本專案先 Provision 必要 Framework。

共確認 18 個 Framework / Architecture combinations。

## .NET Native

```text
Microsoft.NET.Native.Framework 1.7 x64
Microsoft.NET.Native.Framework 1.7 x86

Microsoft.NET.Native.Framework 2.2 x64
Microsoft.NET.Native.Framework 2.2 x86

Microsoft.NET.Native.Runtime 1.7 x64
Microsoft.NET.Native.Runtime 1.7 x86

Microsoft.NET.Native.Runtime 2.2 x64
Microsoft.NET.Native.Runtime 2.2 x86
```

共：

```text
8
```

---

## Microsoft UI XAML

```text
Microsoft.UI.Xaml 2.0 x64
Microsoft.UI.Xaml 2.0 x86

Microsoft.UI.Xaml 2.1 x64
Microsoft.UI.Xaml 2.1 x86

Microsoft.UI.Xaml 2.3 x64
Microsoft.UI.Xaml 2.3 x86
```

共：

```text
6
```

---

## Microsoft Visual C++ Libraries

```text
Microsoft.VCLibs 14.00 x64
Microsoft.VCLibs 14.00 x86

Microsoft.VCLibs 14.00 Desktop x64
Microsoft.VCLibs 14.00 Desktop x86
```

共：

```text
4
```

因此 Framework / Dependency 總數：

```text
8 + 6 + 4 = 18
```

---

# 5. Provisioning 順序

本專案採用：

```text
Frameworks / Dependencies
        ↓
Main Inbox Apps
        ↓
Provisioned-package verification
        ↓
Sysprep
```

這個順序可避免主要 App 因缺少 Framework 而無法 Provision。

---

# 6. Framework Provisioning

Framework 類型套件使用：

```powershell
Add-AppxProvisionedPackage `
    -Online `
    -PackagePath "<package path>" `
    -SkipLicense
```

範例：

```powershell
Add-AppxProvisionedPackage `
    -Online `
    -PackagePath "G:\amd64fre\<FrameworkPackage>.appx" `
    -SkipLicense
```

> [!NOTE]
> 實際 Drive Letter 會依掛載環境而改變。
>
> 本專案的一次成功建置中，Microsoft Inbox Apps 媒體掛載為 `G:`。

---

# 7. Main App Provisioning

具有 Microsoft Offline License XML 的主要 App 使用：

```powershell
Add-AppxProvisionedPackage `
    -Online `
    -PackagePath "<AppPackage>" `
    -LicensePath "<License.xml>"
```

範例：

```powershell
Add-AppxProvisionedPackage `
    -Online `
    -PackagePath "G:\amd64fre\<AppPackage>.appxbundle" `
    -LicensePath "G:\amd64fre\<AppLicense>.xml"
```

不要假設所有 Package 都能使用：

```text
-SkipLicense
```

若 Microsoft 套件來源提供對應 License XML，應使用與該 Package 相符的授權檔案。

---

# 8. Provisioned Package 驗證

完成後：

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, Version, Architecture |
    Sort-Object DisplayName
```

可查看目前映像中 Provisioned 的 App。

---

# 9. Provisioned / Installed App 差異檢查

本專案另外使用以下方式，檢查是否存在已安裝但尚未 Provision 的 Microsoft Store 類 App：

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

本專案成功建置時的目標結果為：

```text
Remaining count = 0
```

表示需要納入 Reference Image 的 Store 類 App 均已正確 Provision。

---

# 10. HEVC

本專案使用的 Microsoft Inbox Apps 套件來源中：

```text
未包含 HEVC 套件
```

因此 HEVC：

```text
NOT PRE-PROVISIONED
```

不應在本 Repository 的 App 清單中宣稱 HEVC 已內建。

若使用者需要 HEVC，應透過具有適當授權的 Microsoft 提供方式另外取得。

---

# 11. 不採用第三方下載來源

本專案不建議從不明第三方網站下載：

```text
.appx
.appxbundle
.msix
.msixbundle
License XML
```

Microsoft Inbox Apps 應來自適當的 Microsoft / 授權來源。

這可降低：

```text
Package tampering
Version mismatch
Dependency mismatch
Invalid license
Malware
```

等風險。

---

# 12. 為什麼使用 Provisioning？

若只執行：

```powershell
Add-AppxPackage
```

App 通常只是安裝給目前使用者。

Reference Image 建置的目標則是：

```text
Current Audit account
        +
Future users created after OOBE
```

因此主要使用：

```powershell
Add-AppxProvisionedPackage
```

將 App Provision 到 Windows Image。

---

# 13. Sysprep 前檢查

在 Sysprep 之前，建議再次執行：

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName,Version |
    Sort-Object DisplayName
```

以及：

```powershell
Get-AppxPackage -AllUsers |
    Select-Object Name,Version,PackageUserInformation |
    Sort-Object Name
```

避免出現：

```text
某 App 只安裝給 Administrator
但沒有 Provision 給所有新使用者
```

的情況。

這類不一致可能導致：

```text
Sysprep 0x80073cf2
```

等 Appx 相關錯誤。

---

# 14. Provisioning 驗證結果

本專案成功建置時確認：

```text
Frameworks / Dependencies : 18 successful
Main Inbox Apps            : 14 successful
Remaining Store Apps       : 0
```

因此該 Reference Image 可繼續進入：

```text
Sysprep
/generalize
/oobe
/shutdown
```

階段。

---

# English

## 1. Purpose

Windows 10 Enterprise LTSC 2021 does not include all of the Microsoft Store / UWP applications commonly present in regular Windows editions.

This project provisions selected Microsoft Inbox Apps into the reference image during Audit Mode.

The goal is to provision applications into the Windows image rather than merely installing them for the current Administrator account.

The primary servicing command is therefore:

```powershell
Add-AppxProvisionedPackage
```

rather than only:

```powershell
Add-AppxPackage
```

---

# 2. Provisioning environment

The successfully tested reference environment was:

```text
Windows       : Windows 10 LTSC
Architecture  : x64
Language      : zh-TW
Version       : 22H2
Build         : 19045.7725
Deployment    : Audit Mode
Account       : Built-in Administrator
```

Required packages were sourced from Microsoft Inbox Apps media containing both:

```text
amd64fre
x86fre
```

Some x64 applications require x86 dependency packages, so required dependencies for both architectures were provisioned where applicable.

---

# 3. Main applications

Fourteen main Inbox Apps were successfully provisioned.

| # | Application | Package / Component | Version |
|---:|---|---|---:|
| 1 | Microsoft Store | Microsoft.WindowsStore | 11910.1002.513.0 |
| 2 | Store Purchase App | Microsoft.StorePurchaseApp | 11811.1001.1813.0 |
| 3 | Desktop App Installer | Microsoft.DesktopAppInstaller | 2019.125.2243.0 |
| 4 | Calculator | Microsoft.WindowsCalculator | 2020.1906.55.0 |
| 5 | ScreenSketch | Microsoft.ScreenSketch | 2019.904.1644.0 |
| 6 | Camera | Microsoft.WindowsCamera | 2018.826.98.0 |
| 7 | Photos | Microsoft.Windows.Photos | 2019.19071.12548.0 |
| 8 | Music | Microsoft.ZuneMusic | 2019.19071.19011.0 |
| 9 | AV1 Video Extension | Microsoft.AV1VideoExtension | 1.1.30781.0 |
| 10 | VP9 Video Extension | Microsoft.VP9VideoExtensions | 1.0.22681.0 |
| 11 | HEIF Image Extension | Microsoft.HEIFImageExtension | 1.0.22742.0 |
| 12 | WebP Image Extension | Microsoft.WebpImageExtension | 1.0.22753.0 |
| 13 | Web Media Extension | Microsoft.WebMediaExtensions | 1.0.20875.0 |
| 14 | MPEG-2 Video Extension | Microsoft.MPEG2VideoExtension | 1.0.22661.0 |

---

# 4. Framework dependencies

The project successfully provisioned 18 framework / architecture combinations.

```text
.NET Native
8

Microsoft UI XAML
6

Microsoft Visual C++ Libraries
4

Total
18
```

Both x64 and required x86 variants are included where applicable.

---

# 5. Provisioning order

The reference image uses:

```text
Framework dependencies
        ↓
Main Inbox Apps
        ↓
Verification
        ↓
Sysprep
```

Dependencies are provisioned before applications that require them.

---

# 6. Package verification

Provisioned packages:

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName, Version, Architecture |
    Sort-Object DisplayName
```

Installed Store-type packages that are not provisioned can be checked with:

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

The successful reference-image result was:

```text
Remaining count = 0
```

---

# 7. HEVC

HEVC was not present in the Microsoft Inbox Apps source used for this project.

Therefore:

```text
HEVC is not pre-provisioned.
```

Users requiring HEVC should obtain it through an appropriately licensed Microsoft distribution channel.

---

# 8. Sysprep compatibility

A common Sysprep problem occurs when an Appx package is installed for one user but is not provisioned for all users.

This can lead to errors such as:

```text
0x80073cf2
```

For this reason, Appx state should be verified before running Sysprep.

---

# 9. Verified provisioning result

The successfully tested reference image confirmed:

```text
Frameworks / Dependencies : 18 successful
Main Inbox Apps            : 14 successful
Remaining Store Apps       : 0
```

The image could then proceed to:

```text
Sysprep
/generalize
/oobe
/shutdown
```

---

# Distribution note

This repository does not redistribute Microsoft's proprietary Inbox App packages or their license files.

Users must obtain required Microsoft packages through appropriately authorized Microsoft sources.

---

# Related Documentation

- [Project README](../README.md)
- [Build Guide](BUILD.md)
- [Edition and Licensing](EDITION.md)
- [Troubleshooting](TROUBLESHOOTING.md)
