# 程式碼撰寫標準 (Enterprise Coding Standard)

## 核心使命
此文件定義了 `nine1.service.mobilewebmall` 專案在實作階段必須嚴格遵守的**企業級開發規範**。作為資深全端工程師暨系統架構師，您必須確保所有程式碼符合大型電商系統的品質標準，包括可維護性、可擴展性、效能最佳化與安全性考量。

## 架構原則與約束
- **Nx Monorepo 為核心**: 遵循 Nx Integrated Monorepo 的最佳實務，支援未來多應用擴展
- **Next.js 全端架構**: 使用 Next.js 15 App Router 作為前端與 BFF (Backend for Frontend) 層
- **型別安全至上**: 全專案 TypeScript 5.9+ 強型別，零容忍 `any` 類型
- **Server Component 優先**: 預設使用 React Server Components，最小化客戶端 JavaScript
- **Zustand + Reducer**: 統一使用 Zustand 搭配 Reducer pattern 進行狀態管理
- **效能驅動**: 目標 Core Web Vitals 優秀評級 (LCP < 2.5s, FID < 100ms, CLS < 0.1)

---

## 第一部分：Nx Monorepo 架構規範

### Workspace 組織原則
- **應用程式 (`apps/`)**: 可獨立部署的應用程式
  - `apps/frontend/`: Next.js 15 前端應用
  - 未來擴展: `apps/admin/`、`apps/api/`
  
- **共享程式庫 (`libs/`)**: 跨應用共享時才建立
  - 目前階段: 使用 `@/` 別名即可
  - 未來擴展: `libs/shared-types/`、`libs/ui/`

### 依賴管理規範
```typescript
// 使用 @/ 別名引用應用內部模組
import { getSalePage } from '@/services/salepage.service';
import { SalePageType } from '@/types/salepage.type';

// 使用相對路徑引用同層級檔案
import { AddToCart } from './_components/AddToCart';
```

### 任務執行規範
```bash
pnpm run dev:frontend      # 開發伺服器（含 SSL）
pnpm run build:frontend    # 生產建置（含 lint & format）
pnpm run lint              # ESLint 檢查
pnpm run format            # Prettier 格式化
```

---

## 第二部分：Next.js App Router 開發規範

### 2.1 檔案系統路由

#### Route Groups 命名規範
```
(root)        # 根路由群組
(salepage)    # 商品頁群組
(auth)        # 認證相關群組
(dashboard)   # 儀表板群組
```

**使用時機**:
- 邏輯分組：將相關頁面組織在一起
- Layout 隔離：不同群組使用不同 layout
- 程式碼組織：改善大型專案結構

#### Dynamic Routes
```typescript
// 單層: /salepage/123
app/(salepage)/salepage/[id]/page.tsx

// 多層: /docs/getting-started/installation
app/docs/[...slug]/page.tsx

// 可選: /shop 和 /shop/electronics
app/shop/[[...slug]]/page.tsx
```

#### Private Folders 規範
```
app/(salepage)/salepage/[id]/
├── _components/          # 路由專屬元件（PascalCase）
├── _lib/                 # 路由專屬工具（kebab-case.ts）
├── _actions/             # 路由專屬 Server Actions（kebab-case.ts）
└── page.tsx
```

**命名規則**:
- `_components/`: PascalCase.tsx（React 元件）
- `_lib/`: kebab-case.ts（工具函式）
- `_actions/`: kebab-case.ts（Server Actions，需標記 "use server"）

---

### 2.2 Server/Client Component 規範

#### 標記時機

**Server Component**（預設，無需標記）:
- 數據獲取
- 存取後端資源
- 保護敏感資訊
- 減少客戶端 JavaScript

**Client Component**（需標記 `"use client"`）:
- 使用 React Hooks（useState、useEffect 等）
- 使用瀏覽器 API（window、document 等）
- 事件處理（onClick、onChange 等）
- 使用 Context Providers
- 使用第三方客戶端庫

#### 元件組織原則
```typescript
// page.tsx (Server Component)
export default async function SalePage({ params }) {
  const data = await fetchData();
  
  return (
    <div>
      <StaticContent data={data} />      {/* Server Component */}
      <InteractiveButton productId={id} /> {/* Client Component */}
    </div>
  );
}

// _components/InteractiveButton.tsx (Client Component)
"use client";

export function InteractiveButton({ productId }) {
  const [isLoading, setIsLoading] = useState(false);
  // ... 互動邏輯
}
```

---

### 2.3 數據獲取與 API

#### Server Component 數據獲取
```typescript
// page.tsx
export default async function Page({ params }) {
  const { id } = await params;
  
  // 直接 await 獲取數據
  const [serverData, pageData] = await Promise.all([
    getServerData(),
    getPageData(id),
  ]);
  
  return <div>{pageData.title}</div>;
}
```

#### API Client 封裝
```typescript
// lib/fetch-client.ts
export async function apiClient<T>(url: string, options?) {
  const response = await fetch(url, {
    ...options,
    cache: options?.cache || 'no-store',
  });
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  
  return response.json() as Promise<T>;
}

// services/product.service.ts
import { unstable_cache } from 'next/cache';

export const getProduct = unstable_cache(
  async (id: string) => {
    return apiClient<Product>(`/api/product/${id}`);
  },
  ['product'],
  { revalidate: 300, tags: ['product'] }
);
```

#### Server Actions 規範
```typescript
// _actions/cart-actions.ts
"use server";

import { revalidatePath } from 'next/cache';

export async function addToCart(productId: string, quantity: number) {
  // 驗證輸入
  if (!productId || quantity < 1) {
    return { success: false, error: '無效的參數' };
  }
  
  // 呼叫 API
  await fetch('/api/cart', {
    method: 'POST',
    body: JSON.stringify({ productId, quantity }),
  });
  
  // 重新驗證快取
  revalidatePath('/cart');
  
  return { success: true };
}
```

---

### 2.4 Middleware Chain 開發規範

#### 使用時機
- 全域數據預載（商店資訊、使用者偏好）
- 語系偵測與設定
- 裝置偵測與分流
- 多個頁面共享的初始化邏輯

#### 設計原則
- **單一職責**: 每個 middleware 只做一件事
- **錯誤隔離**: 使用 try-catch 避免影響其他 middleware
- **快取策略**: 使用 React cache() 避免重複執行
- **繼續執行**: 使用 continueOnError 選項決定錯誤處理策略

#### 基本結構
```typescript
// middleware/custom.middleware.ts
import type { ServerMiddleware } from '@/types/middleware.type';

export const customMiddleware: ServerMiddleware = async (context) => {
  try {
    // 1. 讀取 context 已有資料
    const existingData = context.someData;
    
    // 2. 執行邏輯
    const result = await fetchData(existingData);
    
    // 3. 寫入 context
    context.customData = result;
    
    return context;
  } catch (error) {
    context.error = {
      code: 'CUSTOM_ERROR',
      message: error instanceof Error ? error.message : 'Unknown',
      timestamp: new Date().toISOString(),
    };
    return context;
  }
};

// middleware/server-data.ts
import { cache } from 'react';

export const getServerData = cache(async () => {
  return runMiddlewareChain(
    [middleware1, middleware2, customMiddleware],
    initialContext,
    { continueOnError: true }
  );
});
```

---

## 第三部分：Zustand + Reducer 狀態管理規範

### Store 組織規範

**檔案命名**: `kebab-case.store.ts`
```
store/
├── cart.store.ts         # 購物車狀態
├── user.store.ts         # 使用者狀態
├── ui.store.ts           # UI 狀態（modal、drawer）
└── filters.store.ts      # 篩選器狀態
```

### Store 基本結構
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
    (set, get) => ({
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

### Middleware 使用
```typescript
// Persist (localStorage)
import { persist, createJSONStorage } from 'zustand/middleware';

persist(storeConfig, {
  name: 'storage-key',
  storage: createJSONStorage(() => localStorage),
  partialize: (state) => ({ items: state.items }), // 選擇性持久化
})

// DevTools (Redux DevTools)
import { devtools } from 'zustand/middleware';

devtools(storeConfig, { name: 'StoreName' })
```

### 選擇器使用原則
```typescript
// 只訂閱需要的部分
const items = useCartStore((state) => state.items);
const addItem = useCartStore((state) => state.addItem);

// 多個值使用 shallow
import { shallow } from 'zustand/shallow';

const { items, total } = useCartStore(
  (state) => ({ items: state.items, total: state.total }),
  shallow
);
```

---

## 第四部分：NextAuth v5 認證規範

### 基本設定
```bash
pnpm add next-auth@beta @auth/core
```

```typescript
// auth.ts
import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';

export const { auth, signIn, signOut } = NextAuth({
  providers: [
    Credentials({
      async authorize(credentials) {
        const user = await verifyCredentials(credentials);
        return user || null;
      },
    }),
  ],
  session: { strategy: 'jwt', maxAge: 30 * 24 * 60 * 60 },
});
```

### 使用方式

**Server Component**:
```typescript
import { auth } from '@/auth';

export default async function Page() {
  const session = await auth();
  if (!session) redirect('/login');
  
  return <div>Welcome, {session.user.name}</div>;
}
```

**Client Component**:
```typescript
"use client";
import { useSession } from "next-auth/react";

export function UserMenu() {
  const { data: session } = useSession();
  return session ? <p>{session.user.name}</p> : <a href="/login">登入</a>;
}
```

**Middleware 路由保護**:
```typescript
// middleware.ts
import { auth } from '@/auth';

export default auth((req) => {
  if (!req.auth && req.nextUrl.pathname.startsWith('/dashboard')) {
    return Response.redirect(new URL('/login', req.url));
  }
});
```

**Server Actions 權限驗證**:
```typescript
"use server";
import { auth } from '@/auth';

export async function updateProfile(data: FormData) {
  const session = await auth();
  if (!session) return { error: '未授權' };
  
  // 更新邏輯
  return { success: true };
}
```

---

## 第五部分：TypeScript 與型別規範

### 嚴格模式配置
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### 型別定義規範
```typescript
// types/product.type.ts
export interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
  createdAt: string;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

// 使用
const response: ApiResponse<Product[]> = await fetchProducts();
```

---

## 檢核清單 (Pre-commit Checklist)

### 程式碼品質
- [ ] 通過 ESLint 檢查
- [ ] 通過 TypeScript 編譯
- [ ] 通過所有測試
- [ ] 無 console.log 殘留

### Next.js App Router 規範
- [ ] Server Components 優先
- [ ] `"use client"` 標記正確
- [ ] Private folders 命名正確
- [ ] Route Groups 命名符合規範
- [ ] Server Actions 標記 `"use server"`
- [ ] Dynamic Routes 參數使用 `Promise<>`

### 狀態管理
- [ ] Zustand stores 型別完整
- [ ] 使用選擇器避免不必要 re-render
- [ ] persist middleware 正確配置

### API 與數據
- [ ] 使用統一 fetch-client
- [ ] API 型別定義完整
- [ ] unstable_cache 配置正確
- [ ] Server Actions 包含錯誤處理

### 安全性
- [ ] 無敏感資訊硬編碼
- [ ] 環境變數正確使用
- [ ] 路由保護正確配置
- [ ] 使用者輸入驗證（Zod）

### 效能
- [ ] 圖片使用 Next.js Image
- [ ] 大型元件 lazy loading
- [ ] API 回應有快取策略
- [ ] 最小化客戶端 JavaScript

---

## 快速參考

### 目錄結構
```
apps/frontend/
├── app/                # App Router（pages、layouts）
│   ├── (root)/        # Route Group
│   ├── (salepage)/    # Route Group
│   └── layout.tsx     # Root Layout
├── components/         # 應用層級共用元件
├── middleware/         # Server Middleware Chain
├── services/           # API 服務層
├── store/              # Zustand 狀態管理
├── hooks/              # Custom React Hooks
├── lib/                # 工具函式庫
├── types/              # TypeScript 型別定義
├── middleware.ts       # Next.js Edge Middleware
└── next.config.js      # Next.js 配置
```

### 重要概念

| 概念 | 用途 | 範例 |
|------|------|------|
| **Server Component** | 預設元件，伺服器渲染 | `page.tsx` |
| **Client Component** | 需要互動性 | `"use client"` |
| **Private Folder** | 路由專屬檔案 | `_components/` |
| **Route Group** | 邏輯分組 | `(salepage)/` |
| **Server Action** | 伺服器端函式 | `"use server"` |

---

**文件版本**: v3.0  
**最後更新**: 2025-10-30  
**適用專案**: nine1.service.mobilewebmall  
**技術棧**: Next.js 15 + TypeScript + Nx + Zustand + NextAuth v5
