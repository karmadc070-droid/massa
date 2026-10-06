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
rm -rf "$OUT" && mkdir -p "$OUT"

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

# 기존 한국어 스크린샷이 올라가 있는 슬롯 크기에 맞춘다. 처음에 1242x2688(옛 6.5")로
# 찍었는데 지금 쓰는 슬롯은 1290x2796 이라 안 맞았다. 세 규격을 다 만들어 둔다.
#   뷰포트 x 배율 = 최종 픽셀
DEVICES = [
    ("1290x2796", 430, 932, 3),    # Dynamic Island iPhone (중형) — 지금 쓰는 슬롯
    ("1284x2778", 428, 926, 3),    # 6.5형
    ("2064x2752", 1032, 1376, 2),  # iPad 33.0cm
]

# 그냥 go() 로 건너뛰면 안 되는 화면이 있다. 예약 확인 화면은 코스·시간을 고른
# 상태라야 내용이 차고, 안 그러면 빈 상자만 찍힌다 (처음에 그렇게 찍었다).
# 그래서 앞 네 장은 바로 띄우고, 뒤 네 장은 실제로 눌러서 흐름을 타고 간다.
JUMP = [
    ("01-home",    "home"),
    ("02-massage", "thList"),
    ("03-beauty",  "therapy"),
    ("08-mydash",  "myDash"),
]

async def run(p, tag, vw, vh, dsf):
    import os
    d = f"{OUT}/{tag}"
    os.makedirs(d, exist_ok=True)
    b = await p.chromium.launch(args=["--no-sandbox", "--font-render-hinting=none"])
    if True:
        ctx = await b.new_context(
            viewport={"width": vw, "height": vh},
            device_scale_factor=dsf,
            locale="vi-VN",
            is_mobile=(vw < 800), has_touch=True,
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
            await pg.screenshot(path=f"{d}/{name}.png", full_page=False)
            print(f"  [{tag}] {name:12s} 한글={ko}  원화표시={won}")

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

async def main():
    async with async_playwright() as p:
        for tag, vw, vh, dsf in DEVICES:
            print(f"=== {tag} ({vw}x{vh} x{dsf}) ===")
            await run(p, tag, vw, vh, dsf)

asyncio.run(main())
PY

echo ''
echo '=== 2. 결과 ==='
python3 - "$OUT" <<'PY2'
import sys, os, struct, glob
d = sys.argv[1]
want = {'1290x2796': (1290, 2796), '1284x2778': (1284, 2778), '2064x2752': (2064, 2752)}
bad = 0
for p in sorted(glob.glob(d + '/*/*.png')):
    tag = os.path.basename(os.path.dirname(p))
    head = open(p, 'rb').read(24)
    w, h = struct.unpack('>II', head[16:24])
    ok = 'OK' if want.get(tag) == (w, h) else 'MISMATCH'
    if ok != 'OK': bad += 1
    print('  %-10s %-14s %dx%d  %4d KB  %s' % (tag, os.path.basename(p), w, h, os.path.getsize(p)//1024, ok))
print('  어긋난 파일:', bad)
PY2
