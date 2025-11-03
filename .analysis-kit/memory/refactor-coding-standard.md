# 前端開發編碼標準 (Coding Standards)

> 本文件定義 Next.js 15 App Router 開發的實作細節和最佳實踐，所有程式碼必須遵循這些標準。
>
> **補充說明**：本文件專注於實作層面的技術細節，架構層面的指導原則請參考 [refactor-constitution.md](./refactor-constitution.md)

---

## 1. Server/Client Component 分離原則

### 1.1 基本原則

**預設使用 Server Component**，僅在以下情況使用 Client Component：

1. 需要使用者互動（onClick, onChange 等）
2. 需要使用 React Hooks（useState, useEffect, useMemo 等）
3. 需要使用瀏覽器 API（window, document, localStorage 等）
4. 需要使用 Context API（需搭配 'use client'）

### 1.2 分離策略

**錯誤範例**：
```typescript
// ❌ 整個元件都標記為 Client Component
'use client';

export function ProductList({ products }) {
  const filtered = useMemo(() => {
    return products.filter(p => p.active);
  }, [products]);
  
  return <div>{/* 渲染列表 */}</div>;
}
```

**正確範例**：
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

### 1.3 檢查清單

在設計元件時，確認以下問題：

- [ ] 元件是否需要使用者互動？ → 拆分為 Client Component
- [ ] 元件是否需要 Hooks？ → 拆分為 Client Component
- [ ] 資料計算是否可以在 Server 端完成？ → 移除 `useMemo`，直接在 Server Component 計算
- [ ] 是否只有 Link 等互動元件需要 Client？ → 將互動部分拆分為獨立元件

---

## 2. Props 設計原則

### 2.1 最小化 Props

**原則**：只傳遞元件真正需要的資料，不傳遞完整的資料物件。

**錯誤範例**：
```typescript
// ❌ 傳遞完整的資料物件
<SalepageGroupWrapper salePageData={salePageData} />
```

**正確範例**：
```typescript
// ✅ 只傳遞必要的資料
<SalepageGroupWrapper
  groupData={salePageData.SalePageGroup}
  currentSalePageId={salePageData.Id}
/>
```

### 2.2 從資料中提取 ID

**原則**：ID 應從資料物件中提取，而非從 URL 解析。

**錯誤範例**：
```typescript
// ❌ 從 URL 解析 ID
const salePageId = useParams().id;
```

**正確範例**：
```typescript
// ✅ 從資料中取得 ID
const currentSalePageId = salePageData.Id;
```

### 2.3 Props 型別定義

**原則**：使用 TypeScript 型別提取，而非直接使用完整型別。

**範例**：
```typescript
interface Props {
  groupData: SalePageV2Entity['SalePageGroup'];  // ✅ 使用型別提取
  currentSalePageId: number;
}

// 而非
interface Props {
  groupData: SearchSalePageGroupEntity;  // ❌ 直接引用完整型別（雖然可行，但較不靈活）
  salePageData: SalePageV2Entity;  // ❌ 傳遞完整物件
}
```

---

## 3. Next.js 原生功能優先

### 3.1 導航處理

**原則**：使用 Next.js `<Link>` 元件而非 `window.location.href`。

**錯誤範例**：
```typescript
// ❌ 使用 window.location.href
onClick={() => {
  window.location.href = `/salepage/${item.SalePageId}`;
}}
```

**正確範例**：
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

### 3.2 圖片處理

**原則**：使用 Next.js `<Image>` 元件處理圖片優化。

**範例**：
```typescript
import Image from 'next/image';

<Image
  src={`https:${item.ItemUrl}`}
  alt={item.GroupItemTitle || '商品圖片'}
  fill
  sizes="80px"
  className="object-cover"
/>
```

### 3.3 路由處理

**原則**：使用 App Router 的路由機制，避免手動操作路由。

---

## 4. 圖片 URL 處理

### 4.1 協議相對路徑轉換

**原則**：直接使用模板字串，不需要額外的函數。

**錯誤範例**：
```typescript
// ❌ 建立額外的函數
function normalizeImageUrl(url: string): string {
  if (!url) return '';
  if (url.startsWith('//')) {
    return `https:${url}`;
  }
  return url;
}

<Image src={normalizeImageUrl(item.ItemUrl)} />
```

**正確範例**：
```typescript
// ✅ 直接使用模板字串
<Image src={`https:${item.ItemUrl}`} />
```

**說明**：
- Next.js Image 元件要求絕對 URL（`http://` 或 `https://`）
- 後端 API 可能回傳協議相對路徑（`//` 開頭）
- 直接拼接 `https:` 即可，無需額外函數

### 4.2 為什麼使用 HTTPS

1. **安全性**：現代網站都應使用 HTTPS
2. **混合內容警告**：如果主站是 HTTPS，載入 HTTP 圖片會被瀏覽器阻擋
3. **CDN 標準**：大部分 CDN 都支援 HTTPS

---

## 5. Cache 設計原則

### 5.1 Cache Key 設計

**原則**：`unstable_cache` 的 key 必須包含所有參數。

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

### 5.2 Cache Tags

**原則**：使用 tags 支援按標籤清除快取。

**範例**：
```typescript
{
  revalidate: 300,
  tags: [`salepage-${id}`], // 可用 revalidateTag('salepage-123') 清除
}
```

### 5.3 參數類型轉換

**原則**：確保 cache key 中的參數都是字串。

**範例**：
```typescript
['sale-page', id, String(shopId)] // ✅ 數字轉為字串
```

---

## 6. 響應式設計策略

### 6.1 單一元件策略

**原則**：使用單一元件處理 Desktop + Mobile，透過 CSS 控制響應式。

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

### 6.2 Tailwind 響應式類別

**常用模式**：

- **滾動控制**：
  - Mobile: `overflow-x-auto`（可橫向滾動）
  - Desktop: `md:overflow-x-visible`（不滾動）

- **列表佈局**：
  - Mobile: `flex gap-2`（橫向排列）
  - Desktop 圓形: `md:flex-wrap`（自動換行）
  - Desktop 方形: `md:grid md:grid-cols-6`（6 欄 grid）

- **Tooltip 顯示**：
  - Mobile: `opacity-0`（不顯示）
  - Desktop: `md:group-hover:opacity-100`（hover 顯示）

### 6.3 斷點選擇

**Tailwind 預設斷點**：
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

**建議**：使用 `md:`（768px）作為主要斷點，區分 Mobile 和 Desktop。

---

## 7. CSS 優化原則

### 7.1 選中狀態處理

**原則**：使用 CSS border，而非額外的 div 遮罩層。

**錯誤範例**：
```typescript
// ❌ 額外的遮罩 div
{isSelected && (
  <div className="absolute inset-0 border-2 border-blue-500 rounded-inherit pointer-events-none" />
)}
```

**正確範例**：
```typescript
// ✅ 使用 CSS border
className={cn(
  'block relative overflow-hidden',
  isSelected
    ? 'border-2 border-blue-500'
    : 'border-2 border-transparent'
)}
```

**優點**：
- 減少 DOM 節點
- 更好的效能
- 更簡潔的程式碼

### 7.2 Tailwind 工具類別

**原則**：優先使用 Tailwind 工具類別，避免 inline styles。

**錯誤範例**：
```typescript
// ❌ 使用 inline styles
<div style={{ display: 'flex', gap: '8px' }}>
```

**正確範例**：
```typescript
// ✅ 使用 Tailwind 類別
<div className="flex gap-2">
```

### 7.3 條件式類別

**原則**：使用 `cn()` 工具函數處理條件式類別。

**範例**：
```typescript
function cn(...classes: (string | boolean | undefined)[]) {
  return classes.filter(Boolean).join(' ');
}

className={cn(
  'base-class',
  isActive && 'active-class',
  isDisabled && 'disabled-class'
)}
```

---

## 8. 元件拆分原則

### 8.1 拆分策略

**原則**：將需要互動的部分拆分為獨立的 Client Component。

**範例**：
```typescript
// Server Component：資料獲取和靜態渲染
export function SalepageGroupWrapper({ groupData, currentSalePageId }: Props) {
  // Server-side 計算
  const selectedItem = groupData.SalePageItems.find(
    (item) => item.SalePageId === currentSalePageId
  );
  
  return (
    <ul>
      {groupData.SalePageItems.map((item) => (
        <SalepageGroupItem  // ✅ Client Component
          key={item.SalePageId}
          item={item}
          isSelected={item.SalePageId === currentSalePageId}
        />
      ))}
    </ul>
  );
}

// Client Component：只處理互動邏輯
'use client';

export function SalepageGroupItem({ item, isSelected }: Props) {
  return (
    <Link href={`/salepage/${item.SalePageId}`}>
      {/* 互動內容 */}
    </Link>
  );
}
```

### 8.2 職責劃分

**Server Component**：
- ✅ 資料獲取（使用 service 函式）
- ✅ 資料計算和轉換
- ✅ 靜態內容渲染
- ✅ 條件式渲染邏輯

**Client Component**：
- ✅ 使用者互動（onClick, onChange）
- ✅ 瀏覽器 API（localStorage, window）
- ✅ 狀態管理（useState, useEffect）
- ✅ 第三方互動庫（地圖、圖表等）

---

## 9. 資料計算優化

### 9.1 Server 端計算

**原則**：在 Server Component 中直接計算，不需要 `useMemo`。

**錯誤範例**：
```typescript
'use client';

export function ProductList({ products }) {
  const filtered = useMemo(() => {
    return products.filter(p => p.active);
  }, [products]);
  
  return <div>{/* ... */}</div>;
}
```

**正確範例**：
```typescript
// Server Component
export function ProductList({ products }) {
  // Server 端直接計算
  const filtered = products.filter(p => p.active);
  
  return <div>{/* ... */}</div>;
}
```

### 9.2 標題組合邏輯

**範例**：
```typescript
// Server Component：使用 IIFE 計算
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
```

---

## 10. 錯誤處理與防禦性編程

### 10.1 條件式渲染

**原則**：使用可選鏈（optional chaining）進行防禦性檢查。

**範例**：
```typescript
// ✅ 使用可選鏈
if (!groupData?.SalePageItems?.length) {
  return null;
}
```

### 10.2 預設值處理

**範例**：
```typescript
const iconStyle = groupData.GroupIconStyle || 'Square';
const alt = item.GroupItemTitle || `商品 ${item.SalePageId}`;
```

---

## 11. 可訪問性（Accessibility）

### 11.1 ARIA 屬性

**原則**：為互動元件添加適當的 ARIA 屬性。

**範例**：
```typescript
<Link
  href={`/salepage/${item.SalePageId}`}
  aria-label={item.GroupItemTitle || `商品 ${item.SalePageId}`}
  aria-current={isSelected ? 'page' : undefined}
>
  {content}
</Link>
```

### 11.2 圖片 Alt 文字

**原則**：所有圖片都必須有 alt 屬性。

**範例**：
```typescript
<Image
  src={`https:${item.ItemUrl}`}
  alt={item.GroupItemTitle || '商品圖片'}  // ✅ 必須提供
/>
```

---

## 12. 檢查清單

在實作元件前，確認以下項目：

### Server/Client Component 分離
- [ ] 是否只有 Link 等互動元件需要 Client Component？
- [ ] 資料計算是否可以在 Server 端完成？
- [ ] 是否移除了不必要的 `useMemo`？

### Props 設計
- [ ] 是否只傳遞必要的資料？
- [ ] ID 是否從資料物件中提取？
- [ ] Props 型別是否使用型別提取？

### Next.js 原生功能
- [ ] 是否使用 `<Link>` 而非 `window.location.href`？
- [ ] 是否使用 `<Image>` 元件？
- [ ] 是否遵循 App Router 路由機制？

### 圖片處理
- [ ] 協議相對路徑是否直接拼接 `https:`？
- [ ] 是否沒有建立額外的轉換函數？

### Cache 設計
- [ ] Cache key 是否包含所有參數？
- [ ] 是否使用了 tags 支援按標籤清除？

### 響應式設計
- [ ] 是否使用單一元件處理 Desktop + Mobile？
- [ ] 是否透過 CSS 類別控制響應式？
- [ ] 是否避免建立兩個獨立的元件？

### CSS 優化
- [ ] 選中狀態是否使用 CSS border？
- [ ] 是否使用 Tailwind 工具類別？
- [ ] 是否避免 inline styles？

### 元件拆分
- [ ] 互動部分是否拆分為獨立的 Client Component？
- [ ] Server Component 是否只負責資料獲取和靜態渲染？

---

## 13. 常見錯誤與解決方案 (Common Errors & Solutions)

### 13.1 Server/Client Component 分離錯誤

**錯誤範例 1：不必要地使用 Client Component**
```typescript
// ❌ 整個元件都標記為 Client Component
'use client';

export function ProductList({ products }) {
  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

**正確做法**：
```typescript
// ✅ Server Component：純展示，無互動
export function ProductList({ products }) {
  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

**錯誤範例 2：在 Server Component 中使用 Hooks**
```typescript
// ❌ Server Component 不能使用 Hooks
export function ProductList({ products }) {
  const filtered = useMemo(() => {
    return products.filter(p => p.active);
  }, [products]);
  
  return <div>{/* ... */}</div>;
}
```

**正確做法**：
```typescript
// ✅ Server Component 直接計算
export function ProductList({ products }) {
  const filtered = products.filter(p => p.active);
  
  return <div>{/* ... */}</div>;
}
```

### 13.2 Cache Key 設計錯誤

**錯誤範例：Cache key 不包含參數**
```typescript
// ❌ 所有商品頁共用同一個 cache
export const getSalePage = unstable_cache(
  async (id: string, shopId: number) => fetchSalePage(id, shopId),
  ['sale-page'], // ❌ 缺少參數
  { revalidate: 300 },
);
```

**正確做法**：
```typescript
// ✅ 每個商品頁獨立 cache
export const getSalePage = async (id: string, shopId: number) => {
  return unstable_cache(
    async () => fetchSalePage(id, shopId),
    ['sale-page', id, String(shopId)], // ✅ 包含所有參數
    {
      revalidate: 300,
      tags: [`salepage-${id}`], // ✅ 支援按標籤清除快取
    },
  )();
};
```

### 13.3 Props 設計錯誤

**錯誤範例：傳遞完整資料物件**
```typescript
// ❌ 傳遞完整的資料物件
<SalepageGroupWrapper salePageData={salePageData} />
```

**正確做法**：
```typescript
// ✅ 只傳遞必要的資料
<SalepageGroupWrapper
  groupData={salePageData.SalePageGroup}
  currentSalePageId={salePageData.Id}
/>
```

### 13.4 程式碼品質檢查要點

**檢查清單**：

- [ ] **Server/Client 分離**：
  - [ ] 所有元件都已正確標記為 Server Component 或 Client Component
  - [ ] Server Component 沒有使用 Hooks（useState, useEffect, useMemo 等）
  - [ ] Client Component 只處理最小必要的互動邏輯

- [ ] **Cache 設計**：
  - [ ] 所有 `unstable_cache` 的 key 都包含所有參數
  - [ ] 所有 cache 都支援 tags 清除快取
  - [ ] Cache revalidate 時間合理（建議 300 秒）

- [ ] **Props 設計**：
  - [ ] 所有 Props 都符合最小化原則
  - [ ] 沒有傳遞完整的資料物件
  - [ ] Props 型別定義完整（TypeScript）

- [ ] **Next.js 原生功能**：
  - [ ] 導航使用 Next.js `<Link>` 元件
  - [ ] 圖片使用 Next.js `<Image>` 元件
  - [ ] 沒有使用 `window.location` 或 `<a>` 標籤

- [ ] **型別安全**：
  - [ ] 所有介面都有完整的 TypeScript 定義
  - [ ] 沒有使用 `any` 型別
  - [ ] 所有函式都有明確的參數和回傳值型別

- [ ] **錯誤處理**：
  - [ ] 所有 API 呼叫都有錯誤處理
  - [ ] 使用 Error Boundary 捕捉渲染錯誤
  - [ ] 邊界情況都有適當的處理

---

## 參考資料

- [Next.js 15 App Router 文件](https://nextjs.org/docs/app)
- [React Server Components](https://react.dev/reference/rsc/server-components)
- [Tailwind CSS 文件](https://tailwindcss.com/docs)
- [refactor-constitution.md](./refactor-constitution.md) - 架構層面的指導原則

