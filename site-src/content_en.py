# massaviet.com English content. Translated from content_ko.py — keep the two in step.

SUPPORT = "support@massaviet.com"

LABELS = {
    "nav": {"index": "Home", "services": "Services", "guide": "How it works",
            "safety": "Safety", "partner": "Partners", "faq": "FAQ",
            "about": "About", "download": "Get the app", "contact": "Contact",
            "terms": "Terms", "privacy": "Privacy"},
    "langname": {"ko": "KO", "en": "EN", "vi": "VI"},
    "login": "Log in",
    "cta": "Get the app",
    "footer_tag": "Massage and home beauty, booked to your door in Vietnam.",
    "f_service": "Service", "f_company": "massa", "f_support": "Support",
    "legal": ("© 2026 massa. Home massage and beauty booking in Vietnam. Currently operating in Hanoi.<br>"
              "massa is a platform connecting customers with verified providers. The care offered is not a medical treatment."),
    "rbar_tag": 'NOW HIRING',
    "rbar": 'Looking for 30 founding therapists',
    "rbar_sub": 'Keep 100% of what the customer pays on your first 20 jobs',
    "rbar_cta": 'See details',
    "smart": "Book faster in the app",
    "smart_cta": "Get it",
}

_LD_HOME = """{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "massa",
  "description": "Home massage and beauty booking platform in Vietnam (currently operating in Hanoi)",
  "url": "https://massaviet.com/en/",
  "image": "https://massaviet.com/img/hero.webp",
  "email": "support@massaviet.com",
  "areaServed": { "@type": "City", "name": "Hanoi" },
  "availableLanguage": ["ko", "vi", "en", "zh", "ja"],
  "sameAs": ["https://apps.apple.com/kr/app/id6804698319",
             "https://play.google.com/store/apps/details?id=app.massa.hanoi"]
}"""

_STORES = {"type": "stores", "ios": "iPhone · iPad", "and": "Android", "soon": "Coming soon"}

PAGES = {

"index": {
 "title": "massa — Home massage & beauty in Vietnam, booked to your door",
 "desc": "Therapists come to your home or hotel. Choose your time, and pay on the spot once the service is done. Currently operating in Hanoi.",
 "jsonld": _LD_HOME,
 "blocks": [
  {"type": "hero",
   "kicker": "Vietnam · At your door",
   "h1": "The hour you<br>don't have to<br><em>go out.</em>",
   "lead": "Late after work, or in a hotel room on a business trip. A verified therapist comes at the time you choose. You pay on the spot, after the service is finished.",
   "alt": "A therapist giving a massage in a candlelit room",
   "cap": "Booking to payment, all in the app. The price shown already includes tax and tip.",
   "btns": [("Get the app", "/en/download.html"), ("How it works", "/en/guide.html")]},

  {"type": "section", "soft": True,
   "kicker": "Why call one",
   "h2": "Getting there is<br>the expensive part",
   "lead": "Built for people who cannot bend their evening around a spa's opening hours.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "No opening hours to catch",
       "d": "Even late at night, when nothing nearby is still open, you pick any slot inside your therapist's available hours."},
      {"n": "02", "t": "Straight to your hotel room",
       "d": "We take the hotel name, room number and how to get past the front desk when you book. If a hotel requires visitor registration, we tell you first."},
      {"n": "03", "t": "Someone you can talk to",
       "d": "Each profile shows which languages the therapist speaks. In-app chat is translated automatically."},
    ]}]},

  {"type": "section",
   "kicker": "What you get",
   "h2": "Three ways<br>to be looked after",
   "blocks": [
    {"type": "pcards", "items": [
      {"img": "hero", "t": "Home massage", "href": "/en/services.html",
       "alt": "A therapist giving a back massage",
       "d": "Aromatherapy, Swedish, Thai, deep tissue. Choose 60, 90 or 120 minutes."},
      {"img": "beauty", "t": "Home beauty", "href": "/en/services.html",
       "alt": "Home beauty care",
       "d": "Nails, waxing and exfoliation, done at your home or hotel."},
      {"img": "spa", "t": "Spa directory", "href": "/en/services.html",
       "alt": "A warmly lit spa entrance",
       "d": "Ear cleaning, scalp care, skin, nails and lashes at partner venues, sorted by district."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Booking",
   "h2": "Four steps, then done",
   "lead": "No paperwork. Most first-time users finish in a few minutes.",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Choose", "d": "Compare therapists by verified badge, rating, languages and distance."},
      {"t": "Set", "d": "Pick a 60, 90 or 120 minute course and the time you want."},
      {"t": "Tell us where", "d": "Your address, or the hotel name, room number and how to get past reception."},
      {"t": "Confirm", "d": "You pay on the spot once the service is done. Nothing upfront."},
    ]},
    {"type": "note", "text": "You can cancel freely up to one hour before the appointment. The full cancellation rule is on the How it works page."}]},

  {"type": "section",
   "kicker": "Safety",
   "h2": "So that opening<br>the door is fine",
   "lead": "You are letting a stranger into your home. Reducing that weight is where most of our work has gone.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Marks you can trust",
       "d": "✓ means we checked their ID. ★ means we checked their qualifications too. No mark means we have checked nothing — and we say so."},
      {"n": "02", "t": "Pay after, not before",
       "d": "You pay on the spot once the service is done. Nothing is collected up front."},
      {"n": "03", "t": "Safety button",
       "d": "If something goes wrong mid-service, one tap sends your location straight to our team."},
    ]},
    {"type": "pull", "text": "Inappropriate requests are barred on both sides,<br>and confirmed breaches end access immediately."}]},

  {"type": "section", "soft": True,
   "kicker": "Where we operate",
   "h2": "Starting in Vietnam",
   "blocks": [
    {"type": "table", "rows": [
      ("Live now", "Hanoi — Ba Đình, Hoàn Kiếm, Mỹ Đình, Tây Hồ and more"),
      ("Next", "Đà Nẵng, Nha Trang, Hồ Chí Minh City"),
      ("Languages", "Korean, Vietnamese, English, Japanese, Chinese"),
    ]}]},

  {"type": "section",
   "kicker": "App",
   "h2": "Book straight from the app",
   "lead": "Installing and signing up are free. You only pay for the service, on the spot.",
   "blocks": [dict(_STORES)]},
 ]},

"services": {
 "title": "Services — massa home massage & beauty in Vietnam",
 "desc": "Home massage (aromatherapy, Swedish, Thai, deep tissue), home beauty (nails, waxing, exfoliation) and a partner spa directory. Currently operating in Hanoi.",
 "blocks": [
  {"type": "section",
   "kicker": "Services",
   "h2": "What you can<br>book",
   "lead": "Two services that come to you, and one directory for when you would rather go out. All booked in the app.",
   "blocks": [
    {"type": "pcards", "items": [
      {"img": "hero", "t": "Home massage", "alt": "Home massage",
       "d": "The therapist comes to your home or hotel and brings what they need — mat, oils, towels."},
      {"img": "beauty", "t": "Home beauty", "alt": "Home beauty",
       "d": "Nails, waxing and exfoliation without leaving the room. Consumables are single-use."},
      {"img": "spa", "t": "Spa directory", "alt": "Spa venue",
       "d": "When you would rather visit a venue, browse partner spas by district and category."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Massage",
   "h2": "Courses",
   "lead": "Choose 60, 90 or 120 minutes. Prices vary by therapist even for the same course.",
   "blocks": [
    {"type": "table", "rows": [
      ("Aromatherapy", "Slow pressure with warm oil. A safe choice when you are not sleeping well or feel generally stiff."),
      ("Swedish", "Long strokes over the whole body. What we most often suggest for a first booking."),
      ("Thai", "Stretching, no oil. Good when tightness has been building for a long time."),
      ("Deep tissue", "Pressure into the deeper muscle layers. It is firm, so say what intensity you want beforehand."),
    ]},
    {"type": "note", "text": "The exact amount appears once you pick a therapist and a course in the app. Tax and tip are already included, so nothing is added on the day."}]},

  {"type": "section",
   "kicker": "Home beauty",
   "h2": "Care at home",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Nails", "d": "Hand and foot care with colour. Tools arrive sterilised."},
      {"n": "02", "t": "Waxing", "d": "Choose the areas you want. Wax and strips are single-use only."},
      {"n": "03", "t": "Exfoliation & skin", "d": "Foot exfoliation and basic skin care. Tell us in the booking note if your skin is sensitive."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Venues",
   "h2": "Spa directory",
   "lead": "Things we do not offer as a home visit are available at partner venues.",
   "blocks": [
    {"type": "table", "rows": [
      ("Healing care", "Premium ear cleaning, scalp care"),
      ("Beauty", "Skin care, nails, lashes"),
      ("Hair removal", "Body waxing, area-by-area"),
    ]},
    {"type": "note", "text": "The care massa offers is for relaxation and upkeep, and is not a medical treatment. Please see a medical professional for anything that needs treating."}]},
 ]},

"guide": {
 "title": "How it works — booking, payment, cancellation | massa",
 "desc": "How to book with massa, how paying on the spot works, the cancellation and no-show rule, and what to expect when booking to a hotel.",
 "blocks": [
  {"type": "section",
   "kicker": "How it works",
   "h2": "From booking<br>to paying",
   "lead": "Written so a first-time user knows what each step asks for and what it shows back.",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Service and therapist", "d": "Compare by verified badge, rating, reviews, languages and distance."},
      {"t": "Course and time", "d": "Pick 60, 90 or 120 minutes, then the date and hour."},
      {"t": "Where to come", "d": "Your address, or hotel name, room number and how to get past reception."},
      {"t": "Confirm", "d": "Check the amount and the time on the summary screen, then confirm."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Payment",
   "h2": "Receive first,<br>pay after",
   "body": [
    "massa is pay-after. You settle up on the spot once the service is finished. There is no card to register and nothing to pay when you book.",
    "You can pay by card on the spot, by QR (MoMo, ZaloPay, VNPay) or in cash. Coupons apply on the payment screen."],
   "blocks": [
    {"type": "table", "rows": [
      ("The price shown", "Already includes tax and tip. Nothing is added on the day."),
      ("Extra charges", "Only if you extend beyond the course you booked, and only for that extension."),
      ("Receipt", "In the app, under your booking history."),
    ]}]},

  {"type": "section",
   "kicker": "Cancelling",
   "h2": "Cancellations and no-shows",
   "body": [
    "You can <b>cancel freely up to one hour</b> before the start time, with no penalty.",
    "After that point, cancellations and no-shows are counted. Over the last 30 days, <b>3 of them trigger a warning</b> and <b>5 mean booking is restricted for 7 days</b>.",
    "The rule exists because your therapist may already be travelling to you. If something comes up, cancel as early as you can. Bookings cancelled by the provider do not count against you."]},

  {"type": "section", "soft": True,
   "kicker": "Hotels",
   "h2": "Booking to a hotel",
   "lead": "If you are travelling, you can be seen in your room. Visitor rules differ from hotel to hotel, though.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "What to enter", "d": "Hotel name, room number, and how to get past the front desk. If visitor registration is needed, we tell you first."},
      {"n": "02", "t": "On arrival", "d": "Your therapist calls from the lobby. Letting reception know in advance makes it smoother."},
      {"n": "03", "t": "Space", "d": "Enough floor beside the bed for a mat is plenty. You do not need to prepare anything."},
    ]}]},
 ]},

"safety": {
 "title": "Safety & checks — what each mark means | massa",
 "desc": "What massa's two marks — ID verified and credentials verified — actually mean, how the safety button and reporting work, and what we cannot guarantee.",
 "blocks": [
  {"type": "section",
   "kicker": "Safety & checks",
   "h2": "You are letting a<br>stranger into your home",
   "lead": "Reducing that worry only works if the marks are accurate. So we show only what we have checked, and say plainly when we have not.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "•", "t": "Not verified yet", "d": "We have not received or finished checking this person's documents. No mark does not mean poor work. It means we have checked nothing."},
      {"n": "✓", "t": "ID verified", "d": "Government ID, front and back, submitted and matched against the name. Documents sit in private storage only reviewers can open."},
      {"n": "★", "t": "Credentials verified", "d": "ID verified, plus a massage or beauty qualification, or a business licence, checked as well."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "What the marks don't say",
   "h2": "Don't rule out<br>the unmarked",
   "body": [
    "massa opened in September 2026, and most therapists listed today are still at the not-verified stage. We raise each one as documents arrive.",
    "We do not write down as checked what we have not checked. Few marks is not a sign of a thin service. It is a sign that we don't invent marks.",
    "We do not run in-person interviews yet. If we start, we will add a mark for it and say so here."]},

  {"type": "section",
   "kicker": "Hygiene",
   "h2": "Single-use by default",
   "body": [
    "For anything touching skin directly — waxing, nails — hygiene is the whole job. We require partners to use wax, strips and files once and never reuse them.",
    "That is a standard we require, not something we check and mark case by case yet. Until we have a way to verify it, we show no hygiene mark. If single-use is not respected on the day, please report it."]},

  {"type": "section",
   "kicker": "During the service",
   "h2": "If something goes wrong",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Safety button", "d": "The in-app SOS sends your current location to our team immediately."},
      {"n": "02", "t": "Location sharing", "d": "You can share your location with someone you trust for the duration of the service."},
      {"n": "03", "t": "Report and block", "d": "Reports are reviewed, acted on and answered. Blocking stops that person being matched to you again."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Not allowed",
   "h2": "The same rule<br>on both sides",
   "body": [
    "Inappropriate requests, sexual ones included, are barred for customers and providers <b>alike</b>. A confirmed breach ends access immediately and may be reported to the authorities depending on severity.",
    "Cash deals outside the app and requests for personal contact details are also barred. Refuse them and report. A transaction that never went through the app leaves no record, so we cannot help if it goes wrong."]},

  {"type": "section",
   "kicker": "Limits",
   "h2": "What we cannot guarantee",
   "body": [
    "Plainly: massa is a platform, and we cannot fully control what people do.",
    "Checking documents lowers the odds of something going wrong. It does not take them to zero. The care offered is for relaxation and upkeep and is <b>not a medical treatment</b> — please see a medical professional for anything that needs treating.",
    "What we will do, when something does go wrong, is check the records, establish the facts and take the steps that follow."]},
 ]},

"partner": {
 "title": "Hiring home massage & beauty therapists — founding members | massa",
 "desc": "massa is looking for 30 founding therapists in Hanoi. Keep 100% of what the customer pays on your first 20 jobs. No joining fee, no training fee, no interview. Signing up takes five minutes.",
 "blocks": [
  {"type": "section",
   "kicker": "Join as a partner",
   "h2": "Your hours.<br><em>Your earnings.</em>",
   "lead": "massa is a home massage booking platform. Switch on when you are free, off when you are not, and take bookings only in the districts you choose. No shop ties, and no need to leave the job you already have.",
   "blocks": [
    {"type": "cta", "btns": [("Apply now", "https://app.massaviet.com/?login=1")],
     "sub": "About five minutes in the app. It costs nothing."}]},

  {"type": "section", "soft": True,
   "kicker": "Founding members",
   "h2": "The first thirty therapists<br>of massa in Hanoi",
   "lead": "We are building the first team. Whoever joins now gets the best terms we have to give.",
   "blocks": [
    {"type": "table", "rows": [
      ("First 20 jobs", "<b>You keep 100% of what the customer pays.</b> No commission taken. It counts jobs rather than days, so the offer stays whole until you have used it."),
      ("After 20 jobs", "5% commission for three months. The usual rate is 10%."),
      ("Visibility", "Top of the list for 30 days, with a new-therapist label."),
      ("Badge", "A founding member badge that stays on your profile for good."),
      ("Referrals", "When someone you bring completes 5 jobs, you get 5% for three months."),
      ("Cost to join", "Zero. No joining, training, deposit or monthly fees."),
    ]}]},

  {"type": "section",
   "kicker": "Your call",
   "h2": "You decide all of it",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Your hours",
       "d": "On when you are free, off when you are not. Nothing reaches you while you are off."},
      {"n": "02", "t": "Your area",
       "d": "You pick the districts you take bookings in. Only requests from there come to you."},
      {"n": "03", "t": "Your price",
       "d": "You set your own price within an allowed range. Nobody prices your work for you."},
      {"n": "04", "t": "Paid on the spot",
       "d": "The customer pays you directly when the session ends. No payout cycle to wait for."},
    ]}]},

  {"type": "section", "soft": True,
   "kicker": "Safety",
   "h2": "You walk into someone's home.<br>So we take this part seriously.",
   "lead": "Every partner verifies their ID before working. That is why customers open the door with confidence, and why you can walk in with the same.",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "Everyone is verified",
       "d": "We check each partner's ID before approval. Only checked documents earn a verification mark."},
      {"n": "02", "t": "Safety button in the app",
       "d": "If something feels wrong mid-session, one tap sends your location straight to our team."},
      {"n": "03", "t": "The standard runs both ways",
       "d": "If a customer makes an inappropriate request, refuse and report it. Confirmed violations are suspended immediately."},
      {"n": "04", "t": "Straight with customers too",
       "d": "We state exactly what we checked and nothing more. A customer's trust is something we build together."},
    ]}]},

  {"type": "section",
   "kicker": "Applying",
   "h2": "Three steps, about five minutes",
   "lead": "No interview, no visit, no printed paperwork. You can finish it on your phone.",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Install the massa app", "d": "App Store or Google Play. Free."},
      {"t": "Account to Become a partner", "d": "Your name, districts, payout account and a profile photo."},
      {"t": "Photograph your ID and send", "d": "Front and back. Add a certificate if you have one for an extra mark; it is not required."},
    ]},
    {"type": "note", "text": "Every application is reviewed by hand, so it takes a little time. Once approved you start taking bookings right away."},
    {"type": "cta", "btns": [("Apply now", "https://app.massaviet.com/?login=1"),
                              ("Get the app", "/en/download.html")],
     "sub": "Questions? support@massaviet.com"}]},

  {"type": "section", "soft": True,
   "kicker": "The commitment",
   "h2": "Two things we ask",
   "body": [
    "Finish the bookings you accept. The customer is waiting in their own home, so one missed appointment costs more trust than it looks. Repeated declines lower your visibility.",
    "Keep the hygiene standard. Single-use kits are how massa works, and they are what a customer remembers about you longest."]},
 ]},
"faq": {
 "title": "Frequently asked questions — massa",
 "desc": "Answers on booking, payment, cancellation, safety and applying as a partner.",
 "blocks": [
  {"type": "section",
   "kicker": "FAQ",
   "h2": "Questions we get",
   "blocks": [
    {"type": "faq", "items": [
      ("When do I pay?",
       "On the spot, after the service is finished. Nothing is charged when you book. Pay by card, by QR (MoMo, ZaloPay, VNPay) or in cash."),
      ("I want to change the time",
       "Cancel from your booking history in the app and book again. There is no penalty up to one hour before the start."),
      ("Is there a penalty for cancelling?",
       "Not within the first window — up to one hour before, cancelling is free. After that, cancellations and no-shows are counted: over the last 30 days, 3 trigger a warning and 5 restrict booking for 7 days. Bookings cancelled by the provider do not count."),
      ("Can I book for right now?",
       "If a therapist is currently active, yes. The app shows who is available and how far away they are."),
      ("How do coupons work?",
       "Claim them under Account → Coupons. Applicable ones appear automatically on the payment screen."),
      ("What do I need to prepare at home?",
       "Enough floor space for a mat. The therapist brings oils and equipment. A shower beforehand makes it more pleasant."),
      ("I don't know which massage to choose",
       "Swedish is the safe first choice. Deep tissue if you are badly knotted; aromatherapy if you are sleeping poorly."),
      ("What if the pressure is too strong or too light?",
       "Say so during the session. Do not endure it. Telling your therapist your preferred intensity before starting helps too."),
      ("Is Korean or English spoken?",
       "Each profile lists the languages the therapist speaks, so you can choose. In-app chat is translated automatically."),
      ("Can I book to a hotel?",
       "Yes. Enter the hotel name, room number and how to get past reception when booking. If a hotel requires visitor registration, we flag it at the search stage."),
      ("I'm pregnant — is it safe?",
       "Please tell us when booking, and speak to your doctor first. massa's care is not a medical treatment and is not suitable for every condition."),
      ("How do I know who is coming?",
       "✓ ID verified means we checked their government ID. ★ Credentials verified means we checked a qualification or business licence too. Therapists we have not checked are shown with no mark at all. Reviews can only be left on a booking someone actually received."),
      ("What if something goes wrong during the service?",
       "The in-app safety button (SOS) sends your location to our team immediately. You can also report and block from the app."),
      ("Someone suggested paying cash outside the app",
       "Refuse and report it. Off-app deals are barred for both sides, and without a record we cannot help if something goes wrong."),
      ("Who sees my address?",
       "Only the therapist assigned to your confirmed booking. They receive your name, contact number, visit address and request notes — nothing else."),
      ("How do I work as a partner?",
       "Apply in the app under Account → Become a partner. Upload ID, a settlement account, qualifications and profile photos, then go through vetting."),
      ("Is there a joining fee?",
       "No, and no monthly fee either. Commission applies only to bookings that are accepted and completed."),
      ("Can I set my own hours?",
       "Yes. You switch availability on and off in the app and choose the districts you cover."),
    ]}]},
  {"type": "section", "soft": True,
   "h2": "If your question isn't here",
   "lead": f"Email {SUPPORT} and we will reply in the order received.",
   "blocks": [{"type": "note", "text": "For anything urgent during a service, use the in-app safety button and report function first. They are far faster than email."}]},
 ]},

"about": {
 "title": "About — massa",
 "desc": "massa connects customers in Vietnam with massage and home beauty providers. We are the platform, not the provider. Currently operating in Hanoi.",
 "blocks": [
  {"type": "section",
   "kicker": "About",
   "h2": "massa is<br>the platform",
   "lead": "We do not provide the service ourselves. We connect customers with vetted providers and keep what happens between them accountable.",
   "body": [
     "Vietnam has plenty of good therapists, but from a customer's side it is hard to tell who is trustworthy. From the other side, skilled people are tied to a venue's hours or have few ways to reach customers. massa sits in that gap.",
     "So most of our effort goes into vetting and records. Knowing who is coming, having a record when something goes wrong, and applying the same rules to both sides — we think that is the minimum for a home-visit service to work at all."]},
  {"type": "section", "soft": True,
   "h2": "What we hold to",
   "blocks": [
    {"type": "grid", "items": [
      {"n": "01", "t": "No prepayment", "d": "You pay after you have received the service. We do not collect money before starting."},
      {"n": "02", "t": "No hidden price", "d": "Tax and tip are in the number you see. Nothing is added on the day."},
      {"n": "03", "t": "One rule for both sides", "d": "Inappropriate requests and off-app dealing are barred for customers and providers alike."},
    ]}]},
  {"type": "section",
   "h2": "Contact",
   "blocks": [
    {"type": "table", "rows": [
      ("Email", f'<a href="mailto:{SUPPORT}">{SUPPORT}</a>'),
      ("Coverage", "Vietnam — currently Hanoi (Đà Nẵng, Nha Trang and Hồ Chí Minh City to follow)"),
      ("App", '<a href="/en/download.html">Download the app</a>'),
    ]}]},
 ]},

"download": {
 "title": "Get the app — massa",
 "desc": "Download the massa app and book home massage and beauty in Vietnam straight from your phone. Currently operating in Hanoi.",
 "blocks": [
  {"type": "section",
   "kicker": "Get the app",
   "h2": "Download massa",
   "lead": "Booking, therapist profiles, chat and reviews all live in the app. Installing and signing up are free.",
   "blocks": [dict(_STORES)]},
  {"type": "section", "soft": True, "play_pending": True,
   "h2": "Android is<br>still coming",
   "lead": "It is in closed testing, so it does not yet appear in Google Play search.",
   "body": [
     f'The Android build already works and is in testing. We will publish it as soon as we have completed the testing period Google Play requires, and the install button will appear on this page. Until then, if you are on Android, email <a href="mailto:{SUPPORT}">{SUPPORT}</a> and we will send you instructions for joining the test.']},
  {"type": "section",
   "h2": "Once installed",
   "blocks": [
    {"type": "steps", "items": [
      {"t": "Choose", "d": "Compare therapists by verified badge, rating, languages and distance."},
      {"t": "Set", "d": "Pick a 60, 90 or 120 minute course and the time you want."},
      {"t": "Tell us where", "d": "Your address, or hotel name and room number."},
      {"t": "Confirm", "d": "You pay on the spot once the service is done."},
    ]},
    {"type": "table", "rows": [
      ("Cost", "The app and signing up are free. You only pay for the service, on the spot."),
      ("Languages", "Korean, Vietnamese, English, Japanese, Chinese"),
      ("Coverage", "Hanoi — Ba Đình, Hoàn Kiếm, Mỹ Đình, Tây Hồ and more"),
      ("For partners", 'Therapists register in the same app. <a href="/en/partner.html">See partner information</a>'),
    ]}]},
 ]},

"contact": {
 "title": "Contact — massa",
 "desc": "For help, partnership proposals or bug reports, email support@massaviet.com.",
 "blocks": [
  {"type": "section",
   "kicker": "Contact",
   "h2": "Send us<br>anything",
   "lead": "We read and answer in the order received.",
   "blocks": [
    {"type": "table", "rows": [
      ("Email", f'<a href="mailto:{SUPPORT}">{SUPPORT}</a>'),
      ("Using the service", "Booking, payment, cancellation and account issues"),
      ("Partners", 'Therapist and venue registration. Please read the <a href="/en/partner.html">partner page</a> first.'),
      ("Partnerships", "Spa venues, hotels and other proposals"),
      ("Bug reports", "Tell us your device and what you were doing when it went wrong."),
    ]},
    {"type": "note", "text": "For anything urgent during a service, the in-app safety button (SOS) and report function are far faster than email. They reach our team with your location attached."}]},
 ]},

"terms": {
 "title": "Terms of service — massa",
 "desc": "massa terms of service: booking and pay-after, the cancellation and no-show rule, provider obligations, prohibited conduct and limits of liability.",
 "blocks": [
  {"type": "section",
   "kicker": "Effective 14 August 2026 · version 2026-07-1",
   "h2": "Terms of service",
   "body": ["This is a translation provided for convenience. The Korean version is the binding text."],
   "blocks": [
    {"type": "table", "rows": [
      ("1. Purpose", "These terms set out the conditions and procedures for using the home massage and beauty booking service provided by massa (\"the company\"), and the rights and duties of the company and its users."),
      ("2. Nature of the service", "The company is a platform connecting customers with verified providers, not the provider of the service itself. The care offered is for relaxation and upkeep, not medical treatment; anything requiring treatment should be taken to a medical professional."),
      ("3. Members", "Registration is limited to those aged 18 or over. Using another person's information or registering false information is not permitted. Members are responsible for their own account."),
      ("4. Booking and payment", "Payment is made on the spot after the service is completed. Card, QR payment and cash are accepted. The price shown includes tax and tip; where a coupon applies, the final amount appears at the confirmation step. Dealing directly outside the app is prohibited and may result in suspension."),
      ("5. Cancellation and no-shows", "Bookings may be cancelled free of charge up to one hour before the start time. After that, once cancellations or no-shows reach 3 within the last 30 days a warning is issued, and at 5 booking is restricted for 7 days. Bookings cancelled by the provider carry no penalty for the customer."),
      ("6. Provider obligations", "Providers must pass identity and credential checks before working. Single-use hygiene kits are the standard. Accepted bookings must be honoured; within the last 30 days, 5 declines bring a warning, 8 reduce visibility and 12 suspend incoming bookings for 3 days. Providers remit the 10% platform commission within 3 days of the service date."),
      ("7. Prohibited conduct", "Neither users nor providers may make inappropriate requests of the other, sexual requests included. Confirmed breaches result in immediate suspension and may be reported to the authorities. Abuse, discrimination and unauthorised recording are likewise prohibited."),
      ("8. Reporting and safety", "The in-app safety button (SOS) and report function are available if a problem arises during a service. Reports are reviewed, acted on, and the outcome communicated."),
      ("9. Limits of liability", "As an intermediary, the company is not directly liable for the quality of a provider's service or for users' conduct. Where a dispute arises, the company will check records, establish facts and apply penalties as needed. The company is not liable for loss arising from causes beyond its control, such as natural disaster or network failure."),
      ("10. Changes", "Changes are announced in the app and on this page at least 7 days before taking effect. Changes unfavourable to users are announced 30 days in advance and require fresh consent."),
      ("11. Contact", f'Email <a href="mailto:{SUPPORT}">{SUPPORT}</a> or use in-app support.'),
    ]}]},
 ]},

"privacy": {
 "title": "Privacy policy — massa",
 "desc": "What personal data massa collects, why, who it is shared with, which processors we use, how long it is kept and what rights you have.",
 "blocks": [
  {"type": "section",
   "kicker": "Effective 14 August 2026 · revised 6 September 2026 · version 1.1",
   "h2": "Privacy policy",
   "body": ["This is a translation provided for convenience. The Korean version is the binding text.",
            "massa (\"the company\") is a home-visit booking platform connecting customers in Vietnam with massage and beauty providers. We handle personal data as set out below."],
   "blocks": [
    {"type": "table", "rows": [
      ("1. What we collect", "Account — email, password (stored hashed), social login identifier. Profile — name, mobile number, gender, nationality, language. Booking — visit address including hotel and room number, date and time, request notes, payment method and amount. Location — approximate or precise device location, only with your consent. Providers — ID document, settlement account, business registration, qualifications, profile photos. Automatic — access times, device and browser information, app error logs. Usage statistics — a record that the app was opened (a random identifier stored on your device, the date, platform and display language). At most one row per device per day; no name, email or IP address is stored alongside it."),
      ("2. Why we use it", "Identifying members and keeping you signed in; matching bookings to providers; location-based search where consented; confirming payment and settling commission; verifying provider identity; safety checks, handling reports and detecting fraud; answering enquiries; sending offers where you have opted in."),
      ("3. Sharing", "We do not sell personal data. The assigned provider receives your name, contact number, visit address and request notes, and nothing further. We disclose data to authorities only on a lawful request and only to the extent required. Provider ID and account details are never shown to customers and sit in private storage only reviewers can open."),
      ("4. Processors", "The Constant Company, LLC (Vultr) — server hosting, database, authentication and file storage, Seoul region, Republic of Korea. Vercel Inc. — delivery of the web assets loaded by the Android app, United States. Resend — transactional email such as password resets. Cloudflare, Inc. — domain and email forwarding. Google LLC — AI uniform rendering of profile photos (Gemini), United States."),
      ("5. Retention", "Account data is kept until you delete your account and destroyed immediately after. Booking, payment and settlement records are kept for the statutory period (usually 5 years). Report and dispute records are kept 3 years from resolution; provider identity documents 1 year from the end of the contract."),
      ("6. Your rights", "You may view and correct your data, withdraw consent and delete your account at any time. Edit under Account → Personal information; delete under Account → Delete account. Marketing consent can be withdrawn under Account → Terms and privacy, with no effect on your use of the service."),
      ("7. Location", "Location permission is used only for \"near me\" search and visit guidance, and only when you grant it. Collected coordinates are discarded once matching is done and are not accumulated. You can revoke the permission in device settings and still book by entering an address."),
      ("8. Children", "The service is for those aged 18 and over. We do not knowingly collect data from children."),
      ("9. Security", "All traffic is encrypted over HTTPS and passwords are stored in a form that cannot be reversed. The database enforces row-level security so records are visible only to their owner or an authorised reviewer."),
      ("10. Contact", f'Write to our data protection contact at <a href="mailto:{SUPPORT}">{SUPPORT}</a>, or use Account → Safety centre in the app.'),
      ("11. Changes", "Changes are announced in the app and on this page at least 7 days before taking effect. Material changes require fresh consent."),
    ]},
    {"type": "note", "text": "Revised 6 September 2026 — the processor list was corrected to the providers actually in use after the move to self-hosted infrastructure."}]},
 ]},

}
