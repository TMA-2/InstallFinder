# InstallFinder HTML Template

This directory contains the HTML template used by the `ConvertTo-InstallFinderHtml` function to generate interactive HTML reports.

## Files

### ReportTemplate.html

The main HTML template file containing:
- Complete HTML structure
- CSS styling with dark/light theme support (CSS custom properties)
- JavaScript for interactivity (theme toggle, sorting, search filtering)
- Placeholder tokens for dynamic content replacement

## Template Placeholders

The template uses uppercase placeholder tokens surrounded by double curly braces:

| Placeholder          | Description                            | Example Value                                |
| -------------------- | -------------------------------------- | -------------------------------------------- |
| `{{TITLE}}`          | Report title                           | `"PowerShell Applications on ITS-ADMIN1036"` |
| `{{DEFAULT_THEME}}`  | Initial theme (dark or light)          | `"dark"`                                     |
| `{{GENERATED_DATE}}` | Report generation timestamp            | `"2025-10-11 14:30:45"`                      |
| `{{TOTAL_COUNT}}`    | Total number of applications           | `"42"`                                       |
| `{{VISIBLE_COUNT}}`  | Initially visible apps (same as total) | `"42"`                                       |
| `{{X64_COUNT}}`      | Count of 64-bit applications           | `"35"`                                       |
| `{{X86_COUNT}}`      | Count of 32-bit applications           | `"7"`                                        |
| `{{TABLE_ROWS}}`     | HTML table rows with application data  | `"<tr><td>...</td></tr>"`                    |

## How It Works

The `ConvertTo-InstallFinderHtml` function:

1. Loads `ReportTemplate.html` as a raw string
2. Calculates values for each placeholder
3. Uses `.Replace('{{PLACEHOLDER}}', $value)` for each token
4. Returns the complete HTML string

## Editing the Template

You can edit `ReportTemplate.html` directly in VS Code with full HTML/CSS/JavaScript syntax highlighting and IntelliSense.

### Tips:
- **Test in browser**: Open the template directly to see the layout (placeholders will show as-is)
- **CSS Variables**: All colors use CSS custom properties in `:root` and `[data-theme="dark"]`
- **Add placeholders**: Use the `{{UPPERCASE_NAME}}` pattern, then update the PowerShell function
- **JavaScript**: Modern ES6+ syntax is fine - users will open in modern browsers

### Example: Adding a Custom Placeholder

1. Add to template:
```html
<div>Report Author: {{AUTHOR}}</div>
```

2. Update PowerShell function:
```powershell
$HtmlContent = $Template.
    Replace('{{AUTHOR}}', $env:USERNAME).
    # ... other replacements
```

## Future Enhancements

This simple replacement system could be extended to:
- **EPS Templates** - For more complex templating with loops
- **Pode Integration** - Use this same template for live web dashboards
- **Multiple Themes** - Additional CSS custom property themes
- **Export Templates** - Allow users to provide their own templates

## Benefits of External Template

✅ **Easier Editing** - Full VS Code syntax highlighting
✅ **Cleaner Code** - Separates presentation from logic
✅ **Version Control** - Git diffs show actual HTML changes
✅ **Reusability** - Same template could be used by other tools
✅ **Testing** - Can open template directly in browser
✅ **No Escaping** - No need to escape quotes in strings

---

Last Updated: 2025-10-11
