---
description: 深度分析並更新現有的分析檔案，提升品質等級並自動同步 overview.md
scripts:
  sh: .analysis-kit/scripts/analysis-analyze.sh "{ARGS}"
  ps: .analysis-kit/scripts/analysis-analyze.ps1 "{ARGS}"
---

## 📥 輸入資料 (User Input)

**使用者參數**：`$ARGUMENTS` 的格式為 `[target_file] [source-files...]`

**`target_file` (可選)**：

- **格式**: 要更新的分析檔案名稱或路徑
- **說明**: 
  - 指定要更新的單一分析檔案。腳本會自動在當前 Topic 目錄下搜尋對應的 `.md` 檔案。
  - **若省略此參數，指令將進入批次模式**，自動分析 `overview.md` 中列出的所有檔案。
- **範例**:
  - `"features/001-會員註冊"`
  - `"server.md"`

**`source-files...` (可選)**：

- **格式**: 一個或多個原始碼檔案路徑
- **說明**:
  - 在**單一檔案模式**下，提供這些原始碼檔案供 AI 進行深度分析。
  - 在**批次模式**下，此參數會被忽略，AI 會自動從每個 `.md` 檔案的「分析檔案資訊」區塊尋找原始碼。
- **支援的檔案類型**:
  - **.NET MVC**: `.cshtml`, `.cs` (Controller, Service, Filter, Utility)
  - **React/Node.js**: `.tsx`, `.jsx`, `.ts`, `.js`
  - **Vue**: `.vue`

---

## 📊 流程概覽 (Flow Overview)

```mermaid
flowchart TD
    Start([開始執行]) --> ValidateArgs[驗證參數<br/>target_file + source-files]
    ValidateArgs --> RunScript[執行腳本<br/>analysis-analyze.sh]
    
    RunScript --> CheckResult{腳本執行<br/>成功?}
    CheckResult -->|失敗| Error[回報錯誤訊息]
    CheckResult -->|成功| ParseEnv[解析環境變數<br/>TARGET_FILE<br/>OVERVIEW_FILE]
    
    ParseEnv --> ReadContext[讀取必要檔案<br/>constitution.md<br/>目標分析檔案<br/>overview.md<br/>原始碼]
    
    ReadContext --> AnalyzeSource{分析原始碼<br/>類型}
    
    AnalyzeSource -->|View 檔案| UpdateUI[更新介面分析<br/>HTML 結構<br/>互動流程圖<br/>CSS 樣式]
    AnalyzeSource -->|Controller 檔案| UpdateController[更新實作細節<br/>Controller 方法<br/>路由授權<br/>請求處理]
    AnalyzeSource -->|Service 檔案| UpdateService[更新業務邏輯<br/>服務方法<br/>依賴注入<br/>資料處理]
    AnalyzeSource -->|Component 檔案| UpdateComponent[更新元件結構<br/>Props/State/Events<br/>生命週期<br/>狀態管理]
    
    UpdateUI --> SmartFill[智能填充內容<br/>替換 待補充]
    UpdateController --> SmartFill
    UpdateService --> SmartFill
    UpdateComponent --> SmartFill
    
    SmartFill --> CheckConstitution{遵循<br/>Constitution?}
    CheckConstitution -->|否| FixContent[修正內容]
    FixContent --> CheckConstitution
    CheckConstitution -->|是| TrackDeps[追蹤依賴注入<br/>檢查 overview.md]
    
    TrackDeps --> UpdateChecklist[更新品質檢查清單<br/>計算完成度]
    
    UpdateChecklist --> CalcQuality{計算品質等級}
    CalcQuality -->|0%| Q0[📝 待分析]
    CalcQuality -->|1-40%| Q1[⭐ 基礎框架]
    CalcQuality -->|41-70%| Q3[⭐⭐⭐ 邏輯完成]
    CalcQuality -->|71-90%| Q4[⭐⭐⭐⭐ 架構完整]
    CalcQuality -->|91-100%| Q5[⭐⭐⭐⭐⭐ 完整分析]
    
    Q0 --> CheckDeps{所有依賴<br/>已分析?}
    Q1 --> CheckDeps
    Q3 --> CheckDeps
    Q4 --> CheckDeps
    Q5 --> CheckDeps
    
    CheckDeps -->|否| LimitQuality[限制品質等級<br/>最高 ⭐⭐⭐]
    CheckDeps -->|是| SyncOverview[同步 overview.md<br/>更新品質欄位]
    LimitQuality --> SyncOverview
    
    SyncOverview --> Report[回報完成狀態<br/>更新章節清單<br/>品質等級變化<br/>完成度百分比]
    
    Report --> SuggestNext{品質等級<br/>已達標?}
    SuggestNext -->|否| SuggestMore[建議提供更多<br/>原始碼或分析依賴]
    SuggestNext -->|是| SuggestContinue[建議繼續分析<br/>其他檔案]
    
    Error --> End([結束])
    SuggestMore --> End
    SuggestContinue --> End
    
    style Start fill:#e1f5e1
    style End fill:#ffe1e1
    style RunScript fill:#e3f2fd
    style SmartFill fill:#e1bee7
    style UpdateChecklist fill:#c5e1a5
    style SyncOverview fill:#fff9c4
    style CheckResult fill:#fff3e0
    style CheckConstitution fill:#fff3e0
    style CalcQuality fill:#fff3e0
    style CheckDeps fill:#fff3e0
    style SuggestNext fill:#fff3e0
    style Error fill:#ffcdd2
    style Q3 fill:#ffeb3b
    style Q4 fill:#ffc107
    style Q5 fill:#ff9800
```

---

## 🚀 執行步驟 (Phases)

[ **CRITICAL**: 必須嚴格按照以下階段順序執行。]

### Phase 0: 設置與讀取上下文 (Setup & Context)

1. **驗證參數**: 檢查 `$ARGUMENTS` 包含目標檔案名稱。

2. **執行分析腳本**:
   
   使用 `run_terminal_cmd` 執行：
   ```bash
   .analysis-kit/scripts/analysis-analyze.sh <target_file> [source-files...]
   ```
   
   腳本會執行：
   - ✅ 驗證目標檔案存在
   - ✅ 在當前 Topic 目錄下尋找檔案
   - ✅ 確定對應的 overview.md
   - ✅ 分類原始碼檔案（View/Controller/Service/Component）
   - ✅ 輸出環境變數供 AI 使用

3. **讀取必要檔案**:

   - 讀取 `.analysis-kit/memory/constitution.md` (分析規則憲法)
   - 讀取目標分析檔案（腳本輸出的 `TARGET_FILE`）
   - 讀取對應的 `overview.md`（腳本輸出的 `OVERVIEW_FILE`）
   - 讀取所有提供的原始碼檔案

### Phase 1: 深度分析與智能填充 (Deep Analysis & Smart Filling)

[ **CRITICAL**: 這是此指令的核心工作，需要根據 constitution.md 進行高品質分析。]

**1. 分析原始碼並規劃更新**:

[ **CRITICAL**: 必須完整保留目標檔案的所有章節結構，只針對性更新能從原始碼分析到的章節。]

**分析原則**:
- ✅ **保留所有章節**: 目標檔案中的所有章節必須完整保留
- ✅ **選擇性更新**: 只更新能從提供的原始碼中分析到的章節
- ✅ **保持佔位符**: 無法分析的章節保持 `[待補充]` 狀態或原有內容不變
- ✅ **不刪除已有內容**: 已填充的章節不應被刪除或覆蓋，除非有新資訊可以更新
- ❌ **禁止推測**: 絕對禁止根據部分資訊推測未提供檔案的實作細節

**檔案類型與可更新章節對應**:

| 原始碼類型 | 可更新的章節 | 保持原狀的章節 |
|-----------|-------------|----------------|
| `.cshtml` (View) | 介面分析、HTML 結構、前端互動、UI 元件 | Controller 實作、Service 層、API 規格 |
| `*Controller.cs` | 路由分析、Controller 方法、授權、請求處理 | View 層細節、Service 實作細節 |
| `*Service.cs` | 業務邏輯、方法實作、依賴注入、資料處理 | View 層、Controller 層 |
| `.tsx`/`.jsx` | 元件結構、Props/State、Hooks、前端邏輯 | 後端 API、Server 層 |
| `*/api/*.ts` | API 規格、Request/Response、路由 | View 層、UI 互動 |

根據原始碼檔案類型，決定要更新目標檔案的哪些章節：

- **View 檔案** (`.cshtml`, `.tsx`, `.vue`):
  - 更新「介面分析」章節
  - 填充 HTML 結構分析
  - 繪製互動流程 Mermaid 圖
  - 分析 CSS 樣式和響應式設計
  - **保留**「Controller 實作」、「Service 層」等後端章節
  
- **Controller 檔案** (`*Controller.cs`, `*/api/*.ts`):
  - 更新「實作細節分析」章節
  - 填充 Controller 方法分析
  - 追蹤路由和授權屬性
  - 分析請求/回應處理
  - **保留**「介面分析」、「Service 實作」等其他層章節
  
- **Service 檔案** (`*Service.cs`, `*Service.ts`):
  - 更新「業務邏輯」章節
  - 填充服務方法分析
  - 追蹤依賴注入
  - 分析資料處理和驗證
  - **保留**「介面分析」、「Controller 層」等其他層章節
  
- **Component 檔案** (`.tsx`, `.jsx`, `.vue`):
  - 更新「元件結構」章節
  - 分析 Props/State/Events
  - 追蹤生命週期和 Hooks
  - 分析狀態管理
  - **保留**後端相關章節

**範例**:
```markdown
# 若只提供 TradesOrderDetail.cshtml 進行分析

## 介面分析
[更新: 詳細的 HTML 結構、AngularJS 指令分析、Mermaid 流程圖]

## Controller 實作
[待補充]  # ← 保持此狀態，因為未提供 Controller 檔案

## 業務邏輯
[待補充]  # ← 保持此狀態，因為未提供 Service 檔案
```

**2. 智能填充內容**:

使用 `search_replace` 工具，精準替換 `[待補充]` 佔位符：

- **程式碼片段**: 使用適當的語法高亮標記（```csharp, ```typescript 等）
- **Mermaid 圖表**: 
  - 流程圖 (`flowchart TD`)
  - 序列圖 (`sequenceDiagram`)
  - 類別圖 (`classDiagram`)
- **說明文字**: 清晰、具體、有見地的分析
- **連結追蹤**: 建立到相關分析檔案的連結

**3. 遵循 Constitution.md 規範**:

- ✅ 分析深度標準：根據目標品質等級提供相應深度
- ✅ 命名規範：使用一致的術語和格式
- ✅ Mermaid 圖表規範：遵循繪製標準
- ✅ 程式碼摘錄原則：選取關鍵程式碼並加註解
- ✅ 架構模式識別：識別 MVC、DDD、Clean Architecture 等

**4. 依賴注入追蹤**:

- 掃描分析內容中提及的所有服務、元件、工具類別
- 檢查 overview.md 中是否已註冊對應的分析檔案
- 若依賴項未分析，在「依賴關係」章節中標記並建議建立

### Phase 2: 更新品質檢查清單 (Update Quality Checklist)

[ **CRITICAL**: 必須在同一次操作中更新品質檢查清單。檢查清單的文字內容來自範本，**不可修改**，AI 的唯一任務是根據分析進度將 `[ ]` 更新為 `[x]`。]

**1. 更新檢查項目**:

根據已填充的章節，將品質檢查清單從 `[ ]` 更新為 `[x]`：

```markdown
## 品質檢查清單

### ⭐ 基礎框架級（1-40%）
- [x] **結構完整**: 所有必要章節都已建立
- [x] **基本功能描述**: 已填寫功能概述和基本說明
- [x] **檔案連結**: 相關檔案連結已建立

### ⭐⭐⭐ 邏輯層完成級（41-70%）
- [x] **介面分析**: HTML 結構和互動流程已完成
- [x] **互動流程圖**: Mermaid 圖表已繪製
- [ ] **實作細節**: Controller/API 方法已分析
- [ ] **業務邏輯**: 核心邏輯已說明

### ⭐⭐⭐⭐ 架構層完成級（71-90%）
- [ ] **依賴注入**: 所有相依服務已追蹤分析
- [ ] **架構模式**: 已識別設計模式
- [ ] **資料流向**: 完整的資料流程已記錄

### ⭐⭐⭐⭐⭐ 完整分析級（91-100%）
- [ ] **最佳實踐**: 已提供改進建議
- [ ] **效能考量**: 已評估效能影響
- [ ] **安全性評估**: 已分析安全性考量
```

**2. 計算完成度百分比**:

```
完成百分比 = (已勾選項目數 / 總項目數) × 100
```

**3. 確定品質等級**:

- 0% → 📝 待分析
- 1-40% → ⭐ 基礎框架
- 41-70% → ⭐⭐⭐ 邏輯完成
- 71-90% → ⭐⭐⭐⭐ 架構完整（需確認所有依賴已分析）
- 91-100% → ⭐⭐⭐⭐⭐ 完整分析

### Phase 3: 同步 overview.md (Sync Overview)

[ **CRITICAL**: 必須同步更新 overview.md 的品質等級欄位。]

**1. 讀取 overview.md**: 讀取對應的 overview.md（Topic 或 Shared）

**2. 更新品質等級**:

找到目標檔案在「分析檔案清單」表格中的條目，更新品質等級欄位：

```markdown
## 📂 分析檔案清單

| 檔案 | 品質等級 |
|------|----------|
| [server.md](./server.md) | ⭐⭐⭐ 邏輯完成 |
| [features/001-會員註冊](./features/001-會員註冊.md) | ⭐⭐⭐⭐⭐ 完整分析 |
```

**3. 使用 `search_replace` 精準更新**: 只更新對應檔案的那一列品質等級

### Phase 4: 回報完成狀態 (Report)

1. **確認產出**:

   - ✅ 已更新檔案：`<TARGET_FILE>`
   - ✅ 更新的主要章節：列出已填充的章節清單
   - ✅ 品質等級變化：`<OLD_LEVEL> → <NEW_LEVEL>`
   - ✅ 完成度百分比：`<PERCENTAGE>%`
   - ✅ overview.md 已同步：確認
   - ✅ 依賴項檢查：列出未分析的依賴項（若有）

2. **建議下一步**:

   - 🔜 若品質等級未達 ⭐⭐⭐⭐⭐，建議：
     - 提供更多原始碼檔案再次執行 `/analysis.analyze`
     - 或分析依賴的服務/元件檔案
   
   - 🔜 若品質等級已達目標：
     - 繼續分析其他檔案
     - 或進入重構階段（若所有分析完成）
   
   - 📝 若發現未分析的依賴項：
     - 建議使用 `/analysis.create` 建立對應的分析檔案

---

## 🔑 關鍵規則 (Key Rules)

[ **CRITICAL**: AI 在執行所有步驟時必須遵守的規則。]

- **規則 1**: 必須使用 `search_replace` 進行檔案修改，嚴禁直接覆蓋整個檔案。

- **規則 1.1** [ **CRITICAL** ]: **完整保留所有章節結構**。絕對不能刪除或跳過目標檔案中的任何章節，即使該章節無法從提供的原始碼中更新。無法更新的章節必須保持原狀（`[待補充]` 或已有內容）。

- **規則 1.2** [ **CRITICAL** ]: **選擇性更新原則 + 禁止推測**。只更新能從提供的原始碼中明確分析到的章節：
  - 若只提供 `.cshtml` 檔案 → 只更新介面分析相關章節，保留 Controller、Service 章節不變
  - 若只提供 `*Controller.cs` → 只更新 Controller 實作章節，保留 View、Service 章節不變
  - 若只提供 `*Service.cs` → 只更新業務邏輯章節，保留 View、Controller 章節不變
  - **禁止根據前端程式碼推測後端 API 實作細節**
  - **禁止根據 Controller 推測 Service 層實作邏輯**
  - **只記錄原始碼中能明確看到的事實**，不寫入任何推測性內容
  - 以此類推

- **規則 2**: 填充內容時，必須精準替換 `[待補充]` 佔位符，不得刪除其他章節。

- **規則 3**: 所有 Mermaid 圖表必須語法正確且有意義，不要使用佔位符範例。

- **規則 4**: 程式碼片段必須來自實際原始碼，不要編造或簡化過度。

- **規則 5**: 品質檢查清單必須在同一次 `search_replace` 操作中更新。

- **規則 5.1** [ **CRITICAL** ]: **嚴格遵守品質檢查清單範本**。AI **嚴禁**修改、增加或刪除品質檢查清單中的任何文字項目。唯一的任務是根據分析進度，將對應項目的狀態從 `[ ]` 更新為 `[x]`。

- **規則 6**: overview.md 的品質等級必須與目標檔案的品質檢查清單一致。

- **規則 7**: 依賴注入檢查機制：
  - 若依賴項未分析，品質等級最高只能到 ⭐⭐⭐（邏輯完成）
  - 所有依賴項都已分析完成，才能達到 ⭐⭐⭐⭐（架構完整）或更高

- **規則 8**: 若 source-files 未提供或不足，AI 應基於檔案現有內容進行優化和補充。

- **規則 9**: 所有檔案路徑必須使用腳本輸出的絕對路徑。

- **規則 10**: 遵循 constitution.md 定義的所有分析標準和規範。

- **規則 11**: **模板章節不變原則**：嚴格禁止新增或刪除任何 `template` 中預先定義的章節。分析內容必須填充至既有結構中。

- **規則 12**: **來源檔案限定原則**：分析範圍嚴格限定於使用者提供的原始碼檔案 (`source-files`)，以及目標分析檔案 `### 1.1 📂 分析檔案資訊 (Analyzed Files)` 中已標記的檔案。嚴禁分析任何未明確指定的檔案。

- **規則 13**: **未知依賴處理**：若在分析過程中發現未提供的依賴檔案（例如某個 Service 或 Component），應在 `### 1.2 📦 依賴關係 (Dependencies)` 表格中註記，而非試圖分析它。

- **規則 14**: **品質等級不變原則**：嚴格禁止新增、刪除或修改 `## 📋 品質檢查清單` 中的檢查項目文字或品質等級定義。AI 的唯一任務是根據分析進度更新核取方塊 `[ ]` -> `[x]`。

---

## 💡 使用範例

```bash
# 範例 1: 分析單一功能檔案（提供多個原始碼）
/analysis.analyze "features/001-會員註冊" \
  Controllers/MemberController.cs \
  Services/MemberService.cs \
  Views/Member/Register.cshtml

# 範例 2: 更新 server.md
/analysis.analyze "server.md" Controllers/HomeController.cs

# 範例 3: 批次分析當前 Topic 的所有檔案
# 指令會自動讀取 overview.md，並分析其中每個檔案關聯的原始碼
/analysis.analyze
```

---

## 📊 品質等級詳解

### 📝 待分析 (0%)
- 檔案剛建立，所有章節都是 `[待補充]`
- 尚未進行任何實質分析

### ⭐ 基礎框架 (1-40%)
- 基本章節結構完整
- 已填寫功能概述和檔案連結
- 部分章節仍為 `[待補充]`

### ⭐⭐⭐ 邏輯完成 (41-70%)
- 主要業務邏輯已分析
- 互動流程圖已繪製
- 核心程式碼片段已註解
- 部分架構層分析仍待補充

### ⭐⭐⭐⭐ 架構完整 (71-90%)
- 所有依賴注入已追蹤分析
- 架構模式已識別
- 資料流向清晰完整
- 僅缺少最佳實踐建議

### ⭐⭐⭐⭐⭐ 完整分析 (91-100%)
- 所有章節完成
- 包含 Mermaid 圖表
- 提供最佳實踐建議
- 效能和安全性評估完整

---

## 🎯 分析策略建議

### 循序漸進策略
1. **第一次分析**: 提供 View 檔案，達到 ⭐⭐⭐ (UI 層完成)
2. **第二次分析**: 提供 Controller 檔案，達到 ⭐⭐⭐⭐ (邏輯層完成)
3. **第三次分析**: 提供 Service 檔案，達到 ⭐⭐⭐⭐⭐ (架構完整)

### 一次性完整分析
- 同時提供所有相關原始碼檔案
- AI 會進行全面分析
- 一次達到 ⭐⭐⭐⭐ 或 ⭐⭐⭐⭐⭐

### 優化既有分析
- 不提供新的原始碼檔案
- AI 基於現有內容進行優化
- 補充缺失的圖表或說明

---

## ⚠️ 錯誤處理

如果腳本執行失敗，可能的原因：

1. **目標檔案不存在**: 先使用 `/analysis.create` 建立檔案
2. **不在 analysis 分支上**: 先執行 `/analysis.init`
3. **原始碼檔案不存在**: 確認檔案路徑正確
4. **overview.md 不存在**: 環境可能未正確初始化

如果分析品質無法提升：

1. **原始碼不足**: 提供更多相關原始碼檔案
2. **依賴項未分析**: 先分析依賴的服務/元件
3. **範本不完整**: 檢查範本檔案是否有品質檢查清單

AI 應將所有錯誤訊息和建議清楚回報給使用者。

