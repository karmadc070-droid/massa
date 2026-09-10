// index.html 에서 거리 계산 함수를 그대로 떼어내 실제 하노이 좌표로 검산한다.
const fs = require('fs'), path = require('path');
const src = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const s = src.indexOf('function haversineKm');
const e = src.indexOf('// 마사지사까지 실제 거리');
if (s < 0 || e < 0) { console.log('★ 함수를 찾지 못했다'); process.exit(1); }
eval(src.slice(s, e));

let pass = 0, fail = 0;
function near(name, got, want, tol) {
  const ok = Math.abs(got - want) <= tol;
  console.log(`  ${ok ? '통과' : '★ 실패'} — ${name}: ${got.toFixed(2)}km (기대 ${want}±${tol})`);
  ok ? pass++ : fail++;
}

// 실제 DB 좌표
const 미딩 = [21.0205, 105.779];
const 바딘 = [21.0352, 105.814];
const 호안끼엠 = [21.0285, 105.852];
const 롱비엔 = [21.05, 105.885];

console.log('=== 하노이 권역 사이 거리 ===');
near('미딩 ↔ 바딘', haversineKm(...미딩, ...바딘), 4.0, 0.6);
near('미딩 ↔ 호안끼엠', haversineKm(...미딩, ...호안끼엠), 7.6, 0.8);
near('바딘 ↔ 호안끼엠', haversineKm(...바딘, ...호안끼엠), 4.1, 0.6);
near('미딩 ↔ 롱비엔', haversineKm(...미딩, ...롱비엔), 11.3, 1.2);

console.log('=== 경계값 ===');
near('같은 자리', haversineKm(21.03, 105.85, 21.03, 105.85), 0, 0.001);
near('위도 1도 = 약 111km', haversineKm(21, 105.8, 22, 105.8), 111.2, 0.5);

console.log('=== 표시 규칙 (1km 미만은 m) ===');
const fmt = d => (d < 1 ? Math.round(d * 1000) + 'm' : d.toFixed(1) + ' km');
[[0.34, '340m'], [0.999, '999m'], [1.0, '1.0 km'], [12.34, '12.3 km']].forEach(([d, want]) => {
  const got = fmt(d);
  const ok = got === want;
  console.log(`  ${ok ? '통과' : '★ 실패'} — ${d} → ${got} (기대 ${want})`);
  ok ? pass++ : fail++;
});

console.log('');
console.log(fail === 0 ? `전부 통과 (${pass}/${pass + fail})` : `★ 실패 ${fail}건`);
process.exit(fail ? 1 : 0);
