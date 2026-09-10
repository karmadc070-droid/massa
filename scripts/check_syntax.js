// index.html / admin.html 안의 <script> 블록을 떼어내 구문 오류가 있는지 본다.
const fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os');
const root = path.join(__dirname, '..');
let bad = 0;
for (const f of ['index.html', 'admin.html']) {
  const src = fs.readFileSync(path.join(root, f), 'utf8');
  const blocks = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
  let err = 0;
  blocks.forEach((b, i) => {
    const p = path.join(os.tmpdir(), `${f}.${i}.mjs`);
    fs.writeFileSync(p, b, 'utf8');
    const r = cp.spawnSync(process.execPath, ['--check', p], { encoding: 'utf8' });
    if (r.status !== 0) { err++; bad++; console.log(`★ ${f} 블록 ${i} 구문 오류\n${(r.stderr || '').slice(0, 900)}`); }
    fs.unlinkSync(p);
  });
  console.log(`${f}: 스크립트 ${blocks.length}개 · 오류 ${err}개`);
}
process.exit(bad ? 1 : 0);
