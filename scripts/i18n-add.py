# index.html 의 DICT / TITLE_I18N 에 번역을 추가하거나 덮어쓴다. 여러 번 실행해도 결과가 같다
# 사용법: python3 scripts/i18n-add.py
import re, sys, io

# 값 순서: [베트남어, 영어, 중국어, 일본어]
ADD = {
# ── 시간·단위 ──
'60분': ['60 phút', '60 min', '60分钟', '60分'],
'90분': ['90 phút', '90 min', '90分钟', '90分'],
'120분': ['120 phút', '120 min', '120分钟', '120分'],
'시': ['Giờ', 'Hour', '时', '時'],
'분': ['Phút', 'Min', '分', '分'],
'월': ['T2', 'Mon', '一', '月'],
'화': ['T3', 'Tue', '二', '火'],
'수': ['T4', 'Wed', '三', '水'],
'목': ['T5', 'Thu', '四', '木'],
'금': ['T6', 'Fri', '五', '金'],
'토': ['T7', 'Sat', '六', '土'],
'일': ['CN', 'Sun', '日', '日'],
'24시간': ['24 giờ', '24 hours', '24小时', '24時間'],

# ── 카테고리 ──
'마사지': ['Massage', 'Massage', '按摩', 'マッサージ'],
'마사지샵': ['Tiệm massage', 'Massage shop', '按摩店', 'マッサージ店'],
'스파샵': ['Spa', 'Spa', '水疗馆', 'スパ'],
'귀 청소·두피 케어': ['Lấy ráy tai · Chăm sóc da đầu', 'Ear cleaning · Scalp care', '采耳·头皮护理', '耳かき・頭皮ケア'],
'스킨·네일·속눈썹': ['Da · Nail · Mi', 'Skin · Nail · Lash', '皮肤·美甲·睫毛', 'スキン・ネイル・まつげ'],
'왁싱·제모': ['Waxing · Tẩy lông', 'Waxing · Hair removal', '蜜蜡脱毛', 'ワックス脱毛'],
'골프': ['Golf', 'Golf', '高尔夫', 'ゴルフ'],
'호텔': ['Khách sạn', 'Hotel', '酒店', 'ホテル'],
'모텔': ['Nhà nghỉ', 'Motel', '汽车旅馆', 'モーテル'],
'레지던스': ['Căn hộ dịch vụ', 'Residence', '公寓式酒店', 'レジデンス'],
'자택·아파트': ['Nhà riêng · Chung cư', 'Home · Apartment', '住宅·公寓', '自宅・マンション'],

# ── 코스 ──
'아로마테라피': ['Trị liệu tinh dầu', 'Aromatherapy', '芳香疗法', 'アロマテラピー'],
'타이 마사지': ['Massage Thái', 'Thai massage', '泰式按摩', 'タイ古式マッサージ'],
'아로마 오일로 심신 이완 · 향 선택 가능': ['Thư giãn với tinh dầu · Chọn được mùi hương', 'Relax with aroma oil · Choose your scent', '精油放松身心·可选香型', 'アロマオイルでリラックス・香り選択可'],
'스트레칭 중심 · 오일 없이 진행': ['Tập trung kéo giãn · Không dùng dầu', 'Stretch-focused · No oil', '以拉伸为主·不使用精油', 'ストレッチ中心・オイルなし'],
'부드러운 압의 전신 순환 관리': ['Massage toàn thân lực nhẹ, tăng tuần hoàn', 'Gentle full-body circulation care', '轻柔力度的全身循环护理', 'やさしい圧の全身循環ケア'],
'(약 35,000원~)': ['(khoảng 630.000₫~)', '(approx. 25 USD~)', '(约180元起)', '(約3,800円〜)'],
'(약 46,000원)': ['(khoảng 830.000₫)', '(approx. 33 USD)', '(约240元)', '(約5,000円)'],

# ── 매장·프로모 ──
'📍 매장 방문': ['📍 Đến cửa hàng', '📍 Visit in store', '📍 到店服务', '📍 店舗へ行く'],
'매장에서 직접': ['Trực tiếp tại cửa hàng', 'Right at the store', '在店内直接', '店舗で直接'],
'서비스를 경험해 보세요': ['Hãy trải nghiệm dịch vụ', 'Try the service', '体验服务', 'サービスを体験'],
'매장 방문 — 직접 서비스를 경험해 보세요': ['Đến cửa hàng — trải nghiệm trực tiếp', 'Visit in store — try it in person', '到店服务 — 亲身体验', '店舗訪問 — 直接体験'],
'제휴 스파 매장': ['Spa liên kết', 'Partner spas', '合作水疗馆', '提携スパ店舗'],
'소속 마사지사 · 테라피스트': ['Nhân viên massage · Chuyên viên', 'Masseurs · Therapists', '所属按摩师·理疗师', '所属マッサージ師・セラピスト'],
'✓ 귀 청소·두피 케어 ▾': ['✓ Lấy ráy tai · Chăm sóc da đầu ▾', '✓ Ear cleaning · Scalp care ▾', '✓ 采耳·头皮护理 ▾', '✓ 耳かき・頭皮ケア ▾'],
'해피아워 할인': ['Ưu đãi giờ vàng', 'Happy hour deal', '欢乐时光优惠', 'ハッピーアワー割引'],
'14~17시 예약 시 20% 할인 · 세금·팁 포함가': ['Đặt 14–17h giảm 20% · Đã gồm thuế và tip', '20% off for 14:00–17:00 · Tax & tip included', '14~17点预约享8折·含税含小费', '14〜17時の予約で20%割引・税・チップ込み'],
'첫 이용 490,000₫': ['Lần đầu 490.000₫', 'First visit 490,000₫', '首次体验 490,000₫', '初回 490,000₫'],
'60분 릴랙스 코스 첫 고객 체험가': ['Giá trải nghiệm khách mới, liệu trình thư giãn 60 phút', 'First-timer price for the 60-min relax course', '60分钟放松套餐新客体验价', '60分リラックスコース初回体験価格'],
'네일·왁싱·각질 케어 방문 서비스': ['Dịch vụ tại nhà: Nail · Waxing · Tẩy da chết', 'At-home nail, waxing & exfoliation', '上门美甲·脱毛·去角质服务', 'ネイル・ワックス・角質ケアの訪問サービス'],

# ── 배지 ──
'인기': ['Phổ biến', 'Popular', '热门', '人気'],
'할인중': ['Đang giảm giá', 'On sale', '优惠中', '割引中'],
'여성전용': ['Chỉ dành cho nữ', 'Women only', '仅限女性', '女性専用'],

# ── 위치 ──
'프론트에 방문자 등록해 두었습니다': ['Đã đăng ký khách tại quầy lễ tân', 'Visitor already registered at the front desk', '已在前台登记访客', 'フロントに訪問者登録済み'],
'로비에서 만나 함께 올라갑니다': ['Gặp ở sảnh rồi cùng lên phòng', 'Meet in the lobby and go up together', '在大堂见面一起上楼', 'ロビーで会って一緒に上がります'],
'테라피스트가 프론트에 문의 후 연락': ['Chuyên viên sẽ hỏi lễ tân rồi liên hệ', 'Therapist will ask the front desk and contact you', '理疗师询问前台后联系', 'セラピストがフロントに確認後連絡'],
'반경 1km': ['Bán kính 1km', 'Within 1km', '半径1公里', '半径1km'],
'반경 3km': ['Bán kính 3km', 'Within 3km', '半径3公里', '半径3km'],
'반경 5km': ['Bán kính 5km', 'Within 5km', '半径5公里', '半径5km'],

# ── 결제 ──
'현금 (VND)': ['Tiền mặt (VND)', 'Cash (VND)', '现金 (VND)', '現金 (VND)'],
'현장 카드 결제': ['Quẹt thẻ tại chỗ', 'Card on site', '现场刷卡', '現地カード決済'],
'서비스 완료 후 QR 스캔 결제': ['Quét QR thanh toán sau khi xong', 'Scan QR to pay after service', '服务结束后扫码支付', 'サービス終了後QR決済'],
'테라피스트 휴대 단말로 Visa·Mastercard 결제': ['Thanh toán Visa · Mastercard qua máy POS của chuyên viên', 'Pay by Visa/Mastercard on the therapist\'s terminal', '通过理疗师的POS机刷Visa·Mastercard', 'セラピストの端末でVisa・Mastercard決済'],
'거스름돈 준비를 위해 미리 선택해 주세요': ['Vui lòng chọn trước để chuẩn bị tiền thối', 'Please choose in advance so change can be prepared', '请提前选择以便准备找零', 'おつりの準備のため事前に選択してください'],
'(후불 · 현장 카드)': ['(Trả sau · Thẻ tại chỗ)', '(Pay later · Card on site)', '(后付·现场刷卡)', '(後払い・現地カード)'],

# ── 예약 ──
'예약': ['Đặt lịch', 'Book', '预约', '予約'],
'예약번호': ['Mã đặt lịch', 'Booking no.', '预约号', '予約番号'],
'예약이 확정되었습니다': ['Đã xác nhận đặt lịch', 'Your booking is confirmed', '预约已确认', '予約が確定しました'],
'지금 받기(즉시 매칭)': ['Nhận ngay (ghép nhanh)', 'Get it now (instant match)', '立即预约(即时匹配)', '今すぐ受ける(即時マッチング)'],
'출발·도착 시 푸시 알림을 보내드립니다.': ['Chúng tôi sẽ gửi thông báo khi chuyên viên khởi hành và đến nơi.', 'We will notify you on departure and arrival.', '出发和到达时会推送通知。', '出発・到着時にプッシュ通知をお送りします。'],
'안전 버튼': ['Nút an toàn', 'Safety button', '安全按钮', '安全ボタン'],
'💬 테라피스트와 채팅하기': ['💬 Nhắn tin với chuyên viên', '💬 Chat with your therapist', '💬 与理疗师聊天', '💬 セラピストとチャット'],

# ── 계정 ──
'계정': ['Tài khoản', 'Account', '我的', 'アカウント'],
'예약 내역': ['Lịch sử đặt', 'Bookings', '预约记录', '予約履歴'],
'탐색': ['Khám phá', 'Explore', '探索', 'さがす'],
'회원 가입': ['Đăng ký', 'Sign up', '注册', '会員登録'],
'추가 정보': ['Thông tin thêm', 'More info', '补充信息', '追加情報'],
'한국인': ['Tiếng Việt', 'English', '中文', '日本語'],
'친구 초대': ['Mời bạn bè', 'Invite friends', '邀请好友', '友達を招待'],
'파트너 되기': ['Trở thành đối tác', 'Become a partner', '成为合作伙伴', 'パートナーになる'],
'마사지사·홈뷰티': ['Massage · Làm đẹp tại nhà', 'Massage · Home beauty', '按摩·上门美容', 'マッサージ・ホームビューティー'],
'내 요청 기록': ['Lịch sử yêu cầu của tôi', 'My requests', '我的请求记录', '自分のリクエスト履歴'],
'안전 수칙': ['Nguyên tắc an toàn', 'Safety guidelines', '安全守则', '安全のご案内'],

# ── 약관 ──
'이용약관 (필수)': ['Điều khoản sử dụng (bắt buộc)', 'Terms of Service (required)', '使用条款(必须)', '利用規約(必須)'],
'개인정보 처리방침 (필수)': ['Chính sách bảo mật (bắt buộc)', 'Privacy Policy (required)', '隐私政策(必须)', 'プライバシーポリシー(必須)'],
'마케팅 정보 수신 (선택)': ['Nhận thông tin khuyến mãi (tùy chọn)', 'Marketing messages (optional)', '接收营销信息(可选)', 'マーケティング情報の受信(任意)'],
'[필수] 이용약관에 동의합니다': ['[Bắt buộc] Tôi đồng ý với Điều khoản sử dụng', '[Required] I agree to the Terms of Service', '[必须] 我同意使用条款', '[必須] 利用規約に同意します'],
'[필수] 개인정보 처리방침에 동의합니다': ['[Bắt buộc] Tôi đồng ý với Chính sách bảo mật', '[Required] I agree to the Privacy Policy', '[必须] 我同意隐私政策', '[必須] プライバシーポリシーに同意します'],
'[선택] 마케팅 정보 수신에 동의합니다': ['[Tùy chọn] Tôi đồng ý nhận thông tin khuyến mãi', '[Optional] I agree to receive marketing messages', '[可选] 我同意接收营销信息', '[任意] マーケティング情報の受信に同意します'],
'동의하고 시작하기': ['Đồng ý và bắt đầu', 'Agree and continue', '同意并开始', '同意して開始'],
'서비스 이용을 위해 아래 약관에 동의해 주세요. 동의 기록은 안전하게 보관됩니다.': ['Vui lòng đồng ý với các điều khoản dưới đây để sử dụng dịch vụ. Bản ghi đồng ý được lưu trữ an toàn.', 'Please agree to the terms below to use the service. Your consent record is stored securely.', '请同意以下条款以使用服务。同意记录将被安全保存。', 'サービスのご利用には以下の規約への同意が必要です。同意記録は安全に保管されます。'],
'할인·이벤트 소식을 알림으로 받습니다. 동의하지 않아도 서비스 이용에 제한이 없습니다.': ['Nhận thông báo về ưu đãi và sự kiện. Không đồng ý vẫn dùng dịch vụ bình thường.', 'Get notified about deals and events. Declining does not limit your use of the service.', '接收优惠和活动通知。不同意也不影响服务使用。', '割引・イベント情報を通知で受け取ります。同意しなくてもサービス利用に制限はありません。'],

# ── 안내문 ──
'🛡 인증 마크는 자격증·신원 확인·대면 면접 3단계 검증을 통과한 마사지사에게만 부여됩니다.': ['🛡 Dấu xác thực chỉ được cấp cho chuyên viên đã qua 3 bước kiểm tra: chứng chỉ, danh tính và phỏng vấn trực tiếp.', '🛡 The verified badge is granted only to therapists who pass three checks: certification, identity, and an in-person interview.', '🛡 认证标识仅授予通过资格证书、身份核实、面对面面试三重审核的按摩师。', '🛡 認証マークは資格・本人確認・対面面接の3段階審査を通過したセラピストにのみ付与されます。'],
'💅 네일·왁싱·각질 케어를 집·호텔에서. 인증 마크는 신원 확인·위생 교육을 마친 홈 뷰티 제공자에게 부여됩니다.': ['💅 Nail, waxing và tẩy da chết ngay tại nhà hoặc khách sạn. Dấu xác thực dành cho người cung cấp đã hoàn tất kiểm tra danh tính và đào tạo vệ sinh.', '💅 Nail, waxing and exfoliation at your home or hotel. The verified badge goes to providers who completed identity checks and hygiene training.', '💅 在家或酒店享受美甲·脱毛·去角质。认证标识授予已完成身份核实与卫生培训的美容服务者。', '💅 ネイル・ワックス・角質ケアをご自宅やホテルで。認証マークは本人確認と衛生研修を修了した提供者に付与されます。'],
'🏪 매장 방문 카테고리는 지역별 인기·가성비 매장을 모아 보여줍니다. 홈서비스 예약은 마사지·방문 치료에서 가능합니다.': ['🏪 Mục đến cửa hàng tập hợp các tiệm được ưa chuộng và có giá tốt theo khu vực. Đặt dịch vụ tại nhà ở mục massage hoặc trị liệu.', '🏪 The in-store category collects popular, good-value shops by area. For at-home service, use the massage or therapy menu.', '🏪 到店服务栏目汇总各区域人气与高性价比店铺。上门服务请在按摩或上门理疗中预约。', '🏪 店舗訪問カテゴリは地域ごとの人気・コスパ店舗をまとめています。訪問サービスの予約はマッサージ・訪問ケアから行えます。'],
'🏨 호텔별 외부 방문자 정책이 다릅니다. 출입이 제한되는 호텔은 검색 단계에서 미리 안내됩니다.': ['🏨 Chính sách khách bên ngoài khác nhau tùy khách sạn. Những nơi hạn chế ra vào sẽ được báo trước khi bạn tìm kiếm.', '🏨 Visitor policies differ by hotel. Hotels with entry restrictions are flagged during search.', '🏨 各酒店对外来访客的规定不同。出入受限的酒店会在搜索时提前提示。', '🏨 ホテルごとに外部訪問者の規定が異なります。入館が制限されるホテルは検索時に事前にご案内します。'],
'💳 결제는 서비스가 끝난 뒤 진행됩니다. 단, 예약 시간 1시간 전 이후 취소·노쇼 시 다음 예약이 제한될 수 있습니다.': ['💳 Thanh toán sau khi dịch vụ kết thúc. Tuy nhiên, hủy trong vòng 1 giờ trước giờ hẹn hoặc không đến có thể khiến lần đặt sau bị hạn chế.', '💳 Payment is taken after the service. However, cancelling within 1 hour of the appointment or not showing up may restrict future bookings.', '💳 服务结束后付款。但预约前1小时内取消或爽约，可能会限制下次预约。', '💳 お支払いはサービス終了後です。ただし予約1時間前以降のキャンセル・無断不参加は次回予約が制限される場合があります。'],
'🗺 지도로 스파샵 찾기 · 반경/할인/24시간': ['🗺 Tìm spa trên bản đồ · Bán kính / Ưu đãi / 24 giờ', '🗺 Find spas on the map · Radius / Deals / 24h', '🗺 用地图找水疗馆·半径/优惠/24小时', '🗺 地図でスパを探す・半径/割引/24時間'],
'✓ 외부 방문자 등록 필요 호텔 — 프론트에 방문자 등록 후 입장 가능합니다.': ['✓ Khách sạn yêu cầu đăng ký khách — cần đăng ký tại lễ tân mới vào được.', '✓ This hotel requires visitor registration — entry after registering at the front desk.', '✓ 需登记访客的酒店 — 在前台登记后方可进入。', '✓ 外部訪問者の登録が必要なホテル — フロントで登録後に入館できます。'],
'🆘 서비스 중 문제가 생기면 앱 내': ['🆘 Nếu có sự cố trong lúc dịch vụ, hãy dùng trong ứng dụng', '🆘 If something goes wrong during the service, use the in-app', '🆘 服务过程中出现问题时，请使用应用内的', '🆘 サービス中に問題が起きたらアプリ内の'],
'서비스 중 불안하거나 위급한 상황이면 즉시 도움을 요청하세요. 위치와 함께 관리자에게 전달됩니다.': ['Nếu thấy bất an hoặc gặp tình huống khẩn cấp, hãy yêu cầu trợ giúp ngay. Vị trí của bạn sẽ được gửi kèm cho quản trị viên.', 'If you feel unsafe or face an emergency, ask for help right away. Your location is sent to the admin team.', '若感到不安或遇到紧急情况，请立即求助。您的位置会一并发送给管理员。', 'サービス中に不安や緊急事態を感じたらすぐに助けを求めてください。位置情報とともに管理者へ送信されます。'],
'예약은 반드시 앱 안에서 진행하고, 앱 밖 현금 거래나 개인 연락처 유도 요청은 거절하세요. 제공자 도착 시 인증 마크와 프로필 사진을 확인하고, 호텔이라면 프론트에 방문 사실을 알려두는 것이 안전합니다. 서비스 중 부적절한 언행이 있으면 즉시 중단을 요청하고 신고해 주세요.': ['Hãy luôn đặt lịch trong ứng dụng và từ chối mọi đề nghị giao dịch tiền mặt ngoài ứng dụng hay xin liên hệ cá nhân. Khi chuyên viên đến, hãy kiểm tra dấu xác thực và ảnh hồ sơ; nếu ở khách sạn, nên báo trước cho lễ tân. Nếu có lời nói hay hành vi không phù hợp, hãy yêu cầu dừng ngay và báo cáo.', 'Always book inside the app, and decline any request for off-app cash payment or personal contact details. When the provider arrives, check the verified badge and profile photo; if you are at a hotel, let the front desk know. If there is any inappropriate behaviour, ask them to stop immediately and report it.', '请务必在应用内预约，拒绝任何应用外现金交易或索要私人联系方式的要求。服务者到达时请核对认证标识与头像；若在酒店，建议提前告知前台。服务过程中如有不当言行，请立即要求停止并举报。', '予約は必ずアプリ内で行い、アプリ外での現金取引や個人連絡先を求める要求は断ってください。提供者の到着時は認証マークとプロフィール写真を確認し、ホテルの場合はフロントに伝えておくと安全です。サービス中に不適切な言動があれば直ちに中止を求め、通報してください。'],
'현재 위치(파란 점) 기준 · 마커를 누르면 프로필로 이동합니다. 실서비스에서는 Google Maps로 대체됩니다.': ['Dựa trên vị trí hiện tại (chấm xanh) · Nhấn vào điểm đánh dấu để mở hồ sơ. Bản chính thức sẽ dùng Google Maps.', 'Based on your current location (blue dot) · Tap a marker to open the profile. The live version uses Google Maps.', '以当前位置(蓝点)为准·点击标记可打开档案。正式版将改用 Google 地图。', '現在地(青い点)を基準に表示・マーカーをタップするとプロフィールへ移動します。本番ではGoogle Mapsに置き換わります。'],
'추천을 불러오는 중…': ['Đang tải gợi ý…', 'Loading recommendations…', '正在加载推荐…', 'おすすめを読み込み中…'],
'● DB 연결 중…': ['● Đang kết nối…', '● Connecting…', '● 连接中…', '● 接続中…'],
'🚩 신고': ['🚩 Báo cáo', '🚩 Report', '🚩 举报', '🚩 通報'],
'⛔ 차단': ['⛔ Chặn', '⛔ Block', '⛔ 屏蔽', '⛔ ブロック'],
'전송': ['Gửi', 'Send', '发送', '送信'],

# ── 사진 등록 ──
'대표 사진': ['Ảnh đại diện', 'Main photo', '主图', 'メイン写真'],
'1 · 대표': ['1 · Chính', '1 · Main', '1 · 主图', '1 · メイン'],
'사진 2': ['Ảnh 2', 'Photo 2', '照片2', '写真2'],
'사진 3': ['Ảnh 3', 'Photo 3', '照片3', '写真3'],
'사진 4': ['Ảnh 4', 'Photo 4', '照片4', '写真4'],
'사진 5': ['Ảnh 5', 'Photo 5', '照片5', '写真5'],
'(AI 유니폼 자동 적용)': ['(Tự động áp đồng phục bằng AI)', '(AI applies the uniform automatically)', '(AI自动套用制服)', '(AIがユニフォームを自動適用)'],

# ── placeholder ──
'검색...': ['Tìm kiếm...', 'Search...', '搜索...', '検索...'],
'홈 뷰티 검색...': ['Tìm dịch vụ làm đẹp tại nhà...', 'Search home beauty...', '搜索上门美容...', 'ホームビューティーを検索...'],
'메시지를 입력하세요': ['Nhập tin nhắn', 'Type a message', '输入消息', 'メッセージを入力'],
'예) 2104호': ['VD) Phòng 2104', 'e.g. Room 2104', '例) 2104房', '例) 2104号室'],

# ── zh/ja 가 비어 있던 기존 항목 보완 ──
'호텔 검색 (Google Places)': ['Tìm khách sạn (Google Places)', 'Search hotels (Google Places)', '搜索酒店 (Google Places)', 'ホテル検索 (Google Places)'],
'사진 등록 (최대 4장) · 첫 번째 사진에 mㅏssㅏ 유니폼 로고 적용': ['Tải ảnh (tối đa 4) · Ảnh đầu tiên sẽ được gắn logo đồng phục mㅏssㅏ', 'Upload photos (up to 4) · The first photo gets the mㅏssㅏ uniform logo', '上传照片(最多4张)·第一张会套用 mㅏssㅏ 制服标识', '写真登録(最大4枚)・1枚目にmㅏssㅏユニフォームロゴを適用'],
'🩺 통증·케어 전문 테라피스트입니다. 의료 행위가 아닌 완화 케어이며, 치료가 필요한 증상은 의료기관 이용을 안내합니다.': ['🩺 Chuyên viên chuyên về giảm đau và chăm sóc. Đây là dịch vụ xoa dịu, không phải hành vi y tế; với triệu chứng cần điều trị, chúng tôi khuyên bạn đến cơ sở y tế.', '🩺 A therapist specialising in pain relief and care. This is comfort care, not medical treatment; for symptoms needing treatment we recommend seeing a medical professional.', '🩺 专注疼痛与护理的理疗师。属缓解性护理而非医疗行为，需要治疗的症状建议前往医疗机构。', '🩺 痛み・ケア専門のセラピストです。医療行為ではなく緩和ケアであり、治療が必要な症状は医療機関の受診をご案内します。'],
'신청 후 관리자 승인을 거쳐야 활동할 수 있습니다.': ['Sau khi nộp hồ sơ, bạn cần được quản trị viên duyệt mới bắt đầu hoạt động.', 'After applying, you can start only once an admin approves you.', '提交申请后需管理员审核通过方可开始接单。', '申請後、管理者の承認を経て活動できます。'],
'들어온 예약을 수락·거절하고, 완료 처리합니다.': ['Nhận hoặc từ chối lịch đặt và đánh dấu hoàn tất.', 'Accept or decline incoming bookings and mark them complete.', '接受或拒绝收到的预约，并标记完成。', '入った予約を受諾・拒否し、完了処理します。'],
'신청을 검토해 승인·거절합니다.': ['Xem xét hồ sơ để duyệt hoặc từ chối.', 'Review applications to approve or reject.', '审核申请并批准或拒绝。', '申請を確認して承認・却下します。'],
'아직 예약이 없습니다. 홈에서 서비스를 예약해 보세요.': ['Chưa có lịch đặt nào. Hãy đặt dịch vụ từ trang chủ.', 'No bookings yet. Book a service from the home screen.', '暂无预约。请从首页预约服务。', 'まだ予約がありません。ホームからサービスを予約してみてください。'],
}

# ── 카드·목록에서 조각으로 조립되는 문구 ──
ADD.update({
'예약 가능': ['Có thể đặt', 'Available', '可预约', '予約可能'],
'리뷰': ['đánh giá', 'reviews', '条评价', '件のレビュー'],
'권역': ['khu vực', 'area', '区域', 'エリア'],
'한국어 가능': ['Nói tiếng Hàn', 'Korean spoken', '可用韩语', '韓国語対応'],
'영어 가능': ['Nói tiếng Anh', 'English spoken', '可用英语', '英語対応'],
'위생 인증': ['Chứng nhận vệ sinh', 'Hygiene certified', '卫生认证', '衛生認証'],
'신규 도착': ['Mới', 'New', '新加入', '新着'],
'품질': ['Chất lượng', 'Top quality', '优质', '高品質'],
'내가 자주 받은': ['Bạn hay chọn', 'You often book', '您常选的', 'よく受けている'],
'전문': ['chuyên', 'specialist', '专长', '専門'],
'자주 가는': ['Bạn hay đến', 'You often visit', '您常去的', 'よく行く'],
'평점': ['Đánh giá', 'Rating', '评分', '評価'],
'상위': ['top', 'top-rated', '前列', '上位'],
'건': ['', '', '', ''],
'한국인 인기': ['Được khách Hàn ưa chuộng', 'Popular with Korean guests', '韩国客人喜爱', '韓国人に人気'],
'평점·리뷰 기준 추천': ['Gợi ý theo đánh giá và nhận xét', 'Recommended by rating and reviews', '按评分与评价推荐', '評価・レビューに基づくおすすめ'],
# 예약 상태
'요청됨': ['Đã gửi yêu cầu', 'Requested', '已申请', 'リクエスト済み'],
'확정': ['Đã xác nhận', 'Confirmed', '已确认', '確定'],
'이동 중': ['Đang di chuyển', 'On the way', '在路上', '移動中'],
'진행 중': ['Đang thực hiện', 'In progress', '进行中', '進行中'],
'완료': ['Hoàn tất', 'Completed', '已完成', '完了'],
'취소됨': ['Đã hủy', 'Cancelled', '已取消', 'キャンセル済み'],
'노쇼': ['Không đến', 'No-show', '爽约', 'ノーショー'],
# 서비스 종류
'아로마': ['Tinh dầu', 'Aroma', '芳香', 'アロマ'],
'스웨디시': ['Thụy Điển', 'Swedish', '瑞典式', 'スウェディッシュ'],
'타이': ['Thái', 'Thai', '泰式', 'タイ式'],
'딥티슈': ['Mô sâu', 'Deep tissue', '深层组织', 'ディープティシュー'],
'네일': ['Nail', 'Nail', '美甲', 'ネイル'],
'왁싱': ['Waxing', 'Waxing', '蜜蜡脱毛', 'ワックス脱毛'],
'각질 제거': ['Tẩy da chết', 'Exfoliation', '去角质', '角質ケア'],
})

# ── 하노이 지명 (한국어 음차 → 현지 표기) ──
ADD.update({
'미딩': ['Mỹ Đình', 'My Dinh', '美亭', 'ミーディン'],
'바딘': ['Ba Đình', 'Ba Dinh', '巴亭', 'バーディン'],
'떠이호': ['Tây Hồ', 'Tay Ho', '西湖', 'タイホー'],
'호안끼엠': ['Hoàn Kiếm', 'Hoan Kiem', '还剑', 'ホアンキエム'],
'롱비엔': ['Long Biên', 'Long Bien', '龙编', 'ロンビエン'],
'동다': ['Đống Đa', 'Dong Da', '栋多', 'ドンダー'],
'껌자': ['Cầu Giấy', 'Cau Giay', '纸桥', 'カウザイ'],
'하노이': ['Hà Nội', 'Hanoi', '河内', 'ハノイ'],
})

# ── 남은 UI 문구 ──
ADD.update({
'건': ['', '', '条', '件'],
'안전 센터': ['Trung tâm an toàn', 'Safety Center', '安全中心', '安全センター'],
'약관 및 개인정보': ['Điều khoản & Quyền riêng tư', 'Terms & Privacy', '条款与隐私', '規約とプライバシー'],
'🚨 긴급 도움 요청 (SOS)': ['🚨 Yêu cầu trợ giúp khẩn cấp (SOS)', '🚨 Emergency help (SOS)', '🚨 紧急求助 (SOS)', '🚨 緊急ヘルプ要請 (SOS)'],
'📍 내 위치 공유하기': ['📍 Chia sẻ vị trí của tôi', '📍 Share my location', '📍 分享我的位置', '📍 現在地を共有'],
'(약 40,500원)': ['(khoảng 730.000₫)', '(approx. 29 USD)', '(约210元)', '(約4,400円)'],
'(약 35,100원)': ['(khoảng 630.000₫)', '(approx. 25 USD)', '(约185元)', '(約3,800円)'],
'(약 29,700원)': ['(khoảng 535.000₫)', '(approx. 21 USD)', '(约155元)', '(約3,200円)'],
'아로마테라피 90분': ['Trị liệu tinh dầu 90 phút', 'Aromatherapy 90 min', '芳香疗法90分钟', 'アロマテラピー90分'],
'예상 금액 850,000₫': ['Dự kiến 850.000₫', 'Estimated 850,000₫', '预计 850,000₫', 'お見積り 850,000₫'],
'는 베타 오픈 후 순차 제공 예정입니다. 테라피스트의 \'시작 가능\' 시간 이후로 예약할 수 있습니다.': [
  'sẽ được mở dần sau khi ra mắt bản beta. Bạn có thể đặt lịch từ sau giờ "Có thể bắt đầu" của chuyên viên.',
  'will roll out gradually after the beta launch. You can book from after the therapist\'s "available from" time.',
  '将在Beta上线后陆续开放。可在理疗师的"可开始"时间之后预约。',
  'はベータ公開後、順次提供予定です。セラピストの「開始可能」時刻以降から予約できます。'],
'으로 즉시 연결됩니다. (Phase 1.5)': ['sẽ kết nối ngay lập tức. (Phase 1.5)', 'connects you immediately. (Phase 1.5)', '会立即接通。(Phase 1.5)', 'ですぐにつながります。(Phase 1.5)'],
'mㅏssㅏ는 고객과 검증된 제공자를 연결하는 중개 플랫폼입니다. 서비스는 의료 행위가 아닌 이완·관리 목적의 케어이며, 치료가 필요한 증상은 의료기관 이용을 권장합니다. 예약 후 무단 취소·노쇼가 반복되면 이용이 제한될 수 있습니다. 결제는 서비스 완료 후 현장에서 이루어지며, 플랫폼은 결제·정산 내역을 기록·관리합니다. 이용자는 제공자에게 성적 요구를 포함한 부적절한 요구를 할 수 없으며, 위반 시 즉시 이용이 정지되고 관계 기관에 통보될 수 있습니다.': [
  'mㅏssㅏ là nền tảng trung gian kết nối khách hàng với các nhà cung cấp đã được xác minh. Dịch vụ là chăm sóc thư giãn, không phải hành vi y tế; với triệu chứng cần điều trị, chúng tôi khuyến nghị đến cơ sở y tế. Việc hủy không báo trước hoặc không đến nhiều lần có thể khiến tài khoản bị hạn chế. Thanh toán diễn ra tại chỗ sau khi hoàn tất dịch vụ, và nền tảng ghi nhận, quản lý lịch sử thanh toán, đối soát. Người dùng không được đưa ra yêu cầu không phù hợp, bao gồm yêu cầu mang tính tình dục; vi phạm sẽ bị đình chỉ ngay và có thể bị báo cho cơ quan chức năng.',
  'mㅏssㅏ is an intermediary platform connecting customers with verified providers. The service is relaxation and wellness care, not medical treatment; for symptoms requiring treatment we recommend seeing a medical institution. Repeated no-shows or cancellations without notice may restrict your use. Payment is made on site after the service, and the platform records and manages payment and settlement history. Users may not make inappropriate requests, including sexual ones; violations lead to immediate suspension and may be reported to the authorities.',
  'mㅏssㅏ 是连接顾客与经审核服务者的中介平台。服务为放松与保养性质的护理，并非医疗行为；需要治疗的症状建议前往医疗机构。多次无故取消或爽约可能导致使用受限。付款在服务结束后于现场完成，平台会记录并管理支付与结算明细。用户不得提出包括性要求在内的不当要求，违反者将被立即停用并可能被通报有关机关。',
  'mㅏssㅏ はお客様と審査済みの提供者をつなぐ仲介プラットフォームです。サービスは医療行為ではなくリラクゼーション・ケアを目的としており、治療が必要な症状は医療機関の受診をお勧めします。無断キャンセルや不参加が繰り返されると利用が制限される場合があります。お支払いはサービス完了後に現地で行われ、プラットフォームは決済・精算の履歴を記録・管理します。利用者は性的な要求を含む不適切な要求を行うことはできず、違反時は直ちに利用停止となり関係機関へ通報される場合があります。'],
'수집 항목은 이름·연락처·국적·언어·위치(선택)이며, 예약 중개·안전 확인·정산 목적에 한해 이용합니다. 제공자에게는 서비스 수행에 필요한 최소 정보(이름·연락처·방문 주소)만 전달됩니다. 신분증·계좌 등 제공자 민감정보는 비공개 저장소에 보관되며 심사 담당자만 열람할 수 있습니다. 보관 기간은 회원 탈퇴 시까지이며, 관계 법령상 보존 의무가 있는 기록은 해당 기간 동안 보관 후 파기합니다.': [
  'Chúng tôi thu thập tên, thông tin liên hệ, quốc tịch, ngôn ngữ và vị trí (tùy chọn), chỉ dùng cho mục đích trung gian đặt lịch, xác nhận an toàn và đối soát. Nhà cung cấp chỉ nhận thông tin tối thiểu cần thiết (tên, liên hệ, địa chỉ đến). Thông tin nhạy cảm của nhà cung cấp như CMND/CCCD, tài khoản ngân hàng được lưu ở kho riêng và chỉ người phụ trách thẩm định mới xem được. Dữ liệu được lưu đến khi bạn hủy tài khoản; hồ sơ có nghĩa vụ lưu trữ theo luật sẽ được giữ trong thời hạn quy định rồi hủy.',
  'We collect your name, contact details, nationality, language and location (optional), and use them only for booking, safety checks and settlement. Providers receive only the minimum needed to perform the service (name, contact, visit address). Sensitive provider data such as ID and bank details is kept in private storage viewable only by reviewers. Data is kept until you delete your account; records with a statutory retention duty are kept for the required period and then destroyed.',
  '收集项目为姓名、联系方式、国籍、语言及位置(可选)，仅用于预约中介、安全确认与结算。服务者仅获得执行服务所需的最少信息(姓名、联系方式、上门地址)。身份证、账户等服务者敏感信息保存在非公开存储中，仅审核人员可查阅。保存期限至会员退出为止，依法须保存的记录将在规定期限内保存后销毁。',
  '収集項目は氏名・連絡先・国籍・言語・位置情報(任意)で、予約仲介・安全確認・精算の目的に限り利用します。提供者にはサービス遂行に必要な最小限の情報(氏名・連絡先・訪問先住所)のみが伝わります。身分証・口座など提供者の機微情報は非公開ストレージに保管され、審査担当者のみが閲覧できます。保管期間は退会時までで、法令上の保存義務がある記録は当該期間の保管後に破棄します。'],
})

# ── 초기 사전에 베트남어·영어만 있던 56개 항목에 중국어·일본어를 채운다 ──
ADD.update({
'⚙ 필터': ['⚙ Bộ lọc', '⚙ Filter', '⚙ 筛选', '⚙ 絞り込み'],
'필터': ['Bộ lọc', 'Filter', '筛选', '絞り込み'],
'내 근처': ['Gần tôi', 'Nearby', '附近', '近く'],
'주문 많은 순': ['Đặt nhiều', 'Most booked', '预约最多', '予約が多い順'],
'할인 많은 순': ['Giảm nhiều', 'Best deals', '折扣最多', '割引が大きい順'],
'서비스 유형 ▾': ['Loại dịch vụ ▾', 'Service type ▾', '服务类型 ▾', 'サービス種別 ▾'],
'서비스 유형': ['Loại dịch vụ', 'Service type', '服务类型', 'サービス種別'],
'전체': ['Tất cả', 'All', '全部', 'すべて'],
'지역 ▾': ['Khu vực ▾', 'Area ▾', '地区 ▾', 'エリア ▾'],
'가격 ▾': ['Giá ▾', 'Price ▾', '价格 ▾', '価格 ▾'],
'평점 ▾': ['Đánh giá ▾', 'Rating ▾', '评分 ▾', '評価 ▾'],
'코스': ['Liệu trình', 'Course', '套餐', 'コース'],
'마사지 종류': ['Loại massage', 'Massage type', '按摩种类', 'マッサージの種類'],
'코스 시간': ['Thời lượng', 'Duration', '时长', '所要時間'],
'날짜': ['Ngày', 'Date', '日期', '日付'],
'시작 시간 — 원하는 시간과 분을 직접 선택하세요': ['Giờ bắt đầu — chọn giờ và phút', 'Start time — pick hour & minute', '开始时间 — 请选择小时与分钟', '開始時刻 — 時と分を選んでください'],
'빠른 선택': ['Chọn nhanh', 'Quick pick', '快速选择', 'かんたん選択'],
'위치 유형': ['Loại địa điểm', 'Location type', '地点类型', '場所の種類'],
'객실 번호': ['Số phòng', 'Room number', '房间号', '部屋番号'],
'프론트 통과 방법': ['Cách qua lễ tân', 'Front desk method', '通过前台的方式', 'フロント通過方法'],
'홈서비스': ['Tại nhà', 'At home', '上门服务', '訪問サービス'],
'매장 방문': ['Đến cửa hàng', 'Visit store', '到店', '店舗訪問'],
'카테고리': ['Danh mục', 'Categories', '分类', 'カテゴリ'],
'소개': ['Giới thiệu', 'About', '介绍', '紹介'],
'이름': ['Tên', 'Name', '姓名', '名前'],
'활동 지역': ['Khu vực hoạt động', 'Service area', '活动区域', '対応エリア'],
'제공 서비스': ['Dịch vụ cung cấp', 'Services', '提供服务', '提供サービス'],
'결제 방식 — 후불 (서비스 완료 후 현장 결제)': ['Thanh toán — trả sau (tại chỗ khi xong)', 'Payment — pay later (on site after service)', '支付方式 — 后付(服务结束后现场支付)', 'お支払い — 後払い(サービス終了後に現地決済)'],
'다음 — 위치 입력': ['Tiếp — Địa điểm', 'Next — Location', '下一步 — 输入地点', '次へ — 場所入力'],
'다음 — 시간 설정': ['Tiếp — Thời gian', 'Next — Time', '下一步 — 设置时间', '次へ — 時間設定'],
'다음 — 예약 확인': ['Tiếp — Xác nhận', 'Next — Confirm', '下一步 — 确认预约', '次へ — 予約確認'],
'예약 확정하기': ['Xác nhận đặt chỗ', 'Confirm booking', '确认预约', '予約を確定する'],
'홈으로': ['Về trang chủ', 'Home', '回到首页', 'ホームへ'],
'다음': ['Tiếp tục', 'Next', '下一步', '次へ'],
'신청 제출': ['Gửi đăng ký', 'Submit', '提交申请', '申請を送信'],
'이 제공자로 예약': ['Đặt với người này', 'Book this provider', '预约该服务者', 'この提供者で予約'],
'오픈 알림 신청 — 시간 설정으로': ['Nhận thông báo khi mở', 'Notify me when open', '开放时通知我', 'オープン通知を受け取る'],
'활동 내역': ['Hoạt động', 'Activity', '活动记录', '利用履歴'],
'개인 정보': ['Thông tin cá nhân', 'Profile', '个人信息', '個人情報'],
'언어': ['Ngôn ngữ', 'Language', '语言', '言語'],
'국가': ['Quốc gia', 'Country', '国家', '国'],
'회사 소개': ['Về chúng tôi', 'About us', '关于我们', '会社紹介'],
'예약 관리 (파트너)': ['Quản lý đặt chỗ (Đối tác)', 'Bookings (Partner)', '预约管理(合作伙伴)', '予約管理(パートナー)'],
'관리자 승인': ['Duyệt đăng ký', 'Approvals', '管理员审批', '管理者承認'],
'로그아웃': ['Đăng xuất', 'Log out', '退出登录', 'ログアウト'],
'성명': ['Họ tên', 'Full name', '姓名', '氏名'],
'전화번호': ['Số điện thoại', 'Phone', '电话号码', '電話番号'],
'성별': ['Giới tính', 'Gender', '性别', '性別'],
'국적': ['Quốc tịch', 'Nationality', '国籍', '国籍'],
'비밀번호 변경': ['Đổi mật khẩu', 'Change password', '修改密码', 'パスワード変更'],
'계정 삭제': ['Xóa tài khoản', 'Delete account', '删除账户', 'アカウント削除'],
'알림': ['Thông báo', 'Notifications', '通知', 'お知らせ'],
'후불': ['Trả sau', 'Pay later', '后付', '後払い'],
'QR': ['QR', 'QR', 'QR码', 'QR'],
'현금': ['Tiền mặt', 'Cash', '现金', '現金'],
})

# ── alert / confirm / prompt 문구 ──
ADD.update({
'mㅏssㅏ — 터치 한 번으로 원하는 시간과 공간으로 찾아가는 프리미엄 홈 웰니스 & 그루밍 플랫폼.': [
  'mㅏssㅏ — Nền tảng chăm sóc sức khỏe và làm đẹp tại nhà cao cấp, đến đúng nơi bạn muốn chỉ với một chạm.',
  'mㅏssㅏ — A premium home wellness and grooming platform that comes to your place at a single tap.',
  'mㅏssㅏ — 一键预约，上门为您服务的高端居家养护与美容平台。',
  'mㅏssㅏ — ワンタップでご希望の時間と場所へうかがう、プレミアムなホームウェルネス＆グルーミングのプラットフォームです。'],
'계정을 삭제하면 프로필, 예약 내역, 리뷰, 채팅이 모두 영구 삭제되며 되돌릴 수 없습니다. 계속하시겠어요?': [
  'Xóa tài khoản sẽ xóa vĩnh viễn hồ sơ, lịch sử đặt, đánh giá và tin nhắn, và không thể khôi phục. Bạn có muốn tiếp tục?',
  'Deleting your account permanently removes your profile, bookings, reviews and chats. This cannot be undone. Continue?',
  '删除账户将永久删除您的资料、预约记录、评价和聊天，且无法恢复。要继续吗？',
  'アカウントを削除すると、プロフィール・予約履歴・レビュー・チャットがすべて完全に削除され、元に戻せません。続けますか。'],
'계정이 삭제되었습니다. 이용해 주셔서 감사합니다.': [
  'Tài khoản đã được xóa. Cảm ơn bạn đã sử dụng dịch vụ.',
  'Your account has been deleted. Thank you for using our service.',
  '账户已删除。感谢您的使用。',
  'アカウントを削除しました。ご利用ありがとうございました。'],
'긴급 도움을 요청할까요? 현재 위치와 함께 관리자에게 즉시 전달됩니다.': [
  'Bạn muốn gửi yêu cầu trợ giúp khẩn cấp? Vị trí hiện tại sẽ được gửi ngay cho quản trị viên.',
  'Send an emergency help request? Your current location will be sent to the admin team immediately.',
  '要发送紧急求助吗？您的当前位置将立即发送给管理员。',
  '緊急ヘルプを要請しますか。現在地とともに管理者へ直ちに送信されます。'],
'리뷰가 등록되었습니다. 감사합니다!': [
  'Đã đăng đánh giá. Cảm ơn bạn!', 'Your review has been posted. Thank you!',
  '评价已提交，谢谢！', 'レビューを登録しました。ありがとうございます。'],
'사유를 선택하거나 입력해 주세요.': [
  'Vui lòng chọn hoặc nhập lý do.', 'Please select or enter a reason.',
  '请选择或填写理由。', '理由を選択するか入力してください。'],
'새 비밀번호(6자 이상)': [
  'Mật khẩu mới (từ 6 ký tự)', 'New password (6+ characters)',
  '新密码(6位以上)', '新しいパスワード(6文字以上)'],
'예약 전에 이용약관과 개인정보 처리방침에 동의해 주세요.': [
  'Vui lòng đồng ý với Điều khoản sử dụng và Chính sách bảo mật trước khi đặt lịch.',
  'Please agree to the Terms of Service and Privacy Policy before booking.',
  '预约前请先同意使用条款与隐私政策。',
  'ご予約の前に利用規約とプライバシーポリシーに同意してください。'],
'예약을 완료하시면 담당 테라피스트와 채팅할 수 있습니다.\n서비스·시간·장소를 선택해 예약을 먼저 진행해 주세요.': [
  'Sau khi hoàn tất đặt lịch, bạn có thể nhắn tin với chuyên viên phụ trách.\nHãy chọn dịch vụ, thời gian và địa điểm để đặt lịch trước.',
  'You can chat with your therapist once your booking is complete.\nPlease choose a service, time and place to book first.',
  '完成预约后即可与负责的理疗师聊天。\n请先选择服务、时间和地点完成预约。',
  'ご予約が完了すると担当セラピストとチャットできます。\nサービス・時間・場所を選んで先にご予約ください。'],
'자동 번역은 준비 중입니다.': [
  'Tính năng dịch tự động đang được chuẩn bị.', 'Automatic translation is coming soon.',
  '自动翻译功能正在准备中。', '自動翻訳は準備中です。'],
'재제출되었습니다. 관리자 심사를 기다려 주세요.': [
  'Đã gửi lại. Vui lòng chờ quản trị viên xét duyệt.', 'Resubmitted. Please wait for admin review.',
  '已重新提交，请等待管理员审核。', '再提出しました。管理者の審査をお待ちください。'],
'차단을 해제했습니다.': ['Đã bỏ chặn.', 'Unblocked.', '已解除屏蔽。', 'ブロックを解除しました。'],
'차단했습니다. 목록에서 숨겨집니다.': [
  'Đã chặn. Sẽ được ẩn khỏi danh sách.', 'Blocked. They will be hidden from your list.',
  '已屏蔽，将从列表中隐藏。', 'ブロックしました。一覧から非表示になります。'],
'예약이 취소되었습니다.': ['Đã hủy đặt lịch.', 'Your booking has been cancelled.', '预约已取消。', '予約をキャンセルしました。'],
# 뒤에 값이 붙는 접두사
'실패:': ['Thất bại:', 'Failed:', '失败：', '失敗:'],
'저장 실패:': ['Lưu thất bại:', 'Save failed:', '保存失败：', '保存に失敗しました:'],
'업로드 실패:': ['Tải lên thất bại:', 'Upload failed:', '上传失败：', 'アップロードに失敗しました:'],
'재제출 실패:': ['Gửi lại thất bại:', 'Resubmit failed:', '重新提交失败：', '再提出に失敗しました:'],
'삭제에 실패했습니다:': ['Xóa thất bại:', 'Delete failed:', '删除失败：', '削除に失敗しました:'],
'결제 처리 실패:': ['Xử lý thanh toán thất bại:', 'Payment failed:', '支付处理失败：', '決済処理に失敗しました:'],
'신고 사유를 입력하세요': ['Nhập lý do báo cáo', 'Enter a reason for the report', '请输入举报理由', '通報理由を入力してください'],
'AI 변환 실패 — 원본 사진을 유지합니다.': [
  'Chuyển đổi AI thất bại — giữ nguyên ảnh gốc.', 'AI conversion failed — keeping the original photo.',
  'AI转换失败 — 保留原图。', 'AI変換に失敗しました — 元の写真を維持します。'],
'인증 테라피스트': ['Chuyên viên đã xác minh', 'Verified therapist', '认证理疗师', '認証セラピスト'],
'예상 금액': ['Dự kiến', 'Estimated', '预计金额', 'お見積り'],
'예) 롯데호텔 하노이': ['VD) Lotte Hotel Hanoi', 'e.g. Lotte Hotel Hanoi', '例) 河内乐天酒店', '例) ロッテホテルハノイ'],
'숙소·건물 이름을 입력해 주세요.': [
  'Vui lòng nhập tên khách sạn hoặc tòa nhà.', 'Please enter the hotel or building name.',
  '请输入住宿或建筑名称。', '宿泊先・建物名を入力してください。'],
'약': ['khoảng', 'approx.', '约', '約'],
'원': ['₩', 'KRW', '韩元', '円'],
'⚠ 예약': ['⚠ Đặt lịch', '⚠ Booking', '⚠ 预约', '⚠ 予約'],
'시간 이내 취소입니다. 마사지사가 이미 준비 중일 수 있어': [
  'giờ trước giờ hẹn — chuyên viên có thể đã chuẩn bị, nên lần hủy này',
  'hours before the appointment — the therapist may already be preparing, so this cancellation',
  '小时内取消 — 按摩师可能已在准备，因此本次取消',
  '時間以内のキャンセルです。セラピストがすでに準備中の可能性があるため'],
'취소 횟수에 포함': ['được tính vào số lần hủy', 'counts toward your cancellation limit', '将计入取消次数', 'キャンセル回数に含まれます'],
'됩니다.': ['.', '.', '。', '。'],
'시간 전까지는 자유롭게 취소할 수 있습니다.': [
  'giờ trước giờ hẹn, bạn có thể hủy thoải mái.',
  'hours before the appointment, you can cancel freely.',
  '小时前可自由取消。',
  '時間前までは自由にキャンセルできます。'],
'임박 취소·노쇼가 누적되어': [
  'Do hủy sát giờ và không đến bị tích lũy,', 'Due to repeated last-minute cancellations and no-shows,',
  '因临近取消与爽约累计，', '直前キャンセル・無断不参加が累積したため'],
})

# ── 제공자 프로필 상세 ──
ADD.update({
'✓ 인증': ['✓ Đã xác minh', '✓ Verified', '✓ 已认证', '✓ 認証済み'],
'💬 예약 후 채팅하기': ['💬 Nhắn tin sau khi đặt lịch', '💬 Chat after booking', '💬 预约后聊天', '💬 予約後にチャット'],
'✅ 팁 없음, 이동비 없음': ['✅ Không tip, không phí di chuyển', '✅ No tips, no travel fee', '✅ 无小费，无交通费', '✅ チップなし・出張費なし'],
'소개가 아직 없습니다.': ['Chưa có phần giới thiệu.', 'No introduction yet.', '暂无介绍。', '紹介文はまだありません。'],
'이용 정보': ['Thông tin dịch vụ', 'Service info', '使用信息', 'ご利用案内'],
'🕒 영업시간': ['🕒 Giờ làm việc', '🕒 Hours', '🕒 营业时间', '🕒 営業時間'],
'📍 주소': ['📍 Địa chỉ', '📍 Address', '📍 地址', '📍 住所'],
'📞 전화': ['📞 Điện thoại', '📞 Phone', '📞 电话', '📞 電話'],
'🗨️ 카카오톡': ['🗨️ KakaoTalk', '🗨️ KakaoTalk', '🗨️ KakaoTalk', '🗨️ カカオトーク'],
'시설 소개': ['Giới thiệu cơ sở', 'Facilities', '设施介绍', '施設のご紹介'],
'개인 룸 · 위생 키트 · 샤워 시설': ['Phòng riêng · Bộ vệ sinh · Phòng tắm', 'Private room · Hygiene kit · Shower', '独立房间·卫生套装·淋浴设施', '個室・衛生キット・シャワー設備'],
'개인 룸 · 샤워 시설 · 1회용 위생 키트': ['Phòng riêng · Phòng tắm · Bộ vệ sinh dùng một lần', 'Private room · Shower · Single-use hygiene kit', '独立房间·淋浴·一次性卫生套装', '個室・シャワー・使い捨て衛生キット'],
'내 서비스': ['Dịch vụ của tôi', 'My services', '我的服务', '提供サービス'],
'모두 보기': ['Xem tất cả', 'See all', '查看全部', 'すべて見る'],
'아직 리뷰가 없습니다.': ['Chưa có đánh giá nào.', 'No reviews yet.', '暂无评价。', 'まだレビューがありません。'],
'🚩 이 제공자 신고하기': ['🚩 Báo cáo người này', '🚩 Report this provider', '🚩 举报该服务者', '🚩 この提供者を通報する'],
'이 제공자 차단하기': ['Chặn người này', 'Block this provider', '屏蔽该服务者', 'この提供者をブロックする'],
'차단 해제하기': ['Bỏ chặn', 'Unblock', '解除屏蔽', 'ブロックを解除'],
'프로필 보기 ›': ['Xem hồ sơ ›', 'View profile ›', '查看档案 ›', 'プロフィールを見る ›'],
'불러오는 중…': ['Đang tải…', 'Loading…', '加载中…', '読み込み中…'],
'등록된 서비스가 없습니다.': ['Chưa có dịch vụ nào.', 'No services registered.', '暂无登记的服务。', '登録されたサービスがありません。'],
})

# ── 서비스 메뉴 이름 (DB 값) ──
ADD.update({
'오일 마사지 + 부항 요법': ['Massage dầu + giác hơi', 'Oil massage + cupping', '精油按摩＋拔罐', 'オイルマッサージ＋カッピング'],
'핫 스톤마사지': ['Massage đá nóng', 'Hot stone massage', '热石按摩', 'ホットストーンマッサージ'],
'태국식 마사지': ['Massage Thái', 'Thai massage', '泰式按摩', 'タイ式マッサージ'],
'아로마 마사지': ['Massage tinh dầu', 'Aroma massage', '芳香按摩', 'アロママッサージ'],
'다리 마사지': ['Massage chân', 'Leg massage', '腿部按摩', '脚のマッサージ'],
'어깨·목 마사지': ['Massage vai · cổ', 'Shoulder & neck massage', '肩颈按摩', '肩・首のマッサージ'],
'머리 마사지': ['Massage đầu', 'Head massage', '头部按摩', 'ヘッドマッサージ'],
'오일 없는 마사지': ['Massage không dầu', 'Massage without oil', '无油按摩', 'オイルなしマッサージ'],
'스포츠 테라피': ['Trị liệu thể thao', 'Sports therapy', '运动理疗', 'スポーツセラピー'],
'풋 테라피': ['Trị liệu bàn chân', 'Foot therapy', '足部理疗', 'フットセラピー'],
'등 테라피': ['Trị liệu lưng', 'Back therapy', '背部理疗', 'バックセラピー'],
'목·어깨 테라피': ['Trị liệu cổ · vai', 'Neck & shoulder therapy', '颈肩理疗', '首・肩セラピー'],
'헤드 테라피': ['Trị liệu đầu', 'Head therapy', '头部理疗', 'ヘッドセラピー'],
'강한 압': ['Lực mạnh', 'Firm pressure', '力度较强', '強めの圧'],
})

# ── 알림 ──
ADD.update({
'분 전': ['phút trước', 'min ago', '分钟前', '分前'],
'시간 전': ['giờ trước', 'hours ago', '小时前', '時間前'],
'일 전': ['ngày trước', 'days ago', '天前', '日前'],
'테라피스트 Linh N.는 서비스 예약을 간절히 기다리고 있습니다.': [
  'Chuyên viên Linh N. đang mong chờ lịch đặt của bạn.',
  'Therapist Linh N. is looking forward to your booking.',
  '理疗师 Linh N. 正期待您的预约。',
  'セラピストのLinh N.があなたのご予約をお待ちしています。'],
'서비스가 완료되었습니다. 평가를 남겨주세요': [
  'Dịch vụ đã hoàn tất. Hãy để lại đánh giá nhé.', 'Your service is complete. Please leave a review.',
  '服务已完成，请留下评价。', 'サービスが完了しました。レビューをお願いします。'],
'연결됨': ['Đã kết nối', 'Connected', '已连接', '接続済み'],
'테라피스트와 연결되었습니다': ['Đã kết nối với chuyên viên', 'You are connected with a therapist', '已与理疗师建立联系', 'セラピストとつながりました'],
'완료': ['Hoàn tất', 'Completed', '已完成', '完了'],
})

# ── massa bot (2026-09-05) ──
# 봇 문구가 통째로 DICT 에 없어 비한국어 사용자에게 한국어로 나오던 것을 채운다
ADD.update({
# UI
'AI 자연어 검색 · 보통 몇 초 내 응답': [
  'Tìm kiếm bằng ngôn ngữ tự nhiên · thường trả lời trong vài giây',
  'Natural-language search · usually replies in seconds',
  '自然语言搜索 · 通常几秒内回复', '自然言語検索 · 通常数秒で返信'],
'예: 커플 마사지 10만원 이하': [
  'VD: massage cặp đôi dưới 2 triệu ₫', 'e.g. couple massage under 2,000,000₫',
  '例：情侣按摩 200万₫以下', '例：カップルマッサージ 200万₫以下'],
'전송': ['Gửi', 'Send', '发送', '送信'],
# 퀵리플라이
'예약 방법': ['Cách đặt lịch', 'How to book', '如何预约', '予約方法'],
'가격 안내': ['Bảng giá', 'Pricing', '价格说明', '料金案内'],
'커플 마사지 가능한 곳': ['Nơi có massage cặp đôi', 'Places with couple massage', '可做情侣按摩的店', 'カップルマッサージ可'],
'한국인이 많이 가는 곳': ['Nơi người Hàn hay đến', 'Popular with Koreans', '韩国人常去的店', '韓国人に人気の店'],
'발마사지 잘하는 곳': ['Nơi massage chân tốt', 'Good foot massage', '足疗做得好的店', '足マッサージが上手な店'],
'10만원 이하': ['Dưới 2 triệu ₫', 'Under 2,000,000₫', '200万₫以下', '200万₫以下'],
# 검색 결과 조각
'AI가 이해한 조건': ['Điều kiện AI hiểu được', 'What the AI understood', 'AI 理解的条件', 'AIが理解した条件'],
'곳을 찾았어요!': ['nơi phù hợp!', 'places found!', '家符合！', '件見つかりました！'],
'조건에 맞는 곳을 못 찾았어요 🙏': [
  'Không tìm thấy nơi nào phù hợp 🙏', 'No matching places found 🙏',
  '没有找到符合条件的店 🙏', '条件に合う店が見つかりませんでした 🙏'],
# 인사·기본
'안녕하세요! mㅏssㅏ봇이에요 😊 원하는 조건을 자연어로 말해보세요. 예: "커플 마사지 10만원 이하", "여성전용 네일".': [
  'Xin chào! Mình là mㅏssㅏ bot 😊 Hãy nói điều kiện bạn muốn bằng lời thường. VD: "massage cặp đôi dưới 2 triệu ₫", "làm nail chỉ dành cho nữ".',
  'Hello! I am the mㅏssㅏ bot 😊 Just describe what you want. e.g. "couple massage under 2,000,000₫", "women-only nails".',
  '您好！我是 mㅏssㅏ 机器人 😊 请用日常语言说出您的需求。例如"情侣按摩 200万₫以下"、"女性专用美甲"。',
  'こんにちは！mㅏssㅏボットです 😊 ご希望を普通の言葉でどうぞ。例：「カップルマッサージ 200万₫以下」「女性専用ネイル」。'],
'mㅏssㅏ봇이에요 😊 "커플 마사지 가능한 곳", "발마사지 10만원 이하"처럼 자연어로 물어보셔도 돼요.': [
  'Mình là mㅏssㅏ bot 😊 Bạn có thể hỏi tự nhiên như "nơi có massage cặp đôi", "massage chân dưới 2 triệu ₫".',
  'I am the mㅏssㅏ bot 😊 You can ask naturally, like "places with couple massage" or "foot massage under 2,000,000₫".',
  '我是 mㅏssㅏ 机器人 😊 您可以像"可做情侣按摩的店""足疗 200万₫以下"这样自然提问。',
  'mㅏssㅏボットです 😊「カップルマッサージ可の店」「足マッサージ 200万₫以下」のように自然に聞いてください。'],
'원하시는 조건을 말씀해 주세요. 예: "여성전용 네일", "24시간 타이 마사지", "아이랑 갈 수 있는 곳".': [
  'Hãy cho mình biết điều kiện bạn muốn. VD: "nail chỉ dành cho nữ", "massage Thái 24 giờ", "nơi đi cùng trẻ em được".',
  'Tell me what you are looking for. e.g. "women-only nails", "24-hour Thai massage", "kid-friendly places".',
  '请告诉我您的条件。例如"女性专用美甲""24小时泰式按摩""可带孩子的店"。',
  'ご希望の条件をお知らせください。例：「女性専用ネイル」「24時間タイマッサージ」「子ども同伴可の店」。'],
# FAQ 답변
'예약은 홈에서 서비스 선택 → 마사지사·코스 → 시간·위치 입력 → 예약 확정 순이에요. 결제는 서비스 완료 후 현장 결제(후불)입니다.': [
  'Đặt lịch theo thứ tự: chọn dịch vụ ở trang chủ → chọn chuyên viên và gói → nhập giờ và địa điểm → xác nhận. Thanh toán sau khi xong dịch vụ, trả trực tiếp.',
  'Booking order: pick a service on Home → choose a therapist and course → enter time and place → confirm. You pay on the spot after the service is finished.',
  '预约顺序：首页选择服务 → 选择理疗师与套餐 → 输入时间与地点 → 确认预约。服务结束后现场付款。',
  '予約の流れ：ホームでサービス選択 → セラピストとコース選択 → 時間と場所を入力 → 予約確定。お支払いはサービス完了後の現地払いです。'],
'1회용 위생 키트와 신원·자격 검증(인증 마크), 앱 내 안전 버튼으로 안전을 지켜요.': [
  'Chúng tôi dùng bộ vệ sinh dùng một lần, xác minh nhân thân và chứng chỉ (dấu xác thực), cùng nút an toàn trong ứng dụng.',
  'We use single-use hygiene kits, verify identity and credentials (verified badge), and provide an in-app safety button.',
  '我们使用一次性卫生用品，核验身份与资质（认证标识），并在应用内提供安全按钮。',
  '使い捨て衛生キット、本人・資格の確認（認証マーク）、アプリ内の安全ボタンで安全を守ります。'],
'계정 → 활동 내역(내 예약)에서 예약 상태와 시간을 확인할 수 있어요. 완료 후 결제·리뷰도 여기서 진행합니다.': [
  'Xem trạng thái và giờ đặt tại Tài khoản → Lịch sử hoạt động (Lịch của tôi). Thanh toán và đánh giá sau khi hoàn tất cũng ở đây.',
  'Check status and time under Account → Activity (My bookings). Payment and reviews after completion happen there too.',
  '在 账户 → 活动记录（我的预约）中可查看预约状态与时间。完成后的付款与评价也在这里。',
  'アカウント → 活動履歴（マイ予約）で予約状況と時間を確認できます。完了後の支払い・レビューもここです。'],
'후불 결제입니다. 서비스 완료 후 현장 카드·현금·QR(MoMo·ZaloPay·VNPay)·계좌이체 중에 고르실 수 있어요. 쿠폰은 결제 화면에서 적용됩니다.': [
  'Thanh toán sau. Sau khi xong dịch vụ, bạn chọn thẻ tại chỗ, tiền mặt, QR (MoMo·ZaloPay·VNPay) hoặc chuyển khoản. Mã giảm giá áp dụng ở màn hình thanh toán.',
  'Payment is after the service. You can choose card on site, cash, QR (MoMo, ZaloPay, VNPay) or bank transfer. Coupons apply on the payment screen.',
  '为后付款。服务结束后可选择现场刷卡、现金、QR（MoMo·ZaloPay·VNPay）或转账。优惠券在付款页面使用。',
  '後払いです。サービス完了後、現地でのカード・現金・QR（MoMo・ZaloPay・VNPay）・振込から選べます。クーポンは支払い画面で適用します。'],
'계정 → 쿠폰함에서 보유 쿠폰을 확인하고 받을 수 있어요. 결제 시 자동으로 적용 가능한 쿠폰이 표시됩니다.': [
  'Xem và nhận mã giảm giá tại Tài khoản → Ví mã giảm giá. Khi thanh toán, các mã dùng được sẽ tự hiện ra.',
  'View and claim coupons under Account → Coupons. Applicable coupons appear automatically at payment.',
  '在 账户 → 优惠券 中查看并领取。付款时会自动显示可用的优惠券。',
  'アカウント → クーポンで確認・受け取りができます。支払い時に使えるクーポンが自動で表示されます。'],
'마음에 드는 마사지사는 카드 우측 상단 ♡를 눌러 찜해두세요. 계정 → 즐겨찾기에서 모아볼 수 있어요.': [
  'Nhấn ♡ ở góc trên bên phải thẻ để lưu chuyên viên bạn thích. Xem lại ở Tài khoản → Yêu thích.',
  'Tap the ♡ at the top right of a card to save a therapist. Find them under Account → Favorites.',
  '点击卡片右上角的 ♡ 收藏喜欢的理疗师。可在 账户 → 收藏 中查看。',
  'カード右上の ♡ で気に入ったセラピストを保存できます。アカウント → お気に入りでまとめて見られます。'],
'계정 → 마사지사·홈뷰티 파트너 되기에서 신청할 수 있어요. 프리랜서/마사지샵을 고르고 신분증·계좌·사진을 올리면 관리자 확인 후 승인됩니다.': [
  'Đăng ký tại Tài khoản → Trở thành đối tác. Chọn freelancer hoặc tiệm, tải lên giấy tờ tùy thân, tài khoản ngân hàng và ảnh; quản trị viên sẽ duyệt.',
  'Apply under Account → Become a partner. Choose freelancer or shop, upload your ID, bank account and photos, and an admin will review it.',
  '在 账户 → 成为合作伙伴 中申请。选择自由职业者或店铺，上传身份证件、银行账户与照片，管理员审核后通过。',
  'アカウント → パートナーになるから申請できます。フリーランスか店舗を選び、身分証・口座・写真をアップすると管理者の確認後に承認されます。'],
'홈 우상단 🌐 버튼에서 한국어·베트남어·영어·중국어·일본어로 바꿀 수 있어요.': [
  'Đổi ngôn ngữ bằng nút 🌐 ở góc trên bên phải trang chủ: Hàn, Việt, Anh, Trung, Nhật.',
  'Use the 🌐 button at the top right of Home to switch between Korean, Vietnamese, English, Chinese and Japanese.',
  '点击首页右上角的 🌐 按钮，可切换韩语、越南语、英语、中文、日语。',
  'ホーム右上の 🌐 ボタンから韓国語・ベトナム語・英語・中国語・日本語に切り替えられます。'],
'홈 상단의 ✨ AI 맞춤 추천을 확인해 보세요. 이용 이력·평점·지역을 분석해 어울리는 마사지사를 골라드려요. 조건을 말해주시면 바로 찾아드릴게요.': [
  'Hãy xem ✨ Gợi ý AI ở đầu trang chủ. Chúng tôi phân tích lịch sử, đánh giá và khu vực để chọn chuyên viên phù hợp. Bạn cứ nói điều kiện, mình tìm ngay.',
  'Check ✨ AI picks at the top of Home. We look at your history, ratings and area to suggest a good match. Just tell me your conditions and I will search.',
  '请看首页上方的 ✨ AI 推荐。我们会分析使用记录、评分与地区来挑选合适的理疗师。说出条件，我马上帮您找。',
  'ホーム上部の ✨ AIおすすめをご覧ください。利用履歴・評価・エリアから合うセラピストを選びます。条件を教えていただければすぐ探します。'],
'코스와 시간에 따라 달라집니다. 홈에서 서비스를 고르면 정확한 금액이 표시돼요.': [
  'Giá thay đổi theo gói và thời lượng. Chọn dịch vụ ở trang chủ sẽ thấy số tiền chính xác.',
  'It depends on the course and duration. Pick a service on Home to see the exact amount.',
  '价格因套餐与时长而异。在首页选择服务即可看到准确金额。',
  'コースと時間によって変わります。ホームでサービスを選ぶと正確な金額が表示されます。'],
# 숫자·주소가 섞이는 문장은 문장 전체를 넣고 {자리표시자}만 치환한다.
# 조각을 이어붙이면 언어마다 어순이 달라 문장이 깨진다 — 베트남어에서 실제로 깨졌다.
'가장 저렴한 코스가 {p}₫부터예요. 코스와 시간에 따라 달라집니다.': [
  'Gói rẻ nhất từ {p}₫. Giá thay đổi theo gói và thời lượng.',
  'The cheapest course starts at {p}₫. It varies by course and duration.',
  '最便宜的套餐自 {p}₫ 起。价格因套餐与时长而异。',
  '一番安いコースは {p}₫ からです。コースと時間によって変わります。'],
'예약 {h}시간 전까지는 자유롭게 취소할 수 있어요. 그 이후 취소와 노쇼는 최근 {w}일 기준 {a}회 누적 시 경고, {b}회 누적 시 {d}일간 예약이 제한됩니다.': [
  'Bạn có thể hủy thoải mái đến trước giờ hẹn {h} tiếng. Sau mốc đó, hủy muộn và không đến sẽ được tính trong {w} ngày gần nhất: {a} lần sẽ nhận cảnh báo, {b} lần sẽ bị hạn chế đặt lịch trong {d} ngày.',
  'You can cancel freely up to {h} hour(s) before the appointment. After that, late cancellations and no-shows are counted over the last {w} days: {a} of them triggers a warning, and {b} means booking is restricted for {d} days.',
  '预约开始前 {h} 小时之前可自由取消。此后的临时取消与爽约将计入最近 {w} 天：累计 {a} 次会收到警告，累计 {b} 次将限制预约 {d} 天。',
  '予約の {h} 時間前までは自由にキャンセルできます。それ以降のキャンセルとノーショーは直近 {w} 日間で数え、{a} 回で警告、{b} 回で {d} 日間予約が制限されます。'],
'앱 내 채팅으로 마사지사와 직접 대화할 수 있어요. 그 외 문의는 {m} 으로 메일 주시면 순서대로 답변드립니다.': [
  'Bạn có thể nhắn trực tiếp với chuyên viên qua chat trong ứng dụng. Các thắc mắc khác xin gửi email tới {m}, chúng tôi sẽ trả lời theo thứ tự nhận được.',
  'You can chat directly with the therapist in the app. For anything else, email {m} and we will reply in the order received.',
  '您可以在应用内与理疗师直接聊天。其他咨询请发送邮件至 {m}，我们会按顺序回复。',
  'アプリ内チャットでセラピストと直接やり取りできます。その他のお問い合わせは {m} までメールいただければ順にお返事します。'],
'문의': ['Liên hệ', 'Contact', '咨询', 'お問い合わせ'],
'웹사이트': ['Website', 'Website', '网站', 'ウェブサイト'],
})

# ── 로그인 오버레이 (2026-09-05) ──
# openAuth() 문구가 통째로 사전에 없었다. 예약하려는 비한국어 사용자가 처음 만나는 화면인데 한국어로 떴다
ADD.update({
'mㅏssㅏ 로그인': ['Đăng nhập mㅏssㅏ', 'Sign in to mㅏssㅏ', '登录 mㅏssㅏ', 'mㅏssㅏ にログイン'],
'예약하려면 로그인이 필요합니다': [
  'Bạn cần đăng nhập để đặt lịch', 'You need to sign in to make a booking',
  '预约需要先登录', '予約にはログインが必要です'],
'이메일': ['Email', 'Email', '邮箱', 'メール'],
'비밀번호 (6자 이상)': ['Mật khẩu (từ 6 ký tự)', 'Password (6+ characters)', '密码（6位以上）', 'パスワード（6文字以上）'],
'회원가입 / 로그인': ['Đăng ký / Đăng nhập', 'Sign up / Sign in', '注册 / 登录', '新規登録 / ログイン'],
'비밀번호를 잊으셨나요?': ['Quên mật khẩu?', 'Forgot your password?', '忘记密码？', 'パスワードをお忘れですか？'],
'또는': ['hoặc', 'or', '或', 'または'],
'Google로 계속하기': ['Tiếp tục với Google', 'Continue with Google', '使用 Google 继续', 'Google で続ける'],
'카카오로 계속하기': ['Tiếp tục với Kakao', 'Continue with Kakao', '使用 Kakao 继续', 'カカオで続ける'],
'Apple로 계속하기': ['Tiếp tục với Apple', 'Continue with Apple', '使用 Apple 继续', 'Apple で続ける'],
'닫기': ['Đóng', 'Close', '关闭', '閉じる'],
# 로그인창 안내·오류 문구
'이메일을 먼저 입력해 주세요.': [
  'Vui lòng nhập email trước.', 'Please enter your email first.', '请先输入邮箱。', '先にメールアドレスを入力してください。'],
'재설정 메일을 보내는 중…': [
  'Đang gửi email đặt lại…', 'Sending the reset email…', '正在发送重置邮件…', '再設定メールを送信中…'],
'재설정 메일을 보냈습니다. 메일함을 확인해 주세요.': [
  'Đã gửi email đặt lại. Hãy kiểm tra hộp thư của bạn.', 'Reset email sent. Please check your inbox.',
  '重置邮件已发送，请查收邮箱。', '再設定メールを送信しました。メールボックスをご確認ください。'],
'처리 중…': ['Đang xử lý…', 'Processing…', '处理中…', '処理中…'],
'로그인 완료!': ['Đăng nhập thành công!', 'Signed in!', '登录成功！', 'ログインしました！'],
'서버 응답이 없습니다. 네트워크 상태를 확인해 주세요.': [
  'Máy chủ không phản hồi. Vui lòng kiểm tra kết nối mạng.', 'The server is not responding. Please check your connection.',
  '服务器无响应，请检查网络连接。', 'サーバーから応答がありません。ネットワーク状態をご確認ください。'],
})

# 화면 제목
TITLES = {
'계정 정보': ['Thông tin tài khoản', 'Account', '账户信息', 'アカウント情報'],
'제공자 등록 신청': ['Đăng ký làm nhà cung cấp', 'Provider application', '服务者注册申请', '提供者登録申請'],
'지도 검색': ['Tìm trên bản đồ', 'Map search', '地图搜索', '地図検索'],
'지역 선택': ['Chọn khu vực', 'Select area', '选择地区', 'エリア選択'],
'채팅': ['Trò chuyện', 'Chat', '聊天', 'チャット'],
}

def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')

def entry(k, v):
    return "  '%s': ['%s', '%s', '%s', '%s']," % (esc(k), esc(v[0]), esc(v[1]), esc(v[2]), esc(v[3]))

def merge(html, obj_name, data):
    start = html.index('const %s = {' % obj_name)
    end = html.index('\n};', start)
    blk = html[start:end]
    kept = []
    for line in blk.split('\n')[1:]:
        m = re.match(r"\s*'((?:[^'\\]|\\.)*)'\s*:", line)
        if m and m.group(1).replace("\\'", "'").replace('\\\\', '\\') in data:
            continue          # 새 값으로 대체되므로 옛 줄은 버린다
        kept.append(line)
    new = 'const %s = {\n' % obj_name + '\n'.join(kept).rstrip()
    if not new.rstrip().endswith(','): new = new.rstrip() + ','
    new += '\n' + '\n'.join(entry(k, v) for k, v in data.items())
    return html[:start] + new + html[end:]

p = 'index.html'
h = open(p, encoding='utf-8').read()
h = merge(h, 'DICT', ADD)
h = merge(h, 'TITLE_I18N', TITLES)
open(p, 'w', encoding='utf-8').write(h)
print('DICT +%d, TITLE_I18N +%d 반영' % (len(ADD), len(TITLES)))
