# Test Specification

## width mode

* fix: 列幅固定。幅はユーザーが変更可能
  * セル内の文字数増減により幅は変化しないが行数が変化する
* max: 行数固定。セル内でwrapしない様に列幅を自動調整する
  * セル内の文字数増減により幅は変化するが改行以外で行数は変化しない
* fit: 表幅が指定幅に収まる様に列幅を自動調整する
  * セル内の文字数増減により行数・列幅は変化するが表幅は変化しない
  * 指定幅で表示できない場合は表幅を自動的に拡大する
  * 列数が増えた場合に表幅が増えることがある
* auto: 見やすさ優先。画面内になるべく多くの情報を表示する
  * 見やすさを優先して列幅を自動調整する
  * セル内の文字数増減により列幅、行数、表幅が可変

### command

```
 :Tir width=[n] : fix mode。列幅を指定する。n省略時max幅(wrapなし)
 :Tir width[+|-][n] : fix mode。今の列幅に対して列幅を増減する。省略時n=1
 :Tir width fix : -> fix mode。列幅固定
 :Tir width max : -> max mode。行数固定(wrapしない)
 :Tir width fit [=][n] : -> fit mode。表横幅をnにする。省略時n=画面幅
 :Tir width fit [+|-][n] : -> fit mode。表横幅を増減する。省略時n=1
 :Tir width toggle : 今のモードとmaxを切り替える
```

* 画面横幅を変更しても表の幅は変化しない
* 再度fitしたい場合はTir repairを実行する
* 列の最小幅は2
* fitで指定画面内に収まらない場合は全ての列幅が2になる
* fit, max はコマンド実行時に見えている行で幅を計算する
  * 見えないところに非常に長い文字列があっても考慮しない
  * コマンド実行後見えなかった行が見える様になるかもしれないが、そこは考慮しない
* スクロールしても表の幅は変化しない

### fit アルゴリズム
* 現在表示している範囲を計算対象とする
* natural_width[i] を計算
* 比例配分(切り上げ)する
* はみ出している場合は幅を1だけ削る
* 削る列は次の順番
  * 幅の広い順
  * 同じ場合は右側

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
|  | width-mode=max | repair | width = no wrap | 26/0/6/12 |  | feat: implement width max mode with no-wrap column sizing |
|  | fit | pages省略 | 画面サイズに表が収まる | 26/06/13 |  | feat: use fit width mode when pages width is omitted |
|  | fit | pages,width指定 | 画面サイズに表が収まる | 26/06/13 |  | feat: implement fit width calculation for pages |
|  |  | auto | 画面サイズに表が収まる | 26/06/13 |  | feat: implement auto width |

