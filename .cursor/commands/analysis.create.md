---
description: Create architecture analysis from source files (supports multiple tech stacks and incremental updates)
scripts:
  sh: .analysis-tool-kit/scripts/analysis-create.sh "{ARGS}"
  ps: .analysis-tool-kit/scripts/analysis-create.ps1 "{ARGS}"
---

## 📥 輸入資料 (Input Data)

**使用者參數**：`$ARGUMENTS` 的格式為 `<Type> <File 1> ... <File N>`

**Type (第一參數, 必需)**：
- `arch`: 創建或更新整體的 `architecture.md`，進行高層次分析。
- `view`: 分析前端 View/Component 檔案，更新 `README.md`，並建立 `view-*.md` 框架。
- `server`: 分析後端 Controller/Route 檔案，更新 `README.md`，並建立 `server-*.md` 框架。
- `service`: 分析後端 Service 檔案，更新 `README.md`，並建立 `service-*.md` 框架。

**重要**: 腳本已驗證 Type。你收到的 Type 一定是合法的。若使用者未提供 Type 或提供錯誤的 Type，腳本會自動中斷並提示，不會到達你這一步。

**支援的檔案類型**：
- **.NET MVC**：`.cshtml` (View), `.cs` (Controller, Service)
- **React/Node.js**：`.tsx`/`.jsx` (Component), `.ts`/`.js` (API Route, Service)
- **Vue**：`.vue` (Component)

---

## 🔄 執行流程 (Execution Flow)

### Step 1: 讀取所有必要檔案 (所有 Type 共通)

**使用 `read_file` 工具並行讀取**（一次性讀取所有檔案，不要逐一讀取）：

1.  **Source Files**：`$ARGUMENTS` 中指定的所有原始碼檔案。
2.  **Templates**: 根據分析類型讀取對應模板：
    -   `arch`: `.analysis-tool-kit/templates/architecture-template.md`
    -   `view`: `.analysis-tool-kit/templates/view-template.md`
    -   `server`: `.analysis-tool-kit/templates/server-template.md`
    -   `service`: `.analysis-tool-kit/templates/service-template.md`
3.  **Constitution**：`.analysis-tool-kit/memory/constitution.md`
4.  **Current README**：
    -   使用 `run_terminal_cmd` 執行：`git rev-parse --abbrev-ref HEAD` 獲取當前分支。
    -   從分支名稱 (`analysis/###-name`) 推導分析目錄，讀取 `README.md`。

---

### Step 2: 根據 Type 執行分析 (Execute Analysis based on Type)

**你必須根據腳本輸出中的 `Analysis type` 決定執行哪個路徑。所有操作都必須先更新 `README.md` 建立追蹤記錄，然後才建立或修改其他 `.md` 檔案。**

---

#### ➡️ Path A: if `Type` is `arch`

**🎯 目標**: 創建或更新 `architecture.md`，提供高層次的架構概覽。

1.  **分析原始碼**: 全面分析所有提供的檔案，理解技術棧、分層和主要設計模式。
2.  **創建/更新 `architecture.md`**:
    -   若檔案不存在，使用 `architecture-template.md` 創建。
    -   若已存在，讀取現有內容並**智能更新**，保留手動編輯，補充新的分析洞見。
    -   **不要**在此檔案中列出詳細的元件清單。元件清單由 `README.md` 管理。
3.  **更新 `README.md`**:
    -   更新「技術棧」和「關鍵檔案清單」區塊。
4.  **回報完成**:
    -   確認 `architecture.md` 已創建/更新。

---

#### ➡️ Path B: if `Type` is `view`

**🎯 目標**: 剖析 View 檔案，識別元件階層，更新 `README.md` 追蹤，並建立對應的分析框架檔案。

1.  **分析 View 檔案**:
    -   對所有提供的 `.cshtml`, `.tsx`, `.vue` 等檔案進行**階層式分析**。
    -   使用「自適應分析策略」識別**容器 (Container)** 和 **子元件 (Component)**。
2.  **更新 `README.md` (檔案追蹤)**:
    -   讀取現有的 `README.md`。
    -   找到「功能元件清單」區塊。
    -   將新識別的容器和元件**追加**到清單的表格中，維持階層結構和正確的編號。**必須保留所有已存在的項目**。
    -   使用 `edit_file` 精準地插入新內容。
3.  **執行腳本創建檔案**:
    -   **立即**使用 `run_terminal_cmd` 執行 `.analysis-tool-kit/scripts/analysis-create.sh --create-components`。此腳本會讀取更新後的 `README.md` 來建立檔案。
4.  **填充新檔案**:
    -   對於腳本新建立的 `view-###-*.md` 檔案，填充 Phase 1 的基礎資訊（外層 HTML 結構、上下文註解）。
5.  **回報完成**:
    -   報告新增了多少個 view 元件。
    -   確認 `README.md` 已更新。
    -   確認 `view-###-*.md` 檔案已建立並初步填充。

---

#### ➡️ Path C: if `Type` is `server`

**🎯 目標**: 剖析後端 Controller/Route 檔案，識別端點，更新 `README.md` 追蹤，並建立對應的分析框架檔案。

1.  **分析 Controller/Route 檔案**：從原始碼中識別所有公開的端點 (Actions/Routes)。
2.  **更新 `README.md` (檔案追蹤)**：讀取 `README.md`，找到「後端端點清單」區塊，並將新識別的端點追加到表格中。
3.  **執行腳本創建檔案**：立即執行 `.analysis-tool-kit/scripts/analysis-create.sh --create-components` 來建立 `server-###-*.md`。
4.  **填充新檔案**：填充 Phase 1 基礎資訊，如方法簽名、路由資訊、授權屬性等。
5.  **回報完成**: 報告新增的端點數量及更新狀態。

---

#### ➡️ Path D: if `Type` is `service`

**🎯 目標**: 剖析後端 Service 檔案，識別公開方法，更新 `README.md` 追蹤，並建立對應的分析框架檔案。

1.  **分析 Service 檔案**：從原始碼中識別所有公開的業務邏輯方法。
2.  **更新 `README.md` (檔案追蹤)**：讀取 `README.md`，找到「業務邏輯服務清單」區塊（若無則創建），並將新識別的方法追加到表格中。
3.  **執行腳本創建檔案**：立即執行 `.analysis-tool-kit/scripts/analysis-create.sh --create-components` 來建立 `service-###-*.md`。
4.  **填充新檔案**：填充 Phase 1 基礎資訊，如方法簽名、依賴注入等。
5.  **回報完成**: 報告新增的服務方法數量及更新狀態。

---

## 📝 重要提醒

- **嚴格遵守順序**: 永遠先更新 `README.md` 來追蹤變更，然後才執行 `--create-components` 或修改其他檔案。
- **階層式分析**: 分析 `view` 時，必須識別並在 `README.md` 中體現元件的父子關係。
- **精準編輯**: 使用 `edit_file` 更新 `README.md` 時，應盡可能小範圍地修改，避免破壞現有內容。
- **命名規範**: 所有 AI 創建的檔案名（`view-*.md`, `server-*.md` 等）都必須使用**中文**。

