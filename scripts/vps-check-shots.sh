#!/bin/sh
# 찍은 스크린샷이 등록정보 슬롯 크기와 맞는지 확인한다.
python3 - <<'PY'
import glob, os, struct
want = {'1290x2796': (1290, 2796), '1284x2778': (1284, 2778), '2064x2752': (2064, 2752)}
files = sorted(glob.glob('/root/shots-vi/*/*.png'))
bad = 0
for p in files:
    tag = os.path.basename(os.path.dirname(p))
    w, h = struct.unpack('>II', open(p, 'rb').read(24)[16:24])
    ok = want.get(tag) == (w, h)
    if not ok: bad += 1
    print('  %-10s %-14s %dx%d  %4d KB  %s'
          % (tag, os.path.basename(p), w, h, os.path.getsize(p)//1024, 'OK' if ok else 'MISMATCH'))
print('  총 %d장, 어긋남 %d장' % (len(files), bad))
PY
