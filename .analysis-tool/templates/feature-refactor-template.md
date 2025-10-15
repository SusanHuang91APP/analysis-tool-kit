# Next.js 功能重構範本：[功能名稱]

> **功能名稱**：[填寫功能名稱，例如：年齡限制確認彈窗]  
> **舊版實作**：[填寫舊版技術，例如：AngularJS 1.x Controller + Cookie]  
> **新版實作**：[填寫新版技術，例如：Next.js Client Component + Zustand]  
> **參考文件**：[填寫相關分析文件路徑]

---

## 1. 功能對照

### 1.1 舊版實作

> **填寫說明**：簡要列出舊版實作的核心功能點，以及主要的技術債或問題。

**核心功能**：
- ✅ [功能點 1]
- ✅ [功能點 2]
- ✅ [功能點 3]

**技術債**：
- ❌ [問題 1，例如：安全性不足，Cookie 可被輕易繞過]
- ❌ [問題 2，例如：與頁面緊密耦合，難以重用]
- ❌ [問題 3，例如：依賴過時的狀態管理方式]

---

## 2. 新版實作 (Next.js)

### 2.1 檔案結構

> **填寫說明**：定義新功能的檔案結構。對於可重用的功能元件 (Feature Component)，建議放在 `components/features/` 目錄下。

```
components/
└── features/
    └── [FeatureName]/
        ├── index.tsx                  # 主元件 (通常是 Client Component)
        ├── constants.ts               # [可選] 常數
        └── types.ts                   # [可選] 型別定義

lib/
└── stores/
    └── [feature].store.ts           # [可選] 若需要全域狀態管理
```

### 2.2 技術選型

> **填寫說明**：說明選擇特定技術的原因，展現架構決策的考量。

- ✅ **Zustand**: [說明為何使用，例如：用於管理需要從任何地方觸發的彈窗狀態，比 Context API 更簡潔]
- ✅ **shadcn/ui (`Dialog`)**: [說明為何使用，例如：提供無樣式、符合 a11y 標準的對話框元件，易於客製化]
- ✅ **`'use client'`**: [說明為何使用，例如：此元件涉及狀態和事件處理，必須是 Client Component]

---

## 3. 全域狀態管理 (Zustand)

**檔案**：`lib/stores/[feature].store.ts`

> **填寫說明**：如果此功能需要一個可以從應用程式任何地方存取的狀態（例如：一個全域的 Modal），使用 Zustand 來建立一個 store。

```typescript
import { create } from 'zustand';

interface [Feature]State {
  isOpen: boolean;
  open: () => void;
  close: () => void;
}

export const use[Feature]Store = create<[Feature]State>((set) => ({
  isOpen: false,
  open: () => set({ isOpen: true }),
  close: () => set({ isOpen: false }),
}));
```

---

## 4. 主元件實作

**檔案**：`components/features/[FeatureName]/index.tsx`

> **填寫說明**：實作功能元件本身。這通常是一個 Client Component，負責處理 UI 和互動邏輯。它應該從 Zustand store 讀取狀態，並在用戶互動時呼叫 store 的 actions。

```typescript
'use client';

import { useRouter } from 'next/navigation';
import { use[Feature]Store } from '@/lib/stores/[feature].store';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

export function [FeatureName]Modal() {
  const { isOpen, close } = use[Feature]Store();
  const router = useRouter();

  const handleConfirm = () => {
    // [填寫說明：處理確認邏輯，例如設定 Cookie、發送 API 請求等]
    close();
    router.refresh(); // 重新整理當前頁面的 Server Component 資料
  };

  const handleCancel = () => {
    // [填寫說明：處理取消邏輯，例如導向其他頁面]
    close();
  };

  return (
    <Dialog open={isOpen} onOpenChange={close}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>[功能標題]</DialogTitle>
          <DialogDescription>
            [功能說明文字]
          </DialogDescription>
        </DialogHeader>
        {/* ... [其他 UI 元素] ... */}
        <Button onClick={handleConfirm}>確認</Button>
      </DialogContent>
    </Dialog>
  );
}
```

---

## 5. 使用模式：全域掛載與觸發

> **填寫說明**：這是一個強大的模式，用於處理像 Modal 或 Toast 這類需要在任何地方被觸發的全域 UI。
> 1.  在根佈局 `layout.tsx` 中掛載一次元件。
> 2.  在需要觸發此功能的 Server Component 中，透過一個輔助的 `Initializer` Client Component 來呼叫 Zustand action。

### 5.1 在根佈局中掛載

**檔案**：`app/layout.tsx`

```typescript
import { [FeatureName]Modal } from '@/components/features/[FeatureName]';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        {/* 在此掛載全域元件，它會根據 Zustand 狀態決定是否顯示 */}
        <[FeatureName]Modal />
      </body>
    </html>
  );
}
```

### 5.2 在 Server Component 中觸發

**檔案**：`app/[...]/page.tsx`

```typescript
import { cookies } from 'next/headers';
import { Initializer } from '@/components/Initializer'; // 輔助元件
import { use[Feature]Store } from '@/lib/stores/[feature].store';

export default async function SomePage() {
  // [填寫說明：在 Server Component 中定義觸發條件]
  const needsToTriggerFeature = ... // [例如：檢查 Cookie、用戶權限等]

  return (
    <div>
      {/* 
        如果滿足條件，我們渲染 Initializer 元件，
        它會在客戶端載入時，呼叫 Zustand 的 action 來開啟 Modal。
        這是在 Server Component 中安全觸發客戶端狀態的推薦模式。
      */}
      {needsToTriggerFeature && (
        <Initializer action={() => use[Feature]Store.getState().open()} />
      )}
      
      <h1>頁面內容</h1>
    </div>
  );
}

// components/Initializer.tsx (這是一個可共用的輔助元件)
'use client';
import { useEffect } from 'react';

export const Initializer = ({ action }: { action: () => void }) => {
  useEffect(() => {
    action();
  }, [action]);
  return null;
};
```

---

## 6. 檔案建立檢查清單

> **填寫說明**：按照此清單逐一建立檔案，確保功能元件完整且可重用。✅ 表示必需，🔹 表示可選。

### 6.1 核心功能元件

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/features/[FeatureName]/index.tsx` | 主要功能元件 (Client Component)，實作核心 UI 與互動邏輯 | ✅ 必需 |
| `components/features/[FeatureName]/types.ts` | 功能元件專用型別定義 (Props, State 等) | ✅ 必需 |
| `components/features/[FeatureName]/constants.ts` | 常數定義 (如：預設值、列舉、設定值) | 🔹 可選 |
| `components/features/[FeatureName]/utils.ts` | 輔助函式 (資料處理、格式化等) | 🔹 可選 |

### 6.2 子元件 (如功能複雜度高)

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/features/[FeatureName]/components/[SubComponent].tsx` | 功能專用的子元件 | 🔹 可選 |
| `components/features/[FeatureName]/components/[Form].tsx` | 表單元件 (如需要) | 🔹 可選 |
| `components/features/[FeatureName]/components/[Display].tsx` | 純展示用子元件 | 🔹 可選 |

### 6.3 狀態管理 (如需全域狀態)

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `lib/stores/[feature].store.ts` | Zustand 狀態管理，用於可從任何地方存取的全域狀態 | 🔹 可選 |
| `lib/stores/[feature].types.ts` | Store 專用型別定義 | 🔹 可選 |

### 6.4 Hooks (如邏輯複雜需封裝)

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/features/[FeatureName]/hooks/use[Feature].ts` | 功能專用的自定義 Hook，封裝複雜邏輯 | 🔹 可選 |
| `components/features/[FeatureName]/hooks/use[Feature]Data.ts` | 資料獲取 Hook (使用 SWR) | 🔹 可選 |
| `components/features/[FeatureName]/hooks/use[Feature]Form.ts` | 表單處理 Hook (使用 React Hook Form) | 🔹 可選 |

### 6.5 輔助元件 (全域使用模式)

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/Initializer.tsx` | 通用的客戶端初始化元件，用於在 Server Component 中觸發客戶端狀態 | 🔹 可選 |

### 6.6 測試檔案

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/features/[FeatureName]/__tests__/index.test.tsx` | 主元件單元測試 | ✅ 必需 |
| `components/features/[FeatureName]/__tests__/[SubComponent].test.tsx` | 子元件單元測試 | 🔹 可選 |
| `components/features/[FeatureName]/hooks/__tests__/use[Feature].test.ts` | Hook 測試 | 🔹 可選 |
| `lib/stores/__tests__/[feature].store.test.ts` | Zustand Store 測試 | 🔹 可選 |

### 6.7 文件檔案

| 檔案路徑 | 說明 | 狀態 |
|---|---|----|
| `components/features/[FeatureName]/README.md` | 功能元件使用說明文件 | 🔹 可選 |
| `components/features/[FeatureName]/[FeatureName].stories.tsx` | Storybook 故事檔 (用於視覺化開發與測試) | 🔹 可選 |

---

## 7. 測試

**檔案**：`components/features/[FeatureName]/__tests__/index.test.tsx`

> **填寫說明**：為你的功能元件編寫單元測試。使用 Vitest 和 React Testing Library，並 mock 掉外部依賴，如 `next/navigation` 和 Zustand store。

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { [FeatureName]Modal } from '..';
import { use[Feature]Store } from '@/lib/stores/[feature].store';

// Mock Next.js router
const mockRouter = { push: vi.fn(), refresh: vi.fn() };
vi.mock('next/navigation', () => ({
  useRouter: () => mockRouter,
}));

describe('[FeatureName]Modal', () => {
  it('當 store 的 isOpen 為 true 時，應顯示彈窗', () => {
    // [Arrange] 安排狀態
    use[Feature]Store.setState({ isOpen: true });
    
    // [Act] 執行
    render(<[FeatureName]Modal />);
    
    // [Assert] 驗證
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('[功能標題]')).toBeInTheDocument();
  });

  it('點擊確認按鈕後，應呼叫 close action 和 router.refresh', () => {
    // [Arrange]
    const { close } = use[Feature]Store.getState();
    const closeSpy = vi.spyOn({ close }, 'close');
    use[Feature]Store.setState({ isOpen: true, close: closeSpy });

    render(<[FeatureName]Modal />);
    
    // [Act]
    fireEvent.click(screen.getByText('確認'));

    // [Assert]
    expect(closeSpy).toHaveBeenCalled();
    expect(mockRouter.refresh).toHaveBeenCalled();
  });
});
```

---

## 8. 驗收標準 (Acceptance Criteria)

> **填寫說明**：在開始重構前，定義清晰的驗收標準，確保交付成果符合預期。

### Phase 1: 核心功能實作
- [ ] **功能完整性**: 所有舊版的核心功能點（參考 `## 1.1`），皆已在新版實作中完整實現
- [ ] **技術債改善**: 舊版已知的技術債（例如 `## 1.1` 中列出的安全性、耦合性問題）已被有效解決
- [ ] **元件建立**: 已按照 `## 6 檔案建立檢查清單` 建立所有必需檔案
- [ ] **型別安全**: 所有 Props、State、API 回應皆有完整的 TypeScript 型別定義

### Phase 2: 整合與使用
- [ ] **整合性**: 新元件已遵循全域使用模式（如 `## 5` 所述），在應用程式中被正確掛載與觸發
- [ ] **狀態管理**: 若使用 Zustand，store 已正確建立且可從任何地方存取
- [ ] **Server-Client 協作**: Server Component 與 Client Component 之間的資料傳遞正確無誤
- [ ] **初始化邏輯**: 使用 `Initializer` 元件在適當時機觸發功能（如適用）

### Phase 3: 測試與品質
- [ ] **測試覆蓋率**: 已為新元件編寫完整的單元測試（如 `## 7` 所述），且測試案例覆蓋所有主要邏輯與邊界情況
- [ ] **測試通過率**: 所有測試案例皆通過，無 failing tests
- [ ] **無障礙性**: 元件符合 WCAG 2.1 AA 標準，包含適當的 ARIA 標籤與鍵盤導航支援
- [ ] **程式碼品質**: 程式碼遵循專案的 coding standard，通過 ESLint 和 TypeScript 檢查

### Phase 4: 效能與體驗
- [ ] **效能測試**: 新功能的使用者體驗流暢，沒有可感知的效能問題
- [ ] **Bundle Size**: 確認元件 bundle size 合理，未引入不必要的依賴
- [ ] **載入速度**: 功能元件的初次載入與互動時間符合預期 (< 200ms)
- [ ] **錯誤處理**: 邊界情況與錯誤狀態皆有妥善處理與提示

### Phase 5: 文件與交接
- [ ] **使用文件**: 已建立元件使用說明文件（`README.md` 或 Storybook）
- [ ] **程式碼註解**: 複雜邏輯處已添加清晰的註解說明
- [ ] **團隊審查**: 已通過至少一位團隊成員的 Code Review
- [ ] **知識轉移**: 已向團隊成員說明新功能的實作與使用方式
