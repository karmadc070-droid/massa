#!/bin/bash
# 그날 만들어진 덤프를 공개키로 잠가 /root/backups/enc 에 둔다.
# 서버 밖으로 나가는 것은 이 잠긴 파일뿐이다. 여는 열쇠는 서버에 없다.
#
# pg_backup.sh 가 끝난 뒤에 돈다 (크론에서 순서대로 부른다).
set -u
export GNUPGHOME=/root/.gnupg-massa
BK=/root/backups
ENC=$BK/enc
LOG=$BK/encrypt.log
mkdir -p "$ENC"

# 공개키가 없으면 아무것도 하지 않는다. 평문이 밖으로 나가는 일은 없어야 한다.
if ! gpg --list-keys massa-backup >/dev/null 2>&1; then
  echo "$(date -Is) FAIL 공개키 없음 — 중단" >> "$LOG"
  exit 1
fi

n=0
for f in "$BK"/*.sql.gz; do
  [ -e "$f" ] || continue
  out="$ENC/$(basename "$f").gpg"
  [ -e "$out" ] && continue          # 이미 잠근 것은 건너뛴다
  if gpg --batch --yes --trust-model always --encrypt \
         --recipient massa-backup --output "$out" "$f" 2>>"$LOG"; then
    sz=$(stat -c %s "$out")
    # 너무 작으면 뭔가 잘못된 것이다. 남겨 두면 복구되는 줄 착각한다.
    if [ "$sz" -lt 1000 ]; then
      echo "$(date -Is) WARN $(basename "$out") 너무 작다 ($sz) — 지움" >> "$LOG"
      rm -f "$out"
    else
      n=$((n+1))
    fi
  else
    echo "$(date -Is) FAIL $(basename "$f")" >> "$LOG"
    rm -f "$out"
  fi
done

# 원본과 같은 주기로 정리한다 (7일)
find "$ENC" -name '*.gpg' -mtime +7 -delete
echo "$(date -Is) OK 새로 잠근 파일 ${n}개 · 보관 $(ls -1 "$ENC"/*.gpg 2>/dev/null | wc -l)개" >> "$LOG"
