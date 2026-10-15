# Windows 10 IoT Enterprise LTSC 2021 — Custom 22H2 zh-TW

Custom Windows 10 IoT Enterprise LTSC 2021 reference-image and deployment project.

本專案提供 Windows 10 IoT Enterprise LTSC 2021 的自訂 Reference Image、建置流程、Inbox Apps Provisioning、驗證工具與相關技術文件。

> [!IMPORTANT]
> Microsoft 官方 Windows 10 IoT Enterprise LTSC 2021 為
> **Version 21H2 / Build 19044**。
>
> 本專案使用的 **22H2 / Build 19045.7725** 為自訂 servicing configuration，
> 並不是 Microsoft 官方發布的「Windows 10 IoT Enterprise LTSC 2021 22H2」。

---

# ⬇️ Download / 下載

目前提供三個 Release。

**建議一般使用者使用最新的 `v0.3.0`。**

| Release | Edition ID | Version | Build | Language | Inbox Apps | Status |
|---|---|---|---|---|---|---|
| **v0.3.0** | **`IoTEnterpriseS`** | `22H2` | `19045.7725` | `zh-TW` | Included | **Current / Recommended** |
| v0.2.0 | `IoTEnterpriseS` | `22H2` | `19045.7725` | `zh-TW` | Included | Previous |
| v0.1.0 | `EnterpriseS` | `22H2` | `19045.7725` | `zh-TW` | Included | Legacy |

---

# 🆕 v0.3.0 — IoTEnterpriseS zh-TW

> **Current / Recommended Release**

[➡️ Download v0.3.0 / 下載 v0.3.0](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/tag/v0.3.0)

## Version Information

| **Item** | **Value** |
|---|---|
| Product | Windows 10 IoT Enterprise LTSC |
| Edition ID | `IoTEnterpriseS` |
| Version | `22H2` |
| OS Build | `19045.7725` |
| Architecture | `x64` |
| Language | `zh-TW` |
| Inbox Apps | Included |
| Release | `v0.3.0` |
| Archive Password | **`7725`** |

## What changed from v0.2.0?

`v0.3.0` is a minor maintenance revision of `v0.2.0`.

主要修正 Windows Setup 的作業系統選擇畫面。

在 `v0.2.0` 中，Windows Setup 的映像選擇畫面曾出現一個空白項目。

`v0.3.0` 已修正此問題，現在 Windows Setup 僅正確顯示：

```text
Windows 10 IoT Enterprise LTSC    x64
```

`v0.3.0` 與 `v0.2.0` 的主要系統組態保持相同：

```text
Edition       : IoTEnterpriseS
Version       : 22H2
OS Build      : 19045.7725
Architecture  : x64
Language      : zh-TW
Inbox Apps    : unchanged
Custom setup  : unchanged
```

因此可將 `v0.3.0` 視為：

```text
v0.2.0
        ↓
Windows Setup image-selection display fix
        ↓
v0.3.0
```

除了 Windows Setup 顯示修正之外，系統版本、Build、Edition、語言、Inbox Apps 與其他主要客製內容均維持不變。

---

## 📥 v0.3.0 Download

Please download all five archive parts.

請下載以下五個分卷，並放在同一個資料夾：

1. [⬇️ Part 1 — `.7z.001`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.001)
2. [⬇️ Part 2 — `.7z.002`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.002)
3. [⬇️ Part 3 — `.7z.003`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.003)
4. [⬇️ Part 4 — `.7z.004`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.004)
5. [⬇️ Part 5 — `.7z.005`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.005)

### 🔐 SHA-256

[⬇️ Download `SHA256.txt`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.3.0/SHA256.txt)

### 🔑 Extract Password / 解壓密碼

```text
7725
```

將所有分卷放在同一個資料夾後，只需要使用 7-Zip 開啟：

```text
zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_customs_v0.3.0.7z.001
```

後續：

```text
.002
.003
.004
.005
```

會由 7-Zip 自動讀取，**不需要逐一解壓**。

PowerShell SHA-256 驗證範例：

```powershell
Get-FileHash ".\filename.7z.001" -Algorithm SHA256
```

計算結果應與 `SHA256.txt` 完全一致。

---

# 📦 v0.2.0 — IoTEnterpriseS zh-TW

> **Previous Release**

[➡️ Download v0.2.0 / 下載 v0.2.0](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/tag/v0.2.0)

## Version Information

| **Item** | **Value** |
|---|---|
| Product | Windows 10 IoT Enterprise LTSC |
| Edition ID | `IoTEnterpriseS` |
| Version | `22H2` |
| OS Build | `19045.7725` |
| Architecture | `x64` |
| Language | `zh-TW` |
| Inbox Apps | Included |
| Release | `v0.2.0` |
| Archive Password | **`7725`** |

## What changed from v0.1.0?

`v0.2.0` is a minor revision of `v0.1.0`.

The operating system version, OS build, architecture, language,
Inbox Apps configuration and other project customizations remain unchanged.

主要差異：

```text
v0.1.0
Edition : EnterpriseS

        ↓

v0.2.0
Edition : IoTEnterpriseS
```

v0.2.0 uses Windows 10 IoT Enterprise LTSC English media as the IoT installation base and integrates the `zh-TW` Traditional Chinese language resources into that base.

因此 v0.2.0 的最終映像為：

```text
Edition           : IoTEnterpriseS
Architecture      : x64
Version           : 10.0.19045
ServicePack Build : 7725
Language          : zh-TW
```

除了 Edition 與建置基底修正之外：

```text
Version       : unchanged
OS Build      : unchanged
Architecture  : unchanged
Language      : unchanged
Inbox Apps    : unchanged
Custom setup  : unchanged
```

因此可以將 `v0.2.0` 視為 `v0.1.0` 的 Edition-corrected maintenance release。

---

## 📥 v0.2.0 Download

Please download all five archive parts.

請下載以下五個分卷，並放在同一個資料夾：

1. [⬇️ Part 1 — `.7z.001`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.001)
2. [⬇️ Part 2 — `.7z.002`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.002)
3. [⬇️ Part 3 — `.7z.003`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.003)
4. [⬇️ Part 4 — `.7z.004`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.004)
5. [⬇️ Part 5 — `.7z.005`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.005)

### 🔐 SHA-256

[⬇️ Download `SHA256.txt`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.2.0/SHA256.txt)

### 🔑 Extract Password / 解壓密碼

```text
7725
```

將所有分卷放在同一個資料夾後，只需要使用 7-Zip 開啟：

```text
zh-tw_windows_10_IoT_enterprise_ltsc_2021_x64_19045.7725_custom_App_v0.2.0.7z.001
```

後續：

```text
.002
.003
.004
.005
```

會由 7-Zip 自動讀取。

PowerShell SHA-256 驗證範例：

```powershell
Get-FileHash ".\filename.7z.001" -Algorithm SHA256
```

計算結果應與 `SHA256.txt` 完全一致。

---

# 📦 v0.1.0 — EnterpriseS zh-TW

> **Legacy / Initial Release**

[➡️ View / Download v0.1.0](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/tag/v0.1.0)

## Version Information

| **Item** | **Value** |
|---|---|
| Product | Windows 10 Enterprise LTSC |
| Edition ID | `EnterpriseS` |
| Version | `22H2` |
| OS Build | `19045.7725` |
| Architecture | `x64` |
| Language | `zh-TW` |
| Inbox Apps | Included |
| Release | `v0.1.0` |
| Archive Password | **`7725`** |

v0.1.0 是本專案第一個公開版本。

Reference configuration：

```text
Edition           : EnterpriseS
Architecture      : x64
Version           : 10.0.19045
ServicePack Build : 7725
Language          : zh-TW
Inbox Apps        : Included
```

主要 Edition 差異：

```text
v0.1.0 : EnterpriseS
v0.2.0 : IoTEnterpriseS
v0.3.0 : IoTEnterpriseS
```

若沒有特別需要保留舊版，建議使用最新：

```text
v0.3.0
```

---

## 📥 v0.1.0 Download

Please download all five archive parts.

請下載以下五個分卷：

1. [⬇️ Part 1 — `.7z.001`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.001)
2. [⬇️ Part 2 — `.7z.002`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.002)
3. [⬇️ Part 3 — `.7z.003`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.003)
4. [⬇️ Part 4 — `.7z.004`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.004)
5. [⬇️ Part 5 — `.7z.005`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/zh-tw_windows_10_enterprise_ltsc_2021_x64_19045.7725_custom_App.7z.005)

### 🔐 SHA-256

[⬇️ Download `SHA256.txt`](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/download/v0.1.0/SHA256.txt)

### 🔑 Extract Password / 解壓密碼

```text
7725
```

---

# 📀 Build Origin / 建置來源

## v0.3.0 / v0.2.0

`v0.2.0` 開始使用：

```text
Windows 10 IoT Enterprise LTSC
English
x64
```

作為 IoT Edition 基底，再整合：

```text
zh-TW
Traditional Chinese
```

語言資源。

之後依本專案 Reference Image 流程進行：

```text
Windows 10 IoT Enterprise LTSC base
        │
        ▼
zh-TW language integration
        │
        ▼
Windows servicing
        │
        ▼
22H2 / Build 19045
        │
        ▼
Service to 19045.7725
        │
        ▼
Inbox Apps provisioning
        │
        ▼
Verification
        │
        ▼
Sysprep / Generalize
        │
        ▼
Windows PE
        │
        ▼
Capture WIM
        │
        ▼
Build ISO
```

最終 Edition：

```text
IoTEnterpriseS
```

`v0.3.0` 延續 `v0.2.0` 的相同系統組態，主要修正 Windows Setup 映像選擇畫面的顯示問題。

---

# ⚠️ LTSC / 22H2 Clarification

Microsoft officially released Windows 10 IoT Enterprise LTSC 2021 as:

```text
Version : 21H2
Build   : 19044
```

This project uses:

```text
Version : 22H2
Build   : 19045.7725
```

Therefore:

> The Build 19045 configuration provided by this project is a custom
> servicing configuration based on the LTSC 2021 platform.

It should **not** be described as an official Microsoft
“Windows 10 IoT Enterprise LTSC 2021 22H2” release.

本專案名稱中的 `22H2` 用於描述實際自訂系統版本，
並不表示 Microsoft 官方曾發布 LTSC 2021 22H2。

---

# 🛍️ Microsoft Inbox Apps

`v0.1.0`、`v0.2.0` 與 `v0.3.0` 使用相同的 Inbox Apps Configuration。

Reference configuration：

```text
Main Inbox Apps            : 14
Framework combinations     : 18
Remaining Store Apps       : 0
```

## Main Apps

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

> [!NOTE]
> Microsoft Store 與以上 Inbox Apps 為本專案額外 Provision 的自訂元件，
> 並非 Microsoft 官方 Windows 10 IoT Enterprise LTSC 2021 的預設 App 組合。

HEVC：

```text
Not pre-provisioned
```

---

# 🧩 Frameworks / Dependencies

Reference Framework configuration：

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

Required architectures：

```text
x64
x86
```

Total：

```text
18 Framework / Architecture combinations
```

---

# 🛠️ PowerShell Tools

Repository scripts：

```text
scripts/
├── Provision-InboxApps.ps1
├── Verify-InboxApps.ps1
└── Verify-Windows-Edition.ps1
```

## Provision-InboxApps.ps1

用途：

```text
18 Framework / Architecture combinations
        +
14 Main Inbox Apps
        ↓
Post-provisioning validation
```

主要功能：

- Full preflight
- Source validation
- License validation
- Framework-first provisioning
- Existing-package detection
- No automatic package downgrade
- No automatic App removal
- Post-install verification
- Transcript logging

Example：

```powershell
powershell.exe -NoProfile -File .\scripts\Provision-InboxApps.ps1 `
    -SourceRoot "G:\" `
    -LogPath "D:\Logs\InboxApps_Provision.log"
```

---

## Verify-InboxApps.ps1

Read-only verification：

```text
Main Apps              : 14
Framework combinations : 18
Remaining Store Apps   : 0
```

Run：

```powershell
powershell.exe -NoProfile -File .\scripts\Verify-InboxApps.ps1
```

Exit codes：

```text
0 = PASS
1 = FAIL
```

---

## Verify-Windows-Edition.ps1

Checks：

```text
Edition
Version
Build
Architecture
Activation
```

Run：

```powershell
powershell.exe -NoProfile -File .\scripts\Verify-Windows-Edition.ps1
```

Expected Edition：

```text
v0.3.0 : IoTEnterpriseS
v0.2.0 : IoTEnterpriseS
v0.1.0 : EnterpriseS
```

---

# 📚 Documentation

Detailed documentation：

- [Build Guide](docs/BUILD.md)
- [Edition and Licensing](docs/EDITION.md)
- [Microsoft Inbox Apps](docs/INBOX-APPS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

# 🔍 Verification

## Windows Edition

```cmd
dism /online /Get-CurrentEdition
```

v0.3.0 / v0.2.0：

```text
Current Edition : IoTEnterpriseS
```

v0.1.0：

```text
Current Edition : EnterpriseS
```

---

## Windows Version

```cmd
winver
```

Reference：

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

Edition 與 Activation 是不同概念：

```text
Edition ≠ Activation
```

---

## WIM Metadata

```cmd
dism /Get-ImageInfo /ImageFile:install.wim /Index:1
```

v0.3.0 / v0.2.0 Reference：

```text
Architecture        : x64
Version             : 10.0.19045
ServicePack Build   : 7725
Edition             : IoTEnterpriseS
Installation        : Client
Product Type        : WinNT
System Root         : WINDOWS
Language            : zh-TW
```

---

# 📁 Repository Structure

```text
.
├── README.md
├── LICENSE
│
├── docs/
│   ├── BUILD.md
│   ├── EDITION.md
│   ├── INBOX-APPS.md
│   └── TROUBLESHOOTING.md
│
└── scripts/
    ├── Provision-InboxApps.ps1
    ├── Verify-InboxApps.ps1
    └── Verify-Windows-Edition.ps1
```

---

# 📌 Release History

## v0.3.0 — Setup Display Fix

Current / Recommended release.

```text
Edition           : IoTEnterpriseS
Version           : 22H2
OS Build          : 19045.7725
Architecture      : x64
Language          : zh-TW
Inbox Apps        : Included
```

Changes from v0.2.0：

- Fixed the empty entry in the Windows Setup operating-system selection screen
- Windows Setup now correctly displays `Windows 10 IoT Enterprise LTSC`
- Retained `IoTEnterpriseS`
- Retained Version `22H2`
- Retained Build `19045.7725`
- Retained `x64`
- Retained `zh-TW`
- Retained the same Inbox Apps configuration
- Retained the same reference-image customization

---

## v0.2.0 — IoTEnterpriseS zh-TW

Edition-corrected maintenance release.

```text
Edition           : IoTEnterpriseS
Version           : 22H2
OS Build          : 19045.7725
Architecture      : x64
Language          : zh-TW
Inbox Apps        : Included
```

Changes from v0.1.0：

- Changed the reference Edition from `EnterpriseS` to `IoTEnterpriseS`
- Rebuilt using a Windows 10 IoT Enterprise LTSC base
- Integrated `zh-TW` Traditional Chinese language resources
- Retained the same OS Build
- Retained the same Inbox Apps configuration
- Retained the same project customization

---

## v0.1.0 — EnterpriseS zh-TW

Initial public release.

```text
Edition           : EnterpriseS
Version           : 22H2
OS Build          : 19045.7725
Architecture      : x64
Language          : zh-TW
Inbox Apps        : Included
```

---

# ⚖️ Licensing / Distribution Notice

Windows, Windows IoT Enterprise, Microsoft Store and related Microsoft
software remain subject to Microsoft's applicable license terms.

The MIT License included in this repository applies only to original
repository content authored for this project, including:

```text
PowerShell scripts
Documentation
Project configuration examples
Original project text
```

It does not relicense:

```text
Windows binaries
Microsoft application packages
Microsoft license files
Microsoft trademarks
```

Users are responsible for ensuring that their use, licensing,
deployment and redistribution of Microsoft software comply with the
applicable Microsoft license terms.

This project is:

```text
not affiliated with Microsoft Corporation
not sponsored by Microsoft Corporation
not endorsed by Microsoft Corporation
not an official Microsoft Windows release
```

No activation bypass or crack is provided.

---

# 🔒 Security / Integrity

Before using a downloaded release：

1. Download all five archive volumes.
2. Place all archive volumes in the same directory.
3. Download the corresponding `SHA256.txt`.
4. Verify each downloaded archive using SHA-256.
5. Open `.7z.001` using 7-Zip.
6. Enter archive password `7725`.
7. Test the resulting ISO in an isolated VM before production use.

---

# 📌 Project Status

```text
Current Release  : v0.3.0
Current Edition  : IoTEnterpriseS

Previous Release : v0.2.0
Previous Edition : IoTEnterpriseS

Legacy Release   : v0.1.0
Legacy Edition   : EnterpriseS

Version          : 22H2
OS Build         : 19045.7725
Architecture     : x64
Language         : zh-TW
Inbox Apps       : Included
```

**Recommended release: `v0.3.0`**

[➡️ Open v0.3.0 Release](https://github.com/hom-line/Windows-10-IoT-Enterprise-LTSC-2021-22H2-zh-TW-Custom/releases/tag/v0.3.0)
