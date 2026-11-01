# Clean Minimal Chat Design System

This design system defines the visual principles, color tokens, typography scales, dynamic theming, and layout guidelines for the Flutter Chat Application.

## 1. Principles
- **Clean & Minimal**: Ultra-clean interface with no unnecessary visual noise. Focus is 100% on communication.
- **Pure White & True Black**:
  - Light mode uses crisp `#FFFFFF` backgrounds with gentle `#F3F4F6` message bubbles and `#E5E7EB` borders.
  - Dark mode uses OLED/Pitch Black `#000000` with subtle `#18181B` surfaces and `#27272A` dividers.
- **Dynamic Theming**:
  - Supports switching between Light, Dark, and System modes.
  - Supports choosing dynamic accent colors (Blue, Emerald, Violet, Orange, Rose, Slate).
- **Smooth & Lightweight Performance ("Panir moto halka r smooth")**:
  - Const constructors everywhere to prevent redundant widget rebuilds.
  - Native bouncing scroll physics for natural deceleration.
  - Granular State Management via Provider with Selector/Consumer.
  - `RepaintBoundary` for heavy media items to isolate canvas paints.
- **Strict File Limit**:
  - Every file must remain strictly under 250 lines of code.

## 2. Color Palettes
### Light Palette
- `background`: `#FFFFFF`
- `surface`: `#F9FAFB`
- `card`: `#F3F4F6`
- `textPrimary`: `#0F172A`
- `textSecondary`: `#64748B`
- `divider`: `#E2E8F0`

### Dark Palette
- `background`: `#000000`
- `surface`: `#0F0F11`
- `card`: `#18181B`
- `textPrimary`: `#F8FAFC`
- `textSecondary`: `#94A3B8`
- `divider`: `#27272A`

### Dynamic Accent Palette Options
1. **Electric Blue**: `#2563EB` (Primary Default)
2. **Emerald Green**: `#10B981` (Fresh & Vibrant)
3. **Royal Violet**: `#8B5CF6` (Elegant Modern)
4. **Sunset Orange**: `#F97316` (Warm & Punchy)
5. **Rose Pink**: `#EC4899` (Playful & Chic)
6. **Minimal Slate**: `#475569` (Monochrome Minimalist)

## 3. Responsive Dimensions (via flutter_screenutil)
- Base Design Scale: 393 x 852 (Modern Portrait)
- Orientation: Strictly Portrait (Landscape disabled)
- Spacing Scale: 4.w, 8.w, 12.w, 16.w, 20.w, 24.w, 32.w
- Border Radii: 8.r, 12.r, 16.r, 20.r, 24.r, 999.r (circular)

