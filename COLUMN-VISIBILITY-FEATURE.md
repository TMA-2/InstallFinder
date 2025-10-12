# Column Visibility Feature - Implementation Summary

## Overview

Added a sophisticated column visibility control system to the HTML report template, allowing users to show/hide table columns dynamically.

## UI Components

### Dropdown Button
- **Location**: Top-right controls area, next to Theme toggle
- **Label**: "⚙️ Columns"
- **Behavior**: Opens/closes checkbox menu on click

### Column Menu
- **Type**: Dropdown panel
- **Position**: Absolute, right-aligned below button
- **Features**:
  - Checkbox list for each column
  - Header with "All" and "Reset" quick actions
  - Scrollable (max-height: 400px for many columns)
  - Click-outside-to-close behavior

### Checkbox Options
Each column has:
- **Checkbox**: Toggle visibility
- **Label**: Column name
- **State**: Checked = visible, Unchecked = hidden
- **Required Columns**: Disabled (grayed out) - cannot be unchecked

## Column Configuration

### Required Columns (Cannot Hide)
1. **Computer** - Essential for multi-machine reports
2. **Name** - Primary identifier

### Optional Columns (Can Toggle)
3. Version
4. Publisher  
5. Install Date
6. GUID
7. Size (MB)
8. Architecture
9. Location

### Default Visibility
**All columns visible by default** on first load to match the complete table data.

Users can then customize their view:
- Hide unnecessary columns (GUID, Location, etc.)
- Show only essential data
- Preferences persist via LocalStorage

**PowerShell DefaultDisplayPropertySet** (Computer, Name, Version, Publisher) serves as a suggested baseline but does not auto-hide columns on first load.

## JavaScript Implementation

### Column Data Structure
```javascript
const columns = [
    { index: 0, name: 'Computer', required: true },
    { index: 1, name: 'Name', required: true },
    { index: 2, name: 'Version', required: false },
    // ... etc
];
```

### Key Functions

#### `updateColumnVisibility()`
- Reads checkbox states
- Shows/hides `<th>` headers using `display: none`
- Shows/hides `<td>` cells using nth-child selectors
- Saves state to LocalStorage

#### Event Handlers
- **Column Toggle Button**: Opens/closes menu
- **Checkbox Change**: Calls `updateColumnVisibility()`
- **Show All**: Checks all non-required columns
- **Reset**: Restores default visibility and clears LocalStorage
- **Click Outside**: Closes dropdown menu

### LocalStorage Persistence

**Key**: `columnVisibility`  
**Value**: JSON array of booleans  
**Example**: `[true, true, true, true, false, false, false, false, false]`

On page load:
1. Check for saved preferences
2. If found, apply saved visibility
3. If not found, apply defaults

## CSS Styling

### Responsive Controls Layout
```css
.controls {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.controls-left {
    flex: 1; /* Search box takes remaining space */
}

.controls-right {
    display: flex;
    gap: 10px; /* Column + Theme buttons */
}
```

### Dropdown Menu
- Positioned absolute, right-aligned
- Box shadow for depth
- Border radius for modern look
- Scrollable for many columns
- Dark/light theme support

### Checkbox States
- **Normal**: Blue checkbox, white label
- **Required**: Grayed out, cursor: not-allowed
- **Hover**: Background highlight (non-required only)

## User Experience Flow

1. **User clicks "⚙️ Columns" button**
   - Dropdown menu appears
   - Shows all 9 columns with current state

2. **User clicks checkboxes**
   - Columns hide/show instantly
   - State saves to LocalStorage

3. **User clicks "All"**
   - All optional columns become visible
   - Required columns stay checked (disabled)

4. **User clicks "Reset"**
   - Returns to default 4 columns
   - Clears LocalStorage preference

5. **User closes menu** (click outside or re-click button)
   - Preferences persist
   - Next report load remembers settings

## Benefits

### For Users
- ✅ **Customizable View**: Show only relevant columns
- ✅ **Cleaner Reports**: Hide unused data (GUID, Location, etc.)
- ✅ **Persistent Preferences**: Settings remembered across sessions
- ✅ **Quick Actions**: "All" and "Reset" for common scenarios
- ✅ **Mobile Friendly**: Fewer columns = better mobile experience

### For Developers
- ✅ **No PowerShell Changes**: Pure HTML/CSS/JS feature
- ✅ **Easy to Extend**: Add new columns by updating array
- ✅ **Template-Based**: Works with external template approach
- ✅ **No Dependencies**: Vanilla JavaScript, no libraries needed

## Technical Details

### Column Hiding Approach
Uses `display: none` instead of removing elements:
- **Pros**: Maintains DOM structure, easy to toggle back
- **Cons**: Still in DOM (minimal performance impact)

Alternative considered: `visibility: hidden` (takes up space)

### Nth-Child Selector
```javascript
const cells = table.querySelectorAll(`td:nth-child(${col.index + 1})`);
cells.forEach(cell => cell.style.display = isVisible ? '' : 'none');
```

Note: Uses `index + 1` because CSS nth-child is 1-indexed

### Required Columns Logic
```javascript
checkbox.disabled = col.required;
option.className = 'column-option' + (col.required ? ' required' : '');
```

Prevents user from hiding essential columns

## Testing Checklist

- [x] Dropdown opens/closes on button click
- [x] Checkboxes toggle column visibility
- [x] Required columns cannot be unchecked
- [x] "All" button shows all columns
- [x] "Reset" restores defaults
- [x] Preferences save to LocalStorage
- [x] Settings persist across page reloads
- [x] Click outside closes dropdown
- [x] Works in dark and light themes
- [x] Mobile responsive layout

## Browser Compatibility

- ✅ Chrome/Edge (Chromium) - Full support
- ✅ Firefox - Full support
- ✅ Safari - Full support (LocalStorage + ES6)
- ✅ Mobile browsers - Touch-friendly, responsive

**Minimum Requirements**:
- LocalStorage API
- ES6 JavaScript (const, arrow functions, template literals)
- CSS Flexbox

## Future Enhancements

Possible improvements:
1. **Column Reordering**: Drag-and-drop to rearrange columns
2. **Custom Presets**: Save multiple column configurations
3. **Column Groups**: Toggle related columns together (e.g., "System Info")
4. **Export Config**: Share column settings via URL parameter
5. **Column Width Resize**: Drag column borders to adjust width
6. **Freeze Columns**: Pin Computer/Name columns while scrolling

## Related Files

- `Resources/ReportTemplate.html` - Main template with feature
- `HTML-FEATURES.md` - User-facing documentation
- `CHANGELOG.md` - Version history

---

**Implementation Date**: 2025-10-11  
**Feature Type**: UI Enhancement (Non-Breaking)  
**Lines of Code Added**: ~180 (CSS + JavaScript)
