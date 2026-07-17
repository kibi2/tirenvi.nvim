# Test Specification

## embedded grid

* 任意のテキストファイル中の表形式データを、元のファイル形式を維持したまま tirenvi で編集可能にする
* 言語ファイルの場合、コメントはコメントとして加工するので表の編集可能状態で言語のコンパイルなども可能

### 例

```python
import importlib
from typing import Any, Dict, TypedDict
import traceback
# | tabel header1 | header2 |
# | cell data1 | cell data2 |
# | row3 | column2 |
```

## 用語の定義

* prefix
  * 行頭から最初の "|" の直前までの文字列

* key
  *  trim(prefix) で得られる比較用文字列
  * key は空文字の場合もあり得る

## embedded grid format

* 詳細は tir-embedded を参照のこと
* まずカレント行から key を決定することを試みる。
  * "|"を二つ以上含むこと
  * 行末が"|"であること
* カレント行が条件を満たさない場合は先頭行から検索する
* 条件を満たす行がない場合はtirenviの対象としない(通常どおりflatで開く)
* 先頭行から順次解析して1行ごとrecord(ndjson)に変換する
* 次の条件を満たす行をrecord.kind=gridとする。それ以外はrecord.kind=plainとする。
  * "|"を二つ以上含むこと
  * 行末が"|"であること
  * key が一致すること
* grid block 最初のrecordにrecord.prefix=prefixとする
* セル内容に"|"を含める場合は"\\|"とする
* セル内で改行する場合は&g;tBR&ltとする
* 文字列として記述するのであれば\\<BR\\>とする

## コマンド

* Tir toggle コマンドで flat <-> tir-buf 変換をする
* Tir toggle 実行時にはparser が指定されているfiletypeの場合は指定したparserが解析する
  * config.parser_map.markdown = { executable = "tir-gfm-lite" } の様に指定しておく
  * filetype=markdown であればtir-gfm-liteがparseする
* Tir toggle 実行時にparser が指定されていないfiletypeの場合はあらかじめ決められたparserが解析する
  * config.parser_map["*"] = { executable = "tir-embedded" } の様に指定しておく
  * filetype=python であればtir-embeddedがparseする
* tir-embedded の場合はカレント行位置をコマンド引数として渡す
* Tir toggle はバッファ全体に対して flat <-> tir-buf 変換を行う
  * つまりコメント内に書いた表部分にカーソルを置いてTir toggleを実行するとコメント内の表だけtir-buf化する
  * ヒアドキュメント内に書いた表部分にカーソルを置いてTir toggleを実行するとヒアドキュメント内の表だけtir-buf化する
  * これはkeyが一致している行だけを変換する仕様のためである。grid ごとにkeyを変えることはできない。
* prefix を明示することもできる
  * Tir toggle //
  * Tir toggle ""

## 修正機能

ユーザー操作によりgridが壊された場合はreconcileする

* key のインデントがgrid内で一致しない場合は一致させる
* grid 内で列数が一致しない場合は列数を一致させる
* key の後ろに"|"がない場合は"|"を追加する
  * key cell1 | cell2 | -> key | cell1 | cell2 |
* key がない場合はkeyを追加する
  * | cell1 | cell2 | -> key | cell1 | cell2 |
  * cell1 | cell2 | -> key | cell1 | cell2 |

## implement max

* branch name: feat/tirenvi-grid-prefix
* PR: kibi2/tirenvi.nvim#

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | health | OK | 26/07/16 |  | feat: support both legacy and new parser version interfaces |
|  | edit table.txt | Tir toggle (row # 1) | show grid block | 26/07/18 |  | Add grid display support for text files in :Tir toggle |
|  | record.prefix=" #hoge# " | Tir _read_tir ./tests/data/simple.tir | #hoge# |  |  |  |
|  |  | Tir _write_tir /tmp/hoge.tir | record.prefix=" #hoge# " |  |  |  |
|  | record.prefix=" // " | " // " -> "  // " | 戻る |  |  |  |
|  | record.prefix=" // " | " // " -> "   " | 戻る |  |  |  |

