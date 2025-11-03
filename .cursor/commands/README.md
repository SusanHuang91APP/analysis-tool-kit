# Cursor Claude 指令 (Commands)

這個目錄包含 Analysis Tool Kit V2 的 Cursor Claude AI 指令 Prompt。

## 📁 指令清單

### 核心指令（3 個）

1. **`/analysis.init`** - 初始化 Topic 環境
2. **`/analysis.create`** - 建立分析檔案
3. **`/analysis.analyze`** - 深度分析更新

---

## 🚀 使用流程

### Step 1: 初始化新的分析主題

```
/analysis.init 會員管理功能
```

**結果：**
- ✅ 建立分支 `analysis/001-會員管理功能`
- ✅ 建立 Topic 目錄和基礎結構
- ✅ 建立 `server.md`, `client.md`, `overview.md`
- ✅ 建立 `features/`, `apis/` 目錄
- ✅ 首次執行會建立 `analysis/shared/` 結構

---

### Step 2: 建立分析檔案

#### 建立 Topic 功能分析

```
/analysis.create feature Controllers/MemberController.cs Services/MemberService.cs
```

**結果：**
- ✅ 建立 `features/001-<name>.md`
- ✅ 進行初始分析 (First Pass)
- ✅ 註冊到 `overview.md`
- ✅ 品質等級：📝 待分析 或 ⭐ 基礎框架

#### 建立 API 分析

```
/analysis.create api Routes/api/members.ts
```

#### 建立 Shared 元件分析

```
/analysis.create component Components/LoginForm.tsx
```

---

### Step 3: 深度分析與品質提升

```
/analysis.analyze "features/001-會員註冊" \
  Controllers/MemberController.cs \
  Services/MemberService.cs \
  Views/Member/Register.cshtml
```

**結果：**
- ✅ 深度分析原始碼
- ✅ 填充 `[待補充]` 佔位符
- ✅ 繪製 Mermaid 圖表
- ✅ 更新品質檢查清單
- ✅ 計算品質等級
- ✅ 同步更新 `overview.md`
- ✅ 品質等級提升：📝 → ⭐⭐⭐ → ⭐⭐⭐⭐⭐

---

## 📊 完整工作流程

```mermaid
graph LR
    A[/analysis.init] --> B[/analysis.create]
    B --> C[/analysis.analyze]
    C --> D{品質達標?}
    D -->|否| C
    D -->|是| E[完成]
    B -->|建立更多檔案| B
    
    style A fill:#e1f5ff
    style B fill:#fff3e0
    style C fill:#f3e5f5
    style E fill:#e8f5e9
```

---

## 🎯 指令詳細說明

### `/analysis.init`

**用途：** 初始化一個新的分析主題 (Topic)

**語法：** `/analysis.init <topic_name>`

**參數：**
- `topic_name` (必需) - 主題名稱，建議使用中文

**範例：**
```
/analysis.init 會員管理功能
/analysis.init 訂單處理系統
/analysis.init 支付流程
```

**產出：**
- Git 分支：`analysis/[###]-<topic_name>`
- Topic 目錄：`analysis/[###]-<topic_name>/`
- 檔案：`overview.md`, `server.md`, `client.md`
- 目錄：`features/`, `apis/`

---

### `/analysis.create`

**用途：** 建立新的分析檔案（Topic 或 Shared）

**語法：** `/analysis.create <type> [source-files...]`

**參數：**
- `type` (必需) - 分析類型
- `source-files...` (可選) - 原始碼檔案

**支援類型：**

**Topic 類型：**
- `server` - 後端頁面渲染邏輯
- `client` - 前端頁面驅動邏輯
- `feature` - 重點功能分析
- `api` - API Endpoint 規格

**Shared 類型：**
- `request-pipeline` - Filter/Middleware
- `component` - 共用 UI 元件
- `helper` - 共用輔助函式

**範例：**
```
# Topic 功能分析
/analysis.create feature Controllers/MemberController.cs

# Topic API 分析
/analysis.create api Routes/api/members.ts

# Shared 元件分析
/analysis.create component Components/LoginForm.tsx

# Shared 輔助函式
/analysis.create helper Utils/DateHelper.ts

# 建立空白檔案（稍後分析）
/analysis.create feature
```

**產出：**
- 新檔案：`[###]-<name>.md`
- 自動註冊到 `overview.md`
- 初始品質：📝 待分析 或 ⭐ 基礎框架

---

### `/analysis.analyze`

**用途：** 深度分析並更新現有檔案，提升品質等級

**語法：** `/analysis.analyze <target_file> [source-files...]`

**參數：**
- `target_file` (必需) - 要更新的檔案名稱
- `source-files...` (建議提供) - 原始碼檔案

**範例：**
```
# 完整分析功能
/analysis.analyze "features/001-會員註冊" \
  Controllers/MemberController.cs \
  Services/MemberService.cs \
  Views/Member/Register.cshtml

# 更新 API 分析
/analysis.analyze "apis/001-登入API" \
  Routes/api/auth.ts

# 更新 server.md
/analysis.analyze "server.md" \
  Controllers/HomeController.cs

# 優化現有分析（不提供新原始碼）
/analysis.analyze "features/002-訂單處理"
```

**產出：**
- 填充 `[待補充]` 區塊
- 繪製 Mermaid 圖表
- 更新品質檢查清單
- 品質等級提升
- 同步 `overview.md`

---

## 📈 品質等級系統

| 等級 | 標記 | 完成度 | 說明 |
|------|------|--------|------|
| 📝 待分析 | `📝 待分析` | 0% | 檔案已建立，無實質內容 |
| ⭐ 基礎框架 | `⭐ 基礎框架` | 1-40% | 基本結構和佔位符 |
| ⭐⭐⭐ 邏輯完成 | `⭐⭐⭐ 邏輯完成` | 41-70% | 主要業務邏輯已分析 |
| ⭐⭐⭐⭐ 架構完整 | `⭐⭐⭐⭐ 架構完整` | 71-90% | 所有依賴注入已分析 |
| ⭐⭐⭐⭐⭐ 完整分析 | `⭐⭐⭐⭐⭐ 完整分析` | 91-100% | 所有章節完成含圖表 |

---

## 🎨 分析策略

### 策略 1: 循序漸進

```
# 第一次：UI 層分析
/analysis.analyze "features/001-會員註冊" Views/Member/Register.cshtml
→ 達到 ⭐⭐⭐ (UI 層完成)

# 第二次：邏輯層分析
/analysis.analyze "features/001-會員註冊" Controllers/MemberController.cs
→ 達到 ⭐⭐⭐⭐ (邏輯層完成)

# 第三次：架構層分析
/analysis.analyze "features/001-會員註冊" Services/MemberService.cs
→ 達到 ⭐⭐⭐⭐⭐ (架構完整)
```

### 策略 2: 一次性完整分析

```
# 提供所有相關檔案，一次完成
/analysis.analyze "features/001-會員註冊" \
  Views/Member/Register.cshtml \
  Controllers/MemberController.cs \
  Services/MemberService.cs
→ 直接達到 ⭐⭐⭐⭐⭐
```

---

## 📝 使用技巧

### 1. 檔案命名

指令會自動推導檔案名稱，但你也可以在原始碼分析後建議更好的名稱：

```
# 腳本會從 MemberController.cs 推導出 "member"
/analysis.create feature Controllers/MemberController.cs
→ 建立 features/001-member.md

# AI 可以建議更好的中文名稱
→ 實際建立 features/001-會員註冊.md
```

### 2. 批次建立

可以多次執行 `/analysis.create` 建立多個檔案：

```
/analysis.create feature Controllers/MemberController.cs
/analysis.create feature Controllers/OrderController.cs
/analysis.create feature Controllers/PaymentController.cs
/analysis.create api Routes/api/members.ts
/analysis.create api Routes/api/orders.ts
```

### 3. 依賴追蹤

分析時會自動追蹤依賴項，建議按依賴順序建立：

```
# 先分析底層服務
/analysis.create helper Utils/DateHelper.ts
/analysis.analyze "helpers/001-date-helper" Utils/DateHelper.ts

# 再分析使用該服務的元件
/analysis.create component Components/DatePicker.tsx
/analysis.analyze "components/001-date-picker" Components/DatePicker.tsx
```

### 4. 查看環境狀態

使用腳本查看當前分析環境：

```bash
./.analysis-kit/scripts/analysis-paths.sh
```

---

## ⚠️ 常見問題

**Q: 執行指令時出現「不在 analysis 分支」錯誤？**  
A: 先執行 `/analysis.init <topic_name>` 初始化環境

**Q: server.md 或 client.md 已存在？**  
A: 這些檔案在 init 時已建立，使用 `/analysis.analyze` 更新它們

**Q: 如何建立 Shared 類型的分析？**  
A: 使用 `request-pipeline`, `component`, `helper` 類型

**Q: 品質等級如何計算？**  
A: 基於檔案末尾的品質檢查清單，計算已勾選項目的百分比

**Q: 如何提升品質等級？**  
A: 多次執行 `/analysis.analyze` 提供更多原始碼或優化現有內容

---

## 📚 指令設計原則

1. **腳本優先：** 環境驗證和檔案操作由腳本執行
2. **AI 專注分析：** AI 專注於程式碼理解和內容生成
3. **自動追蹤：** overview.md 自動更新，保持同步
4. **品質驅動：** 清晰的品質等級系統引導分析深度
5. **依賴感知：** 自動追蹤和提示未分析的依賴項

---

**Version:** 2.0  
**Last Updated:** 2025-10-21  
**Maintainer:** Analysis Tool Kit Team

