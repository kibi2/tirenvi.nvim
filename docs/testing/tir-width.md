# Test Specification

## Column Width Visual Range

* Tir toggle(init.enable) でblocksを作った後buffer localに覚える

## implement

* branch name: feat/tir-width-visual-range
* PR: kibi2/tirenvi.nvim#??

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | 列幅変更関数が長い | 列幅変更関数を分割する | 2026/4/10 |  | refactor: split column width logic for multi-table support |
|  | visual 選択で複数列選択<br>visual 選択で複数表選択<br>範囲選択で複数表選択 | Tir width=n | 選択した列幅が指定した値になる |  |  |  |
|  | visual block選択で複数表の列を選択 | Tir width- | 選択した列幅が減少する |  |  |  |

