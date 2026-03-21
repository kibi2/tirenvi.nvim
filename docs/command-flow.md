# Command Flow

NDJSON records represent the TIR format itself.

Blocks provide a structured in-memory representation
derived from NDJSON records.

Records represent a render-oriented form used to display
tables in the Vim buffer.

All conversions pass through **Blocks**, which act as the central
intermediate representation.

---

## Architecture Overview

```text
          flat formats
        (tir-flat, CSV, etc.)
                │
                ▼
            fl_lines
                │
        external / flat parser
                │
                ▼
            js_lines
                │
                ▼
            ndjsons
        (TIR serialized form)
                │
                ▼
             Blocks
    (structured representation)
                │
                ▼
             records
       (render-ready rows)
                │
                ▼
            vi_lines
                │
                ▼
           vim buffer
```

NDJSON records represent the TIR format itself.
Blocks are a structured in-memory representation of TIR.
All parsing and rendering operations convert through Blocks.

---

## Data Types

```text
flat file
   ↓
fl_lines   : string[]   (flat text lines)
   ↓
js_lines   : string[]   (NDJSON text lines)
   ↓
ndjsons    : Ndjson[]   (TIR canonical representation)
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

## Transformation Layers

The following components are responsible for converting between layers.

### Parsers

```text
flat_parser
    fl_lines  ↔ Blocks

vim_parser
    vi_lines  ↔ Blocks

external parser
    fl_lines  ↔ js_lines
```

### Structural Transformations

These transformations are internal normalization steps.

```text
ndjsons ↔ Blocks
    escape / unescape LF and TAB characters
    "\n", "\t"  ↔  LF mark, TAB mark

Blocks ↔ records
    convert logical records into renderable rows

    differences from NDJSON records:
      • padding marks are inserted
      • column width and alignment are embedded as padding

records ↔ vi_lines
    insert/remove pipe marks for Vim table rendering
```

---

## Command Flow

### BufReadPost (init.from_flat)

```text
flat file
  → (neovim)             read file into fl_lines
  → (flat_parser.parse)  fl_lines → Blocks
  → (vim_parser.unparse) Blocks → vi_lines
  → (neovim)             replace vim buffer
```

---

### BufWritePre (init.to_flat)

```text
vim buffer
  → (neovim)               get lines into vi_lines
  → (vim_parser.parse)     vi_lines → Blocks
  → (flat_parser.unparse)  Blocks → fl_lines
  → (neovim)               write to file
```

---

### BufWritePost

```text
init.from_flat
```

---

### BufFilePost

```text
init.to_flat
init.from_flat
```

---

### :Tir redraw

```text
vim buffer
  → (neovim)             get lines into vi_lines
  → (vim_parser.parse)   vi_lines → Blocks
  → (vim_parser.unparse) Blocks → vi_lines
  → (neovim)             replace vim buffer
```

---

### :Tir toggle (disable)

```text
init.to_flat
```

---

### :Tir toggle (enable)

```text
init.from_flat
```

---

### on_lines

```text
vim buffer
  → (neovim)             get lines into vi_lines
  → (vim_parser.parse)   vi_lines → Blocks
  → (rapair.repair)      Blocks.repair()
  → (vim_parser.unparse) Blocks → vi_lines
  → (neovim)             replace vim buffer
```
