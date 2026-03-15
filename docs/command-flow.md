# Command Flow

Blocks represent the logical TIR structure,
while Records represent the rendered Vim table representation.

## Data Types

```text
flat file
   ↓
fl_lines   : string[]   (flat text lines)
   ↓
js_lines   : string[]   (NDJSON text lines)
   ↓
ndjsons    : Ndjson[]   (parsed NDJSON objects: Attr_file | Attr | Record)
   ↓
Blocks     : Block[]    (TIR block structure)
   ↓
records    : Record[]   (unparsed Record objects)
   ↓
vi_lines   : string[]   (lines rendered for vim buffer)
   ↓
vim buffer
```

---

## BufReadPost (init.lua from_flat)

```text
flat file
  → (neovim)            read file into fl_lines
  → (external parser)   fl_lines → js_lines
  → (flat_parser.lua)   js_lines → ndjsons → Blocks (escape lf, tab)
  → (vim_parser.lua)    Blocks → records (add padding into cell) → vi_lines
  → (neovim)            replace vim buffer
```

---

## BufWritePre (init.lua to_flat)

```text
vim buffer
  → (neovim)            get lines into vi_lines
  → (vim_parser.lua)    vi_lines → records → Blocks (remove padding from cell)
  → (flat_parser.lua)   Blocks → ndjsons (unescape lf, tab) → js_lines
  → (external parser)   js_lines → fl_lines
  → (neovim)            write to file
```

## BufWritePost

init.lua from_flat

## BufFilePost

init.lua to_flat

## :Tir redraw

```text
vim buffer
  → (neovim)            get lines into vi_lines
  → (vim_parser.lua)    vi_lines → records →  Blocks (remove padding from cell)
  → (vim_parser.lua)    Blocks → records (add padding in cell) → vi_lines
  → (neovim)            replace vim buffer
```

## :Tir toggle (disable)

init.lua to_flat

## :Tir toggle (enable)

init.lua from_flat

## on_lines

```text
vim buffer
  → (neovim)            get lines into vi_lines
  → (vim_parser.lua)    vi_lines → Records →  Blocks (remove padding from cell)
  → (validator.lua)     Blocks.validate()
  → (vim_parser.lua)    Blocks → Records (add padding in cell) → vi_lines
  → (neovim)            replace vim buffer
```
