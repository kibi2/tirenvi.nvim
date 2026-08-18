# Changelog

All notable changes to this project will be documented in this file.

## [0.5.3] - 2026-08-18

### Added

- Add cell text objects `vic` and `vac` for selecting cell content or cells including the left border.
- Support multi-line selection for wrapped cells.

## [0.5.2] - 2026-08-17

### Fixed

- Fix compatibility with the updated `vim.str_byteindex` and `vim.str_utfindex` API in Neovim 0.11+ while retaining support for Neovim 0.10.
- Remove the deprecation warning reported by `:checkhealth` on newer Neovim versions.

## [0.5.1] - 2026-08-16

### Added

- Added structural motions for TIR buffers:
  - `block_top`
  - `block_bottom`
  - `cell_next`
  - `cell_prev`
- Structural motions support counts and Visual mode.
- Added default key mappings using `Ctrl-h/j/k/l`:
  - `Ctrl-h`: previous cell
  - `Ctrl-l`: next cell
  - `Ctrl-k`: top of block
  - `Ctrl-j`: bottom of block

## [0.5.0] - 2026-07-28

### Added

- Implemented Tir-embedded support.
  - Tables can now be embedded and edited inside arbitrary files such as txt, Python, and Java source files.
- Added column width adjustment commands.
  - `:Tir fit=n`
  - `:Tir fit=`
  - `:Tir fit{+|-}[n]`
  - `:Tir wrap`
- Changed width settings to be managed per table instead of applying to all tables in a file.
- Added `manage_wrap` mode.
  - Enables wrap for plain-style lines when content exceeds the window width.
  - Disables wrap for grid-style lines to preserve table layout.
- Improved vertical navigation behavior.
  - Moving through rows with different cell widths now behaves more naturally.
- Restore the cursor position after `:write` / `WritePost`.
- Automatically install required parser packages when using lazy.nvim.
- Added TIR (ndjson) file I/O support for debugging.
  - `:Tir _read_tir {file}`
  - `:Tir _write_tir {file}`
- Added support for opening files saved in tir-buf format.

### Refactoring

- Reorganized internal modules.
- Reorganized buffer-local layout state handling.
- Rebuilt CI test cases.

## [0.4.0] - 2026-05-25

### Added

* Deferred structural repair mode
* Dirty line tracking and highlighting
* Configurable highlight groups for dirty markers
* Dirty range tracking infrastructure
* `:Tir repair [enable|disable|toggle]`

### Changed

* Rename `:Tir redraw` to `:Tir repair`
* Rename reconcile-based APIs and modules to repair
* Rename `tir-vim` architecture terminology to `tir-buf`
* Rename `vim_*` modules to `buf_*`
* Rename `INVALID` namespace/state to `DIRTY`
* Improve internal pipeline organization and repair flow
* Improve Range utility APIs and naming consistency

### Deprecated

* `:Tir redraw`

  * Deprecated in favor of `:Tir repair`
  * Will be removed in v0.5

### Notes

This release introduces a deferred repair model that allows temporary malformed table edits while preserving a structurally valid internal table model.

Buffer text and internal table state are now treated separately:
the internal attrs/model remains authoritative, while the visible buffer may temporarily diverge until repaired.

This release also continues the transition from the older redraw/reconcile terminology toward a repair-based architecture.

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
