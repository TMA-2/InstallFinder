# HTML Report Features

## Overview
The InstallFinder module includes a sophisticated HTML report generator that creates interactive, themeable, and sortable application reports.

## Key Features

### ⚙️ Column Visibility Control (NEW!)
- **Dropdown Menu**: Click the "⚙️ Columns" button to manage visible columns
- **Checkboxes**: Toggle individual columns on/off
- **Required Columns**: Computer and Name cannot be hidden (grayed out)
- **Show All**: One-click to display all columns
- **Reset to Default**: Restore default view (Computer, Name, Version, Publisher)
- **Persistent Preferences**: Column visibility saved in browser LocalStorage
- **Smooth Transitions**: Columns hide/show instantly without page reload

**Default Visible Columns** (all visible on first load):
- Computer ✅
- Name ✅
- Version ✅
- Publisher ✅
- Install Date ✅
- GUID ✅
- Size (MB) ✅
- Architecture ✅
- Location ✅

**User Can Customize** - Hide any non-required columns via dropdown menu

### 🌓 Theme Toggle
- **Dark Mode**: Default theme optimized for reduced eye strain
- **Light Mode**: Clean, bright theme for daytime viewing
- **Persistent Preference**: Your theme choice is saved in browser local storage
- **Smooth Transitions**: Animated theme switching for a polished experience

### 🔍 Real-Time Search
- **Instant Filtering**: Type to filter applications across all columns
- **Case-Insensitive**: Matches regardless of capitalization
- **Live Counter**: Shows number of visible results
- **No Results Message**: Clear indication when no matches found

### ⬆️⬇️ Sortable Columns
All columns are sortable by clicking the header:
- **Computer** - Sort by hostname
- **Name** - Sort alphabetically by application name
- **Version** - Smart numeric sorting for version numbers
- **Publisher** - Sort by vendor/publisher
- **Install Date** - Chronological sorting
- **GUID** - Sort by installation GUID
- **Size (MB)** - Numeric sorting by size
- **Architecture** - Sort by x86/x64
- **Location** - Sort by installation path

**Visual Indicators**:
- `⇅` - Column is sortable
- `▲` - Currently sorted ascending
- `▼` - Currently sorted descending

### 📊 Statistics Dashboard
Three key metrics displayed at the top:
1. **Visible Applications** - Updates with search filtering
2. **64-bit Applications** - Count of x64 installations
3. **32-bit Applications** - Count of x86 installations

### 📱 Responsive Design
- **Desktop**: Full-width table with all columns visible
- **Tablet**: Adjusted font sizes and padding
- **Mobile**: Stacked layout with reduced spacing
- **Touch-Friendly**: Large click targets for sorting

## Usage Examples

### Basic HTML Report
```powershell
# Generate HTML report (dark mode by default)
Find-InstalledApplication "Microsoft*" -Display -Output HTML
```

### Silent Mode (No Dialog)
```powershell
# Auto-save to temp folder and open in browser
Find-InstalledApplication "Adobe*" -Display -Output HTML -Silent
```

### Custom Search with HTML Export
```powershell
# Find apps installed in 2024, export to HTML
Find-InstalledApplication -Filter {$_.InstallDate -match '2024'} -Display -Output HTML
```

### Remote Computer HTML Report
```powershell
# Generate report for multiple computers
Find-InstalledApplication "*" -ComputerName SERVER01,SERVER02 -Display -Output HTML
```

## HTML Structure

### Header Section
- Report title
- Generation timestamp
- Total application count

### Controls Section
- Search box (real-time filtering)
- Theme toggle button

### Statistics Cards
- Visible count (updates with search)
- Architecture breakdown (x64 vs x86)

### Data Table
Columns included in report:
1. **Computer** - Target hostname
2. **Name** - Application display name
3. **Version** - Version number (smart sorted)
4. **Publisher** - Vendor/publisher name
5. **Install Date** - Installation date
6. **GUID** - Unique identifier
7. **Size (MB)** - Installation size in megabytes
8. **Architecture** - x86 or x64
9. **Location** - Installation path

## Technical Details

### Color Scheme

**Light Mode**:
- Background: #ffffff (white)
- Text: #212529 (near black)
- Accent: #0d6efd (blue)
- Borders: #dee2e6 (light gray)

**Dark Mode**:
- Background: #1a1a1a (near black)
- Text: #e0e0e0 (off white)
- Accent: #4a9eff (bright blue)
- Borders: #404040 (dark gray)

### Browser Compatibility
Tested and working on:
- ✅ Microsoft Edge (recommended)
- ✅ Google Chrome
- ✅ Mozilla Firefox
- ✅ Safari

Requires modern browser with:
- CSS Grid support
- CSS Custom Properties (CSS variables)
- JavaScript ES6+
- LocalStorage API

### File Size
- Base HTML template: ~15KB
- With 100 applications: ~25KB
- With 1000 applications: ~150KB

### Performance
- **Search**: Instant filtering with debouncing
- **Sort**: Efficient array sorting with DOM manipulation
- **Theme**: CSS variable switching (no reflow)

## Advanced Customization

### Modify Default Theme
Edit the `ConvertTo-InstallFinderHtml` function:
```powershell
# Change line 27 to default to light mode:
$DefaultTheme = if ($DarkMode) { 'dark' } else { 'light' }
# becomes:
$DefaultTheme = 'light'
```

### Add Custom Columns
Edit the table generation section to include additional properties:
```powershell
# Add a new <th> in the header
# Add a new <td> in the row template
```

### Modify Colors
Edit the `:root` and `[data-theme="dark"]` CSS variables in the style section.

## Troubleshooting

### Report Opens Blank
- Check that JavaScript is enabled in your browser
- Verify file saved correctly (check file size > 0)
- Try opening in different browser

### Search Not Working
- Ensure JavaScript is enabled
- Check browser console for errors (F12)
- Verify data loaded correctly

### Theme Toggle Not Saving
- Check browser allows localStorage
- Not in private/incognito mode
- Clear browser cache and try again

### Columns Not Sorting
- Click on column header (not cells)
- Ensure JavaScript is enabled
- Check for console errors

## Examples Output

### Small Report (< 10 apps)
```
Installed Applications Report
Generated: 2025-10-11 14:30:00
Total Applications: 5

[Statistics showing counts]
[Sortable table with 5 rows]
```

### Large Report (> 100 apps)
```
Installed Applications Report
Generated: 2025-10-11 14:30:00
Total Applications: 237

[Search box for filtering]
[Statistics showing counts]
[Sortable table with 237 rows]
```

## Version
Added in v0.1.0 (2025-10-11)

## See Also
- `Find-InstalledApplication` - Main function
- `ConvertTo-InstallFinderHtml` - HTML generation function
- `Show-SaveDialog` - File save dialog
