# Commands Template

---

description: [指令的簡短描述，例如：初始化一個新的分析主題結構]
scripts:
sh: .analysis-kit/scripts/[script-name].sh "{ARGS}"
ps: .analysis-kit/scripts/[script-name].ps1 "{ARGS}"

---

## 📥 輸入資料 (User Input)

**使用者參數**：`$ARGUMENTS` 的格式為 `<param_1> [param_2] ...`

**`param_1` (必需/可選)**：

- **格式**: [說明格式]

- **說明**: [說明此參數的用途]

**`param_2` (必需/可選)**：

- **格式**: [說明格式]

- **說明**: [說明此參數的用途]



---

## 🚀 執行步驟 (Phases)

[ **CRITICAL**: 必須嚴格按照以下階段順序執行。]

### Phase 0: 設置與讀取上下文 (Setup & Context)

1. **驗證參數**: 檢查 `$ARGUMENTS` 是否符合本指令的格式要求。

2. **讀取上下文**:

   - 讀取 [constitution.md](.analysis-kit/memory/constitution.md) (憲法)。

   - (可選) 讀取當前 Topic 的 `[overview.md](overview.md)` (追蹤檔案)。

   - (可選) 讀取 `[source-files...]` (原始碼)。

### Phase 1: 核心任務執行 (Core Task Execution)

[ **CRITICAL**: 這是此指令的主要工作。]

1. **[動作 1]**: [說明此階段的核心動作，例如：根據範本建立新檔案 `create_file ...`]

2. **[動作 2]**: [說明此階段的核心動作，例如：分析原始碼並使用 `edit_file` 填充內容...]

3. **[動作 3]**: [說明此階段的其他動作...]

### Phase 2: 更新追蹤檔案 (Update Manifest)

1. **[動作 1]**: [說明此階段的追蹤動作，例如：讀取 `[overview.md](overview.md)`]

2. **[動作 2]**: [說明此階段的追蹤動作，例如：使用 `edit_file` 精準地將新檔案或狀態更新回 `[overview.md](overview.md)` 的追蹤表格中]

### Phase 3: 回報完成狀態 (Report)

1. **確認產出**:

   - ✅ [確認事項 1，例如：已建立/更新的目標檔案]

   - ✅ [確認事項 2，例如：確認 `[overview.md](overview.md)` 進度已同步]

2. **建議下一步**:

   - 🔜 [建議的下一步行動，例如：請執行 `/analysis.create` 來建立 feature 檔案]



---

## 🔑 關鍵規則 (Key Rules)

[ **CRITICAL**: AI 在執行所有步驟時必須遵守的規則。]

- **[規則 1]**: [例如：必須使用 `edit_file` 進行檔案修改，嚴禁直接覆蓋整個檔案。]

- **[規則 2]**: [例如：所有檔案路徑必須使用相對於專案根目錄的絕對路徑。]

- **[規則 3]**: [例如：如果 `[overview.md](overview.md)` 不存在或找不到對應項目，必須回報 `ERROR` 並中斷。]

- **[規則 4]**: [例如：填充內容時，必須精準替換 `[待補充]` 佔位符，不得刪除其他章節。]



---

## 💡 使用範例

```bash
# 範例 1 說明
/command [param_1] [param_2]

# 範例 2 說明
/command [param_1] [param_3] [param_4]
```