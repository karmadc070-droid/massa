# massaviet.com 정적 사이트 생성기 — 페이지를 블록 데이터로 기술하고 HTML 을 찍어낸다.
# 10페이지 x 3언어 = 30개를 손으로 관리할 수 없어서 만들었다. 실행: python3 site-src/build.py
import os, re, shutil, html as H

SITE = "https://massaviet.com"
OUT  = "site"
SRC  = "site-src"
LANGS = ["ko", "en", "vi"]          # ko 는 루트, 나머지는 /en/ /vi/
APPLE = "https://apps.apple.com/kr/app/id6804698319"
SUPPORT = "support@massaviet.com"
PLAY_LIVE = False                    # 프로덕션 승인되면 True 로 바꾸고 다시 빌드한다
PLAY = "https://play.google.com/store/apps/details?id=app.massa.hanoi"

# 페이지 순서 = 네비게이션 순서. (파일명, 네비 노출 여부)
PAGES = [
    ("index",    True),  ("services", True),  ("guide",   True),
    ("safety",   True),  ("partner",  True),  ("faq",     True),
    ("about",    False), ("download", True),  ("contact", False),
    ("terms",    False), ("privacy",  False),
]

def url(lang, name):
    """언어·페이지에 해당하는 절대 경로를 만든다. ko 는 루트."""
    base = "" if lang == "ko" else f"/{lang}"
    return f"{base}/" if name == "index" else f"{base}/{name}.html"

def esc(s): return H.escape(str(s), quote=False)

# ── 블록 렌더러 ────────────────────────────────────────────
def r_hero(b, L, lang):
    cap = f'<div class="hero-cap">{esc(b["cap"])}</div>' if b.get("cap") else ""
    btns = "".join(
        f'<a class="btn{"" if i==0 else " ghost"}" href="{b["btns"][i][1]}">{esc(b["btns"][i][0])}</a>'
        for i in range(len(b.get("btns", []))))
    return f'''<div class="hero">
  <div class="wrap">
    <div class="rv">
      <span class="kicker">{esc(b.get("kicker",""))}</span>
      <h1>{b["h1"]}</h1>
      <p class="lead">{esc(b["lead"])}</p>
      <div class="btns">{btns}</div>
    </div>
    <div class="hero-img rv">
      <picture>
        <source media="(max-width:640px)" srcset="/img/hero-mobile.webp">
        <img src="/img/hero.webp" width="1082" height="992" alt="{esc(b.get("alt",""))}" fetchpriority="high">
      </picture>
      {cap}
    </div>
  </div>
</div>'''

def r_section(b, L, lang):
    soft = " soft" if b.get("soft") else ""
    head = ""
    if b.get("h2"):
        head = f'''<div class="sec-head rv">
      {f'<span class="kicker">{esc(b["kicker"])}</span>' if b.get("kicker") else ""}
      <h2>{b["h2"]}</h2>
      {f'<p class="lead">{esc(b["lead"])}</p>' if b.get("lead") else ""}
    </div>'''
    body = "".join(f'<p class="rv">{p}</p>' for p in b.get("body", []))
    inner = "".join(render(x, L, lang) for x in b.get("blocks", []))
    return f'<section class="{soft.strip()}"><div class="wrap">{head}{body}{inner}</div></section>'

def r_grid(b, L, lang):
    cs = "".join(f'''<div class="card rv"><span class="num">{esc(c.get("n",""))}</span>
      <h3>{esc(c["t"])}</h3><p>{esc(c["d"])}</p></div>''' for c in b["items"])
    return f'<div class="grid">{cs}</div>'

def r_pcards(b, L, lang):
    cs = ""
    for c in b["items"]:
        href = c.get("href", "")
        tag = "a" if href else "div"
        at = f' href="{href}"' if href else ""
        cs += f'''<{tag} class="pcard rv"{at}><div class="ph">
      <img src="/img/{c["img"]}.webp" loading="lazy" alt="{esc(c.get("alt", c["t"]))}"></div>
      <h3>{esc(c["t"])}</h3><p>{esc(c["d"])}</p></{tag}>'''
    return f'<div class="grid">{cs}</div>'

def r_steps(b, L, lang):
    ls = "".join(f'<li class="rv"><b>{esc(s["t"])}</b><span>{esc(s["d"])}</span></li>' for s in b["items"])
    return f'<ol class="steps">{ls}</ol>'

def r_table(b, L, lang):
    rs = "".join(f'<tr><th>{esc(k)}</th><td>{v}</td></tr>' for k, v in b["rows"])
    return f'<table class="tbl rv">{rs}</table>'

def r_faq(b, L, lang):
    ds = "".join(f'<details class="rv"><summary>{esc(q)}</summary><p>{esc(a)}</p></details>'
                 for q, a in b["items"])
    return f'<div class="faq">{ds}</div>'

def r_pull(b, L, lang):
    return f'<p class="pull rv">{b["text"]}</p>'

def r_note(b, L, lang):
    return f'<p class="note rv">{esc(b["text"])}</p>'

def r_stores(b, L, lang):
    ios = f'''<a class="store" href="{APPLE}" rel="noopener">
      <svg width="22" height="26" viewBox="0 0 22 26" fill="currentColor" aria-hidden="true"><path d="M18.1 13.8c0-3 2.4-4.4 2.5-4.5-1.4-2-3.5-2.3-4.2-2.3-1.8-.2-3.5 1-4.4 1-.9 0-2.3-1-3.8-1-2 0-3.8 1.1-4.8 2.9-2 3.5-.5 8.8 1.5 11.7 1 1.4 2.1 3 3.6 2.9 1.4-.1 2-.9 3.7-.9 1.7 0 2.2.9 3.7.9 1.5 0 2.5-1.4 3.4-2.9 1.1-1.6 1.5-3.2 1.5-3.3-.1 0-2.9-1.1-2.9-4.4zM15.3 4.9c.8-1 1.3-2.3 1.2-3.7-1.2 0-2.6.8-3.4 1.8-.7.9-1.4 2.2-1.2 3.6 1.3.1 2.6-.7 3.4-1.7z"/></svg>
      <span><b>App Store</b><small>{esc(b["ios"])}</small></span></a>'''
    if PLAY_LIVE:
        and_ = f'''<a class="store" href="{PLAY}" rel="noopener">
      <svg width="22" height="26" viewBox="0 0 22 26" fill="currentColor" aria-hidden="true"><path d="M2 2.3v21.4c0 .5.3.9.7 1.1l11.5-11.8L2.7 1.2c-.4.2-.7.6-.7 1.1zm14.6 8.4L4.4 1.4l.2-.1 12.9 7.4-.9 2zM19.9 12c.5.3.8.8.8 1.3s-.3 1-.8 1.3l-2.6 1.5-1.6-2.8 1.6-2.8 2.6 1.5zM4.6 24.7l12-9.3.9 2-12.9 7.4-.2-.1z"/></svg>
      <span><b>Google Play</b><small>{esc(b["and"])}</small></span></a>'''
    else:
        and_ = f'''<span class="store off">
      <svg width="22" height="26" viewBox="0 0 22 26" fill="currentColor" aria-hidden="true"><path d="M2 2.3v21.4c0 .5.3.9.7 1.1l11.5-11.8L2.7 1.2c-.4.2-.7.6-.7 1.1zm14.6 8.4L4.4 1.4l.2-.1 12.9 7.4-.9 2zM19.9 12c.5.3.8.8.8 1.3s-.3 1-.8 1.3l-2.6 1.5-1.6-2.8 1.6-2.8 2.6 1.5zM4.6 24.7l12-9.3.9 2-12.9 7.4-.2-.1z"/></svg>
      <span><b>Google Play</b><small>{esc(b["soon"])}</small></span></span>'''
    return f'<div class="stores rv">{ios}{and_}</div>'

R = {"hero": r_hero, "section": r_section, "grid": r_grid, "pcards": r_pcards,
     "steps": r_steps, "table": r_table, "faq": r_faq, "pull": r_pull,
     "note": r_note, "stores": r_stores}

def render(b, L, lang): return R[b["type"]](b, L, lang)

def _blocks_flat(blocks):
    for b in blocks:
        yield b
        for x in b.get("blocks", []) or []:
            yield from _blocks_flat([x])

def auto_faq_ld(page):
    """faq 블록이 있으면 FAQPage 구조화 데이터를 자동으로 만든다. 언어마다 손으로 쓰지 않기 위함."""
    import json
    items = []
    for b in _blocks_flat(page["blocks"]):
        if b.get("type") == "faq":
            items += b["items"]
    if not items:
        return ""
    return json.dumps({
        "@context": "https://schema.org", "@type": "FAQPage",
        "mainEntity": [{"@type": "Question", "name": q,
                        "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in items]
    }, ensure_ascii=False, indent=1)

# ── 페이지 골격 ────────────────────────────────────────────
def css_version():
    """Caddy 가 style.css 를 10분 캐시한다. 내용 해시를 쿼리로 붙여 배포 즉시 반영되게 한다."""
    import hashlib
    return hashlib.md5(open(f"{SRC}/style.css", "rb").read()).hexdigest()[:8]

CSSV = ""

def chrome(lang, name, L, body, page):
    cur = ' aria-current="page"'
    nav = "".join(
        '<a href="%s"%s>%s</a>' % (url(lang, n), cur if n == name else "", esc(L["nav"][n]))
        for n, show in PAGES if show and n not in ("index", "download"))
    langsw = "".join(
        f'<a href="{url(l,name)}" hreflang="{l}" aria-current="{"true" if l==lang else "false"}">{L["langname"][l]}</a>'
        for l in LANGS)
    fcol = lambda title, items: (
        f'<div><h4>{esc(title)}</h4><ul>'
        + "".join(f'<li><a href="{url(lang,n)}">{esc(L["nav"][n])}</a></li>' for n in items)
        + '</ul></div>')
    alts = "".join(
        f'<link rel="alternate" hreflang="{l}" href="{SITE}{url(l,name)}">' for l in LANGS
    ) + f'<link rel="alternate" hreflang="x-default" href="{SITE}{url("ko",name)}">'
    verify = '<meta name="msvalidate.01" content="0B78D4CC15B1549A5F90A122DD123EAC">' if (lang=="ko" and name=="index") else ""
    ld = page.get("jsonld") or auto_faq_ld(page)
    ld = f'<script type="application/ld+json">{ld}</script>' if ld else ""
    return f'''<!DOCTYPE html>
<!-- 자동 생성 파일이다. 고치려면 site-src/content_{lang}.py 를 고치고 build.py 를 다시 돌린다 -->
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(page["title"])}</title>
<meta name="description" content="{esc(page["desc"])}">
<link rel="canonical" href="{SITE}{url(lang,name)}">
{alts}
<meta property="og:type" content="website">
<meta property="og:site_name" content="massa">
<meta property="og:locale" content="{ {'ko':'ko_KR','en':'en_US','vi':'vi_VN'}[lang] }">
<meta property="og:title" content="{esc(page["title"])}">
<meta property="og:description" content="{esc(page["desc"])}">
<meta property="og:url" content="{SITE}{url(lang,name)}">
<meta property="og:image" content="{SITE}/img/hero.webp">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#FAF6F0">
{verify}
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="/style.css?v={CSSV}">
{ld}
</head>
<body>

<header class="site">
  <div class="wrap">
    <a class="brand" href="{url(lang,'index')}">m<span>ㅏ</span>ss<span>ㅏ</span></a>
    <nav class="main">{nav}
      <span class="langs">{langsw}</span>
      <a class="navcta" href="{url(lang,'download')}">{esc(L["cta"])}</a>
    </nav>
  </div>
</header>

{body}

<footer class="site">
  <div class="wrap">
    <div class="cols">
      <div>
        <a class="brand" href="{url(lang,'index')}">m<span>ㅏ</span>ss<span>ㅏ</span></a>
        <p style="margin:0;max-width:30ch">{esc(L["footer_tag"])}</p>
      </div>
      {fcol(L["f_service"], ["services","guide","faq"])}
      {fcol(L["f_company"], ["about","safety","partner"])}
      {fcol(L["f_support"], ["download","contact","terms","privacy"])}
    </div>
    <div class="legal">{L["legal"]}</div>
  </div>
</footer>

<div class="smartbar" id="smartbar">
  <button class="x" id="sbx" aria-label="close">×</button>
  <span>{esc(L["smart"])}</span>
  <a href="{url(lang,'download')}">{esc(L["smart_cta"])}</a>
</div>

<script>
// 스크롤 등장 — 움직임을 줄이도록 설정한 기기에서는 CSS 가 이미 무력화한다
(function(){{
  var io = new IntersectionObserver(function(es){{
    es.forEach(function(e){{ if(e.isIntersecting){{ e.target.classList.add('in'); io.unobserve(e.target); }} }});
  }}, {{rootMargin:'0px 0px -8% 0px'}});
  document.querySelectorAll('.rv').forEach(function(e){{ io.observe(e); }});
  // 앱 설치 띠는 한 번 닫으면 다시 띄우지 않는다
  var bar = document.getElementById('smartbar');
  try {{ if (localStorage.getItem('massa_sb') === 'off') bar.style.display = 'none'; }} catch(e) {{}}
  document.getElementById('sbx').onclick = function(){{
    bar.style.display = 'none';
    try {{ localStorage.setItem('massa_sb','off'); }} catch(e) {{}}
  }};
}})();
</script>
</body>
</html>'''

# ── 빌드 ───────────────────────────────────────────────────
def build():
    import importlib, sys
    global CSSV
    sys.path.insert(0, SRC)
    os.makedirs(OUT, exist_ok=True)
    shutil.copy(f"{SRC}/style.css", f"{OUT}/style.css")
    CSSV = css_version()

    # 관리자 지표 화면은 콘텐츠 페이지가 아니라 앱이다. 템플릿을 타지 않고 그대로 옮긴다.
    # 접근 통제는 여기가 아니라 DB 함수(admin_dashboard)가 한다.
    shutil.copytree(f"{SRC}/admin", f"{OUT}/admin", dirs_exist_ok=True)

    written = []
    for lang in LANGS:
        mod = importlib.import_module(f"content_{lang}")
        L, P = mod.LABELS, mod.PAGES
        d = OUT if lang == "ko" else f"{OUT}/{lang}"
        os.makedirs(d, exist_ok=True)
        for name, _ in PAGES:
            if name not in P:
                raise SystemExit(f"{lang}: '{name}' 페이지 콘텐츠가 없다")
            page = P[name]
            body = "".join(render(b, L, lang) for b in page["blocks"])
            path = f"{d}/{'index' if name=='index' else name}.html"
            open(path, "w", encoding="utf-8", newline="\n").write(chrome(lang, name, L, body, page))
            written.append(path)

    # sitemap — 세 언어 전부, 서로를 alternate 로 가리킨다
    us = ""
    for name, _ in PAGES:
        for lang in LANGS:
            alts = "".join(
                f'\n      <xhtml:link rel="alternate" hreflang="{l}" href="{SITE}{url(l,name)}"/>'
                for l in LANGS)
            pr = "1.0" if name == "index" else ("0.9" if name in ("services","guide","download") else "0.6")
            us += (f'  <url>\n    <loc>{SITE}{url(lang,name)}</loc>{alts}\n'
                   f'    <changefreq>monthly</changefreq>\n    <priority>{pr}</priority>\n  </url>\n')
    open(f"{OUT}/sitemap.xml", "w", encoding="utf-8", newline="\n").write(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
        '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' + us + '</urlset>\n')

    open(f"{OUT}/robots.txt", "w", encoding="utf-8", newline="\n").write(
        "# massaviet.com — 소개 사이트는 전부 열고 사이트맵 위치를 알린다\n"
        "User-agent: *\nAllow: /\n"
        "# 관리자 화면은 색인할 이유가 없다 (보안 장치는 아니다 — 권한은 DB 가 본다)\n"
        "Disallow: /admin/\n\nSitemap: https://massaviet.com/sitemap.xml\n")

    print(f"HTML {len(written)}개 + admin + sitemap + robots 생성")
    return written

if __name__ == "__main__":
    build()
