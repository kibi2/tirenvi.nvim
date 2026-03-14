# Project Overview

This document contains multiple tables embedded in normal text.
It is intended to test GFM table parsing.

---

## 1. Simple table

| Name | Age | City |
| ---- | --- | ---- |
| Alice | 23 | Tokyo |
| Bob | 31 | Osaka |
| Carol | 27 | Nagoya |

Some text between tables.
This should *not* be part of any table.

---

## 2. Alignment test

| Left | Center | Right |
| :--- | :----: | ----: |
| a | b | c |
| 10 | 20 | 30 |
| foo | bar | baz |

---

## 3. Table with inline formatting

| Key | Description | Example |
| --- | ----------- | ------- |
| `id` | **Primary key** | `user_001` |
| name | _Display name_ | **Alice** |
| note | Free text | `a \| b \| c` |

Note: escaped pipes should be preserved.

---

## 4. Different column count (block separation test)

| A | B |
| - | - |
| 1 | 2 |
| 3 | 4 |

Text in between.

| A | B | C | D |
| - | - | - | - |
| 1 | 2 | 3 | 4 |
| 5 | 6 | 7 | 8 |

---

## 5. Table without leading/trailing empty lines
| X | Y |
| - | - |
| x1 | y1 |
| x2 | y2 |
Text immediately after table.

---

## 6. Table inside a section with lists

- item 1
- item 2

| Feature | Status | Comment |
| ------- | ------ | ------- |
| parser | OK | fast |
| writer | WIP | needs tests |
| diff | TODO | later |

- item 3
- item 4

---

## 7. Mixed content, many small tables

### Metrics

| Metric | Value |
| ------ | ----- |
| rows | 120 |
| cols | 8 |

### Limits

| Name | Max |
| ---- | --- |
| rows | 1000 |
| cols | 64 |

### Flags

| Flag | Meaning |
| ---- | ------- |
| `-v` | verbose |
| `-q` | quiet |

---

## 8. Edge-ish cases

| Col1 | Col2 |
| ---- | ---- |
| trailing space | value   |
| empty |  |

---

End of document.

