# Test Specification

## FileType

* tirenvi は tir editor である
* tir 以外の書式は外部パーサーを使ってtir書式に変換する必要がある
* 外部パーサーはfiletypeをキーに検索する(config.parser_map)
* 外部パーサーがない場合はtirenviは動作しない
* 結局tirenviが実行可能かどうかはconfig.parser_map[filetype]の有無で決まる
  * 外部パーサーがあっても実行できない場合(エラーなど)はtirenviは動作しない
  * しかしこの場合はユーザー設定ミスである可能性が高い
  * なのでtirenvi実行をブロックするのではなく、毎回実行してエラーを出す方が良い

## implement

* filetypeに変更があった場合(autocmd FileType)
  * パーサー情報を取得する(config.parser_map(filetype))
  * パーサー情報があればfiletypeをbuffer localに覚える(b.tirenvi.filetype)
    * 他のfiletypeに切り替わった場合以前のfiletypeが必要なため
    * parser情報でなくfileteypeを覚えるのはconfig変更などに対応できる可能性があるため
    * パーサーが実行可能かどうかは調べない
    * パーサーを実行するたびにエラーを表示するため
  * パーサー情報があればbufferにautocmndを登録する
  * パーサー情報があればbufferにon_linesを登録する
* autocmd
  * bufferに紐づかないautocmdはglobalに設定する
  * WinClosed, VimLeave など
  * FileType は新しいfiletypeについて判断する必要があるのでglobalに設定する
  * BufReadPre もglobalにないと呼び出されないのでglobalに設定する
* autocmd, command, などentry pointでの動作
  * b.tirenvi.filetypeがない場合はtirenviは即returnする(should_skip.has_parser)
  * FileType は例外
* on_lines
  * b.tirenvi.filetyp登録時点でon_linesをbufferに対して登録する
    * filetype変更直後にtir-vimをputする場合に対応するため
    * BufReadpostで無駄に処理が走らないか？
  * b.tirenvi.filetypeがなくなれば自分でdettachする
  * CursorHoldでb.tirenvi.filetypeがあればattachする(他のpluginがdettachする可能性があるので)
* modeline対応
  * # vim: ft=csv

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | buf_state.should_skip<br>デフォルト値を設ける | 正常動作 |  |  |  |
|  | should_skip.has_parser |  | parser有無チェック-><br>buffer.IKEY.FILETYPE有無チェック | 2026/4/15 |  |  |

