# 前端重構憲法 (Refactoring Constitution)

> 本文件是所有前端重構專案的最高指導原則。所有新程式碼都必須嚴格遵守此規範，以確保技術統一、架構現代、品質卓越。
>
> **基於：Next.js 15 App Router + TypeScript 5+ 的現代化前端開發標準**

---

## 1. 核心技術棧 (Core Technology Stack)

- **框架 (Framework)**: **Next.js 15 App Router**
- **語言 (Language)**: **TypeScript 5+** (啟用 `strict` 模式)
- **UI 層 (UI Layer)**: **React 18+**
- **樣式 (Styling)**: **Tailwind CSS**
- **UI 組件庫 (UI Component Library)**: **shadcn/ui** (推薦使用)

## 2. 專案結構 (Project Structure)

```
apps/frontend/
├── app/                      # App Router 路由
│   ├── (auth)/              # 路由群組：認證 (e.g., /login)
│   ├── (shop)/              # 路由群組：購物 (e.g., /products)
│   ├── layout.tsx           # 根佈局
│   └── page.tsx             # 首頁
├── components/              # 共享組件
│   ├── ui/                  # 基礎 UI (e.g., Button, Input) - shadcn/ui
│   ├── forms/               # 表單相關組件
│   └── features/            # 特定功能的複合組件 (e.g., ProductCard)
├── lib/                     # 核心邏輯與輔助函式
│   ├── api/                 # API 客戶端與請求定義
│   │   ├── client.ts        # 統一 API Client (含錯誤處理)
│   │   └── products.ts      # 商品相關 API
│   ├── hooks/               # 自定義 Hooks
│   ├── stores/              # Zustand Stores
│   └── utils/               # 通用工具函式
├── types/                   # 全域 TypeScript 型別
└── __tests__/               # 測試檔案
```

## 3. 架構原則 (Architectural Principles)

- **優先使用伺服器組件 (Server Components First)**: 預設所有組件都應為 Server Components 以獲得最佳效能。
- **最小化客戶端組件 (Minimize Client Components)**: 僅在需要使用者互動、Hooks (`useState`, `useEffect`) 或瀏覽器 API 時，才使用 `'use client'`。
- **路由群組 (Route Groups)**: 使用 `(group)` 的方式組織路由，管理佈局且不影響 URL。
- **統一 API 處理 (Unified API Handling)**: 在 `lib/api/client.ts` 中建立一個 `ApiClient` 類別，集中處理請求、`Authorization` 標頭和錯誤（如 401 自動導向登入頁）。
- **全域 SWR 配置**: 在根佈局中提供 `SWRConfig`，統一設定 `fetcher` 和全域錯誤處理。
- **環境變數驗證 (Environment Validation)**: 使用 Zod 在應用程式啟動時驗證所有必要的環境變數，確保環境完整性。
- **中介軟體 (Middleware)**: 使用 `middleware.ts` 處理認證守衛、路由重導向與安全性標頭。
- **錯誤邊界 (Error Boundary)**: 使用 `ErrorBoundary` 元件包裹主要內容，捕捉渲染錯誤並提供友善的 fallback UI。

## 4. 狀態管理核心策略 (State Management Strategy)

嚴格區分伺服器狀態與客戶端狀態是現代 React 開發的關鍵。

| 狀態類型 | 推薦工具 | 使用場景 |
| :--- | :--- | :--- |
| **伺服器狀態** | **SWR** | API 資料獲取、快取、重新驗證。**這是獲取後端資料的唯一標準**。 |
| **全域客戶端狀態** | **Zustand** | 跨組件共享的 UI 狀態（如 `isSidebarOpen`）、使用者設定、購物車內容。 |
| **複雜客戶端流程** | **Zustand + Reducer** | 多步驟、有複雜狀態轉換的流程（如結帳）。將 reducer 邏輯整合到 action 中。 |
| **本地組件狀態** | **useState / useReducer** | 僅限單一組件使用的簡單狀態（如表單輸入、開關）。 |

### 關鍵狀態管理模式

1.  **模式一：純 SWR (預設模式)**
    - **用途**：讀取、顯示來自後端的資料。
    - **實踐**：直接在組件中呼叫 `useSWR` hook。適用於絕大多數只需展示伺服器數據的場景。

2.  **模式二：Zustand (純客戶端狀態)**
    - **用途**：管理與後端無直接關聯的全域 UI 狀態。
    - **實踐**：建立 `useUISettingsStore` 等 store，用於主題切換、側邊欄開關等。

3.  **模式三：SWR + Zustand 同步 (用於可本地修改的伺服器狀態)**
    - **用途**：當需要讓使用者在 UI 上「即時修改」從 SWR 獲取的數據時（例如，在不重新整理頁面的情況下，從商品列表中移除一個商品）。
    - **實踐**：
        1.  建立一個 `useProductsSync` hook，內部使用 `useSWR` 獲取數據。
        2.  使用 `useEffect` 將 SWR 獲取的 `data` 同步到 Zustand 的 `products` state。
        3.  UI 元件從 Zustand 讀取狀態 (`useProductsStore(state => state.products)`)。
        4.  本地修改的 action (如 `removeProduct`) 只更新 Zustand 的狀態。
        5.  SWR 的 `mutate` 用於觸發重新從伺服器同步。

4.  **模式四：Zustand + 直接 API 呼叫 (用於頻繁操作)**
    - **用途**：操作頻繁、狀態主要由客戶端驅動的場景，如購物車加減商品。
    - **實踐**：在 Zustand store 的 action (如 `addItem`) 中直接呼叫 `apiClient.post`，成功後再更新 `set()` 狀態。此模式不使用 SWR，因為不需要其複雜的快取和自動重新驗證機制。

5.  **模式五：Zustand + Reducer (用於複雜流程)**
    - **用途**：管理具有多個步驟和複雜轉換邏輯的狀態機，如結帳流程。
    - **實踐**：在 Zustand store 中定義所有狀態 (`step`, `shippingAddress` 等) 和操作它們的 actions (`nextStep`, `setShippingAddress`)，避免在組件中散落複雜的 `setState` 邏輯。

## 5. 元件設計原則 (Component Design Principles)

- **單一職責原則 (Single Responsibility Principle)**: 每個元件只做一件事。例如，`ProductCard` 應由更小的 `ProductImage`、`ProductPrice`、`AddToCartButton` 等原子元件組合而成。
- **組合模式 (Composition Pattern)**: 優先使用組合而非繼承。例如，建立一個通用的 `Card` 元件，並透過 `Card.Header`, `Card.Content` 等子元件來組合出不同的卡片樣式。

## 6. 表單處理 (Form Handling)

- **標準工具**: **React Hook Form** + **Zod**
- **核心流程**:
    1.  使用 Zod 定義表單的 schema，同時獲得型別與驗證規則。
    2.  將 schema 傳遞給 `zodResolver`。
    3.  `useForm` hook 整合 resolver，提供完整的表單狀態與 API。

## 7. 命名與檔案結構 (Naming & File Structure)

| 類型 | 規則 | 範例 |
| :--- | :--- | :--- |
| **目錄 / 非組件檔案** | 小駝峰 `camelCase` | `productDetail/`, `useProductData.ts` |
| **組件檔案 / 組件名稱** | 大駝峰 `PascalCase` | `ProductCard.tsx`, `<ProductCard />` |
| **型別 / 介面** | 大駝峰 `PascalCase` | `interface Product`, `type Status` |
| **常數** | 大寫蛇形 `UPPER_SNAKE_CASE` | `MAX_ITEMS`, `API_URL` |
| **變數 / 函式** | 小駝ome `camelCase` | `isLoading`, `fetchData` |

## 8. 測試規範 (Testing Standards)

- **框架 (Framework)**: **Vitest**
- **工具 (Utilities)**: **React Testing Library**
- **API Mock**: **MSW (Mock Service Worker)**
- **目標**:
  - **單元測試 (Unit Tests)**: 測試獨立的 Hooks、utils、Zustand stores。
  - **組件測試 (Component Tests)**: 測試組件的渲染與互動。
  - **覆蓋率**: 關鍵邏輯 > 90%，整體 > 80%。

## 9. 程式碼品質 (Code Quality)

- **嚴格型別 (Strict Typing)**: **禁止使用 `any`**。應使用 `unknown` 進行安全的型別檢查。
- **ESLint / Prettier**: 程式碼風格必須通過所有 Linting 和 Formatting 規則。
- **單一職責 (Single Responsibility)**: 保持組件和函式的功能單一、可組合。

## 10. 實施檢查清單 (Implementation Checklist)

專案或功能開始重構前，確保以下基礎設施已就緒：

- [ ] **統一 API Client**: `lib/api/client.ts` 已建立並配置好 baseURL 和錯誤處理邏輯。
- [ ] **SWR Provider**: `SWRConfig` 已在根佈局中配置，並設定了全域 `fetcher`。
- [ ] **ErrorBoundary**: `ErrorBoundary` 元件已建立並應用於主佈局中。
- [ ] **Middleware**: `middleware.ts` 已建立，並配置了基本的認證和路由保護。
- [ ] **環境變數驗證**: `lib/env.ts` 已使用 Zod 對 `process.env` 進行驗證。
- [ ] **Toast 通知**: 全域的 Toast/Sonner 系統已在根佈局中設定。
