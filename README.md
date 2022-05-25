# lcalendar.l
Large calendar mode for [xyzzy text editor](https://ja.wikipedia.org/wiki/Xyzzy).

# 使い方
requireして`M-x lcalendar`でウィンドウ全体を使ったひと月分のカレンダーが現れます。[emacs](https://www.gnu.org/software/emacs/)でお馴染のメモ書きツール[howm](http://howm.osdn.jp/)のxyzzy版[howm-wrap](https://web.archive.org/web/20070709022425/http://homepage3.nifty.com/~ko-ji/)の存在を前提としています。先に読み込んでください。

howmのファイルが多いと表示が遅くなります。howmのファイルを遣り繰りするのも手ですが、`*lcalendar-show-schedule*`変数を`nil`にしておけば予定を読み込みません。その場合でも`T`キーを押下すれば予定の表示を切り替えることができます。

howm以外の予定を読み書きしたい場合 `*lcalendar-func-schedules*` `*lcalendar-func-visit-schedule*` `*lcalendar-func-new-schedule*` の各変数に適宜関数を設定してください。予定を使いたくない場合は`nil`にしてください。

## 設定例

    (require "howm-wrap")
    (require "lcalendar")

## 既定の操作

| キー | 内容 |
| ---- | ---- |
| b    | 前の日へ |
| c    | 新しい予定を記入 |
| f    | 次の日へ |
| g    | 再読込 |
| M-g  | 日付を指定してページ移動 |
| n    | 次の週へ |
| p    | 前の週へ |
| q    | バッファを閉じる |
| T    | 予定表示切替 |
| C-v  | 次の月へ |
| M-v  | 前の月へ |
| C-x ] | 次の年へ |
| C-x [ | 前の年へ |
| M-}  | 次の月へ |
| M-{  | 前の月へ |
| .    | 今日へ |
| >    | 次の月へ |
| <    | 前の月へ |
| PageUp | 次の月へ |
| PageDown | 前の月へ |
| RET  | カーソル位置の予定を表示 |
