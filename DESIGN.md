# Fintech Mobile App UI Design System

## 1. Design Direction

Build a premium dark-mode fintech mobile app based on a modern glassmorphism dashboard style. The UI should feel secure, polished, high-value, and futuristic without looking overly experimental.

The design uses a deep navy-black background, purple gradients, coral/pink highlights, soft glowing cards, rounded components, and large readable financial numbers.

Avoid green and blue as primary theme colors.

---

## 2. Core Visual Style

### Mood
- Premium fintech
- Dark mode first
- Soft glass cards
- Rounded modern banking UI
- Elegant gradients
- Calm but energetic

### Keywords
`dark fintech`, `glassmorphism`, `purple coral gradient`, `premium banking`, `soft glow`, `rounded dashboard`, `mobile-first finance app`

---

## 3. Color System

### Background Colors

```css
--bg-primary: #050711;
--bg-secondary: #0B0D1A;
--bg-card: rgba(255, 255, 255, 0.06);
--bg-card-strong: rgba(255, 255, 255, 0.10);
--bg-nav: rgba(15, 17, 35, 0.88);
```

### Primary Accent

```css
--primary-purple: #7C3AED;
--primary-violet: #8B5CF6;
--primary-deep: #4C1D95;
```

### Secondary Accent

```css
--accent-coral: #FF6B5F;
--accent-pink: #EC4899;
--accent-orange: #FF8A3D;
```

### Text Colors

```css
--text-primary: #FFFFFF;
--text-secondary: #B8B8C8;
--text-muted: #7E8095;
```

### Financial Status Colors

```css
--income-positive: #A78BFA;
--expense-negative: #FF6B5F;
--warning: #FFB86B;
```

Do not use green for income. Use violet/lavender for positive financial movement.

---

## 4. Gradient System

### Main Balance Card Gradient

```css
background: linear-gradient(135deg, #2A145A 0%, #3B1B7A 45%, #20113F 100%);
```

### Primary Button Gradient

```css
background: linear-gradient(135deg, #8B5CF6 0%, #EC4899 55%, #FF7A45 100%);
```

### Active Navigation Gradient

```css
background: linear-gradient(135deg, #5B21B6 0%, #8B5CF6 100%);
```

### Soft Glow

```css
box-shadow: 0 0 40px rgba(139, 92, 246, 0.35);
```

---

## 5. Typography

Use a clean modern sans-serif typeface.

Recommended fonts:
- Inter
- SF Pro Display
- Manrope
- Plus Jakarta Sans

### Type Scale

```css
--font-xs: 12px;
--font-sm: 14px;
--font-base: 16px;
--font-lg: 20px;
--font-xl: 28px;
--font-2xl: 34px;
```

### Font Usage

- Balance amount: 34px, semibold
- Section title: 20px, semibold
- Card label: 14px, medium
- Card amount: 24px, semibold
- Transaction name: 16px, semibold
- Metadata: 13px, regular

---

## 6. Layout Rules

### Screen

```css
width: 390px;
min-height: 844px;
padding: 24px 20px;
background: var(--bg-primary);
```

### Global Spacing

```css
--space-xs: 6px;
--space-sm: 10px;
--space-md: 16px;
--space-lg: 24px;
--space-xl: 32px;
```

### Border Radius

```css
--radius-sm: 12px;
--radius-md: 18px;
--radius-lg: 24px;
--radius-xl: 32px;
```

### Card Border

```css
border: 1px solid rgba(255, 255, 255, 0.08);
```

---

## 7. Home Screen Structure

The home screen contains:

1. Status bar
2. Header with profile, greeting, name, notification button
3. Financial summary section
4. Transaction history
5. Bottom navigation

---

## 8. Header Component

### Structure

- Left: circular user avatar
- Middle: greeting and user name
- Right: circular notification icon with unread dot

### Design

```css
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}
```

Avatar:

```css
width: 52px;
height: 52px;
border-radius: 999px;
border: 2px solid rgba(139, 92, 246, 0.75);
```

Notification button:

```css
width: 52px;
height: 52px;
border-radius: 999px;
background: rgba(255,255,255,0.08);
backdrop-filter: blur(18px);
```

---

## 9. Financial Summary Section

This replaces the old action buttons.

The top section must have three financial blocks:

1. Active Balance
2. Inflow this month
3. Outflow this month

### Active Balance Card

Full-width large card.

Content:
- Wallet icon
- Label: `Active Balance`
- Amount: `$94,765.50`
- Optional hide/show balance icon

Design:

```css
.balance-card {
  padding: 24px;
  border-radius: 28px;
  background: linear-gradient(135deg, #2A145A, #3B1B7A, #20113F);
  border: 1px solid rgba(255,255,255,0.10);
  box-shadow: 0 20px 60px rgba(124,58,237,0.25);
}
```

### Inflow / Outflow Cards

Two cards below the active balance card.

Grid:

```css
display: grid;
grid-template-columns: 1fr 1fr;
gap: 14px;
```

Each card includes:
- Circular icon
- Label
- Amount
- Percentage change chip

Inflow example:

```txt
Inflow this month
$12,430.80
↑ 18.6%
```

Outflow example:

```txt
Outflow this month
$7,286.45
↓ 9.3%
```

Inflow card should use violet/lavender accents.  
Outflow card should use coral/red-orange accents.

---

## 10. Transaction History Section

### Header

Left:

```txt
Transaction History
```

Right:

```txt
View all
```

`View all` uses coral or violet text.

### Transaction Card

Each row contains:
- Contact avatar
- Name
- Time
- Amount
- Category

Example:

```txt
Kristin Watson
09:40 AM

-$125.00
Traveling
```

Design:

```css
.transaction-card {
  height: 74px;
  padding: 14px 16px;
  border-radius: 20px;
  background: rgba(255,255,255,0.055);
  border: 1px solid rgba(255,255,255,0.07);
}
```

Positive amounts may use lavender.  
Negative amounts may use white or coral depending on emphasis.

---

## 11. Bottom Navigation

Bottom nav should be floating, glassy, and rounded.

Tabs:
1. Home
2. Savings
3. Cards
4. Account

### Design

```css
.bottom-nav {
  position: fixed;
  bottom: 20px;
  left: 20px;
  right: 20px;
  height: 78px;
  border-radius: 28px;
  background: rgba(15,17,35,0.88);
  backdrop-filter: blur(24px);
  border: 1px solid rgba(255,255,255,0.08);
}
```

Active tab:

```css
.active-tab {
  background: linear-gradient(135deg, #5B21B6, #8B5CF6);
  color: white;
  box-shadow: 0 0 28px rgba(139,92,246,0.45);
}
```

---

## 12. Top Up Method Screen

### Structure

- Header with back button, title, add button
- Payment method list
- Sticky bottom continue button

### Payment Method Card

Each item includes:
- Brand icon
- Payment name
- Email/account identifier
- Optional chevron

Card design:

```css
.payment-card {
  height: 72px;
  padding: 16px;
  border-radius: 18px;
  background: rgba(255,255,255,0.055);
  border: 1px solid rgba(255,255,255,0.07);
}
```

Button:

```css
.primary-button {
  height: 56px;
  border-radius: 999px;
  background: linear-gradient(135deg, #8B5CF6, #EC4899, #FF7A45);
  color: white;
  font-weight: 600;
}
```

---

## 13. Select Contact Screen

### Structure

- Header with back button, title, search button
- Segmented control: All Contacts / Favorites
- Contact list
- Sticky bottom button

### Segmented Control

```css
.segment {
  height: 48px;
  border-radius: 999px;
  background: rgba(255,255,255,0.06);
}
```

Active segment:

```css
background: linear-gradient(135deg, #8B5CF6, #EC4899, #FF7A45);
```

### Contact Card

Each contact card contains:
- Avatar
- Name
- Email
- Favorite star icon

Use coral/pink filled stars for favorite contacts.

---

## 14. Savings Empty State Screen

### Structure

- Header with back button, title, menu button
- Center empty state illustration
- Empty state title
- Supporting text
- CTA button
- Bottom navigation

### Empty State Content

```txt
Ready to start saving?
You haven’t set any savings goals yet.
Create Your First Goal
```

### Illustration Style

Use a soft 3D piggy bank or wallet icon with purple/coral lighting.

### CTA Button

Same primary gradient button.

---

## 15. Icon Style

Use outline icons with rounded edges.

Recommended icon set:
- Lucide
- Phosphor Icons
- Heroicons

Icon rules:
- Stroke width: 1.8px to 2px
- Default color: `#B8B8C8`
- Active color: `#FFFFFF`
- Accent icons: gradient container with white icon

---

## 16. Component Inventory

Required reusable components:

```txt
AppShell
StatusBar
ScreenHeader
UserHeader
IconButton
GlassCard
BalanceCard
MetricCard
TransactionList
TransactionItem
BottomNavigation
PrimaryButton
PaymentMethodCard
SegmentedControl
ContactCard
EmptyState
```

---

## 17. Data Models

### User

```ts
type User = {
  id: string;
  name: string;
  avatarUrl: string;
  greeting?: string;
};
```

### WalletSummary

```ts
type WalletSummary = {
  activeBalance: number;
  currency: string;
  inflowThisMonth: number;
  outflowThisMonth: number;
  inflowChangePercent: number;
  outflowChangePercent: number;
};
```

### Transaction

```ts
type Transaction = {
  id: string;
  personName: string;
  avatarUrl: string;
  time: string;
  amount: number;
  type: "inflow" | "outflow";
  category: string;
};
```

### PaymentMethod

```ts
type PaymentMethod = {
  id: string;
  provider: string;
  account: string;
  iconUrl?: string;
};
```

### Contact

```ts
type Contact = {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  isFavorite: boolean;
};
```

---

## 18. Interaction Rules

### Balance Visibility

Tapping the eye icon hides/shows the active balance.

Hidden state:

```txt
$••••••••
```

### Bottom Navigation

Tapping each tab changes the active screen.

### Contact Favorites

Tapping the star toggles favorite status.

### Segmented Control

`All Contacts` shows all contacts.  
`Favorites` shows only favorite contacts.

### Primary Buttons

Primary buttons should have a subtle pressed scale effect.

```css
transform: scale(0.98);
```

---

## 19. Motion Guidelines

Use subtle motion only.

### Recommended Animations

- Screen fade in: 180ms
- Card rise in: 220ms
- Button press scale: 100ms
- Tab switch: 180ms
- Empty state illustration float: slow 3s loop

Avoid excessive bouncing.

---

## 20. Accessibility

Minimum requirements:
- Text contrast must be readable on dark background.
- Buttons must have at least 44px height.
- Interactive icons need accessible labels.
- Do not rely on color alone for inflow/outflow.
- Use arrows and labels along with colors.
- Amounts should support screen-reader-friendly formatting.

---

## 21. AI Agent Implementation Notes

When generating this app:

- Preserve the exact screen structure.
- Do not add old action buttons under the balance card.
- The home top section must contain exactly:
  - Active Balance
  - Inflow this month
  - Outflow this month
- Keep dark mode as the default.
- Do not use green or blue as primary theme colors.
- Use purple, violet, coral, pink, and orange accents.
- Use rounded glass cards throughout.
- Use floating bottom navigation.
- Keep the UI mobile-first.
- Use consistent spacing and card radius.
- Use dummy data matching the mockup unless real data is provided.

---

## 22. Example Dummy Data

```ts
const user = {
  id: "u_001",
  name: "Leslie Alexander",
  avatarUrl: "/avatars/leslie.png",
  greeting: "Good morning 👋"
};

const walletSummary = {
  activeBalance: 94765.5,
  currency: "USD",
  inflowThisMonth: 12430.8,
  outflowThisMonth: 7286.45,
  inflowChangePercent: 18.6,
  outflowChangePercent: 9.3
};

const transactions = [
  {
    id: "t_001",
    personName: "Kristin Watson",
    avatarUrl: "/avatars/kristin.png",
    time: "09:40 AM",
    amount: -125,
    type: "outflow",
    category: "Traveling"
  },
  {
    id: "t_002",
    personName: "Jane Cooper",
    avatarUrl: "/avatars/jane.png",
    time: "10:30 AM",
    amount: 200,
    type: "inflow",
    category: "Traveling"
  },
  {
    id: "t_003",
    personName: "Wade Warren",
    avatarUrl: "/avatars/wade.png",
    time: "11:55 AM",
    amount: -325,
    type: "outflow",
    category: "Traveling"
  }
];
```

---

## 23. Final Design Goal

The final application should look like a premium AI-ready fintech wallet: secure, polished, modern, dark, rounded, and financially trustworthy.

It should feel more like a high-end financial operating system than a casual expense tracker.
