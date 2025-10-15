---
description: Generate refactor-architecture.md from architecture analysis (Next.js 15 App Router migration guide)
scripts:
  sh: .analysis-tool-kit/scripts/refactor-architecture.sh "{ARGS}"
  ps: .analysis-tool-kit/scripts/refactor-architecture.ps1 "{ARGS}"
---

> **🎯 用途**: 從現有分析生成 Next.js 15 架構重構指引  
> **📋 輸入**: architecture.md + server-*.md（可指定特定檔案）  
> **📤 輸出**: refactor-architecture.md（完整重構指引）

## 📥 輸入資料

**使用者參數**：`$ARGUMENTS`（可選：指定要分析的 server/service 檔案）

**支援的模式**：
- **Mode 1: 全部分析（預設）** - `refactor.architecture`
- **Mode 2: 指定檔案** - `refactor.architecture <file1> [file2...]`

**自動偵測來源**：
- `{PAGE_ANALYSIS_DIR}/architecture.md` - 現有架構分析（必讀）
- `{PAGE_ANALYSIS_DIR}/server-*.md` - 所有後端端點分析（預設模式）
- `{PAGE_ANALYSIS_DIR}/service-*.md` - Service 層方法分析（預設模式）

**範本與憲法**：
- `.analysis-tool-kit/templates/architecture-refactor-template.md` - 架構重構範本
- `.analysis-tool-kit/memory/refactor-constitution.md` - 重構憲法（最高指導原則）

---

## 🔄 執行流程

### Step 1: 執行 Shell 腳本驗證環境

執行腳本獲取檔案路徑：
**腳本會自動**：
- ✅ 驗證當前在正確的 analysis 分支
- ✅ 檢查 architecture.md 存在
- ✅ 查找所有 server-*.md 檔案（或使用指定的檔案）
- ✅ **檢查 refactor-architecture.md 是否已存在**
- ✅ 輸出檔案路徑和模式供 AI 使用

**腳本輸出範例**：
```bash
ARCH_FILE='/path/to/analysis/001-salepage/architecture.md'
OUTPUT_FILE='/path/to/analysis/001-salepage/refactor-architecture.md'
OUTPUT_MODE='create'  # 或 'update'
SERVER_FILES_COUNT=7
SERVER_FILES=(
  '/path/to/analysis/001-salepage/server-01-xxx.md'
  '/path/to/analysis/001-salepage/server-02-xxx.md'
  # ...
)
```

**輸出模式說明**：
- `OUTPUT_MODE='create'` - 目標檔案不存在，將建立新檔案
- `OUTPUT_MODE='update'` - 目標檔案已存在，將更新現有內容

---

### Step 2: 讀取所有必要檔案

**使用 `read_file` 工具並行讀取**（一次性讀取所有檔案）：

1. **Constitution & Template**：
   - `.analysis-tool-kit/memory/refactor-constitution.md` - 重構憲法
   - `.analysis-tool-kit/templates/architecture-refactor-template.md` - 架構重構範本

2. **Analysis Source**：
   - `{ARCH_FILE}` - 從 Step 1 獲取的 architecture.md 路徑
   - 所有 `server-*.md` - 從 Step 1 的 SERVER_FILES 列表中讀取

---

### Step 3: 分析架構和技術棧

**從 `architecture.md` 提取**：
- 前端技術棧（View 引擎、前端框架、狀態管理）
- 後端技術棧（Controller、路由、認證方式）
- 業務邏輯層（Service 依賴、資料存取）
- 資料流與整合（API 端點、快取策略）

**從 `server-*.md` 提取**：
- 所有 Controller Actions / API Routes
- 方法簽名、HTTP 方法、路由路徑
- 授權屬性、請求/回應格式
- Service 依賴關係

---

### Step 4: 對應到 Next.js 15 App Router 架構

**依照 `refactor-constitution.md` 規定**：
- 核心技術棧：Next.js 15 App Router + TypeScript 5+ + Tailwind CSS
- 架構原則：Server Components First, 統一 API 處理, SWR 配置
- 狀態管理：SWR (伺服器狀態) + Zustand (客戶端狀態)
- 表單處理：React Hook Form + Zod

**架構對應規則**：
```
舊版 (AngularJS + ASP.NET MVC)  →  新版 (Next.js 15)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
View (.cshtml)                 →  app/(group)/[page]/page.tsx (Server Component)
AngularJS Directive            →  Client Component ('use client')
Controller Action              →  BFF API Route (app/api/[endpoint]/route.ts)
Service Layer                  →  BFF Service Layer (lib/services/[service].ts)
AngularJS $http                →  apiClient + SWR
ng-model, ng-click             →  React Hook Form + Event Handlers
```

---

### Step 5: 生成 refactor-architecture.md

**依照 `architecture-refactor-template.md` 結構填充**：

1. **技術棧（依照專案規範）**
   - Frontend: Next.js 15, React 18+, TypeScript 5+, Tailwind CSS, shadcn/ui, SWR, React Hook Form + Zod
   - Backend (BFF Layer): Fastify 4.x / Express, TypeScript 5+, Zod

2. **專案結構 (Frontend)**
   - App Router 目錄結構
   - 路由群組與 Colocation 原則
   - 頁面專用元件與全域共用元件的區分

3. **BFF 實作 (Next.js API Routes & Data Access Layer)**
   - 3.1 Data Access Layer (伺服器端核心邏輯)
   - 3.2 API Route (供 Client Components 使用)

4. **Frontend 實作**
   - 4.1 API Client & 模組 API
   - 4.2 Server Component (`page.tsx`) - 資料初始化與渲染
   - 4.3 Client Component - 處理互動與客戶端狀態

5. **驗收標準 (Acceptance Criteria)**
   - Phase 1: BFF & API Layer
   - Phase 2: Server-Side Rendering
   - Phase 3: Client-Side Interactivity

**填充原則**：
- ✅ 所有「[填寫說明]」都必須替換成具體內容
- ✅ 所有程式碼範例都必須基於實際分析填充
- ✅ 基於舊版實作提供完整的新版對應方案
- ✅ 遵循 Next.js 15 App Router 最佳實踐
- ✅ Data Access Layer 優先於傳統 BFF Controller/Service 模式
- ✅ 提供清晰的檔案路徑和命名建議
- ✅ 確保符合重構憲法的所有規定

---

### Step 6: 寫入檔案

**根據 `{OUTPUT_MODE}` 決定寫入策略**：

**CREATE 模式** (`OUTPUT_MODE='create'`)：
- 使用 `write` 工具建立新檔案
- 寫入完整的重構指引內容

**UPDATE 模式** (`OUTPUT_MODE='update'`)：
- 使用 `read_file` 先讀取現有檔案
- 使用 `search_replace` 更新特定章節
- 保留手動編輯的內容（如已調整的說明、補充的範例等）
- 重點更新：
  - 技術棧資訊（如有新端點）
  - BFF 層實作（如有新方法）
  - 開發檢查清單（如有新任務）

將內容寫入 `{OUTPUT_FILE}` (從 Step 1 獲取)

---

### Step 7: 確認完成

輸出成功訊息（根據模式）：

**CREATE 模式**：
```
✅ 已建立 refactor-architecture.md
📁 位置: {OUTPUT_FILE}
📊 分析來源:
   - architecture.md
   - {SERVER_FILES_COUNT} 個 server-*.md 檔案
📋 下一步: 執行 /refactor.feature 生成功能重構指引
```

**UPDATE 模式**：
```
✅ 已更新 refactor-architecture.md
📁 位置: {OUTPUT_FILE}
📝 更新內容:
   - [列出更新的章節]
   - [列出新增的內容]
⚠️  保留內容: 手動編輯的說明和補充範例
📋 下一步: 執行 /refactor.feature 生成功能重構指引
```

---

## 📝 品質標準

- ✅ 完全遵守 refactor-constitution.md 規定
- ✅ 使用 architecture-refactor-template.md 的完整結構（章節 1-5）
- ✅ 所有佔位符「[填寫說明]」都已填充具體內容
- ✅ 提供清晰的新舊技術對應關係
- ✅ Data Access Layer + API Routes 架構完整
- ✅ Frontend 實作完整（Server/Client Component 分離）
- ✅ 驗收標準具體且可執行（Phase 1-3）

---

## ⚠️ 注意事項

1. **重構憲法優先**：所有技術選型必須符合 refactor-constitution.md
2. **範本完整性**：必須包含 Template 的所有章節（1-5），不可遺漏
3. **架構模式**：使用 Next.js Data Access Layer 模式，而非傳統 Controller/Service 模式
4. **具體且實用**：避免抽象描述，提供可直接使用的程式碼範例
5. **中文專業**：使用中文撰寫，專業術語使用英文

---

## 💡 使用範例

```bash
# 範例 1: 分析所有檔案（預設模式）
refactor.architecture
# → 讀取 architecture.md + 所有 server-*.md + service-*.md
# → 輸出: analysis/001-salepage/refactor-architecture.md

# 範例 2: 只分析特定的 server 檔案
refactor.architecture server-01-商品頁首頁.md server-02-商品詳細說明.md
# → 只分析指定的 2 個 server 檔案
# → 輸出: 聚焦於這些端點的重構指引

# 範例 3: 分析特定的 service 方法
refactor.architecture service-get-01-取得商品頁資料.md service-post-01-新增訂單.md
# → 分析特定的 service 層方法
# → 輸出: BFF 層實作重點放在這些方法

# 範例 4: 混合分析
refactor.architecture server-01-xxx.md service-get-01-xxx.md
# → 同時分析 server 端點和 service 方法
```

---

**執行邏輯示意**：
```
AI 收到指令
  ↓
解析參數（是否指定檔案？）
  ↓
執行 Shell 腳本（驗證環境、找到檔案）
  ├─ 有指定檔案 → 只分析這些檔案
  └─ 沒指定檔案 → 分析所有 server/service 檔案
  ↓
讀取所有必要檔案（憲法、範本、分析來源）
  ↓
分析舊版架構和技術棧
  ↓
對應到 Next.js 15 架構
  ↓
填充重構範本（所有章節）
  ↓
寫入 refactor-architecture.md
  ↓
回報完成
```

---

## 📋 檔案參數說明

**檔案路徑格式**：
- **相對路徑**：`server-01-xxx.md`（相對於 `{PAGE_ANALYSIS_DIR}`）
- **絕對路徑**：`/full/path/to/server-01-xxx.md`

**支援的檔案類型**：
- `server-*.md` - 後端端點分析（Controller Actions / API Routes）
- `service-*.md` - Service 層方法分析（service-get/post/put/delete/patch）

**使用時機**：
- **全部分析**：首次生成完整的重構指引
- **部分分析**：
  - 只想重構特定功能模組
  - 專注於某幾個關鍵端點
  - 分階段進行重構規劃
