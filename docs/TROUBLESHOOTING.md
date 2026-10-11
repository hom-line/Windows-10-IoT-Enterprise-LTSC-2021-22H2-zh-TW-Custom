# Troubleshooting / 疑難排解

This document records problems encountered and verified during the development of this project.

本文件整理本專案實際建置 Windows 10 LTSC Reference Image 時遇到的問題、判斷方式與處理方法。

---

# 1. Windows Setup Cannot Display Available Images
# Windows 安裝程式無法顯示可用映像

## Symptom / 症狀

Windows Setup starts normally, but installation cannot continue and reports that no usable Windows image can be displayed.

可能出現：

```text
Windows cannot display the images available for installation.
```

或中文類似：

```text
Windows 無法顯示可用來安裝的映像。
```

---

## Diagnosis / 判斷

Boot into Windows PE and inspect the WIM:

```cmd
dism /Get-ImageInfo /ImageFile:<path-to-install.wim> /Index:1
```

A healthy image should contain information such as:

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

A problematic image may instead contain several values such as:

```text
Edition      : <undefined>
Installation : <undefined>
Product Type : <undefined>
Language     : <undefined>
```

---

## Resolution / 解決方式

Do not treat a WIM with incomplete core metadata as a validated installation image.

重新從正常且已完成 Sysprep 的 Reference System 使用 WinPE Capture。

Example:

```cmd
dism /Capture-Image ^
 /ImageFile:D:\Win10_Custom.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 LTSC 2021 Custom 22H2" ^
 /Description:"Windows 10 LTSC 2021 custom reference image" ^
 /Compress:max ^
 /Verify ^
 /ScratchDir:D:\DismScratch
```

Then verify again:

```cmd
dism /Get-ImageInfo /ImageFile:D:\Win10_Custom.wim /Index:1
```

---

# 2. WIM Name Says IoT but Edition Is EnterpriseS
# WIM 名稱為 IoT，但 Edition 是 EnterpriseS

## Symptom / 症狀

DISM may report:

```text
Name    : Windows 10 IoT Enterprise LTSC
Edition : EnterpriseS
```

This can appear confusing.

---

## Explanation / 說明

The WIM:

```text
Name
```

and the Windows:

```text
Edition
```

are different properties.

For example:

```cmd
/Name:"Windows 10 IoT Enterprise LTSC"
```

only changes the WIM display label.

It does **not** convert:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

---

## Correct Verification / 正確確認方式

For an offline WIM:

```cmd
dism /Get-ImageInfo /ImageFile:install.wim /Index:1
```

For a running Windows installation:

```cmd
dism /online /Get-CurrentEdition
```

Use the actual Edition ID as the authoritative result.

---

# 3. EnterpriseS vs IoTEnterpriseS

The two important Edition IDs used by this project are:

```text
EnterpriseS
```

Windows 10 Enterprise LTSC

and:

```text
IoTEnterpriseS
```

Windows 10 IoT Enterprise LTSC.

The project deployment model is:

```text
EnterpriseS
        │
        │ Valid IoT Enterprise LTSC licensing
        ▼
IoTEnterpriseS
```

Activation and Edition should be checked separately.

Edition:

```cmd
dism /online /Get-CurrentEdition
```

Activation:

```cmd
slmgr /xpr
```

---

# 4. Offline IoTEnterpriseS Conversion Causes Setup Product-Key Error
# 離線轉換 IoTEnterpriseS 後 Setup 出現產品金鑰錯誤

## Test Result / 實測結果

The project tested changing an offline WIM from:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

DISM successfully reported:

```text
Edition : IoTEnterpriseS
```

However, after replacing the original Setup image with this converted WIM, Windows Setup displayed:

```text
The product key entered does not match any of the Windows images
available for installation.
```

Chinese:

```text
您輸入的產品金鑰不符合任何可用來安裝的 Windows 映像。
```

---

## Project Decision / 本專案處理方式

The project therefore does not use forced offline:

```text
EnterpriseS
→ IoTEnterpriseS
```

conversion as the standard installation-media workflow.

Instead:

```text
EnterpriseS-compatible Setup media
        ↓
Install Windows
        ↓
Apply valid IoT Enterprise LTSC licensing
        ↓
IoTEnterpriseS
```

is used when the IoT Edition conversion is required.

---

# 5. Sysprep Error 0x80073cf2
# Sysprep Appx 錯誤 0x80073cf2

## Typical Cause / 常見原因

A Microsoft Store / Appx package may be installed for one user but not provisioned for all future users.

This creates an inconsistent Appx state that Sysprep may reject.

---

## Verification / 驗證

Check installed packages:

```powershell
Get-AppxPackage -AllUsers |
    Select-Object Name,Version,PackageUserInformation |
    Sort-Object Name
```

Check provisioned packages:

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName,Version |
    Sort-Object DisplayName
```

The project also uses:

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

Successful reference-image result:

```text
Remaining count = 0
```

---

# 6. Inbox Apps Package Path Is Wrong
# Inbox Apps 路徑錯誤

## Symptom / 症狀

PowerShell reports that package folders or files do not exist even though the media is mounted.

Example situation:

```text
Actual Inbox Apps media : G:
Script variable         : F:
```

The script therefore searches the wrong drive.

---

## Resolution / 解決方式

Verify the mounted media first:

```powershell
Test-Path "G:\amd64fre"
Test-Path "G:\x86fre"
```

Expected:

```text
True
True
```

Then make sure all script variables use the correct drive.

Example:

```powershell
$AMD64 = "G:\amd64fre"
$X86   = "G:\x86fre"
```

Drive letters are not guaranteed to remain identical between systems or boot environments.

---

# 7. PowerShell Parser Errors While Pasting a Script
# PowerShell 貼上腳本出現 Parser Error

## Symptom / 症狀

Errors may include:

```text
Missing expression
Missing ')'
Unexpected token
else is not recognized
```

This can happen when a multi-line PowerShell block is pasted into the interactive console in incomplete sections.

For example, an isolated:

```powershell
else {
```

cannot be interpreted correctly without its corresponding preceding block.

---

## Resolution / 解決方式

Prefer one of the following:

```text
Paste the complete block at once
```

or save the script as:

```text
.ps1
```

and run it as a complete PowerShell script.

Do not judge the earlier provisioning operations as failed solely because a later display or verification block produced a parser error.

Always verify the actual provisioning log and package state.

---

# 8. Sysprep Window Appears Automatically in Audit Mode
# Audit Mode 每次開機都出現 Sysprep

This is expected behavior.

In Audit Mode, Windows may automatically open:

```text
System Preparation Tool
```

after login.

If image preparation is not complete:

```text
Close / Cancel the Sysprep window
```

and continue servicing.

Restart normally with:

```cmd
shutdown /r /t 0
```

Run the final Sysprep only after all servicing and provisioning work is complete.

---

# 9. Do Not Boot Windows after Final Sysprep
# 最終 Sysprep 後不要再次進入 Windows

Final command:

```powershell
& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
```

After Windows shuts down:

```text
DO NOT BOOT THE INSTALLED WINDOWS SYSTEM AGAIN
```

Boot directly into WinPE and capture the partition.

Correct workflow:

```text
Sysprep
        ↓
Automatic shutdown
        ↓
WinPE
        ↓
Capture WIM
```

Incorrect workflow:

```text
Sysprep
        ↓
Shutdown
        ↓
Boot Windows again
        ↓
Capture later
```

The second workflow can alter the generalized reference-image state.

---

# 10. Normal User Account Accidentally Created
# 不小心建立一般 USER 帳號

A clean reference image should preferably be prepared entirely in Audit Mode.

The intended reference-image account is the built-in:

```text
Administrator
```

A normal end-user account should not be required before capture.

The preferred solution is:

```text
OOBE
→ Ctrl + Shift + F3
→ Audit Mode
```

before creating any normal user.

Avoid manually deleting only:

```text
C:\Users\<username>
```

because a Windows account also has:

```text
SAM account information
Profile registry information
User profile metadata
```

Removing only the directory does not fully remove the account.

---

# 11. WinPE Drive Letters Are Different
# WinPE 磁碟代號不同

A common mistake is assuming:

```text
C:
```

always contains Windows.

In WinPE this is not guaranteed.

Always verify:

```cmd
dir C:\Windows
dir D:\Windows
dir E:\Windows
```

before using commands such as:

```cmd
dism /Image:
```

or:

```cmd
dism /Capture-Image
```

Likewise, verify the capture destination before writing a large WIM.

---

# 12. DISM Error 87 During Capture
# DISM Capture Error 87

Older WinPE / DISM versions may not accept every optional parameter used by a newer DISM version.

If a capture command reports:

```text
Error: 87
The parameter is incorrect.
```

first check DISM help:

```cmd
dism /Capture-Image /?
```

If an optional switch is unsupported by that WinPE version, remove only the unsupported option.

For example, if necessary:

```text
/CheckIntegrity
```

may be omitted while retaining:

```text
/Verify
/Compress:max
```

Do not change the actual Windows capture partition unless it has been independently verified.

---

# 13. 21H2 Did Not Change to 22H2
# 21H2 升級後仍不是 22H2

The project-specific process is:

```text
Fully service 21H2
        ↓
Shutdown
        ↓
Boot WinPE
        ↓
Apply 22H2 Enablement Package offline
        ↓
Shutdown WinPE
        ↓
Boot Windows
        ↓
Check winver
```

After booting Windows:

```cmd
winver
```

should report:

```text
Version 22H2
```

and the build family should become:

```text
19045.x
```

If it still reports:

```text
21H2 / 19044.x
```

check that:

```text
The correct x64 Enablement Package was used
The package was applied to the correct offline Windows partition
DISM completed successfully
The prerequisite servicing level was present
```

> [!IMPORTANT]
> This is a project-specific customization.
>
> Windows 10 IoT Enterprise LTSC 2021 was officially released as
> version 21H2 / Build 19044.
>
> The resulting 22H2 / 19045 state must not be described as an
> official Microsoft LTSC 22H2 release.

---

# 14. Build Is 19045 but Not 19045.7725
# 已是 22H2，但 Build 尚未到 19045.7725

The 22H2 Enablement Package changes the build family to:

```text
19045
```

It does not by itself guarantee the final project revision:

```text
19045.7725
```

After 22H2 is confirmed, additional applicable cumulative servicing is required to reach the project's target build.

Verify with:

```cmd
winver
```

Expected project build:

```text
19045.7725
```

---

# 15. Setup Works but Installed Windows Shows Enterprise LTSC
# 安裝成功但顯示 Enterprise LTSC

Run:

```cmd
dism /online /Get-CurrentEdition
```

If the result is:

```text
Current Edition : EnterpriseS
```

then the installed system is currently Windows 10 Enterprise LTSC.

This is independent of the WIM display name.

After a valid and applicable IoT Enterprise LTSC licensing conversion, the result should be:

```text
Current Edition : IoTEnterpriseS
```

Only then is the active Windows Edition the IoT Enterprise LTSC Edition.

---

# 16. Activation Does Not Determine Edition
# 是否啟用不能單獨判斷 Edition

Do not assume:

```text
Not activated = EnterpriseS
Activated     = IoTEnterpriseS
```

This is incorrect.

Possible states include:

```text
EnterpriseS
Activated
```

and:

```text
IoTEnterpriseS
Not Activated
```

Edition:

```cmd
dism /online /Get-CurrentEdition
```

Activation:

```cmd
slmgr /xpr
```

These must be checked separately.

---

# 17. HEVC Is Missing
# 沒有 HEVC

The Microsoft Inbox Apps source used by this project did not contain an HEVC package.

Therefore HEVC was intentionally not provisioned into the reference image.

This should not be interpreted as a failed provisioning operation.

The successfully provisioned media extensions include:

```text
AV1
VP9
HEIF
WebP
Web Media
MPEG-2
```

HEVC must be obtained separately through an appropriately licensed Microsoft distribution channel if required.

---

# 18. Final Validation Commands
# 最終驗證指令

## Running Windows

Edition:

```cmd
dism /online /Get-CurrentEdition
```

Version:

```cmd
winver
```

Activation:

```cmd
slmgr /xpr
```

Provisioned Apps:

```powershell
Get-AppxProvisionedPackage -Online |
    Select-Object DisplayName,Version,Architecture |
    Sort-Object DisplayName
```

---

## Captured WIM

```cmd
dism /Get-ImageInfo /ImageFile:<path-to-wim> /Index:1
```

Expected project characteristics:

```text
Architecture        : x64
Version             : 10.0.19045
ServicePack Build   : 7725
Installation        : Client
Product Type        : WinNT
Language            : zh-TW
```

The actual Edition must be interpreted separately according to the image's licensing state.

---

# 19. Recommended Troubleshooting Order
# 建議故障排除順序

When a build fails, verify in this order:

```text
1. Correct Windows / package drive letters
        ↓
2. Windows Edition
        ↓
3. Windows version and build
        ↓
4. WIM metadata
        ↓
5. Provisioned App state
        ↓
6. Sysprep logs
        ↓
7. Windows Setup compatibility
        ↓
8. Clean VM installation
        ↓
9. Final Edition and activation
```

Avoid changing several parts of the image simultaneously.

Change one variable, test again, and record the result.

---

# 20. Useful Logs
# 常用 Log

For Sysprep problems:

```text
C:\Windows\System32\Sysprep\Panther\setupact.log
C:\Windows\System32\Sysprep\Panther\setuperr.log
```

For DISM servicing:

```text
C:\Windows\Logs\DISM\dism.log
```

For Windows servicing:

```text
C:\Windows\Logs\CBS\CBS.log
```

These logs should be checked before rebuilding an image from the beginning.

---

# Related Documentation / 相關文件

- [Project README](../README.md)
- [Build Guide](BUILD.md)
- [Edition and Licensing](EDITION.md)
- [Microsoft Inbox Apps](INBOX-APPS.md)
