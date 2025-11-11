# Analysis Refactor Command

---

description: 初始化一個新的前端重構分析文件，基於重構範本和憲法規範
scripts:
  sh: .analysis-kit/scripts/refactor-plan.sh "{ARGS}"
  ps: .analysis-kit/scripts/refactor-plan.ps1 "{ARGS}"

---

## 📥 輸入資料 (User Input)

**使用者參數**：`$ARGUMENTS` 支援兩種格式：

### 格式 1: `<sourceFiles...>`（自動生成目標文件）

**用法**：`/refactor.plan <sourceFiles...>`

- **說明**：只提供源文件，自動生成目標文件
- **Shell script 行為**：
  - 自動路徑映射：將 `analysis/**/*.md` 映射到 `refactors/**/*.md`
  - 保留完整目錄結構（`analysis/` 之後的所有路徑）
  - 保留原始檔案名（包括數字前綴）
  - 建立檔案：`refactors/<保留的路徑>/<原始檔名>.md`
  - 例如：`analysis/001-salepage/features/004-商品基本資訊與標籤.md` → `refactors/001-salepage/features/004-商品基本資訊與標籤.md`

### 格式 2: `<targetFile> <sourceFiles...>`（指定目標文件）

**用法**：`/refactor.plan <targetFile> <sourceFiles...>`

- **說明**：第一個參數是目標文件路徑，後續參數是源文件
- **Shell script 判斷邏輯**：
  - Shell script 會檢查第一個參數是否符合以下條件之一：
    - 以 `.md` 結尾且為絕對路徑
    - 以 `.md` 結尾且文件已存在
    - 以 `refactors/` 開頭的相對路徑且文件存在
  - 如果符合上述條件，視為格式 2；否則視為格式 1
- **Shell script 行為**：
  - 使用指定的 `targetFile` 作為輸出文件
  - 如果文件已存在，直接使用（不覆蓋，AI 將更新內容）
  - 如果文件不存在，建立新文件並複製範本內容
  - 自動建立目錄（如果不存在）
  - 環境變數 `EXISTING_FILE` 會標示文件是否已存在

**參數說明**：

- **`sourceFiles` (必需)**：
  - **格式**: 一個或多個分析文件路徑，例如 `analysis/001-trades-order-detail/features/001-工具列.md`
  - **說明**: 現有的功能分析文件，用於理解需求並生成重構規格
  
- **`targetFile` (可選，格式 2 時必需)**：
  - **格式**: 目標重構分析文件路徑，例如 `refactors/001-media-gallery.md`
  - **說明**: 如果提供，將使用此路徑作為輸出文件；如果未提供，自動生成

---

## 🚀 執行步驟 (Phases)

[ **CRITICAL**: 必須嚴格按照以下階段順序執行。每個 Phase 都有明確的輸出要求。]

---

### Phase 0: 環境設置 (Setup & Environment)

**目標**：確保所有必要資源就緒，並輸出檢查清單供驗證

[ **CRITICAL**: 必須實際執行工具調用，不可省略。禁止只描述步驟而不執行。]

#### 步驟 0.1: 驗證環境變數

**任務**：
- 確認 Shell script 已成功執行
- 驗證環境變數已正確設定

**必須確認的環境變數**：
- `REFACTOR_DOC_FILE`：目標重構文件的絕對路徑
- `LEGACY_ANALYSIS_FILES`：源分析文件路徑（空格分隔）
- `EXISTING_FILE`：文件狀態（`true` = 更新現有文件，`false` = 新建文件）

**輸出要求**（必須顯示）：
```
✅ Phase 0.1: 環境變數驗證完成
   - REFACTOR_DOC_FILE = /path/to/refactors/###-name.md
   - LEGACY_ANALYSIS_FILES = file1.md file2.md
   - EXISTING_FILE = false (新建) / true (更新)
   - 文件格式: 格式 1 (自動生成) / 格式 2 (指定路徑)
```

**錯誤處理**：
- 如果任一環境變數未設定，立即終止並回報：`❌ 錯誤：環境變數 {變數名} 未設定`

---

#### 步驟 0.2: 讀取核心規範文件

**任務**：
- 使用 `read_file` 工具讀取三個核心規範文件
- 載入技術棧轉換規則

**必須讀取的文件**：
1. `.analysis-kit/memory/refactor-constitution.md`（重構憲法）
2. `.analysis-kit/memory/refactor-coding-standard.md`（編碼標準）
3. `.analysis-kit/templates/refactor-template.md`（重構範本）

**輸出要求**（必須顯示）：
```
✅ Phase 0.2: 核心規範文件讀取完成
   - ✅ refactor-constitution.md (已載入技術架構規範)
   - ✅ refactor-coding-standard.md (已載入編碼標準)
   - ✅ refactor-template.md (已載入文件範本)
```

**錯誤處理**：
- 如果任一文件讀取失敗，立即終止並回報錯誤

---

#### 步驟 0.3: 讀取源分析文件

**任務**：
- 從環境變數 `LEGACY_ANALYSIS_FILES` 解析文件列表
- 使用 `read_file` 工具逐一讀取所有源文件

**輸出要求**（必須顯示）：
```
✅ Phase 0.3: 源分析文件讀取完成
   - 檔案數量: {N} 個
   - 檔案列表:
     1. analysis/001-salepage/features/004-商品基本資訊與標籤.md
     2. ...
   - 總行數: {total_lines} 行
```

**錯誤處理**：
- 如果任一文件不存在，立即終止並列出缺失文件

---

#### 步驟 0.4: 讀取目標文件

**任務**：
- 讀取目標重構文件（`REFACTOR_DOC_FILE`）
- 確認文件已由 Shell script 建立並包含範本內容

**輸出要求**（必須顯示）：
```
✅ Phase 0.4: 目標文件讀取完成
   - 檔案路徑: {REFACTOR_DOC_FILE}
   - 檔案狀態: 新建 / 現有文件
   - 範本結構: ✅ 完整 / ⚠️ 需補充
```

**Phase 0 完成檢查點**：
```
🎯 Phase 0 完成總結
   ✅ 環境變數驗證完成
   ✅ 已讀取 {N} 個核心規範文件
   ✅ 已讀取 {N} 個源分析文件
   ✅ 目標文件已就緒
   
   → 準備進入 Phase 1: 需求分析與確認
```

---

### Phase 1: 需求分析與確認 (Analysis & Confirmation)

**目標**：提取功能需求並分析 Codebase，讓使用者確認後再繼續

**[ 🔄 提取流程總覽 ]**

**階段 A：讀取與理解（Phase 0）**
1. 讀取所有來源分析文件（Feature Template）
2. 理解功能範圍和核心業務邏輯
3. 識別關鍵章節（3.x 互動邏輯、4.x 業務邏輯）

**階段 B：需求提取（Phase 1.1）**
1. 從來源文件提取關鍵功能點
2. 從來源文件提取 API 端點與資料結構
3. 從來源文件提取 UI 元件與條件渲染規則
4. 從來源文件提取業務邏輯與狀態變數
5. 生成需求分析摘要表格，等待使用者確認

**階段 C：架構規劃（Phase 1.2）**
1. 分析現有 Codebase（Services、Hooks、Components）
2. 決定 Server/Client Component 分離策略
3. 規劃檔案結構和資料獲取策略
4. 生成檔案規劃表格，等待使用者確認

**階段 D：內容轉換（Phase 2）**
1. 將 AngularJS 語法轉換為 React/Next.js 語法
2. 保留完整業務邏輯（計算、條件、驗證）
3. 保留 API 規格（後端不變）
4. 使用 `search_replace` 逐章節填充重構文件

**階段 E：標記來源（Phase 2）**
- 標記 `> **[從分析文件提取]**`：直接複製的內容
- 標記 `> **[技術棧轉換]**`：轉換後的技術實作
- 標記 `> **[待填寫]**`：來源文件缺少的資訊

---

[ **CRITICAL**: 本 Phase 包含兩個暫停點，必須等待使用者確認。]

---

#### 步驟 1.1: 分析功能需求（從源文件提取）

**任務**：
- 從所有源分析文件中提取功能需求
- 以結構化表格呈現，便於使用者確認

**提取項目**：
1. **關鍵功能點**（Key Features）
2. **功能性需求**（Functional Requirements）
3. **非功能性需求**（Non-Functional Requirements）
4. **核心業務邏輯**（Business Logic）
5. **API 端點列表**（API Endpoints）
6. **資料結構**（Data Models）
7. **UI 元件清單**（UI Components）
8. **條件式渲染規則**（Conditional Rendering）

**輸出格式**（條列式呈現）：

```markdown
## 📊 需求分析摘要

### 1. 關鍵功能點（共 {N} 項）

1. **顯示商品名稱、價格、規格**
   - 來源：004-商品基本資訊與標籤.md (第 2.1 節)
   - 優先級：P0
   
2. **顯示商品標籤（促銷、新品等）**
   - 來源：004-商品基本資訊與標籤.md (第 2.2 節)
   - 優先級：P0

...

### 2. 功能性需求（共 {N} 項）

1. **[需求名稱]**
   - 說明：[需求描述]
   - 來源：[來源文件]

...

### 3. 非功能性需求

- **效能要求**: [從源文件提取]
- **SEO 要求**: [從源文件提取]
- **無障礙要求**: [從源文件提取]
- **瀏覽器支援**: [從源文件提取]

### 4. 核心業務邏輯（共 {N} 項）

1. **[業務邏輯名稱]**
   - 說明：[邏輯描述]
   - 來源：[來源文件]

...

### 5. API 端點（共 {N} 個）

1. **GET `/api/product/:id`**
   - 用途：獲取商品詳情
   - 來源：004-商品基本資訊與標籤.md (第 4.1 節)

...

### 6. 資料結構（共 {N} 個）

1. **`Product` 介面**
   - 主要欄位：id, name, price, tags
   - 來源：004-商品基本資訊與標籤.md (第 4.2 節)

...

### 7. UI 元件清單（共 {N} 個）

1. **ProductInfo**
   - 職責：顯示商品基本資訊
   - 互動性：靜態
   - 來源：004-商品基本資訊與標籤.md (第 3.1 節)

2. **ProductTags**
   - 職責：顯示商品標籤
   - 互動性：靜態
   - 來源：004-商品基本資訊與標籤.md (第 3.2 節)

...

### 8. 條件式渲染規則（共 {N} 項）

1. **[渲染規則名稱]**
   - 條件：[觸發條件]
   - 行為：[渲染行為]
   - 來源：[來源文件]

...
```

**[ ⏸️  PAUSE POINT 1 ]**

**輸出確認訊息**：
```
🔍 Phase 1.1 完成：需求分析摘要已生成

❓ 請確認以上需求分析是否正確？
   - 如果正確，請回覆「確認」或「繼續」
   - 如果需要修正，請指出錯誤並說明
   
   → 確認後將進入步驟 1.2: Codebase 分析
```

**等待使用者回覆後才能繼續下一步驟**

---

#### 步驟 1.2: 分析 Codebase 並規劃檔案結構

**任務**：
- 使用 `codebase_search` 分析現有專案架構
- 檢查相關 services、hooks、元件是否已存在
- 規劃新檔案路徑，確保符合現有架構慣例

**Codebase 分析項目**：
1. **搜尋相關 Services**：
   - 查詢：`codebase_search "service function related to product" ["services/"]`
   - 目的：確認是否已有商品相關服務

2. **搜尋相關 Hooks**：
   - 查詢：`codebase_search "use hook pattern product" ["hooks/"]`
   - 目的：了解現有 Hook 命名規範

3. **搜尋類似元件**：
   - 查詢：`codebase_search "component similar to product info" ["app/"]`
   - 目的：了解元件目錄結構和命名慣例

4. **檢查現有頁面結構**：
   - 查詢：`codebase_search "product page or detail page" ["app/"]`
   - 目的：確認路由結構

**輸出格式**（必須使用表格）：

```markdown
## 🔍 Codebase 分析結果

### 1. 現有相關檔案

| 類型 | 檔案路徑 | 狀態 | 說明 |
|------|---------|------|------|
| Service | `services/product/get-product.service.ts` | ✅ 已存在 | 可直接使用 |
| Hook | `hooks/use-product.ts` | ❌ 不存在 | 需新建 |
| 元件 | `app/(shop)/product/[id]/_components/` | ❌ 不存在 | 需新建目錄 |

### 2. 檔案結構規劃

#### 2.1 需新建的檔案（共 {N} 個）

| # | 檔案路徑 | 類型 | 職責 | 依賴 |
|---|---------|------|------|------|
| 1 | `app/(shop)/product/[id]/page.tsx` | Page | 商品詳情頁 | ProductInfo, ProductTags |
| 2 | `app/(shop)/product/[id]/_components/ProductInfo.tsx` | Component | 商品基本資訊 | useProduct hook |
| 3 | `app/(shop)/product/[id]/_components/ProductTags.tsx` | Component | 商品標籤 | - |
| 4 | `hooks/use-product.ts` | Hook | 商品資料獲取 | getProduct service |
| 5 | `types/product.types.ts` | Type | 商品類型定義 | - |

#### 2.2 需修改的檔案（共 {N} 個）

| # | 檔案路徑 | 修改原因 | 影響範圍 |
|---|---------|---------|---------|
| 1 | `services/product/index.ts` | 匯出新增的服務函式 | 小 |

### 3. 架構決策

- **Server Component**: `page.tsx`, `ProductInfo.tsx`, `ProductTags.tsx`
  - 理由：靜態內容，使用 Server Component 提升 SEO 和效能
  
- **Client Component**: 無（本功能無互動需求）
  
- **資料獲取策略**: 
  - Server-side: 使用 `fetch` + `unstable_cache`
  - Client-side: 無需求
  
- **狀態管理**: 
  - 無需 Zustand（無跨元件狀態共享需求）
```

**[ ⏸️  PAUSE POINT 2 ]**

**輸出確認訊息**：
```
🏗️  Phase 1.2 完成：Codebase 分析與檔案規劃已完成

📁 規劃結果：
   - 需新建檔案: {N} 個
   - 需修改檔案: {N} 個
   - Server Components: {N} 個
   - Client Components: {N} 個

❓ 請確認檔案規劃是否符合專案架構？
   - 如果正確，請回覆「確認」或「繼續」
   - 如果需要調整，請指出需修改的部分
   
   → 確認後將進入 Phase 2: 內容生成
```

**等待使用者回覆後才能繼續下一 Phase**

**Phase 1 完成檢查點**：
```
🎯 Phase 1 完成總結
   ✅ 已提取 {N} 項功能需求
   ✅ 已識別 {N} 個 API 端點
   ✅ 已規劃 {N} 個新檔案
   ✅ 使用者已確認需求與規劃
   
   → 準備進入 Phase 2: 內容生成
```

---

### Phase 2: 內容生成 (Content Generation)

**目標**：根據確認的需求和規劃，依照 template 填充重構文件

[ **CRITICAL**: 必須使用 `search_replace` 工具，禁止直接輸出 Markdown 內容。]

---

#### 步驟 2.1: 準備填充內容（基於技術棧轉換）

**任務**：
- 根據 Phase 1 確認的需求和規劃
- 準備各章節的填充內容
- 使用正確的標記系統

**填充章節清單**：
0. **1.1 分析檔案資訊**：將環境變數 LEGACY_ANALYSIS_FILES 中的文件路徑填入表格
1. **標題**：從源文件名稱生成有意義的標題
2. **2.1 背景目的與使用者故事**：整合功能描述
3. **2.1 關鍵功能點**：Phase 1.1 提取的功能列表
4. **3. 相關文件**：連結所有源分析文件
5. **4. 認證與路由保護**：從源文件提取或標記 `[待填寫]`
6. **5.1 資料模型**：Phase 1.1 提取的資料結構
7. **5.4 API 規格**：Phase 1.1 提取的 API 端點
8. **5.5 條件式渲染邏輯**：從源文件提取
9. **5.6 資料流與狀態變數**：從源文件提取
10. **6. 狀態管理**：根據 Phase 1.2 的架構決策
11. **7. 檔案結構**：使用 Phase 1.2 的檔案規劃
12. **10.1 元件拆解**（Feature 重構）：Phase 1.1 的 UI 元件清單
13. **12.1 關鍵測試案例**：從源文件的測試情境轉換
14. **13. 驗收標準**：從源文件的驗收條件轉換

**標記系統**（必須嚴格遵守）：
- `> **[從分析文件提取]**`：直接從源文件複製的內容
- `> **[技術棧轉換]**`：根據憲法規範轉換的技術實作（AngularJS → Next.js 15）
- `> **[待填寫]**`：源文件缺少的資訊，需人工補充
- ❌ **禁止使用**：`[AI 建議]`、`[AI 推測]` 等任何推測性標記

---

#### 步驟 2.2: 執行內容填充

**任務**：
- 使用 `search_replace` 工具逐章節填充
- 保持範本完整結構
- 正確標記所有內容來源

**執行順序**：
0. 填充「1.1 分析檔案資訊」章節
1. 替換文件標題
2. 填充第 2 節（功能職責）
3. 填充第 3 節（相關文件）
4. 填充第 4 節（認證與路由）
5. 填充第 5 節（資料流與 API）
6. 填充第 6 節（狀態管理）
7. 填充第 7 節（檔案結構）
8. 填充第 8-9 節（路由與佈局）
9. 填充第 10 節（元件組合）
10. 填充第 11-13 節（錯誤處理、測試、驗收標準）

**Phase 2 完成檢查點**：
```
🎯 Phase 2 完成總結
   ✅ 已執行 {N} 次 search_replace
   ✅ 已填充 {N} 個章節
   ✅ 已標記 {N} 處 [從分析文件提取]
   ✅ 已標記 {N} 處 [技術棧轉換]
   ✅ 已保留 {N} 處 [待填寫]
   
   → 準備進入 Phase 3: 完成報告
```

---

### Phase 3: 完成報告 (Final Report)

**目標**：提供清晰的執行摘要和後續建議

---

#### 步驟 3.1: 生成執行摘要

**輸出格式**：
```
╔════════════════════════════════════════════════════════╗
║          🎉 重構分析文件生成完成                          ║
╚════════════════════════════════════════════════════════╝

📄 文件資訊
   - 目標文件: {REFACTOR_DOC_FILE}
   - 文件狀態: ✅ 新建 / ✅ 更新

📊 Phase 0: 環境設置
   - ✅ 已讀取 3 個核心規範文件
   - ✅ 已讀取 {N} 個源分析文件（共 {total_lines} 行）
   - ✅ 技術棧: Next.js 15 + TypeScript + SWR + Zustand

📋 Phase 1: 需求分析與確認
   - ✅ 已提取 {N} 個關鍵功能點
   - ✅ 已識別 {N} 個 API 端點
   - ✅ 已定義 {N} 個資料結構
   - ✅ 已列出 {N} 個 UI 元件
   - ✅ 已規劃 {N} 個新檔案
   - ✅ 使用者已確認需求與規劃

✍️ Phase 2: 內容生成
   - ✅ 已執行 {N} 次 search_replace
   - ✅ 已填充 {N} 個章節
   - ✅ 已標記 {N} 處 [從分析文件提取]
   - ✅ 已標記 {N} 處 [技術棧轉換]
   - ⚠️ 已保留 {N} 處 [待填寫]（需人工補充）
```

---

#### 步驟 3.2: 後續建議

**輸出格式**：
```
📌 建議後續動作

🔴 **優先級 P0**（必須立即處理）
   1. 執行品質檢查：`/refactor.analysis {REFACTOR_DOC_FILE}`
   2. 檢視所有標記為 [待填寫] 的章節

🟠 **優先級 P1**（重要但非緊急）
   3. 與 UI/UX 設計師確認「相關文件」章節，補充 Figma 連結
   4. 與後端工程師協作，完善「API 規格」章節
   5. 驗證所有檔案路徑是否符合專案慣例

🟡 **優先級 P2**（建議處理）
   6. Review 所有 [技術棧轉換] 標記的內容
   7. 與 QA 團隊確認「測試策略」章節
   8. 補充「認證與路由保護」細節（如適用）

🟢 **優先級 P3**（可選）
   9. 進行團隊 Code Review
   10. 確認「驗收標準」可測試且明確
```

**Phase 3 完成檢查點**：
```
╔════════════════════════════════════════════════════════╗
║          ✅ 重構規劃文件生成完成                          ║
╚════════════════════════════════════════════════════════╝

🎯 總結
   - Phase 0: ✅ 環境設置完成
   - Phase 1: ✅ 需求分析與確認完成（使用者已確認）
   - Phase 2: ✅ 內容生成完成
   - Phase 3: ✅ 完成報告生成

📁 重構文件路徑: {REFACTOR_DOC_FILE}

🔜 下一步：執行 `/refactor.analysis {REFACTOR_DOC_FILE}` 進行品質檢查與功能一致性比對
```
