-- Kun 에게 운영팀 이름으로 채팅을 보낸다.
--
-- messages 는 고객↔마사지사 구조라 sender_role 이 'customer' / 'provider' 둘뿐이다.
-- 관리자 계정을 고객 자리에 두고 'customer' 로 보낸다. Kun 은 [고객 채팅] 에서 본다.
-- 첫 줄에 운영팀임을 밝혀서 손님으로 오해하지 않게 한다.
--
-- Kun 은 베트남 사람이고 신청서도 베트남어로 썼다. 베트남어로 보낸다.
-- 계좌번호·신분증 같은 민감정보는 채팅으로 받지 않는다. 앱 안에서 올리게 안내한다.
--
-- 문자열은 한 덩어리 E'...' 로 쓴다. E'' 와 '' 를 줄바꿈으로 이어 붙이면 구문 오류가 난다.

do $$
declare v_kun uuid; v_adm uuid;
begin
  select id into v_kun from public.providers where display_name = 'Kun' and application_status = 'approved';
  select id into v_adm from public.profiles  where role = 'admin' limit 1;
  if v_kun is null or v_adm is null then raise exception '대상을 찾지 못했습니다.'; end if;

  insert into public.messages (customer_id, provider_id, sender_role, body) values
  (v_adm, v_kun, 'customer',
   E'[mㅏssㅏ] Xin chào Kun! Đây là đội ngũ vận hành mㅏssㅏ (quản trị viên), không phải khách hàng.\n\nHồ sơ của bạn đã được DUYỆT. Bạn đã hiển thị trong danh sách và có thể nhận đặt lịch. Chúng tôi cũng đã thêm sẵn các dịch vụ bạn chọn: Aroma, Thụy Điển, Thái (60/90/120 phút).'),

  (v_adm, v_kun, 'customer',
   E'Tuy nhiên hồ sơ còn THIẾU giấy tờ bắt buộc. Nếu thiếu, chúng tôi KHÔNG THỂ chuyển tiền cho bạn:\n· CCCD/CMND mặt trước\n· CCCD/CMND mặt sau\n· Tên ngân hàng\n· Số tài khoản\n\nCách bổ sung (trong ứng dụng):\nTài khoản → "Trở thành đối tác" → điền các mục có dấu * → bấm "Lưu thông tin & giấy tờ".\n\nXin đừng gửi số tài khoản hay ảnh giấy tờ qua khung chat này — hãy nhập trong ứng dụng, thông tin sẽ được lưu bảo mật.'),

  (v_adm, v_kun, 'customer',
   E'Vài điều cần biết:\n· Phí hoa hồng hiện tại là 10% (ưu đãi khai trương, áp dụng cho tất cả).\n· Bạn có thể tự đặt giá riêng cho từng dịch vụ, cao hơn giá gốc, sau khi quản trị viên duyệt.\n· Bật/tắt trạng thái làm việc tại: Tài khoản → Quản lý đặt chỗ.\n\nCó gì cần hỗ trợ cứ nhắn lại ở đây nhé. Chúc bạn nhiều đơn hàng! 🌿');

  -- 앱 알림도 같이 남긴다. 채팅을 안 열어 볼 수 있다.
  insert into public.notifications (user_id, title, body, kind)
  select coalesce(p.profile_id, p.owner_id),
         'Cần bổ sung giấy tờ',
         E'Hồ sơ đã được duyệt nhưng còn thiếu CCCD và tài khoản ngân hàng.\nVào Tài khoản → Trở thành đối tác để bổ sung, nếu không chúng tôi không thể thanh toán cho bạn.',
         'warning'
    from public.providers p where p.id = v_kun and coalesce(p.profile_id, p.owner_id) is not null;
end $$;

-- ── 확인 ─────────────────────────────────────────────────────
select to_char(m.created_at at time zone 'Asia/Ho_Chi_Minh','HH24:MI') as 시각,
       m.sender_role as 보낸쪽, left(m.body, 46) as 내용
  from public.messages m
  join public.providers p on p.id = m.provider_id
 where p.display_name = 'Kun' order by m.created_at;

select '알림 ' || count(*) || '건' as 확인 from public.notifications n
  join public.providers p on coalesce(p.profile_id, p.owner_id) = n.user_id
 where p.display_name = 'Kun';
