# Test Specification

## Column Width Visual Range

* Tir toggle(init.enable) でblocksを作った後buffer localに覚える

## implement

* branch name: feat/tir-width-visual-range
* PR: kibi2/tirenvi.nvim#59

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | 列幅変更関数が長い | 列幅変更関数を分割する | 2026/4/10 |  | refactor: split column width logic for multi-table support |
|  | visual 選択で複数列選択<br>visual 選択で複数表選択<br>範囲選択で複数表選択 | Tir width=n | 選択した列の幅が指定した値になる | 2026/4/12 |  | feat: allow column width resizing for tables and columns within selection |
|  | visual block選択で複数表の列を選択 | Tir width- | 選択した列の幅が減少する | 2026/4/12 |  |  |
|  |  | Tir width= | 選択した列の幅を自動調整する | 2026/4/13 |  | feat: auto width calculation |
|  |  | Tir redraw | 列幅は変わらない | 2026/4/13 |  | feat: redraw should not reset width |

