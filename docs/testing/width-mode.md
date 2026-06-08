# Test Specification

## width mode

* fit mode:画面幅にfitし全ての列を見渡せるようにする。俯瞰して把握する。
  * 列全体を見渡して修正場所と修正内容を考えるため
* max mode:wrapしない状態にする。セル内改行はそのまま表示する
  * wrapしているとvimコマンド実行時に邪魔になり十分活用できないため

### command

```
 b:tirenvi.width_mode = WidthModeState
 b:tirenvi.prev_width_mode = WidthModeState
 ---@class WidthModeState
 ---@field mode WidthMode fit|max|auto|fix
 ---@field pages? integer
 ---@field width? integer
 
 :Tir width fit [pages] [width] : -> fit mode。横幅をpages*widthにする。省略時pages=1,width=画面横幅
 :Tir width max : -> max mode。wrapなしにする。ただしセル内改行はそのまま表示する
 :Tir width fix : -> fix mode。固定幅(前回のfix幅、なければ今の幅)
 :Tir width auto : -> auto mode。編集性を優先し、縦横比と最大列幅の制約下で列幅を最適化する
 :Tir width toggle : 今のモードとmaxを切り替える
 :Tir width[=+-][n] : fix mode。今の列幅に対して列幅を指定・増減する
```

* fit, max はコマンド実行時に見えている行で幅を計算する
  * 見えないところに非常に長い文字列があっても考慮しない
  * コマンド実行後見えなかった行が見える様になるかもしれないが、そこは考慮しない
* スクロールしても表の幅は変化しない
* 画面横幅を変更しても表の幅は変化しない
* 再度fitしたい場合はTir repairを実行する
* 列の最小幅は2
* fitで指定画面内に収まらない場合は全ての列幅が2になる

### fit アルゴリズム:貪欲法
* 現在表示している範囲を計算対象とする
* natural_width[i] を計算
* wrapなしで収まる場合: natural_total <= width * pages
  * 残り幅分配処理へ
* 最小幅2で開始
* 残り幅が分配できる間、行数を減らす方向で分配する
  * 列毎にwrap行が最大のセルを選び出す(そのセルがその列のボトルネックとみなす)
  * 列毎にそのセルの行数を減らす最小増加幅を求める
  * 最小増加幅が分配可能であればその列に分配する
  * 複数ある場合、減少行数の多いもの、左側の順で優先
* 残り幅分配処理
  * 比例配分(配分量が1以下なら1、floor、現在幅が小さい順)して終了

### auto アルゴリズム
* fitを基準とする
* ただし以下の制約を満たす様に列幅を拡張する
  * 縦横比が2:3以下
  * 列幅は画面幅の1/4以下

### 横スクロール
* zl: 左へ1文字スクロール
* zh: 右へ1文字スクロール
* zL: 半画面左
* zH: 半画面右
* zs: カーソル位置が左端
* ze: カーソル位置が右端

## implement max

* branch name: feat/fit-width-max
* PR: kibi2/tirenvi.nvim#

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  | Tir width | <tab> | サブサブコマンド補完を出す<br>=+- fix, max, fit, toggle | 26/06/07 |  | feat: add completion for width subcommands |
|  |  | 起動時 | b:tirenvi.width_mode=fit | 26/06/07 |  | feat: add buffer-local width_mode with default fit mode |
|  | Tir width mode= | fit,fix, max,auto | width_mode=fit, fix, max, auto | 26/06/07 |  | feat: implement width mode switching |
|  |  | width toggle | max <-> fit, auto, fix | 26/06/08 |  | feat(width): add width mode toggle command |
|  | fit  | pages省略 |  |  |  |  |
|  | width-mode=max | repair | width = no wrap |  |  |  |

