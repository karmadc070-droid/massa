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

# 그냥 go() 로 건너뛰면 안 되는 화면이 있다. 예약 확인 화면은 코스·시간을 고른
# 상태라야 내용이 차고, 안 그러면 빈 상자만 찍힌다 (처음에 그렇게 찍었다).
# 그래서 앞 네 장은 바로 띄우고, 뒤 네 장은 실제로 눌러서 흐름을 타고 간다.
JUMP = [
    ("01-home",    "home"),
    ("02-massage", "thList"),
    ("03-beauty",  "therapy"),
    ("08-mydash",  "myDash"),
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

        async def shot(name):
            await pg.wait_for_timeout(2500)
            # 한국어가 남아 있으면 바로 알 수 있게 센다
            ko = await pg.evaluate(
                "(()=>{const s=document.querySelector('.screen.on')||document.body;"
                "return (s.innerText.match(/[\\uAC00-\\uD7A3]/g)||[]).length})()"
            )
            won = await pg.evaluate(
                "document.querySelectorAll('.wonhint').length && "
                "[...document.querySelectorAll('.wonhint')].some(e=>e.offsetParent)"
            )
            await pg.screenshot(path=f"{OUT}/{name}.png", full_page=False)
            print(f"  {name:12s} 한글={ko}  원화표시={won}")

        for name, sid in JUMP:
            await pg.evaluate(f"window.go({sid!r})")
            await shot(name)

        # --- 실제 예약 흐름을 타고 간다 ---
        await pg.evaluate("window.go('thList')")
        await pg.wait_for_timeout(1500)
        await pg.click(".tcard .bookbtn", timeout=20000)       # 마사지사 예약 누르기 → 코스
        await shot("04-course")

        await pg.click("#menu .card", timeout=20000)           # 코스 하나 고르기
        await pg.wait_for_timeout(800)
        await pg.click("#menu .cta", timeout=20000)            # 다음 — 시간
        await shot("05-time")

        # 시간 칩이 있으면 하나 고른다. 없으면 그대로 찍는다.
        try:
            await pg.click("#time .chip:not(.off)", timeout=5000)
        except Exception:
            print("  (시간 칩을 못 찾아 그대로 간다)")
        await pg.click("#time .cta", timeout=20000)            # 다음 — 위치
        await shot("06-place")

        # 위치 화면은 장소 검색 시트(#placeSheet)가 떠서 버튼을 가린다.
        # 시트와 씨름하지 말고 숙소·호수를 직접 채우고 다음 화면을 부른다.
        await pg.evaluate("""(() => {
            const sheet = document.getElementById('placeSheet');
            if (sheet) sheet.remove();
            const set = (id, v) => { const e = document.getElementById(id);
                if (e) { e.value = v; e.dispatchEvent(new Event('input', {bubbles:true})); } };
            set('locHotel', 'Lotte Hotel Hanoi');
            set('locRoom', '2104');
            if (window.fillConfirm) window.fillConfirm();
            window.go('confirm');
        })()""")
        await shot("07-confirm")

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
