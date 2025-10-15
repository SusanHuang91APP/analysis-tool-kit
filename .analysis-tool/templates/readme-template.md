# [頁面名稱] 分析

## 📋 分析資訊
- **分析編號**: [###]
- **分析主題**: [topic-name]
- **Git 分支**: analysis/[###]-[topic-name]
- **建立日期**: [YYYY-MM-DD]
- **當前狀態**: [階段狀態]

## 🎯 分析目標
[描述本次分析的目標與範圍]

---

## 🛠️ 技術棧 (Technology Stack)

**前端技術**：
- **View 引擎 / 框架**：[待補充]
- **狀態管理**：[待補充]
- **樣式方案**：[待補充]

**後端技術**：
- **框架**：[待補充]
- **語言版本**：[待補充]
- **ORM / 資料存取**：[待補充]

**資料庫**：
- [待補充]

**第三方服務**：
- [待補充]

---

## 📁 關鍵檔案 (Key Files)

**前端檔案**：
- **主要視圖 / 元件**：`[待補充]`
- **部分視圖 / 子元件**：`[待補充]`
- **前端邏輯**：`[待補充]`

**後端檔案**：
- **Controller / Route Handler**：`[待補充]`
- **Business Logic / Service**：`[待補充]`
- **Data Access**：`[待補充]`

**設定檔**：
- [待補充]

---

## 📂 目錄結構
```
[###]-[topic-name]/
├── README.md               # 本文件，分析總覽
├── architecture.md         # 功能架構分析（前端+後端）
├── view-*.md               # 前端視圖的詳細分析（.NET MVC / 任何 View）
├── component-*.md          # React/Vue 元件分析（視技術棧而定）
├── server-*.md             # 後端端點分析（若有後端檔案）
├── service-get-*.md        # Service 層 GET 方法分析
├── service-post-*.md       # Service 層 POST 方法分析
├── service-put-*.md        # Service 層 PUT 方法分析
└── service-delete-*.md     # Service 層 DELETE 方法分析
```

---

## 📊 分析階段與進度

### Phase 1: Architecture & Structure 階段
> **階段目標**: 建立功能架構分析，識別前後端元件，並自動建立所有框架檔案  
> **使用指令**: `/analysis-create "architecture" <source-files...>`  
> **支援技術棧**: .NET MVC, React, Vue, Node.js, Next.js 等  
> **💡 智能模式**: 支援增量執行，可分批分析大型專案

**工作範圍**:
- [ ] 初始化分析環境 (`/analysis-init`)
- [ ] 分析原始碼檔案（View/Controller/Component/API Route）
- [ ] 自動偵測技術棧並分類檔案
- [ ] 識別前端功能區塊/元件
- [ ] 識別後端 Actions/Endpoints（若有提供後端檔案）
- [ ] 創建 `architecture.md` (遵循 10 章節架構模板)
- [ ] 更新 `README.md` 的元件/端點清單
- [ ] 自動建立所有框架檔案（block/component/action）
- [ ] 填充關鍵資訊（HTML 結構、方法簽名、路由）

**不包含**:
- ❌ 詳細的業務邏輯實作分析
- ❌ 完整的 Service 依賴關係圖
- ❌ 深入的技術債分析
- ❌ 重構建議

**成果**:
- ✅ `architecture.md` - 包含 6 章節的架構深度分析
  - 章節 1: 前端架構（View/Component、狀態管理）
  - 章節 2: 後端架構（Controller/Route、授權）
  - 章節 3: 業務邏輯層（服務依賴、資料存取）
  - 章節 4: 資料流與整合（請求生命週期、快取）
  - 章節 5: 效能與安全性（指標、檢查清單）
  - 章節 6: 監控與改善（監控指標、技術債、改善建議）
- ✅ `README.md` - 完整的分析總覽與進度追蹤
  - 分析資訊（編號、主題、分支）
  - 技術棧資訊（前後端技術、資料庫、第三方服務）
  - 關鍵檔案清單
  - 元件/端點清單與進度狀態
  - 優先級定義與下一步行動指引
- ✅ 所有元件框架檔案 - 根據技術棧自動命名：
  - **前端**：`view-*.md` / `component-*.md` / `page-*.md`
  - **後端**：`server-*.md` / `service-get-*.md` / `service-post-*.md` / `service-put-*.md` / `service-delete-*.md`
- ✅ 已填充關鍵資訊：
  - 前端：HTML 結構 / Component 簽名
  - 後端：方法簽名 / 路由 / 授權屬性

**品質等級**: ⭐ 基礎框架級 (Foundation Level)

---

### Phase 2: Detail Analysis 階段
> **階段目標**: 補充各區塊的 Controller、Service 和詳細實作分析  
> **使用指令**: `/analysis-update <view-file>`

**工作範圍**:
- [ ] 補充 Controller 方法的完整程式碼與說明
- [ ] 補充 Service 依賴關係與 API 端點
- [ ] 補充完整的資料流向圖 (Mermaid)
- [ ] 補充完整的互動流程圖 (Mermaid Sequence Diagram)
- [ ] 補充狀態管理分析與狀態變數
- [ ] 補充架構品質分析 (CSS, a11y, 重用性)
- [ ] 提供重構建議與最佳實務評估

**品質等級提升路徑**:
- ⭐ → ⭐⭐ **UI層完成級**: 補充 HTML 結構與互動流程圖
- ⭐⭐ → ⭐⭐⭐ **邏輯層完成級**: 補充 Controller 方法與業務邏輯
- ⭐⭐⭐ → ⭐⭐⭐⭐ **架構層完成級**: 補充服務依賴與外部整合
- ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐ **深度分析完成級**: 提供重構建議與測試策略

**分析優先順序**: [根據項目需求定義，建議分為 P0/P1/P2]

---

## 🧩 功能元件清單

[本章節由 `/analysis-create` 自動生成]

### 前端元件 (Frontend Components)

**範例：**
| 編號 | 元件名稱 | 類型 | 優先級 | 階段狀態 | 檔案 |
|------|---------|------|--------|---------|------|
| 01 | 麵包屑導航 | view | P2 | 📝 框架建立 ⭐ | [view-###-name.md](./view-###-name.md) |
| 02 | 會員資料表單 | view | P1 | 🔄 邏輯分析 ⭐⭐⭐ | [view-###-name.md](./view-###-name.md) |
| 03 | 訂單歷史列表 | view | P0 | ✅ 深度分析 ⭐⭐⭐⭐⭐ | [view-###-name.md](./view-###-name.md) |

**範例說明**：
- **編號**: 流水號
- **元件名稱**: 視圖/元件的中文名稱
- **類型**: 
  - 前端：view（.NET MVC / 任何 View）/ component（React/Vue）/ page（Next.js）
  - 後端：server（端點）/ service-get（查詢）/ service-post（新增）/ service-put（更新）/ service-delete（刪除）
- **優先級**: P0（核心）/ P1（重要）/ P2（輔助）
- **階段狀態**: 根據分析的深度，對應 ⭐ 至 ⭐⭐⭐⭐⭐ 五個品質等級

### 後端端點 (Server Endpoints)

**範例：**
| 編號 | 端點名稱 | HTTP Method | 路由 | 優先級 | 階段狀態 | 檔案 |
|------|---------|-------------|------|--------|---------|------|
| 01 | 取得會員資料 | GET | /V2/VipMember/Profile | P0 | ✅ 深度分析 ⭐⭐⭐⭐⭐ | [server-###-name.md](./server-###-name.md) |
| 02 | 更新購物車 | POST | /api/cart/update | P1 | 🔄 架構分析 ⭐⭐⭐⭐ | [server-###-name.md](./server-###-name.md) |
| 03 | 取得商品推薦 | GET | /api/products/recommend | P2 | 📝 框架建立 ⭐ | [server-###-name.md](./server-###-name.md) |

**範例說明**：
- **編號**: 流水號
- **端點名稱**: Action/Endpoint 的功能名稱
- **HTTP Method**: GET / POST / PUT / DELETE
- **路由**: 完整的路由路徑
- **優先級**: P0（核心）/ P1（重要）/ P2（輔助）
- **階段狀態**: 根據分析的深度，對應 ⭐ 至 ⭐⭐⭐⭐⭐ 五個品質等級

### 階段狀態說明
- ✅ **深度分析 (⭐⭐⭐⭐⭐)**: 分析完整，包含重構建議、技術債與測試策略。
- 🔄 **架構分析 (⭐⭐⭐⭐)**: 已完成效能、安全性、錯誤處理與相依性分析。
- 🔄 **邏輯分析 (⭐⭐⭐)**: 已完成核心邏輯、服務依賴與資料存取。
- 🔄 **實作分析 (⭐⭐)**: 已完成 UI 結構或核心業務邏輯。
- 📝 **框架建立 (⭐)**: 已建立分析檔案，內容為基礎模板。
- ⏳ **待建立**: 框架檔案尚未建立。

---

## ⭐ 品質等級標準說明

本專案採用 5 級品質評估系統，不同類型的分析文件有各自的評級標準：

### 📊 Architecture Analysis (architecture.md)
> 系統架構的全面分析，涵蓋前後端架構、資料流、效能與安全性

| 等級 | 名稱 | 關鍵指標 |
|------|------|----------|
| ⭐ | 基礎框架級 | 前後端技術選型、基本路由、請求生命週期流程圖 |
| ⭐⭐ | 資料流程層級 | 資料初始化、狀態管理、前後端資料流、錯誤處理流程 |
| ⭐⭐⭐ | 業務邏輯層級 | 服務依賴、業務邏輯封裝、資料存取層、快取策略 |
| ⭐⭐⭐⭐ | 架構層級 | 授權、第三方整合、效能指標、安全性、技術債分析 |
| ⭐⭐⭐⭐⭐ | 深度分析級 | SEO 策略、監控指標、改善建議、完整技術債識別 |

**檢查重點**：前端技術 (1.1) / 後端架構 (2.1) / 路由配置 (2.2) / 資料流說明 (4.1) / 效能指標 (5.1) / 安全性檢查 (5.2)

---

### 🎨 View Analysis (view-*.md)
> 前端視圖/元件的 UI、互動、邏輯與架構分析

| 等級 | 名稱 | 關鍵指標 |
|------|------|----------|
| ⭐ | 基礎框架級 | 結構完整、基本功能描述、檔案連結、HTML 外層容器 |
| ⭐⭐ | UI層完成級 | HTML 結構分析、互動流程圖、CSS 樣式、無障礙性評估 |
| ⭐⭐⭐ | 邏輯層完成級 | Controller 方法、業務邏輯、資料流程圖、狀態管理 |
| ⭐⭐⭐⭐ | 架構層完成級 | 服務依賴、外部整合、效能考量、安全性評估 |
| ⭐⭐⭐⭐⭐ | 深度分析完成級 | 重構建議、技術債分析、測試策略、最佳實務評估 |

**檢查重點**：HTML 結構 (1.1) / 互動流程 (1.2) / Controller 方法 (2.1) / 資料流程 (2.3) / 服務依賴 (2.4) / 架構分析表格 (3)

---

### 🎮 Server Analysis (server-*.md)
> 後端 Action/Endpoint 的方法簽名、路由、業務邏輯與架構分析

| 等級 | 名稱 | 關鍵指標 |
|------|------|----------|
| ⭐ | 基礎框架級 | 方法簽名、路由資訊、授權屬性 |
| ⭐⭐ | 業務邏輯層級 | 核心流程、流程圖、ViewBag 設定 |
| ⭐⭐⭐ | 服務依賴層級 | 服務調用分析、資料處理、相依性清單 |
| ⭐⭐⭐⭐ | 架構層級 | 錯誤處理、效能評估、安全性檢查、相關 View 連結 |
| ⭐⭐⭐⭐⭐ | 深度分析級 | 測試覆蓋率、技術債識別、重構建議、API 文檔連結 |

**檢查重點**：方法簽名 (1.1) / 路由資訊 (1.2) / 核心流程 (2.1) / 服務調用 (2.2) / 錯誤處理 (3.1) / 安全性分析 (3.3)

---

### 🔧 Service Method Analysis (service-*.md)
> Service 層方法的簽名、業務邏輯、資料存取與快取策略分析

| 等級 | 名稱 | 關鍵指標 |
|------|------|----------|
| ⭐ | 基礎框架級 | 方法簽名、服務類別資訊、依賴注入列表 |
| ⭐⭐ | 業務邏輯層級 | 核心流程、流程圖、資料處理 |
| ⭐⭐⭐ | 資料存取層級 | Repository 調用、Service 調用、快取策略 |
| ⭐⭐⭐⭐ | 架構層級 | 錯誤處理、效能評估、安全性檢查、相依性分析 |
| ⭐⭐⭐⭐⭐ | 深度分析級 | 測試覆蓋率、技術債識別、Processor 模式、完整文檔 |

**檢查重點**：方法簽名 (1.1) / 服務類別 (1.2) / 核心流程 (2.1) / Repository 調用 (2.2) / 快取策略 (3.1) / 錯誤處理 (4.1)

---

### 📈 品質提升策略

**快速評估清單**：
- ✅ **⭐ → ⭐⭐**: 補充流程圖（Mermaid）和完整的結構說明
- ✅ **⭐⭐ → ⭐⭐⭐**: 補充業務邏輯、資料流程、服務調用
- ✅ **⭐⭐⭐ → ⭐⭐⭐⭐**: 補充效能分析、安全性檢查、相依性清單
- ✅ **⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐**: 補充測試策略、技術債、重構建議

**使用建議**：
1. **Phase 1 完成後**：所有文件都是 ⭐ 基礎框架級
2. **優先提升 P0 文件**：核心功能先達到 ⭐⭐⭐⭐ 架構層級
3. **P1 文件目標**：至少達到 ⭐⭐⭐ 業務邏輯/資料存取層級
4. **P2 文件可選**：保持 ⭐⭐ 或視需求提升

---

## 🎯 優先級說明

### P0 (最高優先) - 核心流程
**定義標準**：
- 影響主要業務流程的功能
- 用戶必經的關鍵路徑
- 系統的核心價值功能
- 若故障會導致系統無法使用

**範例**：
- 登入/註冊流程
- 商品下單流程
- 支付流程
- 訂單確認

### P1 (高優先) - 重要輔助功能
**定義標準**：
- 提升用戶體驗的重要功能
- 業務流程的輔助功能
- 常用的管理功能
- 若故障會影響部分功能

**範例**：
- 會員資料編輯
- 訂單歷史查詢
- 收藏/追蹤功能
- 通知中心

### P2 (中優先) - 輔助功能
**定義標準**：
- 非核心的便利功能
- 使用頻率較低的功能
- 輔助性的 UI 元件
- 若故障不影響主要業務

**範例**：
- 麵包屑導航
- 頁尾連結
- 社群分享按鈕
- 幫助提示

---

## 🚀 下一步行動

### ✅ 已完成階段
- ✅ **Phase 1**: Architecture & Structure 階段完成
  - `architecture.md` 已建立（包含 10 章節架構分析）
  - 所有元件/端點框架檔案已建立並填充關鍵資訊

### 🔜 Phase 2: 詳細分析階段

使用 `/analysis-update` 指令補充詳細分析。

**建議執行順序**:

#### Step 1: 核心功能 (P0) - 優先完成
```bash
# 範例 1: Auto-detection 模式（推薦）
/analysis-update Views/VipMember/Profile.cshtml Controllers/VipMemberController.cs

# 範例 2: Targeted update（針對特定元件）
/analysis-update "view-02-會員資料表單" Views/VipMember/Profile.cshtml
```

#### Step 2: 重要功能 (P1)
```bash
# 補充 P1 優先級元件的詳細分析
/analysis-update Views/Order/History.cshtml Controllers/OrderController.cs Services/OrderService.cs
```

#### Step 3: 輔助功能 (P2)
```bash
# 補充 P2 優先級元件的詳細分析
/analysis-update Views/Shared/_Breadcrumb.cshtml
```

**多技術棧範例**:
```bash
# React 專案
/analysis-update src/components/ProductList.tsx src/api/products.ts

# Vue 專案
/analysis-update src/views/Dashboard.vue src/api/users.js

# Next.js 專案
/analysis-update app/products/page.tsx app/api/products/route.ts
```

---

## 📖 使用說明

### 如何查找功能元件？
1. 查看 [architecture.md](./architecture.md) 了解整體架構
2. 根據元件/端點名稱找到對應的檔案：
   - 前端：`view-*.md` / `component-*.md` / `page-*.md`
   - 後端：`server-*.md` / `service-get-*.md` / `service-post-*.md` / `service-put-*.md` / `service-delete-*.md`
3. 閱讀元件文件了解詳細實作

### 如何新增分析內容？
1. 確保已執行 `/analysis-create` 建立架構和框架檔案
2. 使用 `/analysis-update <file>` 補充詳細分析（支援 view/component/server/service-get/service-post 等所有類型）
3. 根據模板章節補充內容
4. 更新本 README.md 的進度狀態

---

## 🔗 相關資源

### 主要檔案
- **View**: [列出主要 View 檔案路徑]
- **Controller**: [列出主要 Controller 檔案路徑]
- **Services**: [列出主要 Service 檔案路徑]

### 開發文件
[列出相關的開發文件連結]

---

## 📞 聯絡資訊
如有任何問題或建議，請聯絡：
- **維護團隊**: [Team Name]
- **最後更新**: [YYYY-MM-DD]

---

💡 **提示**: 
- **Phase 1 (Architecture & Structure)** 的重點是建立架構框架
  - 自動完成 `architecture.md` 和所有元件/端點檔案的建立
  - 支援多種技術棧（.NET MVC, React, Vue, Node.js, Next.js 等）
  - 自動填充關鍵資訊（HTML 結構、方法簽名、路由）
  - 不包含詳細的業務邏輯和 Service 分析
  - 所有檔案為 ⭐ 基礎框架級
- **Phase 2 (Detail Analysis)** 才會補充完整的實作細節
  - 使用 `/analysis-update` 指令來進行深度分析
  - 支援所有類型的檔案（view/component/server/service-get/service-post/service-put/service-delete 等）
  - 逐步提升品質等級 ⭐ → ⭐⭐ → ⭐⭐⭐ → ⭐⭐⭐⭐ → ⭐⭐⭐⭐⭐