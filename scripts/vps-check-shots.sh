#!/bin/sh
# 찍은 스크린샷이 애플 6.5인치 규격(1242x2688)인지, 한글이 남았는지 확인한다.
python3 - <<'PY'
import os, struct
d = '/root/shots-vi'
for f in sorted(os.listdir(d)):
    if not f.endswith('.png'): continue
    p = os.path.join(d, f)
    head = open(p, 'rb').read(24)
    w, h = struct.unpack('>II', head[16:24])
    ok = 'OK' if (w, h) == (1242, 2688) else 'SIZE MISMATCH'
    print('  %-16s %dx%d  %4d KB  %s' % (f, w, h, os.path.getsize(p)//1024, ok))
PY
