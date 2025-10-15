---
description: Update analysis content by adding detailed information to existing blocks
scripts:
  sh: .analysis-tool-kit/scripts/analysis-update.sh "{ARGS}"
  ps: .analysis-tool-kit/scripts/analysis-update.ps1 "{ARGS}"
---

## 📥 輸入資料

**使用者參數**：`$ARGUMENTS` 的格式為 `"target_analysis_file" <source_file_1> ... <source_file_N>`

**`target_analysis_file` (第一參數, 必需)**：
-   **格式**: `"view-###-功能名稱"` 或 `"server-###-端點名稱"` 等。
-   **驗證**: 腳本已強制此參數存在，並且對應的 `.md` 檔案必須已存在於 `analysis/###-name/` 目錄中。如果檔案不存在，腳本會中斷並提示使用者。你無需再次驗證。

**`source_files` (後續參數, 必需)**：
-   一個或多個用於分析並填充到 `target_analysis_file` 的原始碼檔案路徑。

---

## 🔄 執行流程

### Step 1: 讀取所有必要檔案

**使用 `read_file` 工具並行讀取**（一次性讀取所有檔案）：

1.  **Source Files**: `$ARGUMENTS` 中指定的所有原始碼檔案。
2.  **Target Analysis File**: 腳本輸出中 `Target file` 所指向的 `.md` 檔案。
3.  **Constitution**: `.analysis-tool-kit/memory/constitution.md`
4.  **README.md**: 從當前 Git 分支推導出的 `analysis/###-name/README.md`。

---

## 🎯 Phase 2: Detail Analysis 階段目標

**此階段的任務**：根據提供的原始碼，填充**指定的**分析檔案 (`target_analysis_file`) 的詳細內容，將其品質等級從 ⭐ 基礎框架級提升至更高層級。

### 你的工作範圍：

1.  **分析原始碼**: 深入分析所有提供的原始碼檔案。
2.  **內容填充**: 將分析結果（程式碼片段、業務邏輯、Mermaid 圖表等）填充到 `target_analysis_file` 中對應章節的 `[待補充]` 區塊。
3.  **品質提升**: 根據填充的內容，更新 `target_analysis_file` 末尾的品質等級檢查清單，自動勾選已完成的項目。
4.  **進度同步**: 更新 `README.md` 中對應檔案的狀態和品質等級。

---

## 🚀 執行步驟（CRITICAL - 必須按順序完成）

### Step 1: 分析原始碼並更新目標檔案

-   **讀取目標檔案內容**: 首先讀取 `target_analysis_file` 的現有內容。
-   **分析原始碼**: 根據提供的原始碼檔案類型（View, Controller, Service），決定要更新目標檔案的哪些章節。
    -   **若提供 View 檔案** (`.cshtml`, `.tsx`): 專注更新目標檔案中的 `1. 介面與互動分析` 章節，例如填充 `1.1 元件結構` 的詳細 HTML 和 `1.2 互動流程` 的 Mermaid 圖。
    -   **若提供 Controller 檔案** (`*Controller.cs`): 專注更新目標檔案中的 `2. 實作細節分析` 章節，例如填充 `2.1 對應 Controller 方法` 的程式碼片段和說明。
    -   **若提供 Service 檔案** (`*Service.cs`): 專注更新 `2.4 相依服務與工具` 和 `3. 架構與品質分析` 章節。
-   **執行更新**: 使用 `edit_file` 工具，將分析出的具體程式碼和說明文字，精準地替換掉 `target_analysis_file` 中對應的 `[待補充]` 佔位符。**一次 `edit_file` 呼叫中可以包含對多個章節的修改**。

---

### Step 2: 自動更新品質檢查清單

**CRITICAL**: 在更新完內容後，你**必須**在同一個 `edit_file` 操作中，一併更新檔案末尾的品質檢查清單。

-   **更新規則**:
    -   如果某個章節的內容從 `[待補充]` 變為具體的分析文字或程式碼，就將其對應的檢查項目從 `[ ]` 更新為 `[x]`。
    -   根據勾選的項目數量，更新文件底部的 `品質等級` 描述（例如，從 `⭐ 基礎框架級` 提升到 `⭐⭐⭐ 邏輯層完成級`）。

---

### Step 3: 更新 README.md 進度

在目標檔案被更新後，同步更新 `README.md` 中的追蹤表格。

-   **找到對應行**: 在 `README.md` 的元件/端點清單中，找到與 `target_analysis_file` 對應的那一列。
-   **更新狀態**: 修改該列的「狀態」欄位，以反映新的品質等級。例如，從 `📝 框架完成 ⭐` 更新為 `⭐⭐⭐ 邏輯層完成`。
-   **使用 `edit_file`** 精準地完成此項替換。

---

### Step 4: 回報完成狀態

確認並列出：
-   ✅ 已更新的目標檔案名稱。
-   ✅ 已更新的主要章節清單。
-   ✅ 品質等級的變化（例如：⭐ → ⭐⭐⭐）。
-   ✅ 確認 `README.md` 進度已同步。
-   🔜 建議下一步行動（例如：分析下一個檔案，或執行 `/analysis-refactor`）。

---

## 💡 使用範例

```bash
# 針對 "view-05-會員資料表單.md"，使用 Controller 檔案來填充其「實作細節」章節
/analysis-update "view-05-會員資料表單" Controllers/VipMemberController.cs

# 針對 "server-02-更新個人資料.md"，使用 Service 檔案來填充其「服務調用」和「業務邏輯」章節
/analysis-update "server-02-更新個人資料" Services/VipMemberService.cs
```

---

**執行邏輯示意**：
```
AI 收到指令 (包含目標檔案名和原始碼路徑)
  ↓
讀取指定的目標分析檔案 + 原始碼檔案 + README.md
  ↓
分析原始碼，準備填充內容
  ↓
使用 edit_file 更新目標分析檔案:
  1. 填充內容到對應章節
  2. 自動勾選品質檢查清單
  3. 更新文件底部的品質等級文字
  ↓
使用 edit_file 更新 README.md 中的追蹤狀態
  ↓
回報完成
```
---

Focus on substantially improving the quality level of a *specific* analysis file. Remember: **Phase 2 is about depth and detail, transforming placeholders into comprehensive analysis for a designated target.**
