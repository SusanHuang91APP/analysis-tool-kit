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

基於 **Nx Monorepo** 的 Integrated Monorepo 架構：

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
├── services/                # Server-side API 服務層
│   ├── auth.service.ts      # 認證相關 API（供 Server Components 使用）
│   └── product.service.ts   # 商品相關 API
├── hooks/                   # Client-side SWR Hooks
│   ├── useAuthInfo.ts       # 使用者資訊（供 Client Components 使用）
│   └── useProducts.ts       # 商品列表
├── store/                   # Zustand Stores（客戶端狀態）
│   ├── cart.store.ts        # 購物車狀態
│   └── ui.store.ts          # UI 設定狀態
├── lib/                     # 核心邏輯與輔助函式
│   ├── fetch-client.ts      # 統一 fetch wrapper（錯誤處理）
│   └── utils/               # 通用工具函式
├── types/                   # 全域 TypeScript 型別
│   ├── auth.type.ts         # 認證相關型別
│   └── product.type.ts      # 商品相關型別
└── __tests__/               # 測試檔案
```

**使用 `@/` 別名引用應用內部模組**：
```typescript
import { getAuthInfo } from '@/services/auth.service';
import { useProducts } from '@/hooks/useProducts';
import { useCartStore } from '@/store/cart.store';
```

## 3. 架構原則 (Architectural Principles)

- **優先使用伺服器組件 (Server Components First)**: 預設所有組件都應為 Server Components 以獲得最佳效能。
- **最小化客戶端組件 (Minimize Client Components)**: 僅在需要使用者互動、Hooks (`useState`, `useEffect`) 或瀏覽器 API 時，才使用 `'use client'`。
- **路由群組 (Route Groups)**: 使用 `(group)` 的方式組織路由，管理佈局且不影響 URL。
- **統一 fetch 處理 (Unified Fetch Handling)**: 在 `lib/fetch-client.ts` 中建立統一的 fetch wrapper，集中處理錯誤、認證和重試邏輯。
- **全域 SWR 配置**: 在根佈局中提供 `SWRConfig`，統一設定 `fetcher` 和全域錯誤處理（僅用於 Client Components）。
- **環境變數驗證 (Environment Validation)**: 使用 Zod 在應用程式啟動時驗證所有必要的環境變數，確保環境完整性。
- **中介軟體 (Middleware)**: 使用 `middleware.ts` 處理路由保護、重導向與安全性標頭。
- **Middleware Chain**: 建立可組合的 middleware chain 用於全域數據預載（商店資訊、使用者偏好、語系等）。
- **錯誤邊界 (Error Boundary)**: 使用 `ErrorBoundary` 元件包裹主要內容，捕捉渲染錯誤並提供友善的 fallback UI。

### 3.5 Server/Client Component 分離檢查清單

在設計元件時，必須嚴格遵循 Server/Client Component 分離原則：

**檢查項目**：
- [ ] 元件是否需要使用者互動（onClick, onChange）？ → 拆分為 Client Component
- [ ] 元件是否需要 React Hooks（useState, useEffect）？ → 拆分為 Client Component
- [ ] 元件是否需要瀏覽器 API（window, document）？ → 拆分為 Client Component
- [ ] 資料計算是否可以在 Server 端完成？ → 移除 `useMemo`，直接在 Server Component 計算
- [ ] 是否只有 Link 等互動元件需要 Client？ → 將互動部分拆分為獨立元件

**最佳實踐範例**：

**錯誤範例**：整個元件都標記為 Client Component
```typescript
// ❌ 不必要的 Client Component
'use client';

export function ProductList({ products }) {
  const filtered = useMemo(() => {
    return products.filter(p => p.active);
  }, [products]);
  
  return <div>{/* 渲染列表 */}</div>;
}
```

**正確範例**：Server Component 處理資料，Client Component 處理互動
```typescript
// ✅ Server Component：資料計算和靜態渲染
export function ProductList({ products }) {
  // Server 端直接計算，不需要 useMemo
  const filtered = products.filter(p => p.active);
  
  return (
    <div>
      {filtered.map(product => (
        <ProductItem key={product.id} product={product} />
      ))}
    </div>
  );
}

// ✅ Client Component：只處理互動邏輯
'use client';

export function ProductItem({ product }) {
  const [isFavorite, setIsFavorite] = useState(false);
  
  return (
    <div>
      <button onClick={() => setIsFavorite(!isFavorite)}>
        {isFavorite ? '❤️' : '🤍'}
      </button>
    </div>
  );
}
```

**詳細實作標準請參考**：[refactor-coding-standard.md](./refactor-coding-standard.md)

### Service 層設計原則

所有 Legacy API 呼叫必須透過統一的 service 層，並區分 Server 和 Client 端使用：

**Server-side Service** (供 Server Components 使用):
```typescript
// services/auth.service.ts
import { unstable_cache } from 'next/cache';

export const getAuthInfo = unstable_cache(
  async () => {
    const res = await fetch(`${process.env.API_URL}/Auth/GetInfo`, {
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Auth API failed');
    return res.json();
  },
  ['auth-info'],
  { revalidate: 300, tags: ['auth'] }
);
```

**Client-side Hook** (供 Client Components 使用):
```typescript
// hooks/useAuthInfo.ts
'use client';
import useSWR from 'swr';

export function useAuthInfo() {
  return useSWR('/api/auth/info', fetcher, {
    revalidateOnFocus: true,
    revalidateOnReconnect: true,
  });
}
```

### Cache Key 設計最佳實踐

**重要原則**：`unstable_cache` 的 key 必須包含所有參數，確保每個資源都有獨立的 cache。

**錯誤範例**：
```typescript
// ❌ Cache key 沒有包含參數
export const getSalePage = unstable_cache(
  async (id: string, shopId: number) => fetchSalePage(id, shopId),
  ['sale-page'], // ❌ 所有商品頁共用同一個 cache
  {
    revalidate: 300,
  },
);
```

**正確範例**：
```typescript
// ✅ Cache key 包含所有參數
export const getSalePage = async (id: string, shopId: number) => {
  return unstable_cache(
    async () => fetchSalePage(id, shopId),
    ['sale-page', id, String(shopId)], // ✅ 每個商品頁獨立 cache
    {
      revalidate: 300,
      tags: [`salepage-${id}`], // ✅ 支援按標籤清除快取
    },
  )();
};
```

**關鍵要點**：
- Cache key 必須包含所有動態參數（id, shopId 等）
- 使用 tags 支援 `revalidateTag()` 按標籤清除快取
- 參數需要轉換為字串（`String(shopId)`）

## 4. 狀態管理核心策略 (State Management Strategy)

嚴格區分伺服器狀態與客戶端狀態是現代 React 開發的關鍵。

| 狀態類型 | 推薦工具 | 使用場景 |
| :--- | :--- | :--- |
| **伺服器狀態（Server）** | **fetch + unstable_cache** | Server Component 中獲取資料、SEO 需求、初始頁面載入 |
| **伺服器狀態（Client）** | **SWR** | Client Component 中需要即時更新的資料（使用者資訊、商品列表、我的最愛） |
| **全域客戶端狀態** | **Zustand + Reducer** | 購物車內容、UI 設定（側邊欄開關）、使用者偏好 |
| **複雜客戶端流程** | **Zustand + Reducer** | 多步驟流程（如結帳）、有複雜狀態轉換的場景 |
| **本地組件狀態** | **useState / useReducer** | 僅限單一組件使用的簡單狀態（如表單輸入、開關） |

### 關鍵狀態管理模式

1.  **模式一：Server Component 資料獲取（預設模式）**
    - **用途**：頁面初始載入時獲取資料，優化 SEO 和首次渲染速度。
    - **實踐**：在 Server Component 中直接 `await` service 函式。
    
    ```typescript
    // app/(shop)/products/page.tsx (Server Component)
    import { getProducts } from '@/services/product.service';
    
    export default async function ProductsPage() {
      const products = await getProducts(); // 使用 unstable_cache
      return <ProductList products={products} />;
    }
    ```

2.  **模式二：Client Component + SWR（用於即時資料）**
    - **用途**：需要即時更新、重新驗證、或使用者互動後更新的資料。
    - **實踐**：在 Client Component 中使用 SWR hooks。
    
    ```typescript
    // components/UserProfile.tsx (Client Component)
    'use client';
    import { useAuthInfo } from '@/hooks/useAuthInfo';
    
    export function UserProfile() {
      const { data, error, isLoading } = useAuthInfo();
      
      if (isLoading) return <Skeleton />;
      if (error) return <ErrorMessage />;
      
      return <div>{data.name}</div>;
    }
    ```

3.  **模式三：Zustand + Reducer（純客戶端狀態）**
    - **用途**：管理與後端無直接關聯的全域 UI 狀態。
    - **實踐**：建立 Zustand store，使用 reducer pattern 管理複雜狀態。
    
    ```typescript
    // store/cart.store.ts
    import { create } from 'zustand';
    import { persist } from 'zustand/middleware';
    
    interface CartState {
      items: CartItem[];
      addItem: (item: CartItem) => void;
      removeItem: (id: string) => void;
      clear: () => void;
    }
    
    export const useCartStore = create<CartState>()(
      persist(
        (set) => ({
          items: [],
          
          addItem: (item) => set((state) => ({
            items: [...state.items, item]
          })),
          
          removeItem: (id) => set((state) => ({
            items: state.items.filter(i => i.id !== id)
          })),
          
          clear: () => set({ items: [] }),
        }),
        { name: 'cart-storage' }
      )
    );
    ```

4.  **模式四：Zustand + 直接 API 呼叫（用於頻繁操作）**
    - **用途**：操作頻繁、狀態主要由客戶端驅動的場景，如購物車加減商品。
    - **實踐**：在 Zustand store 的 action 中直接呼叫 API，成功後更新狀態。
    
    ```typescript
    // store/cart.store.ts
    export const useCartStore = create<CartState>()((set) => ({
      items: [],
      
      addItemAsync: async (productId: string) => {
        const response = await fetch('/api/cart/add', {
          method: 'POST',
          body: JSON.stringify({ productId }),
        });
        
        if (response.ok) {
          const item = await response.json();
          set((state) => ({ items: [...state.items, item] }));
        }
      },
    }));
    ```

## 5. 元件設計原則 (Component Design Principles)

- **單一職責原則 (Single Responsibility Principle)**: 每個元件只做一件事。例如，`ProductCard` 應由更小的 `ProductImage`、`ProductPrice`、`AddToCartButton` 等原子元件組合而成。
- **組合模式 (Composition Pattern)**: 優先使用組合而非繼承。例如，建立一個通用的 `Card` 元件，並透過 `Card.Header`, `Card.Content` 等子元件來組合出不同的卡片樣式。

### 5.1 Server/Client Component 分離範例

**完整實作範例**：商品頁群組功能

```typescript
// ✅ Server Component：資料獲取和靜態渲染
// SalepageGroupWrapper.tsx
import { SalePageV2Entity } from '@/types/salepage.type';
import { SalepageGroupItem } from './SalepageGroupItem';

interface Props {
  groupData: SalePageV2Entity['SalePageGroup'];
  currentSalePageId: number;
}

export function SalepageGroupWrapper({ groupData, currentSalePageId }: Props) {
  // 條件式渲染：檢查資料完整性
  if (!groupData?.SalePageItems?.length) {
    return null;
  }

  // Server-side 計算：找出當前選中的項目
  const selectedItem = groupData.SalePageItems.find(
    (item) => item.SalePageId === currentSalePageId
  );

  // Server-side 計算：標題組合邏輯（使用 IIFE，不需要 useMemo）
  const displayTitle = (() => {
    const { GroupTitle } = groupData;
    const itemTitle = selectedItem?.GroupItemTitle;
    
    if (GroupTitle && itemTitle) {
      return `${GroupTitle}：${itemTitle}`;
    }
    if (GroupTitle) return GroupTitle;
    if (itemTitle) return itemTitle;
    return '';
  })();

  return (
    <div className="salepage-group-wrapper py-4">
      {displayTitle && (
        <p className="group-title text-base font-medium mb-3">
          {displayTitle}
        </p>
      )}
      
      <div className="overflow-x-auto md:overflow-x-visible">
        <ul className="flex gap-2">
          {groupData.SalePageItems.map((item) => (
            <SalepageGroupItem
              key={item.SalePageId}
              item={item}
              isSelected={item.SalePageId === currentSalePageId}
              iconStyle={groupData.GroupIconStyle || 'Square'}
            />
          ))}
        </ul>
      </div>
    </div>
  );
}
```

```typescript
// ✅ Client Component：只處理互動邏輯
// SalepageGroupItem.tsx
'use client';

import Link from 'next/link';
import Image from 'next/image';
import type { SearchSalePageGroupSalePageItemEntity } from '@/types/salepage.type';

interface Props {
  item: SearchSalePageGroupSalePageItemEntity;
  isSelected: boolean;
  iconStyle: string;
}

function cn(...classes: (string | boolean | undefined)[]) {
  return classes.filter(Boolean).join(' ');
}

export function SalepageGroupItem({ item, isSelected, iconStyle }: Props) {
  return (
    <li className="group relative flex-shrink-0">
      <Link
        href={`/salepage/${item.SalePageId}`}
        className={cn(
          'block relative overflow-hidden transition-all',
          iconStyle === 'Circle'
            ? 'rounded-full aspect-square w-16 h-16'
            : 'rounded aspect-square w-20 h-20',
          // 選中狀態：使用 CSS border，而非額外的 div
          isSelected
            ? 'border-2 border-blue-500'
            : 'border-2 border-transparent'
        )}
        onClick={(e) => {
          // 防呆：避免重複導航
          if (isSelected) {
            e.preventDefault();
          }
        }}
        aria-label={item.GroupItemTitle || `商品 ${item.SalePageId}`}
        aria-current={isSelected ? 'page' : undefined}
      >
        <Image
          src={`https:${item.ItemUrl}`} // ✅ 直接拼接 https:，不需要函數
          alt={item.GroupItemTitle || '商品圖片'}
          fill
          sizes="80px"
          className="object-cover"
        />
      </Link>

      {/* Tooltip (Desktop only - CSS 控制) */}
      {item.GroupItemTitle && (
        <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded whitespace-nowrap opacity-0 md:group-hover:opacity-100 transition-opacity pointer-events-none z-10">
          {item.GroupItemTitle}
        </div>
      )}
    </li>
  );
}
```

**關鍵設計要點**：
- Server Component 負責資料計算和靜態渲染
- Client Component 只處理最小必要的互動邏輯（Link 的 onClick）
- Props 最小化：只傳遞必要的資料，不傳遞完整的 `salePageData`
- 從資料中提取 ID：`currentSalePageId` 從 `salePageData.Id` 取得

### 5.2 Props 設計最佳實踐

**原則**：只傳遞元件真正需要的資料，不傳遞完整的資料物件。

**錯誤範例**：
```typescript
// ❌ 傳遞完整的資料物件
<SalepageGroupWrapper salePageData={salePageData} />
```

**正確範例**：
```typescript
// ✅ 只傳遞必要的資料
{salePageData?.SalePageGroup && (
  <SalepageGroupWrapper
    groupData={salePageData.SalePageGroup}
    currentSalePageId={salePageData.Id}
  />
)}
```

### 5.3 Next.js 原生功能優先

**導航處理**：使用 Next.js `<Link>` 而非 `window.location.href`

```typescript
// ✅ 使用 Next.js Link
import Link from 'next/link';

<Link
  href={`/salepage/${item.SalePageId}`}
  onClick={(e) => {
    if (isSelected) {
      e.preventDefault(); // 防呆：避免重複導航
    }
  }}
>
  {content}
</Link>
```

**優點**：
- 自動預取（prefetch）提升體驗
- 保持 SPA 導航流暢度
- 支援瀏覽器前進/後退
- 改善 SEO（真實 `<a>` 標籤）

### 5.4 圖片處理標準

**原則**：使用 Next.js `<Image>` 元件，協議相對路徑直接拼接 `https:`

```typescript
import Image from 'next/image';

<Image
  src={`https:${item.ItemUrl}`} // ✅ 直接拼接，不需要函數
  alt={item.GroupItemTitle || '商品圖片'}
  fill
  sizes="80px"
  className="object-cover"
/>
```

### 5.5 響應式設計原則

**單一元件策略**：使用單一元件處理 Desktop + Mobile，透過 CSS 控制響應式。

**錯誤範例**：
```typescript
// ❌ 建立兩個獨立的元件
<DesktopProductList />
<MobileProductList />
```

**正確範例**：
```typescript
// ✅ 單一元件，CSS 控制響應式
<div className="overflow-x-auto md:overflow-x-visible scroll-smooth">
  <ul className={cn(
    'flex gap-2 pb-2 md:pb-0',
    iconStyle === 'Circle' ? 'md:flex-wrap' : 'md:grid md:grid-cols-6'
  )}>
    {items.map(item => (
      <ProductItem key={item.id} item={item} />
    ))}
  </ul>
</div>
```

**常用 Tailwind 響應式模式**：
- **滾動控制**：`overflow-x-auto md:overflow-x-visible`
- **列表佈局**：`flex md:flex-wrap` 或 `flex md:grid md:grid-cols-6`
- **Tooltip 顯示**：`opacity-0 md:group-hover:opacity-100`

**詳細實作標準請參考**：[refactor-coding-standard.md](./refactor-coding-standard.md)

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

### API 重構專案
- [ ] **fetch-client**: `lib/fetch-client.ts` 已建立（統一錯誤處理、認證）
- [ ] **Server Service**: `services/{domain}.service.ts` 已建立
- [ ] **Client Hook**: `hooks/use{Feature}.ts` 已建立（使用 SWR）
- [ ] **TypeScript 型別**: `types/{domain}.type.ts` 已定義
- [ ] **環境變數**: API URL 等設定已配置並驗證

### Feature 重構專案
- [ ] **SWR Config**: 全域 `SWRConfig` 已設定在根佈局
- [ ] **Zustand Stores**: 核心 stores（cart, ui）已建立
- [ ] **ErrorBoundary**: `ErrorBoundary` 元件已建立並應用於主佈局
- [ ] **Middleware**: `middleware.ts` 已建立，並配置基本的路由保護
- [ ] **Middleware Chain**: 基礎 middleware chain 已建立並配置
- [ ] **環境變數驗證**: `lib/env.ts` 已使用 Zod 對 `process.env` 進行驗證
- [ ] **Toast 通知**: 全域的 Toast/Sonner 系統已在根佈局中設定

---

## 11. 執行流程最佳實踐 (Execution Flow Best Practices)

### 11.1 Shell Script 與 AI 協作流程

**設計原則**：
- **Shell Script 職責**：環境驗證、檔案操作、路徑計算、格式判斷
- **AI 職責**：內容分析、智能填充、程式碼理解、圖表生成

**協作流程**：

1. **Shell Script 執行階段**（無條件執行）：
   ```
   Shell Script 執行
   ├── 驗證參數格式
   ├── 判斷使用格式（格式 1 或格式 2）
   ├── 建立目標文件
   ├── 複製範本內容
   └── 輸出環境變數
   ```

2. **AI 讀取階段**：
   ```
   AI 讀取環境變數
   ├── REFACTOR_DOC_FILE（目標文件路徑）
   ├── LEGACY_ANALYSIS_FILES（源文件路徑）
   ├── EXISTING_FILE（文件狀態）
   └── CONSTITUTION_FILE（憲法文件路徑）
   ```

3. **AI 執行階段**：
   ```
   AI 執行分析
   ├── 讀取憲法和範本
   ├── 讀取源文件
   ├── 分析並填充內容
   ├── 執行功能一致性比對
   └── 生成比對報告
   ```

### 11.2 執行順序關鍵原則

**必須遵循的順序**：

1. **文件建立優先**：
   - Shell script 必須先建立目標文件
   - AI 必須確認文件存在後才開始讀取其他文件

2. **憲法優先**：
   - 必須先讀取 `refactor-constitution.md` 和 `refactor-coding-standard.md`
   - 在整個過程中嚴格遵循技術規範

3. **分析優先於填充**：
   - 必須先完整分析源文件
   - 再開始填充目標文件內容

4. **比對最後執行**：
   - 功能一致性比對必須在完成內容填充後執行
   - 作為最後的驗證步驟

### 11.3 錯誤處理原則

**Shell Script 錯誤處理**：
- 參數驗證失敗 → 立即終止並顯示錯誤訊息
- 文件不存在 → 顯示明確的錯誤訊息
- 權限不足 → 顯示權限錯誤

**AI 錯誤處理**：
- 環境變數未設定 → 終止並回報錯誤
- 文件讀取失敗 → 顯示明確的錯誤訊息
- 內容填充失敗 → 保留部分內容並標記錯誤

### 11.4 品質保證流程

**檢查點**：

1. **執行前檢查**：
   - [ ] 所有源文件都存在且可讀取
   - [ ] 目標文件路徑正確
   - [ ] 憲法和範本文件存在

2. **執行中檢查**：
   - [ ] 所有章節都已填充
   - [ ] 內容標記正確（`[從分析文件提取]`、`[AI 建議 - 請驗證]`）
   - [ ] 程式碼範例完整（沒有使用 `...` 省略）

3. **執行後檢查**：
   - [ ] 功能一致性比對已執行
   - [ ] 比對報告格式正確
   - [ ] 所有不一致項目都已標記

---

## 12. 參考資源 (References)
