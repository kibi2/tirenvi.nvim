# Test Specification

## Column Width Restoration

* Tir toggle(init.enable) でblocksを作った後buffer localに覚える
* widths[iblock][icol]
* (保留)ファイル保存した場合は".tirenvi"directory に保存する。filename.attr.json
  * .tirenviの場所は
  * git root
  * parent directory search
  * current directory

## implement

* branch name: feat/persist-column-width-on-toggle
* PR: #53

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  | md is displayed in tir-vim mode<br><br>md tir-vim表示中 | Switch back to flat mode with `Tir toggle`<br>`echo b:tirenvi`<br>Tir toggleでflat表示に戻す<br>echo b:tirenvi | `widths` field exists<br><br>widths[iblock][icol]フィールドに幅保持 | 2026/4/10 |  | feat: persist column widths on tir toggle |
|  | md tir-vim表示中 | Tir toggleを2度実行してtir-vim表示に戻す | 列幅が再現する<br>widths[iblock][icol]フィールド削除 | 2026/4/10 |  | feat: restore column widths after tir toggle roundtrip and clear widths state |

