#!/bin/sh
# 커밋별 game/main.lua 의 줄 수와 수정 번짐을 Markdown 표로 출력한다.
# 블록(hunk) = 변경이 흩어진 지점 수. git diff -U0 의 @@ 개수로 센다.

FILE=game/main.lua
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

echo "| 커밋 | 내용 | 줄 수 | +줄 | -줄 | 블록 |"
echo "|---|---|---:|---:|---:|---:|"

prev=$EMPTY_TREE
for c in $(git log --reverse --format=%h -- "$FILE"); do
  lines=$(git show "$c:$FILE" | wc -l | tr -d ' ')
  added=$(git diff --numstat "$prev" "$c" -- "$FILE" | cut -f1)
  removed=$(git diff --numstat "$prev" "$c" -- "$FILE" | cut -f2)
  hunks=$(git diff -U0 "$prev" "$c" -- "$FILE" | grep -c '^@@')
  subject=$(git log -1 --format=%s "$c")
  echo "| $c | $subject | $lines | $added | $removed | $hunks |"
  prev=$c
done
