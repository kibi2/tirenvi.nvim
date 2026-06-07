# Test Specification

## width mode

* fit mode:画面幅にfitし全ての列を見渡せるようにする
  * 列全体を見渡して修正場所と修正内容を考えるため
* max mode:wrapしない状態にする。セル内改行はそのまま表示する
  * wrapしているとvimコマンド実行時に邪魔になり十分活用できないため

### command

```
 b:tirenvi.width_mode = fit(初期値) | max | fix
 
 :Tir width fit [pages] : -> fit mode。横pages画面にfitする、省略時pages=1
 :Tir width max : -> max mode。wrapなしにする。ただしセル内改行はそのまま表示する
 :Tir width fix : -> fix mode。固定幅(前回のfix幅、なければ今の幅)
 :Tir width[=+-][n] : fix mode。今の列幅に対して列幅を指定・増減する
 :Tir width toggle : fitとmaxを切り替える。fixの場合はfitに切り替える
```

* fit, max はコマンド実行時に見えている行で幅を計算する
  * 見えないところで非常に長い文字列があっても考慮しない
  * コマンド実行後見えなかった行が見える様になるかもしれない
* スクロールしても幅は変化しない
* 再度fitしたい場合はTir repairを実行する
* 列の最小wrap幅はfixの時2、fitの時は6(config.ui.fit_min_width)
* 指定画面内にfitできない場合はなるべく狭くして表示する

### n画面fit アルゴリズム:貪欲法
+ 現在表示している範囲を計算対象とする
+ natural_width[i] を計算
+ natural_total <= win_width * pages
  * 比例配分(1以下なら1、floor、natural_width大きい順)して終了
+ 最小幅で開始
  * natural_width < 6 なら最小幅はmax(natural_width, 2)
  * natural_width >= 6 なら最小幅は6(config.ui.fit_min_width)
+ 残り幅が分配できる間
  * 最大wrap列の行数が減る様に残り幅を分配する
  * 複数ある場合左列優先
+ 残り幅がまだあれば
  * 比例配分(1以下なら1、floor、natural_width小さい順)して終了

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
|  | width_mode=fit | Tir width fix | b:tirenvi.width_mode=fix |  |  |  |

