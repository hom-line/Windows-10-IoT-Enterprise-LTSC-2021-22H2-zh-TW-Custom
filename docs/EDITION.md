# Edition and Licensing / Edition 與授權說明

This document explains the Windows Edition model used by this project.

本文件說明本專案中 Windows 10 Enterprise LTSC 與 Windows 10 IoT Enterprise LTSC 的 Edition、授權轉換與啟用邏輯。

---

# 中文

## 1. 基本概念

本專案需要區分三個不同概念：

```text
Windows Edition
Edition Conversion
Windows Activation
```

它們彼此相關，但不是同一件事。

---

## 2. EnterpriseS

本專案使用 Windows 10 Enterprise LTSC 2021 安裝媒體作為部署基底。

其 Edition ID 為：

```text
EnterpriseS
```

可以使用：

```cmd
dism /online /Get-CurrentEdition
```

確認。

典型結果：

```text
Current Edition : EnterpriseS
```

此時 Windows 通常顯示為：

```text
Windows 10 Enterprise LTSC
```

---

## 3. IoTEnterpriseS

Windows 10 IoT Enterprise LTSC 對應的 Edition ID 為：

```text
IoTEnterpriseS
```

當系統完成合法且適用的 IoT Enterprise LTSC Edition Conversion 後：

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

## 4. Edition Conversion

本專案採用的邏輯為：

```text
Windows 10 Enterprise LTSC
EnterpriseS
        │
        │ Valid IoT Enterprise LTSC licensing
        ▼
Windows 10 IoT Enterprise LTSC
IoTEnterpriseS
```

因此：

```text
EnterpriseS
```

是部署基底 Edition，

而：

```text
IoTEnterpriseS
```

是完成合法 IoT Edition Conversion 後的目標 Edition。

---

## 5. Activation 與 Edition 不相同

Edition Conversion 與 Windows Activation 不應混為一談。

例如：

```text
IoTEnterpriseS
+ Not Activated
```

仍然可以是 Windows 10 IoT Enterprise LTSC。

而：

```text
EnterpriseS
+ Activated
```

仍然是 Windows 10 Enterprise LTSC。

因此判斷 Windows Edition 時，不應只依賴 Activation 狀態。

---

## 6. 如何確認 Edition

最重要的確認方式：

```cmd
dism /online /Get-CurrentEdition
```

若顯示：

```text
Current Edition : EnterpriseS
```

表示目前 Edition 為：

```text
Windows 10 Enterprise LTSC
```

若顯示：

```text
Current Edition : IoTEnterpriseS
```

表示目前 Edition 為：

```text
Windows 10 IoT Enterprise LTSC
```

---

## 7. 如何確認 Activation

Activation 狀態可另外使用：

```cmd
slmgr /xpr
```

或：

```cmd
slmgr /dli
```

確認。

因此建議分別檢查：

```text
Edition:
DISM

Activation:
SLMGR
```

---

## 8. Winver 不應作為唯一判斷依據

可以使用：

```cmd
winver
```

查看：

```text
Windows edition name
Version
OS Build
```

但若要確認真正的 Edition ID，建議仍以：

```cmd
dism /online /Get-CurrentEdition
```

為主要依據。

---

## 9. WIM Name 不等於 Windows Edition

在擷取 WIM 時，例如：

```cmd
dism /Capture-Image ^
 /ImageFile:D:\install.wim ^
 /CaptureDir:C:\ ^
 /Name:"Windows 10 IoT Enterprise LTSC"
```

其中：

```text
/Name
```

只是 WIM 映像的顯示名稱。

它不會將：

```text
EnterpriseS
```

自動轉換成：

```text
IoTEnterpriseS
```

因此不能只看：

```text
Name: Windows 10 IoT Enterprise LTSC
```

就判斷映像真正的 Edition。

真正的 Edition 應使用：

```cmd
dism /Get-ImageInfo /ImageFile:install.wim /Index:1
```

確認。

---

## 10. Offline WIM Edition 測試

本專案曾進行以下測試：

原始 WIM：

```text
Edition : EnterpriseS
```

將 WIM Mount 後：

```cmd
dism /Image:D:\WIM_MOUNT /Get-CurrentEdition
```

確認：

```text
EnterpriseS
```

並使用 DISM 離線轉換：

```text
EnterpriseS
        ↓
IoTEnterpriseS
```

完成後：

```cmd
dism /Get-ImageInfo /ImageFile:install.wim /Index:1
```

可以確認：

```text
Edition : IoTEnterpriseS
```

代表 Offline WIM metadata / Edition conversion 本身成功。

---

## 11. Offline Conversion 的 Setup 問題

雖然 Offline WIM 已成功顯示：

```text
IoTEnterpriseS
```

但將其放回原始 Enterprise LTSC Setup media 後，實際安裝測試出現：

```text
The product key entered does not match any of the Windows images
available for installation.
```

中文：

```text
您輸入的產品金鑰不符合任何可用來安裝的 Windows 映像。
```

因此可確認：

```text
Offline Edition Conversion succeeded
```

並不代表：

```text
Original Windows Setup media
```

一定能直接安裝轉換後的映像。

---

## 12. 本專案採用的標準方式

因此本專案不使用：

```text
Force offline EnterpriseS
        ↓
IoTEnterpriseS
        ↓
Direct Setup installation
```

作為正式標準流程。

目前採用：

```text
EnterpriseS-compatible installation media
        ↓
Install Windows
        ↓
Valid IoT Enterprise LTSC licensing
        ↓
Edition Conversion
        ↓
IoTEnterpriseS
```

這種方式更符合本專案原始媒體與實際測試結果。

---

## 13. 判斷表

| 狀態 | DISM Edition | Windows 類型 |
|---|---|---|
| Base installation | `EnterpriseS` | Windows 10 Enterprise LTSC |
| After valid IoT Edition Conversion | `IoTEnterpriseS` | Windows 10 IoT Enterprise LTSC |
| `EnterpriseS` + Activated | `EnterpriseS` | Windows 10 Enterprise LTSC |
| `IoTEnterpriseS` + Not Activated | `IoTEnterpriseS` | Windows 10 IoT Enterprise LTSC |
| WIM Name says IoT but Edition is EnterpriseS | `EnterpriseS` | Still Enterprise LTSC Edition |

---

# English

## 1. Overview

This project distinguishes between:

```text
Windows Edition
Edition Conversion
Windows Activation
```

These concepts are related but are not identical.

---

## 2. EnterpriseS

The deployment base used by this project is Windows 10 Enterprise LTSC 2021.

Its Edition ID is:

```text
EnterpriseS
```

Verify with:

```cmd
dism /online /Get-CurrentEdition
```

Expected result:

```text
Current Edition : EnterpriseS
```

Windows identifies this as:

```text
Windows 10 Enterprise LTSC
```

---

## 3. IoTEnterpriseS

Windows 10 IoT Enterprise LTSC uses:

```text
IoTEnterpriseS
```

After a valid and applicable IoT Enterprise LTSC Edition Conversion:

```cmd
dism /online /Get-CurrentEdition
```

should report:

```text
Current Edition : IoTEnterpriseS
```

Windows then identifies itself as:

```text
Windows 10 IoT Enterprise LTSC
```

---

## 4. Edition Conversion model

The model used by this project is:

```text
Windows 10 Enterprise LTSC
EnterpriseS
        │
        │ Valid IoT Enterprise LTSC licensing
        ▼
Windows 10 IoT Enterprise LTSC
IoTEnterpriseS
```

---

## 5. Edition and Activation are different

Edition Conversion and Activation must not be treated as the same operation.

For example:

```text
IoTEnterpriseS
+ Not Activated
```

can still be Windows 10 IoT Enterprise LTSC.

Likewise:

```text
EnterpriseS
+ Activated
```

is still Windows 10 Enterprise LTSC.

---

## 6. Verify the Edition

Use:

```cmd
dism /online /Get-CurrentEdition
```

Result:

```text
EnterpriseS
```

means Windows 10 Enterprise LTSC.

Result:

```text
IoTEnterpriseS
```

means Windows 10 IoT Enterprise LTSC.

---

## 7. Verify Activation

Use:

```cmd
slmgr /xpr
```

or:

```cmd
slmgr /dli
```

Edition and Activation should therefore be validated separately.

---

## 8. WIM Name is not the Edition

A captured WIM may use:

```cmd
/Name:"Windows 10 IoT Enterprise LTSC"
```

This only controls the image display name.

It does not automatically transform:

```text
EnterpriseS
```

into:

```text
IoTEnterpriseS
```

Always verify with:

```cmd
dism /Get-ImageInfo /ImageFile:install.wim /Index:1
```

---

## 9. Offline Edition Conversion test

This project experimentally converted an offline WIM from:

```text
EnterpriseS
```

to:

```text
IoTEnterpriseS
```

DISM confirmed that the WIM Edition had successfully changed.

However, this did not guarantee compatibility with the original Windows Setup media.

---

## 10. Windows Setup result

When the converted `IoTEnterpriseS` WIM was inserted into the original Enterprise LTSC Setup media, Windows Setup displayed:

```text
The product key entered does not match any of the Windows images
available for installation.
```

This demonstrates that successful offline Edition conversion does not automatically mean the original Setup media can directly install the converted image.

---

## 11. Standard project approach

For this reason, this project uses:

```text
EnterpriseS-compatible Setup media
        ↓
Install Windows
        ↓
Apply valid IoT Enterprise LTSC licensing
        ↓
Edition Conversion
        ↓
IoTEnterpriseS
```

instead of forced offline Edition modification as the standard deployment method.

---

## 12. Quick reference

| State | DISM Edition | Windows Edition |
|---|---|---|
| Base installation | `EnterpriseS` | Windows 10 Enterprise LTSC |
| Valid IoT conversion complete | `IoTEnterpriseS` | Windows 10 IoT Enterprise LTSC |
| EnterpriseS + Activated | `EnterpriseS` | Windows 10 Enterprise LTSC |
| IoTEnterpriseS + Not Activated | `IoTEnterpriseS` | Windows 10 IoT Enterprise LTSC |
| WIM named IoT but Edition is EnterpriseS | `EnterpriseS` | Enterprise LTSC Edition |

---

# Related Documentation

- [Project README](../README.md)
- [Build Guide](BUILD.md)
- [Inbox Apps](INBOX-APPS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
