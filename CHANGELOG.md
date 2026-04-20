# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-04-20

### Added

- Support for TIR with mixed text and tables (e.g. GFM-style content)
- Multiline cell support with preserved line breaks inside cells
- Column width control commands (set and increment/decrement)
- Automatic wrapping of cell content based on column width
- Repeatable column width adjustments via `.`
- Column text objects (e.g. `vil`, `val`, `v3al`)
- Grid-aware join that merges at the cell level while preserving column structure
- Highlighting for table borders and special characters (`\n`, `\t`)
- Underline-based row separators to visually distinguish wrapped vs non-wrapped cells

### Improved

- Reduced unnecessary buffer reads using caching
- Improved autocmd design with more stable buffer-local handling

### Notes

This release significantly improves table editing ergonomics, especially for multiline cells and column operations.

## [0.2.0] - 2026-03-14

### Changed

- Redesign core architecture
- Reorganize directory structure
- Refactor module layout
- Redesign internal data structures
- Simplify internal data flow

### Notes

This refactoring prepares the codebase for upcoming GFM table support.

## [0.1.0]

### Added

- First release
