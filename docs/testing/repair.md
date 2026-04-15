# Test Specification

## Repair

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

## implement

* rangeを準備しておく。最初は空にしておく
* on_linesがきたらすぐscheduelでenqueue_repair_rangeを呼ぶ
* enqueue_repair_rangeでrangeが空ならrepairをscheduleする
* enqueue_repair_rangeで変更範囲をrangeに貯める
* repiarが呼び出されたらrangeの中をまとめて処理しrangeを空にする

| No | Preconditions | Action | Expected | Date | Notes | Commit Message |
| --- | --- | --- | --- | --- | --- | --- |
|  | モジュール名変更 |  | repair -> reconcile | 2026/4/1? |  |  |
|  | 関数名変更 |  | repair -> hamdle, and more | 2026/4/1? |  |  |
|  | nvim tests/data/simple.md | undo | apply_marks, apply_range を呼び出す | 2026/4/1? | undo 1 node? |  |
|  | nvim tests/data/simple.md | join | enqueue_repair_range経由でapplyを2回呼び出す | 2026/4/1? |  |  |

