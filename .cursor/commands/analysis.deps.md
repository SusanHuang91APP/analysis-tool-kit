---
description: 分析與分析檔案相關的原始碼，並更新「依賴關係」區塊，自動建立與現有分析文件的連結。
---

## 📥 輸入資料 (User Input)

此指令接受一個可選參數。

**`target_file` (可選)**：

- **格式**: 相對於專案根目錄的檔案路徑。
- **說明**: 
  - 指定要更新單一分析檔案 (`.md`) 的路徑。
  - 如果未提供此參數，指令將進入批次模式，處理當前 `Topic` 下 `overview.md` 中列出的所有檔案。

**`source-files...` (可選)**：

- **格式**: 一個或多個原始碼檔案路徑。
- **說明**: 
  - **僅在單一檔案模式下有效**。
  - 指令會先將這些原始碼檔案路徑添加到 `target_file` 的「分析檔案資訊」區塊，然後再進行依賴分析。

---

## 🚀 執行步驟 (Phases)

[ **CRITICAL**: 必須嚴格按照以下階段順序執行。]

### Phase 0: 腳本執行與上下文準備 (Script Execution & Context Preparation)

1.  **執行 Shell 腳本**: 根據使用者是否選擇了檔案，執行對應的腳本邏輯。此腳本負責準備所有 AI 分析所需的上下文。

    **單一檔案模式 (With File Selection)**
    ```bash
    {{#if selected_path}}
      ./.analysis-kit/scripts/analysis-deps.sh "{{selected_path}}"
    {{else}}
      echo "Info: No file selected. Proceeding with batch mode."
    {{/if}}
    ```

    **批次模式 (Without File Selection)**
    ```bash
    {{#unless selected_path}}
      ./.analysis-kit/scripts/analysis-deps.sh
    {{/unless}}
    ```

2.  **等待腳本輸出**: 腳本會為每個需要處理的檔案輸出一組 `=== Environment for AI ===` 區塊。AI 必須等待此輸出，並根據其內容進行後續操作。

### Phase 1: 依賴分析與連結 (Dependency Analysis & Linking)

[ **CRITICAL**: 這是此指令的核心 AI 任務。針對腳本輸出的 **每一個** `Environment for AI` 區塊，重複執行以下步驟。]

1.  **解析上下文**: 讀取腳本提供的 `TARGET_MD_FILE`, `SOURCE_CODE_FILES`, 和 `EXISTING_ANALYSIS_FILES` 環境變數。

2.  **分析原始碼**: 讀取 `SOURCE_CODE_FILES` 列表中的所有檔案內容。分析其依賴關係，例如：
    *   JavaScript/TypeScript 中的 `import` / `require` 陳述式。
    *   C# 中的 `using` 陳述式及建構函式中的依賴注入。
    *   繼承的基底類別或實現的介面。

3.  **交叉比對依賴**: 對於分析出的每一個依賴項，與 `EXISTING_ANALYSIS_FILES` 列表進行比對，找出是否有已存在的對應分析文件。
    *   例如：若找到 `DateHelper` 的依賴，則在列表中尋找 `.../helpers/001-date-helper.md` 這樣的檔案。

4.  **生成 Markdown 表格**: 建立一個符合分析範本格式的「依賴關係 (Dependencies)」表格，包含 `類型`、`名稱`、`用途`、`檔案連結` 等欄位。

5.  **建立相對連結**: 如果依賴項有對應的分析檔案，計算從 `TARGET_MD_FILE` 到該分析檔案的相對路徑，並生成一個 Markdown 連結。若無，則使用預設的 `[分析文件連結]` 佔位符。

6.  **更新檔案**: 使用 `edit_file` 工具，將 `TARGET_MD_FILE` 中 `### 1.2 📦 依賴關係 (Dependencies)` 標題下的**整個舊表格**替換為新產生的內容。

### Phase 2: 回報完成狀態 (Report)

1.  **確認產出**:
    - ✅ 確認所有目標檔案的 `依賴關係` 區塊都已被更新。
2.  **建議下一步**:
    - 🔜 請檢查更新後的檔案，確認依賴關係和連結是否正確。

---

## 🔑 關鍵規則 (Key Rules)

[ **CRITICAL**: AI 在執行所有步驟時必須遵守的規則。]

- **[規則 1]**: 必須使用 `edit_file` 進行檔案修改，嚴禁直接覆蓋整個檔案。
- **[規則 2]**: 更新時，必須精準地替換 `### 1.2 📦 依賴關係 (Dependencies)` 標題下的內容，不得影響檔案的其他部分。
- **[規則 3]**: 產生的檔案連結必須是相對於 `TARGET_MD_FILE` 的**相對路徑**。
- **[規則 4]**: 如果原始碼中沒有可識別的依賴，則應生成一個空的依賴表格或提示無依賴的訊息。

---

## 💡 使用範例

```bash
# 範例 1: 更新單一檔案
# 在編輯器中打開 analysis/001-trades-order-detail/features/001-訂單標頭與商品列表.md
# 然後執行指令
@analysis.deps analysis/001-trades-order-detail/client.md

# 範例 2: 更新當前 Topic 下的所有檔案
# 不打開任何特定檔案，直接執行指令
@analysis.deps

# 範例 3: 將新的原始碼檔案關聯到分析文件並更新依賴
@analysis.deps analysis/001-trades-order-detail/client.md "new/source/file.ts"
```
