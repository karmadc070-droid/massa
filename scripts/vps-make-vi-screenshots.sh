#!/bin/bash
# 앱스토어용 베트남어 스크린샷을 만든다.
#
# 왜 VPS 에서 하나: 애플 6.5" 규격이 1242x2688 인데, 브라우저 창을 띄워 찍으면
# 그 해상도가 안 나온다. 헤드리스 크롬에 deviceScaleFactor 3 을 주면
# 414x896 뷰포트가 정확히 1242x2688 로 떨어진다.
#
# 언어는 localStorage 를 미리 심어서 베트남어로 띄운다. 앱이 그 값을 먼저 본다.
set -e

OUT=/root/shots-vi
mkdir -p "$OUT" && rm -f "$OUT"/*.png

echo '=== 0. 준비 ==='
python3 -c 'import playwright' 2>/dev/null || pip3 install --quiet --break-system-packages playwright
python3 -m playwright install --with-deps chromium 2>&1 | tail -2

echo ''
echo '=== 1. 촬영 ==='
python3 - "$OUT" <<'PY'
import sys, asyncio
from playwright.async_api import async_playwright

OUT = sys.argv[1]
URL = "https://app.massaviet.com/"

# 고를 화면과 파일 이름. 손님이 예약까지 가는 길을 순서대로 보여준다.
SHOTS = [
    ("01-home",    "home",    None),
    ("02-massage", "thList",  None),
    ("03-beauty",  "therapy", None),
    ("04-course",  "menu",    None),
    ("05-time",    "time",    None),
    ("06-place",   "loc",     None),
    ("07-confirm", "confirm", None),
    ("08-mydash",  "myDash",  None),
]

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(args=["--no-sandbox", "--font-render-hinting=none"])
        ctx = await b.new_context(
            viewport={"width": 414, "height": 896},
            device_scale_factor=3,           # 414x896 x3 = 1242x2688 (애플 6.5")
            locale="vi-VN",
            is_mobile=True, has_touch=True,
        )
        # 앱이 읽기 전에 언어를 심어 둔다
        await ctx.add_init_script(
            "try{localStorage.setItem('massa_lang','vi')}catch(e){}"
        )
        pg = await ctx.new_page()
        await pg.goto(URL, wait_until="networkidle", timeout=90000)
        await pg.wait_for_timeout(6000)      # 목록·사진이 다 붙을 때까지

        lang = await pg.evaluate("localStorage.getItem('massa_lang')")
        print("  언어:", lang)

        for name, sid, _ in SHOTS:
            try:
                await pg.evaluate(f"window.go({sid!r})")
            except Exception as e:
                print(f"  [{name}] go() 실패: {e}")
                continue
            await pg.wait_for_timeout(2500)
            # 한국어가 남아 있으면 바로 알 수 있게 센다
            ko = await pg.evaluate(
                "(()=>{const s=document.querySelector('.screen.on')||document.body;"
                "return (s.innerText.match(/[\\uAC00-\\uD7A3]/g)||[]).length})()"
            )
            path = f"{OUT}/{name}.png"
            await pg.screenshot(path=path, full_page=False)
            print(f"  {name:12s} 한글글자수={ko}")
        await b.close()

asyncio.run(main())
PY

echo ''
echo '=== 2. 결과 ==='
ls -la "$OUT"
python3 - "$OUT" <<'PY'
import sys, os, struct
d = sys.argv[1]
for f in sorted(os.listdir(d)):
    p = os.path.join(d, f)
    with open(p, 'rb') as fh:
        head = fh.read(24)
    w, h = struct.unpack('>II', head[16:24])
    print(f"  {f:16s} {w}x{h}  {os.path.getsize(p)//1024} KB")
PY
echo ''
echo '  ※ 1242x2688 이어야 애플 6.5인치 규격에 맞는다'
