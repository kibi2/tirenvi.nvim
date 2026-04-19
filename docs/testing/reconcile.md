# Test Specification

## 遅延正規化

- echo, 

## implement

* branch name: feat/tir-width-visual-range
* PR: kibi2/tirenvi.nvim#

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | 遅延正規化オプションオフ<br>config.table.auto_reconcile | 自動正規化切り替え<br>エコー[Tirenvi] auto-reconcile: ON\|OFF | 2026/4/18 |  | feat: add table.auto_reconcile option |
|  |  | 遅延正規化コマンドon/off<br>Tir ToggleAutoReconcile<br> | 自動正規化切り替え<br>エコー[Tirenvi] auto-reconcile: ON\|OFF | 2026/4/18 |  | feat: add :Tir auto-reconcile [on\|off] command |
|  |  | 遅延正規化コマンドon/off<br>Tir ToggleAutoReconcile<br>buffer local | buffer毎に遅延正規化コマンド実行可能 | 2026/4/18 |  | feat: make auto_reconcile buffer-local |
|  |  |  |  |  |  | feat: add extmark-based table attribute storage |
|  |  | 手動正規化コマンド<br>Tir reconcile |  |  |  |  |

## Repair -> reconcile

* joinをするとon_linesが2度呼び出される
  * 2度のon_linesをまとめてrepairする処理が必要
* 過去repairが呼び出されるタイミングは3種類あった
  * いずれもrepair.repairを呼び出す
  * 通常のコマンド実行時:変更範囲が渡る。init.on_linesから呼び出す
  * insert leave時:変更範囲なし、extmarkの場所をrepairする。init.insert_leaveから呼び出す
  * undo leave時:extrmark + 変更範囲。init.on_linesから呼び出す
* 今回の処理方式
  * 関数名の変更：repair処理のentry point
  * entry での処理
  * extmarkがあればrepairする。scheduleが必要かは疑問
  * rangeがあればenqueue_repair_range
  * repair_range初回でrepairをschedule
  * undoの時extmarkとon_linesが重なるがundojoinできるか？
* 関数名・モジュール名
  * repair -> reconcile
  * handle_, on_ : handle_request
  * enqueue_, mark_
  * apply_, run_ : apply_extmark, ranges, range, line
  * shcdule_ : schedule_flush

## 2種類のranges

* insert/undo modeでの変更は即時修正できないのでextmarksとして覚える -> ext_ranges
* その他modeでの変更は複数回に渡ってくるのでlocal rangeとして覚える -> local_range

## handle_requset 疑似コード

```
local local_range = nil
fucntion handle_request(bufnr, new_range)
  local ext_ranges = ui.get_ext_ranges() -- get ext_marks 
  ui.clear_ext_ranges() -- clear ext_marks
  if insert/undo mode then
    ui.set_ext_ranges(Range.unions(ext_ranges, new_range) -- set ext_marks
  elseif not local_range then -- 最初の1回だけ呼び出す
    vim.schedule(function() run_ext_ranges(bufnr, ext_ranges) end) -- reconcile ext_ranges
    vim.schedule(function() run_local_range(bufnr) end) -- reconcile local_range
    local_range = new_range
  else -- 2回目以降はまとめる
    local_range = Range.union(local_range, new_range) -- expand cocal_range
  end
end
fucntion run_ext_ranges(bufnr, extranges)
  apply_rangesbufnr(extranges) -- local_rangeの前にext_rangを処理する。行番号は変えない
end
fucntion run_local_range(bufnr)
  apply_rangesbufnr({local_range}) -- 2回目以降でまとめたrangeに対して1回だけ実行する
  local_range = nil
end
```

## 関数名変更

module name: core/repair -> core/reconcile

| function name | call function | process |
| --- | --- | --- |
| M.repair | repair | repair をshedule するだけ |
| repair | repair_ranges | extmark参照してrangesを取り出す<br>insert/undo mode ならextmarkを付けるだけ<br>call repair_ranges |
| repair_ranges | get_repaired_lines<br>ui.set_lines | rangeごとにcall get_repaired_lines<br>bufferに修正したtir-vimを書き込む |
| get_repaired_lines | get_reference_attrs<br>get_blocks<br>Blocks.repair<br>vim_parser.unparse | rang前後の未修正行から列幅attrを参照<br>rangeからBlocksを作成する<br>Blocksを修正する<br>修正したBLocksからtir-vimを作る |
| get_blocks | <br>fix_empty_line_after_table | rangeからBlocksを作成する<br>新規行が追加された場合plain, gridを判定して調整する |
| Blocks.repair<br> | apply_reference_attr_multi<br>apply_reference_attr_single | plain混在可blocksにattrを設定する<br>plain混在不可blocksにattrを設定する |
| apply_reference_attr_multi | insert_plain_block<br>attach_attr | block間の矛盾を解消するblocks にattrを設定する |
| apply_reference_attr_single | merge_blocks | blocksを一つのblockにするblock にattrを設定する |

| old name | new name |
| --- | --- |
| M.repair | reconcile.handle |
| repair | handle_request |
| repair_ranges | apply_ranges |
| get_repaired_lines | reconcile_range |
| get_reference_attrs | resolve_reference_attrs |
| get_blocks | build_blocks |
| fix_empty_line_after_table | normalize_trailing_empty_line |
| Blocks.repair | Blocks.reconcile |
| apply_reference_attr_multi | apply_reference_attrs |
| apply_reference_attr_single | apply_reference_attrs_strict |
| insert_plain_block | ensure_plain_block |
| attach_attr | apply_attr |
| merge_blocks | merge_blocks |

結局repairの処理のメインは
* 指定したrange(on_linesから渡ってきた修正行)からBlocksを作成する
* 未修正行(rangeの前後1行を見る)からattrを作成する
* attrをblockに設定する
* BlockとBlockの構造に矛盾があればここで対処する(Block内の矛盾はここでは無視)
* Block内の矛盾はvim_parser.unparseが行う

## implement

* rangeを準備しておく。最初は空にしておく
* on_linesがきたらすぐscheduelでenqueue_repair_rangeを呼ぶ
* enqueue_repair_rangeでrangeが空ならrepairをscheduleする
* enqueue_repair_rangeで変更範囲をrangeに貯める
* repiarが呼び出されたらrangeの中をまとめて処理しrangeを空にする

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  | モジュール名変更<br> 関数名変更 |  | repair -> reconcile<br>repair -> hamdle, and more | 2026/4/16 |  | refactor: rename repair to reconcile and standardize function namin |
|  | nvim tests/data/simple.md | undo | apply_extra_ranges, apply_local_range を呼び出す | 2026/4/18 |  |  |
|  | nvim tests/data/simple.md | join | schedule_new_range経由でapplyを2回呼び出す | 2026/4/18 |  |  |

