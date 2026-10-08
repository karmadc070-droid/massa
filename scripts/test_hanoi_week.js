// index.html·admin.html 의 hanoiWeek 를 떼어내 월말·연말·하노이 자정 경계에서 날짜가 맞는지 확인한다
const fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..');
const src = f => fs.readFileSync(path.join(root, f), 'utf8').match(/function hanoiWeek\(now\) \{[\s\S]*?\n\}/)[0];
const a = src('index.html'), b = src('admin.html');
if (a !== b) throw new Error('index·admin 의 hanoiWeek 가 다르다');
const hanoiWeek = new Function(a + '; return hanoiWeek;')();
let bad = 0;
const check = (nowIso, wantYmds, wantDow0) => {
  const w = hanoiWeek(new Date(nowIso));
  const got = w.map(x => x.ymd).join(',');
  const ok = got === wantYmds.join(',') && w[0].dow === wantDow0 && w.every(x => +x.ymd.slice(8) === x.day);
  console.log((ok ? 'OK  ' : 'FAIL') + ' ' + nowIso + ' → ' + w.map(x => x.ymd.slice(5) + x.dow).join(' '));
  if (!ok) bad++;
};
// 하노이 10/30 낮 → 10/30~11/05
check('2026-10-30T05:00:00Z', ['2026-10-30','2026-10-31','2026-11-01','2026-11-02','2026-11-03','2026-11-04','2026-11-05'], '금');
// UTC 로는 아직 10/29 이지만 하노이는 이미 10/30 01:00
check('2026-10-29T18:00:00Z', ['2026-10-30','2026-10-31','2026-11-01','2026-11-02','2026-11-03','2026-11-04','2026-11-05'], '금');
// 하노이 10/29 23:59 → 아직 10/29
check('2026-10-29T16:59:00Z', ['2026-10-29','2026-10-30','2026-10-31','2026-11-01','2026-11-02','2026-11-03','2026-11-04'], '목');
// 연말 하노이 12/29 → 다음 해 1/04
check('2026-12-29T03:00:00Z', ['2026-12-29','2026-12-30','2026-12-31','2027-01-01','2027-01-02','2027-01-03','2027-01-04'], '화');
// 윤년 아닌 2월 말
check('2027-02-26T03:00:00Z', ['2027-02-26','2027-02-27','2027-02-28','2027-03-01','2027-03-02','2027-03-03','2027-03-04'], '금');
// 오늘(작업일) — 6월이 아니어야 한다
check('2026-10-08T03:00:00Z', ['2026-10-08','2026-10-09','2026-10-10','2026-10-11','2026-10-12','2026-10-13','2026-10-14'], '목');
// submitBooking 과 같은 식으로 저장값을 만든다: 칩 날짜 + 시각 + 하노이 시간대
const iso = (ymd, time) => new Date(`${ymd}T${time}:00+07:00`).toISOString();
for (const [ymd, time, want] of [['2026-11-01', '00:30', '2026-10-31T17:30:00.000Z'], ['2027-01-01', '20:00', '2027-01-01T13:00:00.000Z'], ['2026-10-08', '20:00', '2026-10-08T13:00:00.000Z']]) {
  const got = iso(ymd, time); const ok = got === want;
  console.log((ok ? 'OK  ' : 'FAIL') + ` ${ymd} ${time} 하노이 → ${got}`); if (!ok) bad++;
}
// 지난 시각·30분 안쪽은 막고, 30분 뒤부터는 받는다 (isBookable — 두 파일이 같아야 한다)
const g = f => fs.readFileSync(path.join(root, f), 'utf8').match(/function isBookable\(iso, now\) \{.*\}/)[0];
if (g('index.html') !== g('admin.html')) throw new Error('index·admin 의 isBookable 이 다르다');
const isBookable = new Function(g('index.html') + '; return isBookable;')();
const now = new Date('2026-10-08T13:00:00Z');   // 하노이 10/08 20:00
for (const [ymd, time, want] of [
  ['2026-10-08', '19:00', false],   // 이미 지남
  ['2026-10-08', '20:00', false],   // 지금
  ['2026-10-08', '20:25', false],   // 30분 안쪽
  ['2026-10-08', '20:30', true],    // 딱 30분 뒤
  ['2026-10-09', '10:00', true],    // 내일
]) {
  const got = isBookable(iso(ymd, time), now); const ok = got === want;
  console.log((ok ? 'OK  ' : 'FAIL') + ` 지금 하노이 10/08 20:00 · ${ymd} ${time} 예약 가능=${got}`); if (!ok) bad++;
}
console.log(bad ? `실패 ${bad}건` : 'ALL PASS'); process.exit(bad ? 1 : 0);
