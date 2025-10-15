# Notes Directory

This directory contains supplementary documentation and implementation notes for the InstallFinder module.

## Contents

### Architecture & Refactoring
- **[REFACTORING-SUMMARY.md](REFACTORING-SUMMARY.md)** - Overview of the module refactoring from monolithic script to proper module structure
- **[HTML-TEMPLATE-REFACTORING.md](HTML-TEMPLATE-REFACTORING.md)** - How the HTML generation was refactored to use external template files

### HTML Report Features
- **[HTML-FEATURES.md](HTML-FEATURES.md)** - Complete guide to all HTML report features (themes, search, sorting, column visibility)
- **[HTML-ENHANCEMENT-SUMMARY.md](HTML-ENHANCEMENT-SUMMARY.md)** - Technical implementation details of the HTML report enhancements
- **[COLUMN-VISIBILITY-FEATURE.md](COLUMN-VISIBILITY-FEATURE.md)** - Deep dive into the column visibility control system
- **[COLUMN_CUSTOMIZATION.md](COLUMN_CUSTOMIZATION.md)** - Guide for modifying HTML report columns dynamically with template-driven approach

### Output Formatting
- **[FORMATTING.md](FORMATTING.md)** - Custom type definitions and PowerShell formatting views (table/list display)

## Purpose

The Notes folder is used for:
- Implementation guides and tutorials
- Architectural decision records (ADRs)
- Developer documentation
- Technical notes and patterns
- Feature summaries
- Migration guides

## Convention

When adding notes:
1. Use descriptive, ALL_CAPS filenames for major topics (e.g., `COLUMN_CUSTOMIZATION.md`)
2. Use PascalCase for specific features (e.g., `RemoteExecution.md`)
3. Include a clear purpose/overview at the top
4. Add entry to this README for discoverability, organized by category
