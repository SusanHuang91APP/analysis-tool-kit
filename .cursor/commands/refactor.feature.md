---
description: Generate refactor-###-*.md from view analysis (Next.js component migration guide)
scripts:
  sh: .analysis-tool-kit/scripts/refactor-feature.sh "{ARGS}"
  ps: .analysis-tool-kit/scripts/refactor-feature.ps1 "{ARGS}"
---

> **🎯 用途**: 從現有 view 分析生成 Next.js 元件重構指引  
> **📋 輸入**: view-*.md（可指定特定檔案）  
> **📤 輸出**: refactor-###-*.md（每個功能的重構指引）  
> **⚠️ 重要**: Template 專為「全域功能」設計（Modal/Toast/Drawer），一般元件需調整結構

## 📥 輸入資料

**使用者參數**：`$ARGUMENTS`（可選：指定要分析的 view/component 檔案）

**支援的模式**：
- **Mode 1: 全部分析（預設）** - `/refactor.feature`
- **Mode 2: 指定檔案** - `/refactor.feature <file1> [file2...]`

**自動偵測來源**：
- `{PAGE_ANALYSIS_DIR}/view-*.md` - 前端視圖分析（預設模式）
- `{PAGE_ANALYSIS_DIR}/component-*.md` - React/Vue 元件分析（預設模式）

**範本與憲法**：
- `.analysis-tool-kit/templates/feature-refactor-template.md` - 功能重構範本
- `.analysis-tool-kit/memory/refactor-constitution.md` - 重構憲法（最高指導原則）

---

## 🔄 執行流程

### Step 1: 執行 Shell 腳本驗證環境

執行腳本獲取檔案路徑：
**腳本會自動**：
- ✅ 驗證當前在正確的 analysis 分支
- ✅ 查找所有 view-*.md 檔案（或使用指定的檔案）
- ✅ **檢查對應的 refactor-##-*.md 檔案是否已存在**
- ✅ 輸出檔案路徑和模式清單

**腳本輸出範例**：
```bash
PAGE_ANALYSIS_DIR='/path/to/analysis/001-salepage'
VIEW_FILES_COUNT=30
EXISTING_COUNT=5   # 已存在的 refactor 檔案數量（將 UPDATE）
NEW_COUNT=25       # 新的 refactor 檔案數量（將 CREATE）

VIEW_FILES=(
  '/path/to/analysis/001-salepage/view-00-年齡限制確認彈窗.md'
  '/path/to/analysis/001-salepage/view-01-媒體畫廊.md'
  # ...
)

EXISTING_REFACTOR_FILES=(  # 已存在，將更新
  'refactor-01-媒體畫廊.md'
  'refactor-08-加入購物車.md'
  # ...
)

NEW_REFACTOR_FILES=(  # 不存在，將建立
  'refactor-00-年齡限制確認彈窗.md'
  'refactor-02-商品活動列表.md'
  # ...
)
```

**輸出模式說明**：
- **CREATE** - 目標檔案不存在，將建立新檔案
- **UPDATE** - 目標檔案已存在，將更新現有內容

---

### Step 2: 讀取所有必要檔案

**使用 `read_file` 工具並行讀取**（一次性讀取所有檔案）：

1. **Constitution & Template**：
   - `.analysis-tool-kit/memory/refactor-constitution.md` - 重構憲法
   - `.analysis-tool-kit/templates/feature-refactor-template.md` - 功能重構範本

2. **Analysis Source**：
   - 所有 `view-*.md` - 從 Step 1 的 VIEW_FILES 列表中讀取

---

### Step 3: 為每個 view 生成 refactor 文件

**批次處理**：對於每個 `view-##-名稱.md`，生成對應的 `refactor-##-名稱.md`

**從 `view-*.md` 提取的資訊**：
- 元件結構（HTML 結構、Directive 簽名）
- 核心功能列表（從「核心功能」章節）
- 技術債（從「技術債」章節）
- Controller 依賴（從「實作細節分析」章節）
- Service 依賴（從「架構與品質分析」章節）
- 互動流程（從「互動流程分析」章節）

**判斷元件類型**：
- ✅ **全域功能** (Modal/Toast/Drawer)：使用完整的 Template 結構
- ⚠️ **一般元件** (列表/表單/卡片)：需要調整 Template，移除「全域掛載」章節，簡化為一般元件使用方式

---

### Step 4: 對應到 Next.js 元件架構

**依照 `refactor-constitution.md` 規定**：
- 元件設計原則：單一職責、組合模式
- 元件類型判斷：Client Component（全域功能通常需要互動和狀態）
- 狀態管理模式：Zustand（全域 UI 狀態）

**元件對應規則（全域功能專用）**：
```
舊版 (AngularJS 全域功能)       →  新版 (Next.js 全域功能)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AngularJS Service + $rootScope  →  Zustand Store (全域狀態)
在任意 Controller 中觸發        →  在任意元件中呼叫 store.open()
Modal/Alert/Toast 邏輯         →  Client Component + shadcn/ui
在 View 中定義 Modal 結構       →  在根佈局中掛載一次
條件式顯示                      →  Initializer 模式觸發
```

**全域功能模式的特點**：
- ✅ 在根佈局 (`layout.tsx`) 中掛載一次
- ✅ 使用 Zustand 管理開啟/關閉狀態
- ✅ 從任何地方都可以觸發（包括 Server Component）
- ✅ 透過 Initializer Client Component 在伺服器端觸發

---

### Step 5: 生成每個 refactor-##-*.md

**依照 `feature-refactor-template.md` 結構填充**：

1. **功能對照**
   - 1.1 舊版實作（核心功能、技術債）

2. **新版實作 (Next.js)**
   - 2.1 檔案結構
   - 2.2 技術選型

3. **全域狀態管理 (Zustand)**
   - Store 定義（如需要全域狀態）

4. **主元件實作**
   - 元件本身的實作（通常是 Client Component）

5. **使用模式：全域掛載與觸發**
   - 5.1 在根佈局中掛載
   - 5.2 在 Server Component 中觸發

6. **測試**
   - 單元測試（Vitest + React Testing Library）

7. **驗收標準 (Acceptance Criteria)**
   - 功能完整性、技術債改善、整合性、測試覆蓋率等

**填充原則**：
- ✅ 所有「[填寫說明]」都必須替換成具體內容
- ✅ 所有程式碼範例都必須基於實際分析填充
- ✅ 基於舊版功能提供完整的新版對應方案
- ✅ 遵循「全域功能」模式（Modal/Toast/全域 UI）
- ✅ 使用 Zustand 進行全域狀態管理
- ✅ 採用「根佈局掛載 + Initializer 觸發」模式
- ✅ 提供清晰的檔案路徑和命名建議
- ✅ 確保符合重構憲法的所有規定

---

### Step 6: 寫入所有檔案

**根據檔案是否存在決定寫入策略**：

**CREATE 模式**（檔案不存在）：
- 使用 `write` 工具建立新檔案
- 寫入完整的功能重構指引內容

**UPDATE 模式**（檔案已存在）：
- 使用 `read_file` 先讀取現有檔案
- 使用 `search_replace` 更新特定章節
- 保留手動編輯的內容（如已調整的說明、補充的程式碼範例等）
- 重點更新：
  - 技術棧選擇（如狀態管理模式）
  - 型別定義（如有新增欄位）
  - 元件實作範例（如有更好的實作方式）
  - 測試策略（如有新的測試需求）

為每個 view 寫入對應的 refactor 檔案：`{PAGE_ANALYSIS_DIR}/refactor-##-名稱.md`

---

### Step 7: 確認完成

輸出成功訊息（根據模式）：

**全部建立（所有檔案都是新的）**：
```
✅ 已建立 {NEW_COUNT} 個 refactor-##-*.md 檔案
📁 位置: {PAGE_ANALYSIS_DIR}/
📋 建立的檔案：
   - refactor-00-年齡限制確認彈窗.md
   - refactor-01-媒體畫廊.md
   # ...
📖 下一步: 根據 refactor-architecture.md 和 refactor-##-*.md 開始重構
```

**混合模式（部分更新、部分建立）**：
```
✅ 已更新 {EXISTING_COUNT} 個，建立 {NEW_COUNT} 個 refactor 檔案
📁 位置: {PAGE_ANALYSIS_DIR}/
📝 更新的檔案：
   - refactor-01-媒體畫廊.md (UPDATE)
   - refactor-08-加入購物車.md (UPDATE)
📋 建立的檔案：
   - refactor-00-年齡限制確認彈窗.md (CREATE)
   - refactor-02-商品活動列表.md (CREATE)
   # ...
⚠️  保留內容: 手動編輯的說明和補充範例
📖 下一步: 根據 refactor-architecture.md 和 refactor-##-*.md 開始重構
```

---

## 📝 品質標準

- ✅ 完全遵守 refactor-constitution.md 規定
- ✅ 使用 feature-refactor-template.md 的完整結構（章節 1-7）
- ✅ 所有佔位符「[填寫說明]」都已填充具體內容
- ✅ 採用全域功能模式（Zustand + 根佈局掛載）
- ✅ 明確的使用模式說明（如何在 Server Component 中觸發）
- ✅ 包含完整的單元測試範例
- ✅ 驗收標準具體且可執行

---

## ⚠️ 注意事項

1. **重構憲法優先**：所有技術選型必須符合 refactor-constitution.md
2. **範本完整性**：必須包含 Template 的所有章節（1-7），不可遺漏
3. **適用場景**：Template 專為「全域功能」設計（Modal/Toast/Drawer 等）
   - 需要從應用程式任何地方觸發的 UI 元件
   - 使用 Zustand 管理全域狀態
   - 在根佈局中掛載一次，透過 Initializer 觸發
4. **如果是一般元件**：Template 可能不適用，需要調整為一般元件重構方式
5. **具體且實用**：避免抽象描述，提供可直接使用的程式碼範例
6. **中文專業**：使用中文撰寫，專業術語使用英文
7. **批次處理效率**：所有 view 檔案應在同一次執行中處理完成

---

## 💡 使用範例

```bash
# 範例 1: 分析所有 view 檔案（預設模式）
/refactor.feature
# → 讀取所有 view-*.md 和 component-*.md
# → 輸出: refactor-00-*.md ~ refactor-29-*.md（共 30 個檔案）

# 範例 2: 只分析特定的 view 檔案
/refactor.feature view-01-媒體畫廊.md view-08-加入購物車.md
# → 只分析這 2 個 view
# → 輸出: 
#   refactor-01-媒體畫廊.md
#   refactor-08-加入購物車.md

# 範例 3: 分析優先級 P0 的功能（手動指定）
/refactor.feature view-01-媒體畫廊.md view-02-商品活動列表.md view-05-價格區塊.md view-08-加入購物車.md
# → 只生成核心功能的重構指引
# → 適合分階段重構

# 範例 4: 分析特定容器的所有元件
/refactor.feature view-01-媒體畫廊.md view-02-商品活動列表.md view-03-商品標題與標籤.md
# → 分析「商品主要資訊區塊」容器內的元件
# → 輸出: 該容器的完整重構方案
```

---

**執行邏輯示意**：
```
AI 收到指令
  ↓
解析參數（是否指定檔案？）
  ↓
執行 Shell 腳本（驗證環境、找到檔案）
  ├─ 有指定檔案 → 只分析這些 view
  └─ 沒指定檔案 → 分析所有 view/component 檔案
  ↓
讀取所有必要檔案（憲法、範本、指定的 view）
  ↓
批次處理每個 view
  ↓
  ├─ 提取功能資訊
  ├─ 判斷元件類型（Server/Client）
  ├─ 選擇狀態管理模式
  ├─ 填充重構範本
  └─ 生成 refactor-##-*.md
  ↓
寫入所有 refactor 檔案
  ↓
回報完成（列出所有生成的檔案）
```

---

## 📋 檔案參數說明

**檔案路徑格式**：
- **相對路徑**：`view-01-xxx.md`（相對於 `{PAGE_ANALYSIS_DIR}`）
- **絕對路徑**：`/full/path/to/view-01-xxx.md`

**支援的檔案類型**：
- `view-*.md` - 前端視圖分析（.NET MVC / 任何 View）
- `component-*.md` - React/Vue 元件分析

**使用時機**：
- **全部分析**：首次生成完整的功能重構指引
- **部分分析**：
  - 優先處理 P0 核心功能
  - 按容器分組處理（如商品主要資訊區塊）
  - 分階段進行重構（Phase 1: P0, Phase 2: P1）
  - 測試特定功能的重構方案

---

## 📊 效能考量

- **批次處理**：一次處理所有指定的 view 檔案
- **並行讀取**：同時讀取所有必要檔案（減少 I/O 等待時間）
- **範本複用**：範本只讀取一次，所有 view 共用
- **選擇性處理**：只處理需要的檔案，節省時間和 token
