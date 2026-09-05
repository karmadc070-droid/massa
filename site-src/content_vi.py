# massaviet.com — nội dung tiếng Việt. Dịch từ content_ko.py, giữ hai bản đồng bộ.
# 주의: 이 번역은 원어민 검수를 받지 않았다. 하노이 현지 사용자와 파트너 모집에 쓰이는 언어이므로
# 실제 운영 전에 한 번 훑어보게 하는 편이 좋다.

SUPPORT = "support@massaviet.com"

LABELS = {
    "nav": {"index": "Trang chủ", "services": "Dịch vụ", "guide": "Hướng dẫn",
            "safety": "An toàn", "partner": "Đối tác", "faq": "Câu hỏi thường gặp",
            "about": "Giới thiệu", "download": "Tải ứng dụng", "contact": "Liên hệ",
            "terms": "Điều khoản", "privacy": "Quyền riêng tư"},
    "langname": {"ko": "KO", "en": "EN", "vi": "VI"},
    "cta": "Tải ứng dụng",
    "footer_tag": "Massage và làm đẹp tại nhà, đặt lịch tận nơi ở Hà Nội.",
    "f_service": "Dịch vụ", "f_company": "massa", "f_support": "Hỗ trợ",
    "legal": ("© 2026 massa. Nền tảng đặt lịch massage và làm đẹp tại nhà ở Hà Nội.<br>"
              "massa là nền tảng kết nối khách hàng với nhà cung cấp đã được xác minh; dịch vụ cung cấp không phải là điều trị y tế."),
    "smart": "Đặt lịch nhanh hơn trên ứng dụng",
    "smart_cta": "Tải ngay",
}

_LD_HOME = """{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "massa",
  "description": "Nền tảng đặt lịch massage và làm đẹp tại nhà ở Hà Nội",
  "url": "https://massaviet.com/vi/",
  "image": "https://massaviet.com/img/hero.webp",
  "email": "support@massaviet.com",
  "areaServed": { "@type": "City", "name": "Hanoi" },
  "availableLanguage": ["ko", "vi", "en", "zh", "ja"],
  "sameAs": ["https://apps.apple.com/kr/app/id6804698319"]
}"""

_STORES = {"type": "stores", "ios": "iPhone · iPad", "and": "Android", "soon": "Sắp ra mắt"}

PAGES = {

"index": {
 "title": "massa — Massage & làm đẹp tại nhà ở Hà Nội",
 "desc": "Chuyên viên đã được xác minh đến tận nhà hoặc khách sạn của bạn tại Hà Nội. Chọn giờ bạn muốn, thanh toán tại chỗ sau khi xong.",
 "jsonld": _LD_HOME,
 "blocks": [
  {"type": "hero",
   "kicker": "Hà Nội · Đến tận nơi",
   "h1": "Giờ mà bạn<br>không phải<br><em>ra khỏi nhà.</em>",
   "lead": "Đêm muộn sau giờ làm, hay trong phòng khách sạn giữa chuyến công tác. Chuyên viên đã qua xác minh đến đúng giờ bạn chọn. Bạn thanh toán tại chỗ, sau khi dịch vụ kết thúc.",
   "alt": "Chuyên viên đang massage trong căn phòng thắp nến",
   "cap": "Từ đặt lịch đến thanh toán, tất cả trong ứng dụng. Giá hiển thị đã gồm thuế và tiền tip.",
   "btns": [("Tải ứng dụng", "/vi/download.html"), ("Xem cách dùng", "/vi/guide.html")]},

  {"type": "section", "soft": True,
   "kicker": "Vì sao gọi tận nơi",
   "h2": "Thời gian di chuyển<br>mới là thứ tốn kém",
   "lead": "Dành cho những người khó sắp xếp buổi tối theo giờ mở cửa của tiệm.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Không phụ thuộc giờ mở cửa",
       "d": "Ngay cả khuya, khi quanh đây không còn chỗ nào mở, bạn vẫn chọn được giờ trong khung thời gian chuyên viên nhận lịch."},
      {"n": "02", "t": "Ngay tại phòng khách sạn",
       "d": "Khi đặt lịch, bạn điền tên khách sạn, số phòng và cách qua quầy lễ tân. Khách sạn nào cần đăng ký khách ngoài, chúng tôi báo trước."},
      {"n": "03", "t": "Người nói được tiếng bạn cần",
       "d": "Hồ sơ ghi rõ chuyên viên nói được ngôn ngữ nào. Tin nhắn trong ứng dụng được dịch tự động."},
    ]}]},

  {"type": "section",
   "kicker": "Bạn nhận được gì",
   "h2": "Ba cách<br>để được chăm sóc",
   "blocks": [
    {"type": "pcards", "items": [
      {"img": "hero", "t": "Massage tại nhà", "href": "/vi/services.html",
       "alt": "Chuyên viên massage lưng",
       "d": "Aromatherapy, Thụy Điển, Thái, mô sâu. Chọn 60, 90 hoặc 120 phút."},
      {"img": "beauty", "t": "Làm đẹp tại nhà", "href": "/vi/services.html",
       "alt": "Dịch vụ làm đẹp tại nhà",
       "d": "Làm móng, wax và tẩy da chết, ngay tại nhà hoặc khách sạn của bạn."},
      {"img": "spa", "t": "Danh bạ spa", "href": "/vi/services.html",
       "alt": "Cửa spa với ánh đèn ấm",
       "d": "Lấy ráy tai, chăm sóc da đầu, da, móng và mi tại các spa đối tác, xem theo quận."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Đặt lịch",
   "h2": "Bốn bước là xong",
   "lead": "Không thủ tục rườm rà. Người dùng lần đầu thường mất vài phút.",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Chọn", "d": "So sánh chuyên viên theo dấu xác minh, đánh giá, ngôn ngữ và khoảng cách."},
      {"t": "Đặt", "d": "Chọn gói 60, 90 hoặc 120 phút và giờ bạn muốn."},
      {"t": "Ghi địa chỉ", "d": "Địa chỉ nhà, hoặc tên khách sạn, số phòng và cách qua lễ tân."},
      {"t": "Xác nhận", "d": "Bạn trả tiền tại chỗ sau khi xong. Không trả trước."},
    ]},
    {"type": "note", "text": "Bạn có thể hủy thoải mái đến trước giờ hẹn 1 tiếng. Quy định hủy đầy đủ nằm ở trang Hướng dẫn."}]},

  {"type": "section",
   "kicker": "An toàn",
   "h2": "Để bạn yên tâm<br>mở cửa",
   "lead": "Bạn đang cho một người lạ vào nhà. Giảm bớt gánh nặng đó là phần chúng tôi dồn công sức nhiều nhất.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Xác minh ba bước",
       "d": "Chỉ chuyên viên vượt qua kiểm tra chứng chỉ, kiểm tra nhân thân và phỏng vấn trực tiếp mới nhận dấu xác minh."},
      {"n": "02", "t": "Chứng nhận bộ vệ sinh",
       "d": "Đối tác được xác nhận dùng vật tư một lần sẽ có dấu riêng trên hồ sơ."},
      {"n": "03", "t": "Nút an toàn",
       "d": "Nếu có sự cố giữa buổi, một chạm là vị trí của bạn được gửi ngay cho đội ngũ của chúng tôi."},
    ]},
    {"type": "pull", "text": "Yêu cầu không phù hợp bị cấm với cả hai bên,<br>vi phạm được xác nhận sẽ bị khóa ngay."}]},

  {"type": "section", "soft": True,
   "kicker": "Khu vực",
   "h2": "Bắt đầu từ Hà Nội",
   "blocks": [
    {"type": "table", "rows": [
      ("Đang hoạt động", "Khắp Hà Nội — Ba Đình, Hoàn Kiếm, Mỹ Đình, Tây Hồ và hơn thế"),
      ("Sắp tới", "Đà Nẵng, Nha Trang, Thành phố Hồ Chí Minh"),
      ("Ngôn ngữ", "Tiếng Hàn, tiếng Việt, tiếng Anh, tiếng Nhật, tiếng Trung"),
    ]}]},

  {"type": "section",
   "kicker": "Ứng dụng",
   "h2": "Đặt lịch ngay trên ứng dụng",
   "lead": "Cài đặt và đăng ký miễn phí. Bạn chỉ trả tiền dịch vụ, tại chỗ.",
   "blocks": [dict(_STORES)]},
 ]},

"services": {
 "title": "Dịch vụ — massage & làm đẹp tại nhà ở Hà Nội | massa",
 "desc": "Massage tại nhà (aromatherapy, Thụy Điển, Thái, mô sâu), làm đẹp tại nhà (móng, wax, tẩy da chết) và danh bạ spa đối tác khắp Hà Nội.",
 "blocks": [
  {"type": "section",
   "kicker": "Dịch vụ",
   "h2": "Bạn có thể<br>đặt những gì",
   "lead": "Hai dịch vụ đến tận nơi, và một danh bạ cho khi bạn muốn ra ngoài. Tất cả đặt qua ứng dụng.",
   "blocks": [
    {"type": "pcards", "items": [
      {"img": "hero", "t": "Massage tại nhà", "alt": "Massage tại nhà",
       "d": "Chuyên viên đến nhà hoặc khách sạn và mang theo đầy đủ — nệm, tinh dầu, khăn."},
      {"img": "beauty", "t": "Làm đẹp tại nhà", "alt": "Làm đẹp tại nhà",
       "d": "Làm móng, wax và tẩy da chết mà không cần ra khỏi phòng. Vật tư dùng một lần."},
      {"img": "spa", "t": "Danh bạ spa", "alt": "Spa đối tác",
       "d": "Khi bạn muốn đến tận nơi, xem các spa đối tác theo quận và theo loại dịch vụ."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Massage",
   "h2": "Các gói",
   "lead": "Chọn 60, 90 hoặc 120 phút. Cùng một gói, giá có thể khác nhau tùy chuyên viên.",
   "blocks": [
    {"type": "table", "rows": [
      ("Aromatherapy", "Ấn chậm với tinh dầu ấm. Lựa chọn an toàn khi bạn ngủ không ngon hoặc người bị mỏi chung."),
      ("Thụy Điển", "Các đường xoa dài trên toàn thân. Chúng tôi hay gợi ý cho lần đặt đầu tiên."),
      ("Thái", "Có giãn cơ, không dùng dầu. Hợp khi cơ thể bị căng cứng đã lâu."),
      ("Mô sâu", "Ấn sâu vào lớp cơ bên dưới. Lực khá mạnh, nên hãy nói trước mức bạn muốn."),
    ]},
    {"type": "note", "text": "Số tiền chính xác hiện ra khi bạn chọn chuyên viên và gói trong ứng dụng. Thuế và tiền tip đã bao gồm, nên không phát sinh thêm vào hôm đó."}]},

  {"type": "section",
   "kicker": "Làm đẹp",
   "h2": "Chăm sóc tại nhà",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Làm móng", "d": "Chăm sóc tay chân và sơn màu. Dụng cụ được tiệt trùng trước khi mang đến."},
      {"n": "02", "t": "Wax", "d": "Chọn vùng bạn muốn. Sáp và giấy wax chỉ dùng một lần."},
      {"n": "03", "t": "Tẩy da chết & da", "d": "Tẩy da chết chân và chăm sóc da cơ bản. Nếu da bạn nhạy cảm, hãy ghi vào ghi chú khi đặt."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Cửa hàng",
   "h2": "Danh bạ spa",
   "lead": "Những hạng mục chúng tôi không làm tại nhà đều có ở các spa đối tác.",
   "blocks": [
    {"type": "table", "rows": [
      ("Chăm sóc thư giãn", "Lấy ráy tai cao cấp, chăm sóc da đầu"),
      ("Làm đẹp", "Chăm sóc da, móng, mi"),
      ("Triệt lông", "Wax toàn thân, theo từng vùng"),
    ]},
    {"type": "note", "text": "Dịch vụ massa cung cấp nhằm mục đích thư giãn và chăm sóc, không phải điều trị y tế. Với triệu chứng cần điều trị, xin hãy đến cơ sở y tế."}]},
 ]},

"guide": {
 "title": "Hướng dẫn — đặt lịch, thanh toán, hủy | massa",
 "desc": "Cách đặt lịch trên massa, cách thanh toán tại chỗ, quy định hủy và không đến, cùng những điều cần biết khi đặt về khách sạn.",
 "blocks": [
  {"type": "section",
   "kicker": "Hướng dẫn",
   "h2": "Từ đặt lịch<br>đến thanh toán",
   "lead": "Viết để người dùng lần đầu biết mỗi bước cần nhập gì và hiển thị ra sao.",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Dịch vụ và chuyên viên", "d": "So sánh theo dấu xác minh, đánh giá, nhận xét, ngôn ngữ và khoảng cách."},
      {"t": "Gói và giờ", "d": "Chọn 60, 90 hoặc 120 phút, rồi chọn ngày và giờ."},
      {"t": "Nơi đến", "d": "Địa chỉ nhà, hoặc tên khách sạn, số phòng và cách qua lễ tân."},
      {"t": "Xác nhận", "d": "Kiểm tra số tiền và giờ trên màn hình tóm tắt rồi xác nhận."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Thanh toán",
   "h2": "Nhận dịch vụ trước,<br>trả tiền sau",
   "body": [
    "massa thu tiền sau. Bạn thanh toán tại chỗ khi dịch vụ kết thúc. Không cần đăng ký thẻ và không phải trả gì lúc đặt lịch.",
    "Bạn có thể trả bằng thẻ tại chỗ, quét QR (MoMo, ZaloPay, VNPay) hoặc tiền mặt. Mã giảm giá được áp dụng ở màn hình thanh toán."],
   "blocks": [
    {"type": "table", "rows": [
      ("Giá hiển thị", "Đã gồm thuế và tiền tip. Không phát sinh thêm vào hôm đó."),
      ("Phụ phí", "Chỉ khi bạn kéo dài quá gói đã đặt, và chỉ tính phần kéo dài."),
      ("Hóa đơn", "Xem trong ứng dụng, ở phần lịch sử đặt lịch."),
    ]}]},

  {"type": "section",
   "kicker": "Hủy lịch",
   "h2": "Hủy và không đến",
   "body": [
    "Bạn có thể <b>hủy thoải mái đến trước giờ hẹn 1 tiếng</b>, không bị gì cả.",
    "Sau mốc đó, việc hủy muộn và không đến sẽ được tính. Trong 30 ngày gần nhất, <b>3 lần sẽ nhận cảnh báo</b> và <b>5 lần sẽ bị hạn chế đặt lịch trong 7 ngày</b>.",
    "Quy định này có vì chuyên viên có thể đã lên đường đến chỗ bạn. Nếu có việc, hãy hủy sớm nhất có thể. Lịch bị hủy do phía nhà cung cấp thì không tính cho bạn."]},

  {"type": "section", "soft": True,
   "kicker": "Khách sạn",
   "h2": "Khi đặt về khách sạn",
   "lead": "Nếu bạn đang đi công tác hay du lịch, có thể nhận dịch vụ ngay tại phòng. Tuy nhiên mỗi khách sạn có quy định khách ngoài khác nhau.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Cần điền gì", "d": "Tên khách sạn, số phòng và cách qua quầy lễ tân. Nếu cần đăng ký khách ngoài, chúng tôi báo trước."},
      {"n": "02", "t": "Khi đến nơi", "d": "Chuyên viên gọi từ sảnh. Báo trước cho lễ tân sẽ thuận tiện hơn."},
      {"n": "03", "t": "Không gian", "d": "Đủ chỗ trải nệm cạnh giường là được. Bạn không cần chuẩn bị gì thêm."},
    ]}]},
 ]},

"safety": {
 "title": "An toàn & xác minh — dấu xác minh và các biện pháp | massa",
 "desc": "Cách massa xác minh chuyên viên qua ba bước, ý nghĩa dấu vệ sinh, nút an toàn và quy trình báo cáo — và cả những gì chúng tôi không thể bảo đảm.",
 "blocks": [
  {"type": "section",
   "kicker": "An toàn & xác minh",
   "h2": "Bạn đang cho một<br>người lạ vào nhà",
   "lead": "Đó là phần khó nhất của dịch vụ này, và cũng là phần chúng tôi làm kỹ nhất.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Chứng chỉ", "d": "Chúng tôi kiểm tra chứng chỉ massage, làm đẹp và kinh nghiệm làm việc. Giấy tờ không thôi là chưa đủ."},
      {"n": "02", "t": "Nhân thân", "d": "Giấy tờ tùy thân xác nhận tên thật và tuổi. Hồ sơ nằm trong kho riêng, chỉ người thẩm định mở được."},
      {"n": "03", "t": "Phỏng vấn trực tiếp", "d": "Chúng tôi gặp trực tiếp để xem thái độ và cách giao tiếp. Phải qua cả ba thì dấu xác minh mới xuất hiện."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Vệ sinh",
   "h2": "Mặc định là dùng một lần",
   "body": [
    "Với những thứ chạm trực tiếp vào da — wax, làm móng — vệ sinh là tất cả. Sáp, giấy wax và giũa chỉ dùng một lần, không tái sử dụng.",
    "Đối tác đã được xác nhận điều này sẽ có dấu vệ sinh trên hồ sơ. Không có dấu không có nghĩa là vệ sinh kém, nhưng giúp bạn chọn được nơi chúng tôi đã kiểm tra."]},

  {"type": "section",
   "kicker": "Trong lúc làm",
   "h2": "Nếu có chuyện xảy ra",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Nút an toàn", "d": "Nút SOS trong ứng dụng gửi vị trí hiện tại của bạn đến đội ngũ chúng tôi ngay lập tức."},
      {"n": "02", "t": "Chia sẻ vị trí", "d": "Bạn có thể chia sẻ vị trí với người thân trong suốt thời gian làm dịch vụ."},
      {"n": "03", "t": "Báo cáo & chặn", "d": "Báo cáo được xem xét, xử lý và phản hồi. Chặn rồi thì người đó không được ghép với bạn nữa."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Nghiêm cấm",
   "h2": "Cùng một chuẩn<br>cho cả hai bên",
   "body": [
    "Yêu cầu không phù hợp, kể cả yêu cầu tình dục, bị cấm với <b>cả</b> khách hàng lẫn nhà cung cấp. Vi phạm được xác nhận sẽ bị khóa ngay và có thể bị báo cơ quan chức năng tùy mức độ.",
    "Giao dịch tiền mặt ngoài ứng dụng và việc xin số liên lạc cá nhân cũng bị cấm. Hãy từ chối và báo cáo. Giao dịch không qua ứng dụng thì không có dữ liệu, nên chúng tôi không thể giúp khi có chuyện."]},

  {"type": "section",
   "kicker": "Giới hạn",
   "h2": "Những gì chúng tôi không bảo đảm được",
   "body": [
    "Nói thẳng: massa là nền tảng trung gian, và chúng tôi không thể kiểm soát hoàn toàn hành vi con người.",
    "Xác minh làm giảm rủi ro, nhưng không đưa về 0. Dịch vụ cung cấp nhằm mục đích thư giãn và chăm sóc, <b>không phải điều trị y tế</b> — với triệu chứng cần điều trị, xin hãy đến cơ sở y tế.",
    "Nhưng khi có chuyện, việc kiểm tra dữ liệu, xác minh sự thật và xử lý đến nơi thì chúng tôi sẽ làm nghiêm túc."]},
 ]},

"partner": {
 "title": "Tuyển đối tác — chuyên viên massage & làm đẹp | massa",
 "desc": "massa đang tuyển đối tác massage và làm đẹp tại nhà ở Hà Nội. Không phí gia nhập, không phí hàng tháng, chỉ tính hoa hồng trên lịch đã hoàn thành.",
 "blocks": [
  {"type": "section",
   "kicker": "Đối tác",
   "h2": "Bạn tự quyết<br>giờ làm việc",
   "lead": "Làm việc mà không bị buộc vào một cửa hàng. Bạn chọn khung giờ và khu vực mình nhận lịch.",
   "blocks": [
    {"type": "table", "rows": [
      ("Phí gia nhập", "Không có."),
      ("Phí hàng tháng", "Không có."),
      ("Hoa hồng", "Chỉ tính trên những lịch được nhận và hoàn thành."),
      ("Hạn nộp", "Trong thời hạn quy định tính từ ngày làm dịch vụ. Nộp trễ sẽ có nhắc nhở."),
      ("Giờ làm", "Bạn tự bật tắt trạng thái nhận lịch. Ngoài khung đó sẽ không có yêu cầu nào đến."),
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Đăng ký",
   "h2": "Các bước",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Đăng ký trong ứng dụng", "d": "Tài khoản → Trở thành đối tác, chọn cá nhân hoặc cửa hàng."},
      {"t": "Nộp hồ sơ", "d": "Giấy tờ tùy thân, tài khoản nhận tiền, chứng chỉ và ảnh hồ sơ."},
      {"t": "Thẩm định", "d": "Xét hồ sơ rồi phỏng vấn trực tiếp."},
      {"t": "Bắt đầu", "d": "Được duyệt là có dấu xác minh và bắt đầu nhận yêu cầu đặt lịch."},
    ]}]},

  {"type": "section",
   "kicker": "Điều chúng tôi mong",
   "h2": "Cam kết",
   "body": [
    "Lịch đã nhận thì phải làm đến nơi. Từ chối nhiều lần sẽ giảm mức hiển thị, và tích lũy đủ sẽ tạm dừng khả năng nhận lịch một thời gian.",
    "Bộ vệ sinh dùng một lần là tiêu chuẩn. Đưa ra yêu cầu không phù hợp với khách, hoặc dẫn khách ra ngoài ứng dụng, sẽ bị khóa ngay.",
    "Ngược lại cũng vậy: nếu khách đưa ra yêu cầu không phù hợp, hãy từ chối và báo cáo. Chuẩn mực áp dụng cho cả hai bên."]},
 ]},

"faq": {
 "title": "Câu hỏi thường gặp — massa",
 "desc": "Giải đáp về đặt lịch, thanh toán, hủy lịch, an toàn và cách đăng ký làm đối tác.",
 "blocks": [
  {"type": "section",
   "kicker": "Câu hỏi thường gặp",
   "h2": "Những câu hay được hỏi",
   "blocks": [
    {"type": "faq", "items": [
      ("Khi nào tôi trả tiền?",
       "Tại chỗ, sau khi dịch vụ kết thúc. Lúc đặt lịch không phải trả gì. Bạn trả bằng thẻ, quét QR (MoMo, ZaloPay, VNPay) hoặc tiền mặt."),
      ("Tôi muốn đổi giờ",
       "Hủy trong phần lịch sử đặt lịch rồi đặt lại. Trước giờ hẹn 1 tiếng thì không bị gì."),
      ("Hủy lịch có bị phạt không?",
       "Trước 1 tiếng thì hủy miễn phí. Sau đó, hủy muộn và không đến sẽ được tính: trong 30 ngày gần nhất, 3 lần nhận cảnh báo, 5 lần bị hạn chế đặt lịch 7 ngày. Lịch do nhà cung cấp hủy thì không tính."),
      ("Tôi đặt ngay bây giờ được không?",
       "Nếu đang có chuyên viên hoạt động thì được. Ứng dụng hiển thị ai đang rảnh và cách bạn bao xa."),
      ("Mã giảm giá dùng thế nào?",
       "Nhận ở Tài khoản → Mã giảm giá. Mã dùng được sẽ tự hiện ở màn hình thanh toán."),
      ("Ở nhà cần chuẩn bị gì?",
       "Đủ chỗ trải nệm là được. Tinh dầu và dụng cụ chuyên viên mang theo. Tắm trước sẽ dễ chịu hơn."),
      ("Tôi không biết chọn loại massage nào",
       "Lần đầu thì Thụy Điển là an toàn. Cơ căng nhiều thì mô sâu; ngủ không ngon thì aromatherapy."),
      ("Nếu lực quá mạnh hoặc quá nhẹ thì sao?",
       "Cứ nói ngay trong lúc làm, đừng cố chịu. Nói trước mức lực bạn muốn từ đầu thì càng tốt."),
      ("Có nói được tiếng Hàn hay tiếng Anh không?",
       "Hồ sơ mỗi chuyên viên ghi rõ ngôn ngữ nói được để bạn chọn. Tin nhắn trong ứng dụng được dịch tự động."),
      ("Đặt về khách sạn được không?",
       "Được. Khi đặt, bạn điền tên khách sạn, số phòng và cách qua lễ tân. Khách sạn nào cần đăng ký khách ngoài, chúng tôi báo ngay ở bước tìm kiếm."),
      ("Tôi đang mang thai, có làm được không?",
       "Xin hãy báo khi đặt lịch và hỏi ý kiến bác sĩ trước. Dịch vụ của massa không phải điều trị y tế và không phù hợp với mọi tình trạng."),
      ("Làm sao biết ai sẽ đến?",
       "Dấu xác minh chỉ xuất hiện sau khi qua kiểm tra chứng chỉ, kiểm tra nhân thân và phỏng vấn trực tiếp. Hồ sơ cũng có điểm đánh giá và nhận xét của người đã thực sự đặt."),
      ("Nếu có chuyện xảy ra giữa buổi?",
       "Nút an toàn (SOS) trong ứng dụng gửi vị trí của bạn đến đội ngũ chúng tôi ngay. Bạn cũng có thể báo cáo và chặn ngay trong ứng dụng."),
      ("Có người rủ trả tiền mặt ngoài ứng dụng",
       "Hãy từ chối và báo cáo. Giao dịch ngoài ứng dụng bị cấm với cả hai bên, và không có dữ liệu thì chúng tôi không giúp được khi có chuyện."),
      ("Ai nhìn thấy địa chỉ của tôi?",
       "Chỉ chuyên viên được phân cho lịch đã xác nhận. Họ nhận tên, số điện thoại, địa chỉ đến và ghi chú yêu cầu — không gì khác."),
      ("Làm đối tác thì đăng ký thế nào?",
       "Đăng ký trong ứng dụng ở Tài khoản → Trở thành đối tác. Tải lên giấy tờ tùy thân, tài khoản nhận tiền, chứng chỉ và ảnh hồ sơ rồi qua bước thẩm định."),
      ("Có phí gia nhập không?",
       "Không, phí hàng tháng cũng không. Hoa hồng chỉ tính trên lịch được nhận và hoàn thành."),
      ("Tôi tự đặt giờ làm được không?",
       "Được. Bạn bật tắt trạng thái nhận lịch trong ứng dụng và chọn khu vực mình phụ trách."),
    ]}]},
  {"type": "section", "soft": True,
   "h2": "Nếu không có câu bạn cần",
   "lead": f"Gửi email tới {SUPPORT}, chúng tôi trả lời theo thứ tự nhận được.",
   "blocks": [{"type": "note", "text": "Với việc gấp trong lúc đang làm dịch vụ, hãy dùng nút an toàn và chức năng báo cáo trong ứng dụng trước. Nhanh hơn email rất nhiều."}]},
 ]},

"about": {
 "title": "Giới thiệu — massa",
 "desc": "massa kết nối khách hàng ở Hà Nội với các nhà cung cấp massage và làm đẹp đã được xác minh. Chúng tôi là nền tảng, không phải người trực tiếp làm dịch vụ.",
 "blocks": [
  {"type": "section",
   "kicker": "Giới thiệu",
   "h2": "massa là<br>nền tảng trung gian",
   "lead": "Chúng tôi không tự làm dịch vụ. Chúng tôi kết nối khách hàng với nhà cung cấp đã thẩm định, và giữ cho mọi việc giữa hai bên có trách nhiệm.",
   "body": [
     "Hà Nội có nhiều chuyên viên giỏi, nhưng từ phía khách rất khó biết ai đáng tin. Ở chiều ngược lại, người có tay nghề lại bị buộc vào giờ của cửa hàng hoặc ít kênh tiếp cận khách. massa nằm ở khoảng giữa đó.",
     "Vì vậy chúng tôi dồn sức nhiều nhất vào thẩm định và lưu vết. Biết ai sẽ đến, có dữ liệu khi xảy ra chuyện, và cùng một luật cho cả hai bên — chúng tôi cho rằng đó là điều kiện tối thiểu để dịch vụ tại nhà có thể tồn tại."]},
  {"type": "section", "soft": True,
   "h2": "Nguyên tắc",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Không thu tiền trước", "d": "Bạn trả sau khi đã nhận dịch vụ. Chúng tôi không gom tiền rồi mới bắt đầu."},
      {"n": "02", "t": "Không giấu giá", "d": "Thuế và tiền tip nằm trong con số bạn thấy. Không phát sinh vào hôm đó."},
      {"n": "03", "t": "Một luật cho hai bên", "d": "Yêu cầu không phù hợp và giao dịch ngoài ứng dụng đều bị cấm với khách lẫn nhà cung cấp."},
    ]}]},
  {"type": "section",
   "h2": "Liên hệ",
   "blocks": [
    {"type": "table", "rows": [
      ("Email", f'<a href="mailto:{SUPPORT}">{SUPPORT}</a>'),
      ("Khu vực", "Hà Nội, Việt Nam (Đà Nẵng, Nha Trang và TP. Hồ Chí Minh sắp tới)"),
      ("Ứng dụng", '<a href="/vi/download.html">Tải trên App Store</a>'),
    ]}]},
 ]},

"download": {
 "title": "Tải ứng dụng — massa",
 "desc": "Tải ứng dụng massa trên App Store và đặt lịch massage, làm đẹp tại nhà ở Hà Nội ngay trên điện thoại.",
 "blocks": [
  {"type": "section",
   "kicker": "Tải ứng dụng",
   "h2": "Tải massa",
   "lead": "Đặt lịch, xem hồ sơ chuyên viên, nhắn tin và đánh giá đều nằm trong ứng dụng. Cài đặt và đăng ký miễn phí.",
   "blocks": [dict(_STORES)]},
  {"type": "section", "soft": True,
   "h2": "Bản Android<br>vẫn đang chuẩn bị",
   "lead": "Hiện đang ở giai đoạn thử nghiệm kín nên chưa tìm được trên Google Play.",
   "body": [
     f'Bản Android đã chạy được và đang trong quá trình thử nghiệm. Chúng tôi sẽ phát hành ngay khi hoàn tất thời gian thử nghiệm mà Google Play yêu cầu, và nút cài đặt sẽ xuất hiện trên trang này. Từ giờ đến lúc đó, nếu bạn dùng Android, hãy gửi email tới <a href="mailto:{SUPPORT}">{SUPPORT}</a> để nhận hướng dẫn tham gia thử nghiệm.']},
  {"type": "section",
   "h2": "Sau khi cài đặt",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Chọn", "d": "So sánh chuyên viên theo dấu xác minh, đánh giá, ngôn ngữ và khoảng cách."},
      {"t": "Đặt", "d": "Chọn gói 60, 90 hoặc 120 phút và giờ bạn muốn."},
      {"t": "Ghi địa chỉ", "d": "Địa chỉ nhà, hoặc tên khách sạn và số phòng."},
      {"t": "Xác nhận", "d": "Bạn trả tiền tại chỗ sau khi dịch vụ kết thúc."},
    ]},
    {"type": "table", "rows": [
      ("Chi phí", "Ứng dụng và đăng ký miễn phí. Bạn chỉ trả tiền dịch vụ, tại chỗ."),
      ("Ngôn ngữ", "Tiếng Hàn, tiếng Việt, tiếng Anh, tiếng Nhật, tiếng Trung"),
      ("Khu vực", "Hà Nội — Ba Đình, Hoàn Kiếm, Mỹ Đình, Tây Hồ và hơn thế"),
      ("Dành cho đối tác", 'Chuyên viên cũng đăng ký trong cùng ứng dụng. <a href="/vi/partner.html">Xem thông tin đối tác</a>'),
    ]}]},
 ]},

"contact": {
 "title": "Liên hệ — massa",
 "desc": "Cần hỗ trợ, muốn hợp tác hoặc báo lỗi, hãy gửi email tới support@massaviet.com.",
 "blocks": [
  {"type": "section",
   "kicker": "Liên hệ",
   "h2": "Gửi cho chúng tôi<br>bất cứ điều gì",
   "lead": "Chúng tôi đọc và trả lời theo thứ tự nhận được.",
   "blocks": [
    {"type": "table", "rows": [
      ("Email", f'<a href="mailto:{SUPPORT}">{SUPPORT}</a>'),
      ("Dùng dịch vụ", "Vấn đề về đặt lịch, thanh toán, hủy lịch và tài khoản"),
      ("Đối tác", 'Đăng ký chuyên viên và cửa hàng. Vui lòng đọc <a href="/vi/partner.html">trang đối tác</a> trước.'),
      ("Hợp tác", "Spa, khách sạn và các đề xuất khác"),
      ("Báo lỗi", "Hãy cho biết thiết bị bạn dùng và bạn đang làm gì khi lỗi xảy ra."),
    ]},
    {"type": "note", "text": "Với việc gấp trong lúc đang làm dịch vụ, nút an toàn (SOS) và chức năng báo cáo trong ứng dụng nhanh hơn email rất nhiều. Chúng gửi kèm vị trí của bạn đến đội ngũ chúng tôi."}]},
 ]},

"terms": {
 "title": "Điều khoản sử dụng — massa",
 "desc": "Điều khoản sử dụng massa: đặt lịch và trả sau, quy định hủy và không đến, nghĩa vụ của nhà cung cấp, hành vi bị cấm và giới hạn trách nhiệm.",
 "blocks": [
  {"type": "section",
   "kicker": "Hiệu lực 14/08/2026 · phiên bản 2026-07-1",
   "h2": "Điều khoản sử dụng",
   "body": ["Đây là bản dịch để tham khảo. Bản tiếng Hàn là bản có hiệu lực pháp lý."],
   "blocks": [
    {"type": "table", "rows": [
      ("1. Mục đích", "Điều khoản này quy định điều kiện, trình tự sử dụng dịch vụ trung gian đặt lịch massage và làm đẹp tại nhà do massa (\"công ty\") cung cấp, cùng quyền và nghĩa vụ của công ty và người dùng."),
      ("2. Bản chất dịch vụ", "Công ty là nền tảng kết nối khách hàng với nhà cung cấp đã xác minh, không phải bên trực tiếp thực hiện dịch vụ. Dịch vụ nhằm mục đích thư giãn và chăm sóc, không phải điều trị y tế; triệu chứng cần điều trị nên đến cơ sở y tế."),
      ("3. Thành viên", "Chỉ người từ 18 tuổi trở lên được đăng ký. Không được mạo danh hoặc đăng ký thông tin sai sự thật. Thành viên tự chịu trách nhiệm quản lý tài khoản của mình."),
      ("4. Đặt lịch và thanh toán", "Thanh toán được thực hiện tại chỗ sau khi hoàn tất dịch vụ. Chấp nhận thẻ, QR và tiền mặt. Giá hiển thị đã gồm thuế và tiền tip; khi áp dụng mã giảm giá, số tiền cuối hiện ở bước xác nhận. Giao dịch trực tiếp ngoài ứng dụng bị cấm và có thể dẫn tới khóa tài khoản."),
      ("5. Hủy và không đến", "Có thể hủy miễn phí đến trước giờ bắt đầu 1 tiếng. Sau đó, khi hủy hoặc không đến đạt 3 lần trong 30 ngày gần nhất sẽ có cảnh báo, đạt 5 lần thì bị hạn chế đặt lịch 7 ngày. Lịch bị hủy do phía nhà cung cấp thì khách hàng không chịu bất lợi."),
      ("6. Nghĩa vụ nhà cung cấp", "Phải qua kiểm tra nhân thân và thẩm định chứng chỉ mới được hoạt động. Bộ vệ sinh dùng một lần là nguyên tắc. Lịch đã nhận phải thực hiện nghiêm túc; trong 30 ngày gần nhất, 5 lần từ chối sẽ có cảnh báo, 8 lần giảm mức hiển thị, 12 lần dừng nhận lịch 3 ngày. Nhà cung cấp nộp phí nền tảng 10% trong vòng 3 ngày kể từ ngày hoàn tất dịch vụ."),
      ("7. Hành vi bị cấm", "Người dùng và nhà cung cấp không được đưa ra yêu cầu không phù hợp với đối phương, bao gồm yêu cầu tình dục. Vi phạm được xác nhận sẽ bị khóa ngay và có thể bị báo cơ quan chức năng tùy mức độ. Ngoài ra, lăng mạ, phân biệt đối xử, quay chụp trái phép cũng bị cấm."),
      ("8. Báo cáo và an toàn", "Khi có sự cố trong lúc làm dịch vụ, có thể dùng nút an toàn (SOS) và chức năng báo cáo trong ứng dụng. Báo cáo được quản trị viên xem xét, xử lý và thông báo kết quả."),
      ("9. Giới hạn trách nhiệm", "Với tư cách bên trung gian, công ty không chịu trách nhiệm trực tiếp về chất lượng dịch vụ của nhà cung cấp hay hành vi của người dùng. Tuy nhiên khi phát sinh tranh chấp, công ty sẽ kiểm tra dữ liệu, xác minh sự việc và áp dụng chế tài cần thiết. Công ty không chịu trách nhiệm với thiệt hại do nguyên nhân ngoài tầm kiểm soát như thiên tai, sự cố mạng."),
      ("10. Thay đổi điều khoản", "Khi có thay đổi, thông báo trên ứng dụng và trang này ít nhất 7 ngày trước ngày hiệu lực. Thay đổi bất lợi cho người dùng được thông báo trước 30 ngày và cần đồng ý lại."),
      ("11. Liên hệ", f'Email <a href="mailto:{SUPPORT}">{SUPPORT}</a> hoặc liên hệ trong ứng dụng.'),
    ]}]},
 ]},

"privacy": {
 "title": "Chính sách quyền riêng tư — massa",
 "desc": "massa thu thập dữ liệu cá nhân nào, để làm gì, chia sẻ với ai, dùng bên xử lý nào, lưu bao lâu và bạn có quyền gì.",
 "blocks": [
  {"type": "section",
   "kicker": "Hiệu lực 14/08/2026 · sửa đổi 06/09/2026 · phiên bản 1.1",
   "h2": "Chính sách quyền riêng tư",
   "body": ["Đây là bản dịch để tham khảo. Bản tiếng Hàn là bản có hiệu lực pháp lý.",
            "massa (\"công ty\") là nền tảng trung gian đặt lịch tại nhà, kết nối khách hàng ở Hà Nội với nhà cung cấp massage và làm đẹp đã được xác minh. Chúng tôi xử lý dữ liệu cá nhân như sau."],
   "blocks": [
    {"type": "table", "rows": [
      ("1. Dữ liệu thu thập", "Tài khoản — email, mật khẩu (lưu dạng mã hóa), mã định danh đăng nhập mạng xã hội. Hồ sơ — họ tên, số điện thoại, giới tính, quốc tịch, ngôn ngữ. Đặt lịch — địa chỉ đến gồm tên khách sạn và số phòng, ngày giờ, ghi chú yêu cầu, phương thức và số tiền thanh toán. Vị trí — vị trí thiết bị ở mức tương đối hoặc chính xác, chỉ khi bạn đồng ý. Nhà cung cấp — bản sao giấy tờ tùy thân, tài khoản nhận tiền, giấy phép kinh doanh, chứng chỉ, ảnh hồ sơ. Tự động — thời điểm truy cập, thông tin thiết bị và trình duyệt, nhật ký lỗi ứng dụng."),
      ("2. Mục đích sử dụng", "Xác định thành viên và duy trì đăng nhập; trung gian đặt lịch và ghép nhà cung cấp; tìm kiếm theo vị trí khi được đồng ý; xác nhận thanh toán và đối soát hoa hồng; xác minh nhân thân nhà cung cấp; kiểm tra an toàn, xử lý báo cáo và phát hiện gian lận; giải đáp thắc mắc; gửi ưu đãi nếu bạn đã đồng ý nhận."),
      ("3. Cung cấp cho bên thứ ba", "Chúng tôi không bán dữ liệu cá nhân. Nhà cung cấp được phân lịch nhận tên, số điện thoại, địa chỉ đến và ghi chú yêu cầu, không gì thêm. Chỉ cung cấp cho cơ quan chức năng khi có yêu cầu hợp pháp và trong phạm vi được yêu cầu. Giấy tờ tùy thân và tài khoản của nhà cung cấp không hiển thị cho khách và nằm trong kho riêng chỉ người thẩm định mở được."),
      ("4. Bên xử lý dữ liệu", "The Constant Company, LLC (Vultr) — máy chủ, cơ sở dữ liệu, xác thực và lưu trữ tệp, khu vực Seoul, Hàn Quốc. Vercel Inc. — phân phối tài nguyên web mà ứng dụng Android tải về, Hoa Kỳ. Resend — gửi email giao dịch như đặt lại mật khẩu. Cloudflare, Inc. — tên miền và chuyển tiếp email. Google LLC — chuyển đổi đồng phục bằng AI cho ảnh hồ sơ (Gemini), Hoa Kỳ."),
      ("5. Lưu trữ và hủy", "Dữ liệu tài khoản được giữ đến khi bạn xóa tài khoản và hủy ngay sau đó. Hồ sơ đặt lịch, thanh toán và đối soát được giữ trong thời hạn luật định (thường 5 năm). Hồ sơ báo cáo và tranh chấp giữ 3 năm kể từ ngày xử lý xong; giấy tờ nhân thân của nhà cung cấp giữ 1 năm kể từ ngày kết thúc hợp đồng."),
      ("6. Quyền của bạn", "Bạn có thể xem, sửa dữ liệu, rút lại đồng ý và xóa tài khoản bất cứ lúc nào. Sửa ở Tài khoản → Thông tin cá nhân; xóa ở Tài khoản → Xóa tài khoản. Đồng ý nhận tiếp thị có thể rút ở Tài khoản → Điều khoản và quyền riêng tư, không ảnh hưởng đến việc sử dụng dịch vụ."),
      ("7. Vị trí", "Quyền vị trí chỉ dùng cho tìm kiếm \"gần tôi\" và hướng dẫn đến nơi, và chỉ khi bạn cho phép. Tọa độ thu được sẽ hủy ngay sau khi ghép xong và không được tích lũy. Bạn có thể tắt quyền trong cài đặt máy và vẫn đặt lịch bằng cách nhập địa chỉ."),
      ("8. Trẻ em", "Dịch vụ dành cho người từ 18 tuổi trở lên. Chúng tôi không cố ý thu thập dữ liệu của trẻ em."),
      ("9. Biện pháp an toàn", "Mọi lưu lượng được mã hóa qua HTTPS và mật khẩu được lưu ở dạng không thể giải ngược. Cơ sở dữ liệu áp dụng kiểm soát truy cập theo hàng (RLS) nên chỉ chủ sở hữu hoặc người phụ trách có quyền mới xem được."),
      ("10. Liên hệ", f'Liên hệ người phụ trách bảo vệ dữ liệu tại <a href="mailto:{SUPPORT}">{SUPPORT}</a>, hoặc qua Tài khoản → Trung tâm an toàn trong ứng dụng.'),
      ("11. Thông báo thay đổi", "Khi chính sách thay đổi, chúng tôi thông báo trên ứng dụng và trang này ít nhất 7 ngày trước ngày hiệu lực. Thay đổi quan trọng cần đồng ý lại."),
    ]},
    {"type": "note", "text": "Sửa đổi 06/09/2026 — danh sách bên xử lý đã được chỉnh lại đúng với các nhà cung cấp đang thực sự sử dụng sau khi chuyển sang hạ tầng tự vận hành."}]},
 ]},

}
