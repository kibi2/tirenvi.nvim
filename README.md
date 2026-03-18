# tirenvi.nvim

[![CI](https://github.com/kibi2/tirenvi.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/kibi2/tirenvi.nvim/actions)
![GitHub release](https://img.shields.io/github/v/release/kibi2/tirenvi.nvim)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-57A143?logo=neovim)

> Structural TIR editing for Neovim — pure text, always valid.

![demo gif](./demo.gif)

Raw CSV → structured table view → edit → redraw → undo/redo → back to raw.

## Design Philosophy

* Vim-first
* Text-only buffer
* Structurally safe
* Fully reversible transformation
* No hidden metadata
* Always valid

## Why?

CSV is text.

But it is also structure.

Tirenvi lets you edit structured tabular data
without leaving Vim’s native editing model —
while guaranteeing structural integrity.

You edit text.
Tirenvi preserves structure.

## Core Architecture

At the center is: **TIR — Tabular Intermediate Representation**

```text
flat (csv, tsv, ...)
        ↓ external parser
TIR (intermediate representation)
        ↓ tirenvi
tir-vim (structured buffer view)
```

Editing happens in **tir-vim format**.

On save:

```text
tir-vim → TIR → original flat format
```

Key principles:

* The buffer contains only text
* No hidden state
* No shadow buffer
* No custom buffer type
* Transformations are reversible
* The buffer is always structurally valid

## Features

* Render CSV/TSV into aligned structured view
* Preserve original file format on save
* Automatic structural correction
* Toggle raw ↔ structured view
* External parser architecture (extensible)
* Works with all native Vim motions and operators
* No learning curve

## Structural Integrity Model

Tirenvi is a **strict editor**.

* Invalid structural edits are detected
* In Normal mode: corrected immediately
* In Insert mode: corrected after leaving Insert
* Undo tree integrity is preserved
* Only leaf undo states are auto-corrected

Structural integrity is preserved in the current editing state.

Tirenvi respects Vim’s undo tree.
Historical undo states are not modified,
even if they contain temporary structural inconsistencies.

## Installation

### lazy.nvim

```lua
{
  "kibi2/tirenvi.nvim",
  config = function()
    require("tirenvi").setup()
  end,
}
```

### vim-plug

```vim
Plug 'kibi2/tirenvi.nvim'
```

### Requirements

* Neovim >= 0.9
* UTF-8 environment

Install CSV parser:

```bash
pip install tir-csv
```

## Usage

Automatically activates for:

* `.csv`
* `.tsv`

Custom parser mapping:

```lua
require("tirenvi").setup({
  parser_map = {
    csv = { command = "tir-csv", options = {} },
    tsv = { command = "tir-csv", options = { "--delimiter", "\t" } },
  }
})
```

## Commands

| Command       | Description                        |
| ------------- | ---------------------------------- |
| `:Tir redraw` | Recalculate column widths          |
| `:Tir toggle` | Switch raw ↔ structured table view |

All native Vim editing works.

* `dd`, `yy`, `p`, `D`, `o`, `R`, `J`, and more
* Command-line command
* Visual mode command

No special editing mode.

## Column Editing

Columns are structural units.

To modify a column:

1. Enter Visual Block mode (`<C-v>`)
2. Select vertically
3. Apply standard operators (`d`, `p`, etc.)

Operations that would break structure
are automatically corrected.

## Pipe Motions

Fast horizontal navigation across cells.

```lua
vim.keymap.set({ 'n', 'o', 'x' }, '<leader>tf', require('tirenvi').motion.f, { expr = true })
vim.keymap.set({ 'n', 'o', 'x' }, '<leader>tF', require('tirenvi').motion.F, { expr = true })
vim.keymap.set({ 'n', 'o', 'x' }, '<leader>tt', require('tirenvi').motion.t, { expr = true })
vim.keymap.set({ 'n', 'o', 'x' }, '<leader>tT', require('tirenvi').motion.T, { expr = true })
```

They behave like Vim’s `f/F/t/T`,
but target table separators.

`;` and `,` continue to repeat as usual.

## What Tirenvi Is Not

* Not a spreadsheet
* Not a new editing mode
* Not a hidden AST editor
* Not a file-format converter

It is a structured text editor layer.

## Roadmap

### Next

* Markdown (GFM) support
* Text objects (table, row, column, cell)
* Column resize command

### Future

* Header pinning
* Column formatting presets
* Multi-line cell editing
* Outline mode
* Optional non-strict mode (experimental)

## Comparison

| Feature                   | Tirenvi | csv.vim | Spreadsheet tools |
| ------------------------- | ------- | ------- | ----------------- |
| Native Vim editing        | ✅      | ⚠️      | ❌                |
| Always structurally valid | ✅      | ❌      | ⚠️                |
| No file format change     | ✅      | ❌      | ❌                |
| No custom buffer type     | ✅      | ❌      | ❌                |
| Toggle raw view           | ✅      | ❌      | ❌                |

Tirenvi prioritizes **structural safety with Vim purity**.

## Contributing

The architecture centers around:

* flat ↔ TIR (external)
* TIR ↔ tir-vim (internal)

Large changes should respect this separation.

Please open an issue before major design proposals.

## License

MIT License.

