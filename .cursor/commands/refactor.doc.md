# Analysis Refactor Command

---

description: 初始化一個新的前端重構分析文件，基於重構範本和憲法規範
scripts:
  sh: .analysis-kit/scripts/refactor-doc.sh "{ARGS}"
  ps: .analysis-kit/scripts/refactor-doc.ps1 "{ARGS}"

---

## 📥 輸入資料 (User Input)

**使用者參數**：`$ARGUMENTS` 支援兩種格式：

### 格式 1: `<sourceFiles...>`（自動生成目標文件）

**用法**：`/refactor.doc <sourceFiles...>`

- **說明**：只提供源文件，自動生成目標文件
- **Shell script 行為**：
  - 自動計算編號（掃描 `refactors/` 目錄，取得下一個編號）
  - 自動生成檔名（基於第一個分析文件的名稱，轉換為 kebab-case）
  - 建立檔案：`refactors/###-{name}.md`
  - 例如：`002-MediaGallery.md` → `refactors/001-media-gallery.md`

### 格式 2: `<targetFile> <sourceFiles...>`（指定目標文件）

**用法**：`/refactor.doc <targetFile> <sourceFiles...>`

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
   - 技術棧: Next.js 15 App Router + TypeScript + SWR + Zustand
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
   ✅ 已讀取 3 個核心規範文件
   ✅ 已讀取 {N} 個源分析文件
   ✅ 目標文件已就緒
   
   → 準備進入 Phase 1: 需求分析與確認
```

---

### Phase 1: 需求分析與確認 (Analysis & Confirmation)

**目標**：提取功能需求並分析 Codebase，讓使用者確認後再繼續

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

**輸出格式**（必須使用表格）：

```markdown
## 📊 需求分析摘要

### 1. 關鍵功能點（共 {N} 項）

| # | 功能點 | 來源文件 | 優先級 |
|---|-------|---------|--------|
| 1 | 顯示商品名稱、價格、規格 | 004-商品基本資訊與標籤.md (第 2.1 節) | P0 |
| 2 | 顯示商品標籤（促銷、新品等） | 004-商品基本資訊與標籤.md (第 2.2 節) | P0 |
| ... | ... | ... | ... |

### 2. API 端點（共 {N} 個）

| # | 端點 | 方法 | 用途 | 來源文件 |
|---|------|------|------|---------|
| 1 | `/api/product/:id` | GET | 獲取商品詳情 | 004-商品基本資訊與標籤.md (第 4.1 節) |
| ... | ... | ... | ... | ... |

### 3. 資料結構（共 {N} 個）

| # | 介面名稱 | 主要欄位 | 來源文件 |
|---|---------|---------|---------|
| 1 | `Product` | id, name, price, tags | 004-商品基本資訊與標籤.md (第 4.2 節) |
| ... | ... | ... | ... |

### 4. UI 元件（共 {N} 個）

| # | 元件名稱 | 職責 | 互動性 | 來源文件 |
|---|---------|------|--------|---------|
| 1 | ProductInfo | 顯示商品基本資訊 | 靜態 | 004-商品基本資訊與標籤.md (第 3.1 節) |
| 2 | ProductTags | 顯示商品標籤 | 靜態 | 004-商品基本資訊與標籤.md (第 3.2 節) |
| ... | ... | ... | ... | ... |

### 5. 非功能性需求

- **效能要求**: [從源文件提取]
- **SEO 要求**: [從源文件提取]
- **無障礙要求**: [從源文件提取]
- **瀏覽器支援**: [從源文件提取]
```

**[ ⏸️  PAUSE POINT 1 ]**

**輸出確認訊息**：
```
🔍 Phase 1.1 完成：需求分析摘要已生成

📋 已提取內容：
   - 關鍵功能點: {N} 項
   - API 端點: {N} 個
   - 資料結構: {N} 個
   - UI 元件: {N} 個

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

**目標**：根據確認的需求和規劃，填充重構文件

[ **CRITICAL**: 必須使用 `search_replace` 工具，禁止直接輸出 Markdown 內容。]

---

#### 步驟 2.1: 判斷重構類型

**任務**：
- 根據源文件位置判斷是 API 重構還是 Feature 重構
- 調整後續填充策略

**判斷規則**：
- 如果源文件位於 `apis/` 目錄 → **API 重構**
- 如果源文件位於 `features/` 目錄 → **Feature 重構**
- 如果混合 → 以主要文件類型為準

---

#### 步驟 2.2: 準備填充內容（基於技術棧轉換）

**任務**：
- 根據 Phase 1 確認的需求和規劃
- 準備各章節的填充內容
- 使用正確的標記系統

**填充章節清單**：
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

#### 步驟 2.3: 執行內容填充

**任務**：
- 使用 `search_replace` 工具逐章節填充
- 保持範本完整結構
- 正確標記所有內容來源

**執行順序**：
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
   
   → 準備進入 Phase 3: 品質保證
```

---

### Phase 3: 品質保證 (Quality Assurance)

**目標**：確保重構文件品質，驗證功能一致性

[ **CRITICAL**: 這是驗證步驟，必須仔細執行。]

---

#### 步驟 3.1: 功能一致性比對

**任務**：
- 比對重構文件與源文件的功能一致性
- 確保沒有遺漏或誤解需求

**比對項目**（共 7 項）：
1. **商業邏輯**：比對核心業務邏輯是否一致
2. **關鍵功能點**：比對功能列表是否完整
3. **API 端點**：比對 API 規格是否一致
4. **資料模型**：比對資料結構是否一致
5. **互動流程**：比對使用者互動流程是否一致
6. **條件式渲染**：比對渲染邏輯是否一致
7. **狀態變數**：比對狀態管理是否一致

**輸出格式**：
     ```markdown
## 15. 功能一致性比對報告
     
> **[自動生成 - 功能一致性比對]**
     
### 15.1 比對結果清單
     
| 比對項目 | 源文件章節 | 重構文件章節 | 比對結果 | 備註 |
     |---------|-----------|-------------|---------|------|
| 商業邏輯 | 4.2 | 5.5 | ✅ 一致 | - |
| 關鍵功能點 | 2.1 | 2.1 | ✅ 一致 | - |
| API 端點 | 4.1 | 5.4 | ✅ 一致 | - |
| 資料模型 | 4.2 | 5.1 | ✅ 一致 | - |
| 互動流程 | 3.2 | 7.1 | ✅ 一致 | - |
| 條件式渲染 | 3.3 | 5.5 | ✅ 一致 | - |
| 狀態變數 | 4.3 | 5.6 | ✅ 一致 | - |
     
     ### 15.2 比對結果摘要
     
**✅ 一致項目**: {N} 項
**⚠️ 不一致項目**: {N} 項（需人工確認）

### 15.3 詳細說明

[針對不一致項目提供詳細說明]
```

---

#### 步驟 3.2: 品質等級檢查（4 層檢查）

**任務**：
- 執行 4 層品質檢查
- 確保文件品質達標

**Level 1: 必填項檢查**
- [ ] 所有 `[待填寫]` 是否已合理保留（有明確理由）
- [ ] 所有章節是否有實質內容（非空白或範本文字）
- [ ] TypeScript 介面定義是否完整且有效
- [ ] 檔案路徑是否使用絕對路徑

**Level 2: 內容一致性檢查**
- [ ] API 規格與源文件完全一致
- [ ] 資料模型涵蓋所有源文件提到的欄位
- [ ] 狀態管理策略明確且符合憲法規範
- [ ] 元件拆解與源文件的 UI 結構一致

**Level 3: 技術規範檢查**
- [ ] 符合 Next.js 15 App Router 規範
- [ ] Server/Client Component 分離清楚且合理
- [ ] 資料獲取策略符合 `refactor-coding-standard.md`
- [ ] 狀態管理使用 Zustand（如需要）+ SWR（Client）
- [ ] 無使用對應表外的技術方案

**Level 4: 可實作性檢查**
- [ ] 檔案路徑符合專案現有結構（基於 Phase 1.2 分析）
- [ ] 所有依賴的服務已存在或已規劃建立
- [ ] 驗收標準可測試且明確
- [ ] 無循環依賴或架構衝突

**輸出格式**：
```
📊 品質檢查結果

✅ Level 1 (必填項): 通過 ({N}/4 項)
✅ Level 2 (內容一致性): 通過 ({N}/4 項)
⚠️  Level 3 (技術規範): 需改善 ({N}/5 項)
   - ⚠️ 項目名稱: 原因說明
✅ Level 4 (可實作性): 通過 ({N}/4 項)

總體評分: {score}/17
品質等級: ✅ 優秀 (15-17) / ⚠️ 良好 (12-14) / ❌ 需改善 (<12)
```

**Phase 3 完成檢查點**：
```
🎯 Phase 3 完成總結
   ✅ 功能一致性比對完成 (7/7 項)
   ✅ 4 層品質檢查完成
   ✅ 品質等級: {等級}
   ✅ 比對報告已附加到文件末尾
   
   → 準備進入 Phase 4: 完成報告
```

---

### Phase 4: 完成報告 (Final Report)

**目標**：提供清晰的執行摘要和後續建議

---

#### 步驟 4.1: 生成執行摘要

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

✍️  Phase 2: 內容生成
   - ✅ 已執行 {N} 次 search_replace
   - ✅ 已填充 {N} 個章節
   - ✅ 已標記 {N} 處 [從分析文件提取]
   - ✅ 已標記 {N} 處 [技術棧轉換]
   - ⚠️  已保留 {N} 處 [待填寫]（需人工補充）

🔍 Phase 3: 品質保證
   - ✅ 功能一致性比對: {N}/7 項一致
   - ✅ 品質等級: {等級}（{score}/17 分）
   - ✅ Level 1 (必填項): {N}/4 通過
   - ✅ Level 2 (內容一致性): {N}/4 通過
   - ✅ Level 3 (技術規範): {N}/5 通過
   - ✅ Level 4 (可實作性): {N}/4 通過
```

---

#### 步驟 4.2: 後續建議

**輸出格式**：
```
📌 建議後續動作（優先順序排序）

🔴 **優先級 P0**（必須立即處理）
   1. 檢查功能一致性比對報告（如有不一致項目）
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

**Phase 4 完成檢查點**：
```
╔════════════════════════════════════════════════════════╗
║          ✅ 所有階段執行完成                              ║
╚════════════════════════════════════════════════════════╝

🎯 總結
   - Phase 0: ✅ 環境設置完成
   - Phase 1: ✅ 需求分析與確認完成（使用者已確認）
   - Phase 2: ✅ 內容生成完成
   - Phase 3: ✅ 品質保證完成
   - Phase 4: ✅ 完成報告生成

📁 重構文件路徑: {REFACTOR_DOC_FILE}

🚀 可以開始重構實作！
```

---

## 🔑 關鍵規則 (Key Rules)

[ **CRITICAL**: AI 在執行所有步驟時必須遵守的規則。]

---

### 核心規則

- **規則 1**: 環境變數驗證（必須優先執行）：
  - Shell script 負責驗證參數並建立目標文件
  - **無條件執行**：無論參數格式如何，Shell script 都會先建立目標文件
  - AI 必須在 Phase 0.1 確認 `REFACTOR_DOC_FILE`、`LEGACY_ANALYSIS_FILES`、`EXISTING_FILE` 三個環境變數已設定
  - 如果 Shell script 未提供必要的環境變數，立即終止並回報錯誤
  - **必須輸出檢查清單**：不可省略環境變數確認步驟

- **規則 2**: 工具調用強制執行：
  - **Phase 0 步驟 0.2-0.4 必須實際執行 `read_file` 工具**
  - 禁止只描述步驟而不執行工具（例如：「已讀取憲法」但未調用 read_file）
  - 每個 read_file 調用必須有對應的輸出確認
  - **Phase 2 必須使用 `search_replace` 工具**，禁止直接輸出 Markdown 內容

- **規則 3**: 目標文件處理：
  - **統一方式**：無論格式 1 或格式 2，目標文件路徑都由環境變數 `REFACTOR_DOC_FILE` 提供
  - **格式 1**：Shell script 自動生成路徑（`refactors/###-name.md`）
  - **格式 2**：Shell script 使用第一個參數作為路徑
  - **文件狀態**：如果文件已存在（`EXISTING_FILE=true`），AI 將更新內容而非覆蓋

- **規則 4**: 源文件識別：
  - **統一方式**：無論格式 1 或格式 2，源文件路徑都由環境變數 `LEGACY_ANALYSIS_FILES` 提供（空格分隔）
  - Shell script 已處理格式差異，AI 只需讀取環境變數並執行 read_file

---

### 技術規範規則

- **規則 5**: 技術棧轉換對應（必須嚴格遵守）：
  - 必須先讀取 `refactor-constitution.md` 和 `refactor-coding-standard.md`
  - 嚴格遵循技術棧轉換對應表（見下方）
  - **禁止使用對應表外的技術方案**
  - **禁止推測或建議分析文件中不存在的功能**
  - 技術棧：Next.js 15 App Router + TypeScript + SWR (Client) + Zustand + Reducer + Server Component First + Nx Monorepo

- **規則 6**: 內容標記規則（修訂版）：
  - ✅ **`> **[從分析文件提取]**`**：直接從源文件複製的內容（技術中立的需求描述）
  - ✅ **`> **[技術棧轉換]**`**：根據憲法規範轉換的等價技術實作（AngularJS → Next.js 15）
  - ✅ **`> **[待填寫]**`**：源文件缺少的資訊，需人工補充
  - ❌ **禁止使用**：`[AI 建議]`、`[AI 推測]`、`[AI 補充]` 等任何推測性標記

---

### 技術棧轉換對應表

**基於 refactor-constitution.md 的技術轉換規則**：

| 舊技術（AngularJS） | 新技術（Next.js 15 + React） | 轉換規則說明 |
|-------------------|---------------------------|------------|
| `$scope` / `$rootScope` | `useState` / Zustand Store | 元件內狀態用 useState，跨元件狀態用 Zustand |
| `$http` / `$resource` | `fetch` + `unstable_cache` (Server) / SWR (Client) | Server Component 用 fetch，Client Component 用 SWR |
| `ng-if` / `ng-show` / `ng-hide` | `{condition && <Component />}` / `{condition ? <A /> : <B />}` | 條件式渲染 |
| `.service()` / `.factory()` | Server Action (services/) + Custom Hook (hooks/) | Service 層拆分為 Server 和 Client |
| `.directive()` | React Component (Server/Client) | 優先使用 Server Component |
| `.controller()` | Page Component (`page.tsx`) | 頁面層級元件 |
| `$q` (Promise) | `async`/`await` | ES2017+ 非同步語法 |
| `$timeout` / `$interval` | `setTimeout` / `setInterval` | 標準 Web API |
| `ng-repeat` | `array.map()` | JSX 中的列表渲染 |
| `$watch` | `useEffect` | 副作用處理 |
| `$filter` | Utility Function / `useMemo` | 純函式或記憶化運算 |

**重要提醒**：
- 所有技術轉換必須在標記中附上轉換理由
- 範例格式：`> **[技術棧轉換：AngularJS $http → Next.js SWR]** 因為這是 Client Component 的資料獲取`

---

### 執行流程規則

- **規則 7**: 暫停點（Pause Point）規則：
  - **Phase 1.1 完成後必須暫停**：輸出需求分析摘要，等待使用者確認
  - **Phase 1.2 完成後必須暫停**：輸出 Codebase 分析與檔案規劃，等待使用者確認
  - 使用者回覆「確認」、「繼續」或「OK」後才能進入下一步驟
  - 如使用者提出修正，需更新分析結果後再繼續
  - **禁止自動跳過暫停點**

- **規則 8**: 功能一致性比對（必須執行）：
  - 在 Phase 3.1 必須執行功能一致性比對
  - 比對項目：商業邏輯、關鍵功能點、API 端點、資料模型、互動流程、條件式渲染、狀態變數（共 7 項）
  - 生成比對報告並附加到重構文件末尾（第 15 節）
  - 不一致項目必須標記為 `> **[功能不一致 - 需要人工確認]**`

- **規則 9**: 品質等級檢查（必須執行）：
  - 在 Phase 3.2 必須執行 4 層品質檢查
  - Level 1: 必填項檢查（4 項）
  - Level 2: 內容一致性檢查（4 項）
  - Level 3: 技術規範檢查（5 項）
  - Level 4: 可實作性檢查（4 項）
  - 總分 17 分，必須輸出評分結果和品質等級

---

### 文件操作規則

- **規則 10**: 工具使用規範：
  - 使用 `write` 建立新檔案
  - 使用 `search_replace` 修改現有檔案
  - **嚴禁直接覆蓋整個檔案內容**
  - **嚴禁在回應中直接輸出完整 Markdown 內容代替工具調用**

- **規則 11**: 檔案路徑規範：
  - 所有檔案路徑必須使用絕對路徑（`/Users/susanhuang/Work/Projects/analysis-tool-kit/...`）
  - Phase 1.2 規劃的檔案路徑必須基於 Codebase 分析結果
  - 新建的重構分析檔案必須保持範本的完整結構

- **規則 12**: 編號與檔名生成（僅格式 1，由 Shell Script 執行）：
  - 編號規則：掃描 `refactors/` 目錄，取最大編號 +1，從 `001` 開始
  - 檔名規則：使用第一個分析文件名稱（移除編號前綴），轉換為 kebab-case
  - 範例：`004-商品基本資訊與標籤.md` → `refactors/001-商品基本資訊與標籤.md`

---

## 💡 使用範例

### 格式 1: 自動生成目標文件

```bash
# 範例 1：基於單一分析文件建立重構規格（使用 @ 引用）
/refactor.doc @004-商品基本資訊與標籤.md
# → 自動建立 refactors/001-商品基本資訊與標籤.md

# 範例 2：基於多個分析文件建立完整重構規格
/refactor.doc @002-MediaGallery.md @005-MediaCarousel.md
# → 自動建立 refactors/001-media-gallery.md

# 範例 3：使用相對路徑
/refactor.doc analysis/001-salepage/features/004-商品基本資訊與標籤.md
# → 自動建立 refactors/001-商品基本資訊與標籤.md

# 範例 4：使用絕對路徑
/refactor.doc /Users/susanhuang/Work/Projects/analysis-tool-kit/analysis/001-salepage/features/008-商品頁群組.md
# → 自動建立 refactors/001-商品頁群組.md
```

### 格式 2: 指定目標文件

```bash
# 範例 5：指定目標文件路徑
/refactor.doc refactors/001-media-gallery.md @002-MediaGallery.md
# → 使用指定的 refactors/001-media-gallery.md 作為目標文件

# 範例 6：更新現有文件
/refactor.doc refactors/001-media-gallery.md @002-MediaGallery.md @005-MediaCarousel.md
# → 更新 refactors/001-media-gallery.md（如果已存在）或建立新文件

# 範例 7：使用完整路徑指定目標文件
/refactor.doc /Users/susanhuang/Work/Projects/analysis-tool-kit/refactors/001-media-gallery.md analysis/001-salepage/features/008-商品頁群組.md
# → 使用指定的完整路徑作為目標文件
```

---

### 執行流程範例

**範例：執行 `/refactor.doc @004-商品基本資訊與標籤.md`**

**Step 1: Phase 0 - 環境設置**
```
✅ Phase 0.1: 環境變數驗證完成
   - REFACTOR_DOC_FILE = /Users/.../refactors/001-商品基本資訊與標籤.md
   - LEGACY_ANALYSIS_FILES = analysis/001-salepage/features/004-商品基本資訊與標籤.md
   - EXISTING_FILE = false (新建)
   - 文件格式: 格式 1 (自動生成)

✅ Phase 0.2: 核心規範文件讀取完成
   - ✅ refactor-constitution.md
   - ✅ refactor-coding-standard.md
   - ✅ refactor-template.md

✅ Phase 0.3: 源分析文件讀取完成
   - 檔案數量: 1 個
   - 總行數: 850 行

✅ Phase 0.4: 目標文件讀取完成
   - 範本結構: ✅ 完整
```

**Step 2: Phase 1.1 - 需求分析**
```
📊 需求分析摘要已生成

關鍵功能點: 5 項
API 端點: 2 個
資料結構: 3 個
UI 元件: 4 個

⏸️  請確認以上需求分析是否正確？
```

**使用者**: 確認

**Step 3: Phase 1.2 - Codebase 分析**
```
🔍 Codebase 分析結果

現有相關檔案:
- Service: services/product/get-product.service.ts (✅ 已存在)
- Hook: hooks/use-product.ts (❌ 不存在，需新建)

規劃新建檔案: 5 個
Server Components: 3 個
Client Components: 0 個

⏸️  請確認檔案規劃是否符合專案架構？
```

**使用者**: 確認

**Step 4: Phase 2 - 內容生成**
```
🎯 Phase 2 完成總結
   ✅ 已執行 23 次 search_replace
   ✅ 已填充 12 個章節
   ✅ 已標記 45 處 [從分析文件提取]
   ✅ 已標記 12 處 [技術棧轉換]
   ✅ 已保留 8 處 [待填寫]
```

**Step 5: Phase 3 - 品質保證**
```
🎯 Phase 3 完成總結
   ✅ 功能一致性比對完成 (7/7 項一致)
   ✅ 品質等級: ✅ 優秀（16/17 分）
   ✅ 比對報告已附加到文件末尾
```

**Step 6: Phase 4 - 完成報告**
```
╔════════════════════════════════════════════════════════╗
║          🎉 重構分析文件生成完成                          ║
╚════════════════════════════════════════════════════════╝

📁 重構文件路徑: /Users/.../refactors/001-商品基本資訊與標籤.md

🚀 可以開始重構實作！
```

## ⚠️ 常見錯誤與解決方案 (Common Errors & Solutions)

### 錯誤 1: Shell script 找不到

**錯誤訊息**：
```
看來 Shell script 不存在。讓我手動完成這個流程。
```

**原因**：
- AI 執行了錯誤的 script 名稱（例如：`analysis-refactor.sh` 而不是 `refactor-doc.sh`）
- Script 路徑不正確

**解決方案**：
- 確認指令中使用的 script 名稱正確：`refactor-doc.sh`
- 確認 script 位於 `.analysis-kit/scripts/refactor-doc.sh`
- 如果 script 不存在，檢查是否在正確的 Git 倉庫中執行

### 錯誤 2: 環境變數未設定

**錯誤訊息**：
```
如果 Shell script 未提供必要的環境變數，終止並回報錯誤
```

**原因**：
- Shell script 執行失敗
- 環境變數輸出格式錯誤

**解決方案**：
- 確認 Shell script 成功執行並輸出環境變數
- 檢查環境變數格式：
  ```
  REFACTOR_DOC_FILE='...'
  LEGACY_ANALYSIS_FILES='...'
  EXISTING_FILE='true' 或 'false'
  ```

### 錯誤 3: 目標文件路徑錯誤

**錯誤訊息**：
```
目標文件不存在或無法讀取
```

**原因**：
- 格式 2 時，目標文件路徑解析錯誤
- 目錄不存在

**解決方案**：
- Shell script 會自動建立目錄，確認有寫入權限
- 確認目標文件路徑為絕對路徑或正確的相對路徑

### 錯誤 4: 分析文件找不到

**錯誤訊息**：
```
File not found: ...
```

**原因**：
- 文件路徑錯誤
- 文件不存在於指定位置

**解決方案**：
- 確認所有分析文件路徑正確
- 使用絕對路徑或相對於專案根目錄的路徑
- 檢查文件是否確實存在

### 錯誤 5: 功能一致性比對遺漏

**錯誤訊息**：
```
功能一致性比對未執行
```

**原因**：
- AI 忘記執行比對步驟
- 比對報告格式不正確

**解決方案**：
- 確認 Phase 1 步驟 5 已執行
- 確認比對報告包含所有 7 個比對項目
- 確認報告格式符合範本要求

---

## 📋 執行檢查清單 (Execution Checklist)

### 執行前準備

執行此指令前，請確認：

- [ ] 功能分析文件（features/*.md 或 apis/*.md）已完成並經過 Review
- [ ] 已明確定義需要重構的功能範圍
- [ ] 已準備好所有源文件的完整路徑或 @ 引用
- [ ] 確認 Shell script 存在於 `.analysis-kit/scripts/refactor-doc.sh`

### 執行中檢查

AI 執行時會自動完成以下檢查（使用者無需手動操作）：

**Phase 0: 環境設置**
- [x] 驗證環境變數（`REFACTOR_DOC_FILE`、`LEGACY_ANALYSIS_FILES`、`EXISTING_FILE`）
- [x] 讀取 3 個核心規範文件
- [x] 讀取所有源分析文件
- [x] 確認目標文件已建立

**Phase 1: 需求分析與確認**
- [x] 提取功能需求並生成摘要
- [ ] **使用者確認**：需求分析是否正確？
- [x] 分析 Codebase 並規劃檔案結構
- [ ] **使用者確認**：檔案規劃是否符合專案架構？

**Phase 2: 內容生成**
- [x] 使用 `search_replace` 填充所有章節
- [x] 正確標記內容來源（`[從分析文件提取]` / `[技術棧轉換]` / `[待填寫]`）

**Phase 3: 品質保證**
- [x] 執行功能一致性比對（7 項）
- [x] 執行品質等級檢查（4 層，共 17 項）
- [x] 生成比對報告

**Phase 4: 完成報告**
- [x] 生成執行摘要
- [x] 提供後續建議

### 執行後驗證

執行完成後，請務必檢查：

#### 🔴 優先級 P0（必須立即處理）

- [ ] **檢視重構文件**：確認文件結構完整
- [ ] **檢查功能一致性比對報告**（文件第 15 節）：
  - 如有 ⚠️ 不一致項目，必須人工確認
  - 檢視所有比對項目的對應關係
- [ ] **檢視所有 `[待填寫]` 標記**：
  - 確認哪些是真正缺少資訊
  - 規劃如何補充這些資訊
- [ ] **驗證品質等級**：
  - 如果 < 12 分（需改善），檢視不合格項目
  - 特別注意 Level 3（技術規範）是否通過

#### 🟠 優先級 P1（重要但非緊急）

- [ ] **驗證所有 `[技術棧轉換]` 標記**：
  - 確認轉換理由合理
  - 檢查是否符合技術棧轉換對應表
- [ ] **補充相關文件連結**（第 3 節）：
  - Figma 設計稿連結
  - API 文件連結（如適用）
  - 相關 RFC 或技術文件
- [ ] **確認 API 規格**（第 5.4 節）：
  - 與後端工程師確認 API 端點
  - 確認請求/回應格式
  - 確認錯誤處理機制
- [ ] **驗證檔案路徑**（第 7 節）：
  - 確認所有路徑符合專案慣例
  - 確認目錄結構合理

#### 🟡 優先級 P2（建議處理）

- [ ] **Review 資料模型**（第 5.1 節）：
  - 確認 TypeScript 介面定義完整
  - 確認與後端 API 回應格式一致
- [ ] **確認狀態管理策略**（第 6 節）：
  - Server/Client Component 分離是否合理
  - Zustand store 設計是否必要
  - SWR 配置是否正確
- [ ] **補充測試策略**（第 12 節）：
  - 定義單元測試範圍
  - 定義整合測試案例
  - 定義 E2E 測試情境
- [ ] **完善驗收標準**（第 13 節）：
  - 確保所有標準可測試
  - 確保所有標準可驗證
  - 加入優先級標記

#### 🟢 優先級 P3（可選）

- [ ] **團隊 Code Review**：與團隊成員 Review 重構方向
- [ ] **技術預研**：對不確定的技術點進行 POC
- [ ] **風險評估**：識別重構過程中的潛在風險
- [ ] **排程規劃**：評估重構工作量並排程

### 常見問題檢查

執行過程中如遇到問題，請檢查：

1. **環境變數未設定**：
   - 檢查 Shell script 是否成功執行
   - 確認 script 路徑：`.analysis-kit/scripts/refactor-doc.sh`

2. **工具未實際執行**：
   - AI 是否輸出了 Phase 0 的檢查清單？
   - AI 是否使用了 `read_file` 工具？
   - AI 是否使用了 `search_replace` 工具？

3. **暫停點被跳過**：
   - 檢查 AI 是否在 Phase 1.1 和 1.2 後輸出確認訊息
   - 如果跳過，提醒 AI 遵守規則 7

4. **標記系統錯誤**：
   - 檢查是否出現 `[AI 建議]` 標記（應禁止）
   - 檢查是否正確使用 `[技術棧轉換]` 標記

5. **品質檢查未執行**：
   - 檢查文件是否包含第 15 節「功能一致性比對報告」
   - 檢查 AI 是否輸出品質等級評分

---

## 🎯 成功標準

重構分析文件視為成功完成，需滿足：

1. ✅ 所有 4 個 Phase 都已執行
2. ✅ 使用者已在 Phase 1 確認需求與規劃
3. ✅ 功能一致性比對結果：7/7 項一致或不一致項已標記
4. ✅ 品質等級：≥ 12 分（良好以上）
5. ✅ 所有內容都有正確的來源標記
6. ✅ 文件結構完整（所有章節都有內容）

**當以上條件都滿足後，即可開始重構實作！** 🚀

