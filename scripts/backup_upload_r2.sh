#!/bin/bash
# 잠긴 백업을 R2 로 올린다. 평문은 절대 올리지 않는다.
#
# sync 가 아니라 copy 를 쓴다. sync 는 서버에서 지워진 것을 R2 에서도 지운다 —
# 서버가 털려 백업이 삭제되면 원격 사본까지 같이 사라진다. 백업을 두는 이유가 없어진다.
# 오래된 것은 R2 쪽에서 따로 정리한다 (아래 30일).
set -u
ENC=/root/backups/enc
REMOTE=r2:massa-db-backup/enc
LOG=/root/backups/upload.log

# .gpg 가 아닌 것이 enc 에 섞여 있으면 올리지 않는다. 평문 유출을 막는 마지막 빗장.
BAD=$(find "$ENC" -type f ! -name '*.gpg' | wc -l)
if [ "$BAD" -gt 0 ]; then
  echo "$(date -Is) FAIL enc 에 .gpg 아닌 파일 ${BAD}개 — 중단" >> "$LOG"
  exit 1
fi

if rclone copy "$ENC" "$REMOTE" --include '*.gpg' --transfers 4 --retries 3 >>"$LOG" 2>&1; then
  N=$(rclone ls "$REMOTE" 2>/dev/null | wc -l)
  echo "$(date -Is) OK 원격 보관 ${N}개" >> "$LOG"
else
  echo "$(date -Is) FAIL 업로드 실패" >> "$LOG"
  exit 1
fi

# 서버는 7일, 원격은 30일 보관한다. 서버에서 지워져도 한 달은 되돌릴 수 있다.
rclone delete "$REMOTE" --min-age 30d >>"$LOG" 2>&1 || true
