-- ════════════════════════════════════════════════════════════════════════════
--  demo_trips.sql  ·  110 hand-planned trips for 26 demo travellers
--
--  A small, natural-looking cast on top of the generated dataset, so the website can be
--  shown without signing in as one of the 26,000 synthetic guests (one of whom has 181 stays).
--  Every row goes through the real tables and triggers: prices come from fn_quote_stay,
--  rooms are only taken if fn_room_is_free, the review roll-up trigger updates the hotels.
--
--  Cast: Indian names with home cities, a usual way of paying (UPI / card / net banking),
--  business trips on weekdays, family holidays at festival time, a few cancellations with the
--  refund the cancellation policy gives, two no-shows, three guests staying right now, trips
--  that were extended or shortened after booking, and unpaid pay-at-hotel bookings.
--
--  Generated once from a fixed plan (the SQL below is the source of truth).
--  Re-run safe: it does nothing if the cast is already there.
--  Platform "today" = 2026-10-29 (fn_today()).
-- ════════════════════════════════════════════════════════════════════════════
\set ON_ERROR_STOP on

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM guests WHERE email = 'priya.nair@example.in') THEN
        RAISE EXCEPTION 'demo trips are already loaded';
    END IF;
END $$;

-- ── 1. the travellers ──────────────────────────────────────────────────────
-- created_at = the moment of their first booking (accounts are made while booking)
CREATE TEMP TABLE demo_guest (
    key text PRIMARY KEY, first_name text, last_name text, phone text, email text, dob date, id_type id_document_t,
    id_number text, city_name text, state_code char(2), referred_by_key text, created_at timestamptz, vpa text, card text,
    persona text, sort_order int);
INSERT INTO demo_guest VALUES
    ('priya', 'Priya', 'Nair', '9607307530', 'priya.nair@example.in', DATE '1991-06-14', 'PAN', 'WFSPN1249O', 'Bangalore', 'KA', NULL, '2025-03-15 15:37:46+05:30', 'priya.nair@okhdfcbank', '1198', 'Product manager · work trips and long weekends', 1),
    ('arjun', 'Arjun', 'Mehta', '8404011553', 'arjun.mehta@example.in', DATE '1986-02-03', 'PAN', 'JLMPM2284P', 'Mumbai', 'MH', NULL, '2025-02-04 14:10:28+05:30', 'arjun.mehta@okicici', '1329', 'Finance lead · business travel and family holidays', 2),
    ('ananya', 'Ananya', 'Iyer', '7015110270', 'ananya.iyer@example.in', DATE '1994-09-21', 'PASSPORT', 'P2395808', 'Chennai', 'TN', NULL, '2025-01-15 10:19:26+05:30', 'ananya.iyer@oksbi', '1913', 'Freelance designer · solo and friends'' trips', 3),
    ('harpreet', 'Harpreet', 'Gill', '9641330038', 'harpreet.gill@example.in', DATE '1989-11-30', 'DRIVING_LICENCE', 'CH1220116874690', 'Chandigarh', 'CH', NULL, '2025-01-24 22:40:47+05:30', 'harpreetg95@okaxis', '5963', 'Family of four · hill-station holidays', 4),
    ('rohan', 'Rohan', 'Deshmukh', '8058199453', 'rohan.deshmukh@example.in', DATE '1990-04-12', 'PAN', 'LJPPD1551I', 'Pune', 'MH', NULL, '2025-06-05 11:55:42+05:30', 'rohan.deshmukh@okaxis', '2736', 'Weekend getaways from Pune', 5),
    ('sneha', 'Sneha', 'Kulkarni', '9249504806', 'sneha.kulkarni@example.in', DATE '1992-12-05', 'PAN', 'RYGPK9694X', 'Pune', 'MH', 'rohan', '2025-09-18 10:07:09+05:30', 'sneha.kulkarni@ybl', '4380', 'Books for the whole family', 6),
    ('vikram', 'Vikram', 'Rathore', '8919230562', 'vikram.rathore@example.in', DATE '1978-08-19', 'DRIVING_LICENCE', 'RJ1020151459721', 'Jaipur', 'RJ', NULL, '2025-02-26 17:32:51+05:30', 'vikram.rathore@okhdfcbank', '7399', 'Businessman · premium family trips', 7),
    ('kavya', 'Kavya', 'Reddy', '6731566268', 'kavya.reddy@example.in', DATE '1996-03-27', 'PAN', 'IWDPR0093C', 'Hyderabad', 'TG', 'ananya', '2025-03-01 06:52:48+05:30', 'kavya.reddy@ybl', '3551', 'Software engineer · trips with friends', 8),
    ('imran', 'Imran', 'Qureshi', '9463872548', 'imran.qureshi@example.in', DATE '1984-07-08', 'PASSPORT', 'G4101436', 'Hyderabad', 'TG', NULL, '2025-03-28 17:33:05+05:30', 'imranq56@oksbi', '1776', 'Sales manager · work trips and family visits', 9),
    ('debashish', 'Debashish', 'Banerjee', '9046637745', 'debashish.banerjee@example.in', DATE '1972-01-25', 'VOTER_ID', 'DPF6737480', 'Kolkata', 'WB', NULL, '2025-08-10 19:00:30+05:30', 'debashishb69@oksbi', '5878', 'Bank officer · festival holidays with family', 10),
    ('sourav', 'Sourav', 'Chatterjee', '9927744934', 'sourav.chatterjee@example.in', DATE '1988-10-10', 'PAN', 'HCDPC5981E', 'Kolkata', 'WB', 'debashish', '2025-03-15 14:45:17+05:30', 'sourav.chatterjee@paytm', '3377', 'Budget trips to the hills', 11),
    ('meera', 'Meera', 'Pillai', '7622269027', 'meera.pillai@example.in', DATE '1985-05-18', 'PASSPORT', 'T1478764', 'Kochi', 'KL', NULL, '2025-03-29 08:15:54+05:30', 'meerap93@okicici', '2406', 'Teacher · school-holiday trips with two kids', 12),
    ('gurpreet', 'Gurpreet', 'Sandhu', '7648718119', 'gurpreet.sandhu@example.in', DATE '1981-09-02', 'DRIVING_LICENCE', 'PB0620153667558', 'Amritsar', 'PB', 'harpreet', '2025-07-22 08:47:12+05:30', 'gurpreets19@okaxis', '5960', 'Shop owner · yatra and hill trips', 13),
    ('aditya', 'Aditya', 'Verma', '8617709275', 'aditya.verma@example.in', DATE '1993-06-09', 'PAN', 'THRPV4123K', 'Delhi', 'DL', NULL, '2025-02-10 08:57:39+05:30', 'adityav70@okhdfcbank', '8486', 'Delhi weekenders', 14),
    ('neha', 'Neha', 'Agarwal', '8667184913', 'neha.agarwal@example.in', DATE '1990-11-22', 'PAN', 'TNMPA4194Z', 'Gurgaon', 'HR', 'arjun', '2025-11-24 15:02:10+05:30', 'neha.agarwal@okicici', '7310', 'Consultant · design-hotel weekends', 15),
    ('siddharth', 'Siddharth', 'Joshi', '7978327115', 'siddharth.joshi@example.in', DATE '1987-02-14', 'PAN', 'MIIPJ5824Q', 'Ahmedabad', 'GJ', NULL, '2025-04-24 07:32:56+05:30', 'siddharth.joshi@paytm', '9082', 'Family holidays from Ahmedabad', 16),
    ('pooja', 'Pooja', 'Patel', '9861907206', 'pooja.patel@example.in', DATE '1995-07-30', 'PAN', 'UQNPP2281Z', 'Surat', 'GJ', 'tanvi', '2025-03-26 22:17:47+05:30', 'pooja.patel@ybl', '3583', 'Budget-friendly trips', 17),
    ('karthik', 'Karthik', 'Subramanian', '9533940229', 'karthik.subramanian@example.in', DATE '1983-03-11', 'VOTER_ID', 'OMK8586625', 'Coimbatore', 'TN', NULL, '2025-01-29 13:51:52+05:30', 'karthiks10@oksbi', '5049', 'Engineer · hills and temples', 18),
    ('lakshmi', 'Lakshmi', 'Venkatesh', '7408431369', 'lakshmi.venkatesh@example.in', DATE '1969-12-28', 'VOTER_ID', 'JTC8604087', 'Chennai', 'TN', NULL, '2025-05-28 14:56:09+05:30', 'lakshmi.venkatesh@okhdfcbank', '5942', 'Temple pilgrimages', 19),
    ('rahul', 'Rahul', 'Gupta', '6462192074', 'rahul.gupta@example.in', DATE '1991-01-16', 'PAN', 'PFXPG2414F', 'Lucknow', 'UP', NULL, '2025-10-15 07:14:31+05:30', 'rahul.gupta@paytm', '8719', 'Travels light and cheap', 20),
    ('shreya', 'Shreya', 'Mishra', '8954362984', 'shreya.mishra@example.in', DATE '1997-05-04', 'PAN', 'QDRPM5563Z', 'Patna', 'BR', NULL, '2025-07-19 08:52:40+05:30', 'shreyam68@ybl', '4497', 'Student · family trips', 21),
    ('faisal', 'Mohammed Faisal', 'Khan', '8958823078', 'mohammed.khan@example.in', DATE '1980-10-23', 'PASSPORT', 'R6381447', 'Bhopal', 'MP', NULL, '2025-08-04 09:11:42+05:30', 'mohammedk20@okicici', '1330', 'Auditor · mostly work trips', 22),
    ('tanvi', 'Tanvi', 'Shah', '7925376324', 'tanvi.shah@example.in', DATE '1998-08-08', 'PAN', 'IKEPS6448P', 'Mumbai', 'MH', NULL, '2025-02-11 11:00:17+05:30', 'tanvis19@okaxis', '1800', 'Girls'' trips', 23),
    ('abhishek', 'Abhishek', 'Pandey', '6402803400', 'abhishek.pandey@example.in', DATE '1985-04-17', 'PAN', 'PJEPP0049D', 'Indore', 'MP', NULL, '2025-06-25 11:16:26+05:30', 'abhishek.pandey@oksbi', '5245', 'Temple trips with his parents', 24),
    ('nandini', 'Nandini', 'Menon', '8345849865', 'nandini.menon@example.in', DATE '1979-09-26', 'PASSPORT', 'V8854961', 'Thiruvananthapuram', 'KL', NULL, '2025-07-11 09:41:47+05:30', 'nandinim74@okhdfcbank', '6697', 'Doctor · short breaks', 25),
    ('manish', 'Manish', 'Tiwari', '6304147157', 'manish.tiwari@example.in', DATE '1975-06-21', 'PAN', 'DKSPT0042T', 'Nagpur', 'MH', NULL, '2025-04-29 09:47:27+05:30', 'manisht32@okaxis', '3730', 'Pilgrimages and family visits', 26);

-- referred_by points to another guest, so insert the people first and the referrals second
INSERT INTO guests (first_name, last_name, phone, email, date_of_birth, id_type, id_number, home_city_id, created_at)
SELECT d.first_name, d.last_name, d.phone, d.email, d.dob, d.id_type, d.id_number, c.city_id, d.created_at
FROM demo_guest d JOIN cities c ON c.city_name = d.city_name AND c.state_code = d.state_code
ORDER BY d.sort_order;

UPDATE guests g SET referred_by = r.guest_id
FROM demo_guest d
JOIN demo_guest rd ON rd.key = d.referred_by_key
JOIN guests r ON r.email = rd.email
WHERE g.email = d.email;

-- the sign-in screen offers these (instead of the dataset's most-booked, synthetic guests)
CREATE TABLE lab.demo_guests (
    guest_id   integer PRIMARY KEY REFERENCES guests (guest_id) ON DELETE CASCADE,
    persona    varchar(80) NOT NULL,
    sort_order smallint    NOT NULL
);
INSERT INTO lab.demo_guests
SELECT g.guest_id, d.persona, d.sort_order FROM demo_guest d JOIN guests g ON g.email = d.email;
GRANT SELECT ON lab.demo_guests TO yup_app, yup_lab;
COMMENT ON TABLE lab.demo_guests IS 'Hand-made demo travellers offered on the sign-in screen (02-database/seed/demo_trips.sql)';

-- ── 2. the trips ───────────────────────────────────────────────────────────
-- hotel_id and the dates are fixed; the SQL below picks a room type (tier 0 = cheapest) and free rooms.
-- change: E = extended / S = shortened by one night after booking (orig_nights = nights first booked)
CREATE TEMP TABLE demo_trip (
    trip_no int PRIMARY KEY, guest_key text, hotel_id int, booking_ref char(8), check_in date, nights int, adults int, children int,
    rooms int, rt_tier int, status booking_status_t, booked_at timestamptz, cancelled_at timestamptz, special_request text,
    method payment_method_t, first_attempt_failed boolean, change char(1), orig_nights int, changed_at timestamptz,
    rating int, review_title text, review_body text, reviewed_at timestamptz);
INSERT INTO demo_trip VALUES
    (1, 'ananya', 3058, 'YR3NUDMV', DATE '2025-03-14', 3, 2, 0, 1, 0, 'COMPLETED', '2025-01-15 10:31:26+05:30', NULL, 'Rooms on the same floor, please', 'UPI', false, NULL, NULL, NULL, 2, 'Not as described', 'The room was smaller and noisier than the listing suggested. Staff were polite but could not do much.', '2025-03-23 14:25:00+05:30'),  -- ananya: Hotel Sierra, Kodaikanal
    (2, 'harpreet', 2755, 'YR83QE8X', DATE '2025-04-12', 2, 2, 1, 1, 0, 'COMPLETED', '2025-01-24 23:00:47+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- harpreet: Hotel Sakhi Inn, Amritsar
    (3, 'karthik', 2673, 'YRX39X6M', DATE '2025-04-25', 2, 2, 1, 1, 0, 'COMPLETED', '2025-01-29 14:02:52+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, 4, 'Pleasant and peaceful', 'Staff went out of their way when our train was delayed. Rooms are comfortable.', '2025-05-02 19:51:00+05:30'),  -- karthik: The Willow Hill, Ooty
    (4, 'arjun', 1571, 'YRQZRMU3', DATE '2025-02-11', 2, 1, 0, 1, 1, 'COMPLETED', '2025-02-04 14:16:28+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 2, 'Wifi let me down', 'The connection kept dropping and I had calls to take. The front desk tried but it was not fixed.', '2025-02-16 12:00:00+05:30'),  -- arjun: Comfort Inn The President, Delhi
    (5, 'aditya', 447, 'YRG4QSBJ', DATE '2025-03-21', 2, 3, 0, 1, 0, 'COMPLETED', '2025-02-10 09:14:39+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 2, 'Not worth the money', 'Rooms were dusty and the staff seemed disinterested. Location is the only plus.', '2025-03-29 12:35:00+05:30'),  -- aditya: Chanakya Resort & Rafting, Rishikesh
    (6, 'tanvi', 1351, 'YRNPDF9U', DATE '2025-04-04', 3, 4, 0, 2, 0, 'COMPLETED', '2025-02-11 11:03:17+05:30', NULL, 'Parking for two cars, please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- tanvi: Cafe Blue, Goa
    (7, 'arjun', 885, 'YRH6B3JW', DATE '2025-04-17', 4, 2, 2, 1, 1, 'COMPLETED', '2025-02-23 17:14:12+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 3, 'Average, nothing special', 'Room was fine but the bathroom needed some maintenance. Staff were polite and breakfast was okay.', '2025-04-27 10:13:00+05:30'),  -- arjun: Soul vacation Resort & Spa, Goa
    (8, 'vikram', 785, 'YR4VV3QQ', DATE '2025-03-04', 2, 1, 0, 1, 1, 'COMPLETED', '2025-02-26 17:40:51+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 5, 'Warm hospitality', 'The owner personally checked on us twice. Home-cooked breakfast was the best meal of our trip.', '2025-03-10 12:15:00+05:30'),  -- vikram: Express 66, Delhi
    (9, 'kavya', 1971, 'YRGZD3ST', DATE '2025-03-29', 4, 4, 0, 2, 0, 'COMPLETED', '2025-03-01 07:12:48+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Mixed experience', 'Lovely rooftop but the rooms were not cleaned until we asked twice.', '2025-04-08 23:23:00+05:30'),  -- kavya: Hotel Parth Inn, Goa
    (10, 'harpreet', 1127, 'YR8EH9CB', DATE '2025-06-05', 4, 2, 2, 1, 0, 'COMPLETED', '2025-03-03 23:03:13+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 4, 'Comfortable for families', 'Plenty of space for the four of us. The pool was a hit. Wifi in the room was patchy but we were out most of the day.', '2025-06-10 17:49:00+05:30'),  -- harpreet: Sparsh Resort, Manali
    (11, 'vikram', 844, 'YR9TD3FB', DATE '2025-05-30', 5, 2, 2, 1, 1, 'COMPLETED', '2025-03-05 15:39:49+05:30', NULL, 'Pure vegetarian meals only, please', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- vikram: Flamingo Resorts, Manali
    (12, 'sourav', 335, 'YRA2H7ZC', DATE '2025-04-18', 3, 3, 0, 2, 0, 'COMPLETED', '2025-03-15 14:50:17+05:30', NULL, 'Parking for two cars, please', 'CARD', false, NULL, NULL, NULL, 1, 'Very poor housekeeping', 'The room had not been cleaned on arrival. They moved us after an hour of waiting. Not a relaxing start to the holiday.', '2025-04-24 23:29:00+05:30'),  -- sourav: Cedar Inn, Darjeeling
    (13, 'priya', 3089, 'YR7V5C5D', DATE '2025-03-18', 2, 1, 0, 1, 0, 'COMPLETED', '2025-03-15 15:41:46+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 2, 'Needs work', 'No hot water on the first morning. Fixed by evening, but we lost half a day.', '2025-03-26 10:46:00+05:30'),  -- priya: Hotel Sharda Sion, Mumbai
    (14, 'pooja', 3237, 'YRY5WEA6', DATE '2025-05-09', 4, 3, 0, 1, 0, 'COMPLETED', '2025-03-26 22:23:47+05:30', NULL, NULL, 'UPI', true, NULL, NULL, NULL, 4, 'Fun stay, would repeat', 'Great location and the staff arranged our sightseeing cab at a fair price. Rooms are a little dated.', '2025-05-17 22:45:00+05:30'),  -- pooja: Villa Gesler, Goa
    (15, 'imran', 1209, 'YRSU5QKF', DATE '2025-04-08', 2, 1, 0, 1, 0, 'COMPLETED', '2025-03-28 17:39:05+05:30', NULL, 'Late check-out at 2 pm if possible', 'NETBANKING', false, NULL, NULL, NULL, 5, 'A hidden gem', 'Found this through a friend and it did not disappoint. Great food, kind people, fair prices.', '2025-04-15 11:12:00+05:30'),  -- imran: The Beatle, Mumbai
    (16, 'meera', 2512, 'YRDJGQCM', DATE '2025-05-02', 3, 2, 2, 1, 0, 'COMPLETED', '2025-03-29 08:32:54+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 3, 'Okay for a night or two', 'Rooms are smaller than shown online and the AC was noisy. Location is good though.', '2025-05-08 11:06:00+05:30'),  -- meera: The Regency Hotel, Munnar
    (17, 'priya', 2512, 'YRB75T2T', DATE '2025-05-23', 3, 2, 0, 1, 1, 'COMPLETED', '2025-04-18 13:17:17+05:30', NULL, 'High floor, away from the road', 'UPI', false, NULL, NULL, NULL, 5, 'Better than the photos', 'Rooms are bigger than expected and everything we wanted to see was walkable.', '2025-05-31 23:01:00+05:30'),  -- priya: The Regency Hotel, Munnar
    (18, 'siddharth', 412, 'YRF69WPZ', DATE '2025-06-20', 2, 2, 1, 1, 0, 'COMPLETED', '2025-04-24 07:43:56+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- siddharth: Cama Rajputana Club Resort, Mount Abu
    (19, 'manish', 1299, 'YR527EKE', DATE '2025-05-17', 2, 4, 0, 1, 0, 'COMPLETED', '2025-04-29 09:53:27+05:30', NULL, NULL, 'PAY_AT_HOTEL', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- manish: Suraj Residency Shirdi, Shirdi
    (20, 'lakshmi', 2102, 'YR5D422P', DATE '2025-06-27', 2, 3, 0, 1, 0, 'COMPLETED', '2025-05-28 15:14:09+05:30', NULL, 'Hot water at 4 am, please', 'UPI', false, NULL, NULL, NULL, 4, 'Convenient and clean', 'Walking distance to the temple, which saved us a lot of time. Hot water took a few minutes to come.', '2025-07-04 22:31:00+05:30'),  -- lakshmi: V K Residency, Tirupati
    (21, 'rohan', 793, 'YR67U92J', DATE '2025-07-19', 2, 2, 0, 1, 1, 'COMPLETED', '2025-06-05 11:57:42+05:30', NULL, 'Celebrating our anniversary, a quiet room with a view if possible', 'UPI', false, NULL, NULL, NULL, 3, 'Good location, tired rooms', 'The property could do with a fresh coat of paint. The staff made up for it with their warmth.', '2025-07-26 18:36:00+05:30'),  -- rohan: Fantasy Villas, Lonavala
    (22, 'abhishek', 936, 'YRPTSG22', DATE '2025-07-26', 2, 4, 0, 1, 0, 'COMPLETED', '2025-06-25 11:26:26+05:30', NULL, 'Pure vegetarian kitchen only, please', 'UPI', false, NULL, NULL, NULL, 2, 'Needs work', 'No hot water on the first morning. Fixed by evening, but we lost half a day.', '2025-08-03 10:54:00+05:30'),  -- abhishek: ShreeRam Hotel, Ujjain
    (23, 'nandini', 624, 'YRJVQ3XW', DATE '2025-09-04', 3, 2, 1, 1, 0, 'COMPLETED', '2025-07-11 09:56:47+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- nandini: Emarald Pristine Island, Alleppey
    (24, 'shreya', 1091, 'YREKJCK5', DATE '2025-10-25', 2, 3, 0, 1, 0, 'COMPLETED', '2025-07-19 09:07:40+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 5, 'Grandparents were comfortable', 'Ground floor room as requested, a ramp at the entrance and very patient staff. Thank you for making it easy for my parents.', '2025-10-29 12:01:00+05:30'),  -- shreya: Shree Hare Rama Hare Krishna Guest House, Varanasi
    (25, 'gurpreet', 2438, 'YRDQ4VVS', DATE '2025-08-22', 2, 4, 0, 1, 0, 'COMPLETED', '2025-07-22 08:49:12+05:30', NULL, NULL, 'PAY_AT_HOTEL', false, NULL, NULL, NULL, 3, 'Basic but fine', NULL, '2025-08-29 17:09:00+05:30'),  -- gurpreet: Triund Regency, Katra
    (26, 'kavya', 1606, 'YR2SUGJX', DATE '2025-09-05', 2, 3, 0, 1, 0, 'COMPLETED', '2025-07-29 15:30:27+05:30', NULL, 'Rooms on the same floor, please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- kavya: Coorg Regency, Coorg
    (27, 'harpreet', 2066, 'YRQYBTAE', DATE '2025-09-12', 2, 2, 0, 1, 1, 'COMPLETED', '2025-08-01 22:39:34+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- harpreet: Hotel Pik Nik, Mussoorie
    (28, 'faisal', 1739, 'YRTSXFQR', DATE '2025-08-12', 2, 1, 0, 1, 0, 'COMPLETED', '2025-08-04 09:23:42+05:30', NULL, 'Need a proper work desk and good wifi', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- faisal: Hotel Purva, Indore
    (29, 'debashish', 2724, 'YRKDA6BM', DATE '2025-09-27', 4, 2, 1, 1, 0, 'COMPLETED', '2025-08-10 19:03:30+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- debashish: Hotel Sai Chandan Residency, Puri
    (30, 'ananya', 1354, 'YRWYZF6R', DATE '2025-09-26', 2, 1, 0, 1, 0, 'COMPLETED', '2025-08-29 17:30:30+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 2, 'Not as described', 'The room was smaller and noisier than the listing suggested. Staff were polite but could not do much.', '2025-10-02 18:45:00+05:30'),  -- ananya: Chitravana Resorts, Mysore
    (31, 'rohan', 2458, 'YRPUKQKF', DATE '2025-11-14', 3, 2, 1, 1, 0, 'COMPLETED', '2025-09-13 15:30:30+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rohan: Tiara Hideaway, Goa
    (32, 'sneha', 3083, 'YRAJEZ9P', DATE '2025-10-24', 2, 4, 0, 1, 0, 'COMPLETED', '2025-09-18 10:21:09+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Could be better', 'Check-in was smooth but the room smelled musty. They changed it quickly when we complained.', '2025-11-01 12:52:00+05:30'),  -- sneha: Hotel shivanand, Nashik
    (33, 'harpreet', 3014, 'YRN65PF6', DATE '2025-12-27', 3, 2, 2, 1, 0, 'CANCELLED', '2025-09-19 08:16:22+05:30', '2025-12-18 12:02:00+05:30', NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- harpreet: Hotel Sheel, Shimla
    (34, 'aditya', 2834, 'YRMBDG7B', DATE '2025-11-08', 2, 2, 0, 1, 1, 'COMPLETED', '2025-09-20 11:24:20+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- aditya: Hotel Sangam, Jaipur
    (35, 'siddharth', 3576, 'YRE4SRUU', DATE '2025-11-28', 3, 2, 1, 1, 0, 'COMPLETED', '2025-10-09 18:57:23+05:30', NULL, NULL, 'WALLET', false, 'S', 4, '2025-10-31 17:22:00+05:30', 4, 'Nice place for the price', 'Value for money. Not luxury, but everything works and the staff is polite.', '2025-12-05 20:50:00+05:30'),  -- siddharth: Hotel Shubh Laxmi, Udaipur
    (36, 'arjun', 3, 'YRFKAVSE', DATE '2025-12-24', 4, 2, 2, 1, 1, 'COMPLETED', '2025-10-12 12:00:49+05:30', NULL, 'Quiet room away from the lift', 'CARD', false, NULL, NULL, NULL, 4, 'Good base for sightseeing', 'Everything was an easy auto ride away. Rooms are simple but clean. Breakfast was decent.', '2025-12-31 09:39:00+05:30'),  -- arjun: Pichola Rajbagh, Udaipur
    (37, 'rahul', 1093, 'YRBDC7Y2', DATE '2025-11-05', 2, 2, 0, 1, 0, 'COMPLETED', '2025-10-15 07:33:31+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rahul: Shree Sai Kripa Guest House, Varanasi
    (38, 'debashish', 3062, 'YRKEQTC2', DATE '2025-12-22', 4, 2, 1, 1, 0, 'COMPLETED', '2025-10-20 20:19:24+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Okay for a night or two', 'Rooms are smaller than shown online and the AC was noisy. Location is good though.', '2025-12-29 17:47:00+05:30'),  -- debashish: Hotel Sarojini, Darjeeling
    (39, 'imran', 3102, 'YR3T8HRA', DATE '2025-12-12', 2, 4, 0, 1, 0, 'COMPLETED', '2025-10-29 16:21:43+05:30', NULL, 'Please help arrange a cab to the temple in the morning', 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- imran: Hotel satyam near dargah nalabazar ajmer, Ajmer
    (40, 'manish', 2538, 'YRSAUGNM', DATE '2026-01-10', 2, 4, 0, 1, 0, 'COMPLETED', '2025-10-29 18:12:01+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- manish: The Sky Court, Aurangabad
    (41, 'pooja', 2906, 'YRQ7AZJZ', DATE '2025-12-06', 2, 4, 0, 1, 0, 'COMPLETED', '2025-10-30 12:51:56+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- pooja: HOTEL SAI GOVIND, Shirdi
    (42, 'ananya', 69, 'YRS8YXKG', DATE '2025-11-21', 4, 1, 0, 1, 0, 'COMPLETED', '2025-11-07 19:15:11+05:30', NULL, 'Vegetarian meals, please', 'UPI', false, NULL, NULL, NULL, 4, 'Good stay, minor niggles', 'Clean rooms and friendly staff. Breakfast could have a few more options and the lift was slow at peak hours.', '2025-12-01 15:28:00+05:30'),  -- ananya: Bhagirathi Palace, Rishikesh
    (43, 'gurpreet', 2815, 'YRAN6Z2E', DATE '2026-01-09', 3, 4, 0, 2, 0, 'COMPLETED', '2025-11-18 07:12:46+05:30', NULL, 'Early check-in if possible, driving overnight', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- gurpreet: Hotel Royal Orchard - Manali, Manali
    (44, 'priya', 624, 'YR3XKT2E', DATE '2025-12-26', 3, 2, 0, 1, 1, 'COMPLETED', '2025-11-18 19:56:14+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- priya: Emarald Pristine Island, Alleppey
    (45, 'meera', 2183, 'YR48WJ72', DATE '2025-12-27', 3, 2, 2, 1, 0, 'COMPLETED', '2025-11-21 10:47:47+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Average, nothing special', 'Room was fine but the bathroom needed some maintenance. Staff were polite and breakfast was okay.', '2025-12-31 17:14:00+05:30'),  -- meera: Thekkady homestay, Thekkady
    (46, 'neha', 124, 'YRXR22JM', DATE '2025-12-19', 4, 2, 0, 1, 2, 'COMPLETED', '2025-11-24 15:22:10+05:30', NULL, 'Honeymoon trip. No rush at check-in please', 'CARD', false, NULL, NULL, NULL, 2, 'Expected more', 'Photos looked better than the actual rooms. The bed was comfortable though.', '2025-12-25 23:41:00+05:30'),  -- neha: Chokhi Dhani - The Palace Hotel, Jaisalmer
    (47, 'lakshmi', 812, 'YR4AUEJT', DATE '2025-12-18', 3, 2, 0, 1, 0, 'COMPLETED', '2025-11-26 22:46:09+05:30', NULL, 'Please help arrange a cab to the temple in the morning', 'UPI', false, NULL, NULL, NULL, 4, 'Pleasant and peaceful', 'Staff went out of their way when our train was delayed. Rooms are comfortable.', '2025-12-24 13:36:00+05:30'),  -- lakshmi: Dreamz Hotel, Thiruvananthapuram
    (48, 'ananya', 1606, 'YRNK3UZR', DATE '2026-01-23', 3, 2, 0, 1, 0, 'COMPLETED', '2025-12-11 22:19:22+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Decent for the price', 'You get what you pay for. Clean sheets, hot water, no frills.', '2026-02-01 22:15:00+05:30'),  -- ananya: Coorg Regency, Coorg
    (49, 'vikram', 412, 'YRY7DRUD', DATE '2026-01-23', 3, 2, 1, 1, 1, 'COMPLETED', '2025-12-12 18:08:40+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 5, 'Kids did not want to leave', 'Big rooms, friendly staff and a breakfast spread with something for everyone. Our two were asking to come back before we had checked out.', '2026-01-27 14:50:00+05:30'),  -- vikram: Cama Rajputana Club Resort, Mount Abu
    (50, 'imran', 2352, 'YRHB373T', DATE '2026-03-14', 2, 2, 2, 1, 0, 'COMPLETED', '2025-12-12 23:16:12+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, 5, 'Everything just worked', NULL, '2026-03-20 14:42:00+05:30'),  -- imran: Tourist Rest House, Agra
    (51, 'abhishek', 1299, 'YRVMTAPK', DATE '2026-01-31', 2, 4, 0, 1, 0, 'COMPLETED', '2025-12-17 22:55:03+05:30', NULL, 'Hot water at 4 am, please', 'UPI', false, NULL, NULL, NULL, 4, 'Convenient and clean', 'Walking distance to the temple, which saved us a lot of time. Hot water took a few minutes to come.', '2026-02-06 14:06:00+05:30'),  -- abhishek: Suraj Residency Shirdi, Shirdi
    (52, 'arjun', 2192, 'YRVCZTSA', DATE '2026-02-13', 3, 2, 0, 1, 2, 'COMPLETED', '2025-12-23 07:39:40+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- arjun: Trishul Desert Resort, Jaisalmer
    (53, 'kavya', 1405, 'YRT6AT52', DATE '2026-02-27', 3, 2, 0, 1, 1, 'COMPLETED', '2025-12-31 07:19:52+05:30', NULL, 'High floor, away from the road', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- kavya: County Pep Holiday Home, Wayanad
    (54, 'karthik', 1982, 'YR5K7XXW', DATE '2026-02-20', 2, 4, 0, 1, 0, 'COMPLETED', '2026-01-01 22:44:40+05:30', NULL, NULL, 'NETBANKING', false, 'E', 1, '2026-01-08 13:07:00+05:30', 3, 'Decent for the price', 'You get what you pay for. Clean sheets, hot water, no frills.', '2026-02-26 18:31:00+05:30'),  -- karthik: Hotel Pasuparthy Residency, Tirupati
    (55, 'debashish', 2788, 'YRQY2E24', DATE '2026-02-14', 3, 2, 0, 1, 0, 'COMPLETED', '2026-01-04 14:15:32+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 2, 'Not as described', 'The room was smaller and noisier than the listing suggested. Staff were polite but could not do much.', '2026-02-19 18:12:00+05:30'),  -- debashish: Hotel Sahu, Varanasi
    (56, 'faisal', 1876, 'YRJEPHQ8', DATE '2026-01-20', 3, 1, 0, 1, 0, 'NO_SHOW', '2026-01-09 21:13:50+05:30', NULL, NULL, 'PAY_AT_HOTEL', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- faisal: Hotel Plaza, Mumbai
    (57, 'meera', 1405, 'YR3CBT3H', DATE '2026-04-10', 2, 2, 2, 1, 0, 'COMPLETED', '2026-01-10 22:26:52+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, 4, 'Lovely hosts', 'The family running this place is wonderful. The room was basic but their hospitality made the stay.', '2026-04-13 15:54:00+05:30'),  -- meera: County Pep Holiday Home, Wayanad
    (58, 'rohan', 2402, 'YR5ANQ8R', DATE '2026-03-27', 2, 2, 0, 1, 1, 'COMPLETED', '2026-01-15 11:46:46+05:30', NULL, 'Honeymoon trip. No rush at check-in please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rohan: The Travellers Inn, Mahabaleshwar
    (59, 'sneha', 2895, 'YRQAHQJK', DATE '2026-02-06', 2, 4, 0, 1, 0, 'COMPLETED', '2026-01-19 17:22:24+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- sneha: Hotel Sai Laxmi, Shirdi
    (60, 'neha', 1258, 'YRJVHQBA', DATE '2026-04-03', 4, 2, 1, 1, 1, 'COMPLETED', '2026-01-30 19:56:50+05:30', NULL, 'Extra bed for our son, please', 'CARD', false, NULL, NULL, NULL, 5, 'Our best family holiday so far', 'Extra bed and baby cot were ready when we arrived. The cook made khichdi for our toddler on request. Can''t thank them enough.', '2026-04-12 18:59:00+05:30'),  -- neha: Sun Flower Beach Resort, Goa
    (61, 'rahul', 1647, 'YRSD5MPD', DATE '2026-02-21', 2, 2, 0, 1, 0, 'COMPLETED', '2026-01-31 11:30:58+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rahul: Hotel Prem Sagar, Agra
    (62, 'sourav', 1067, 'YRCASX5X', DATE '2026-04-25', 3, 2, 0, 1, 0, 'NO_SHOW', '2026-02-15 09:53:40+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- sourav: Sri Puri Palace Guest House, Puri
    (63, 'shreya', 226, 'YREAN7FD', DATE '2026-03-17', 3, 2, 0, 1, 0, 'COMPLETED', '2026-02-19 16:12:16+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- shreya: BnB in GK II, Delhi
    (64, 'nandini', 2122, 'YRH3399B', DATE '2026-03-05', 2, 1, 0, 1, 0, 'COMPLETED', '2026-02-23 20:46:47+05:30', NULL, 'Need a proper work desk and good wifi', 'CARD', false, NULL, NULL, NULL, 4, 'Smooth and professional', 'Prompt pick-up and a comfortable bed. Would like a better coffee machine.', '2026-03-13 10:18:00+05:30'),  -- nandini: Tri-Star Regency, Kochi
    (65, 'harpreet', 3005, 'YRE99TF4', DATE '2026-03-20', 2, 4, 0, 1, 0, 'COMPLETED', '2026-03-01 07:20:03+05:30', NULL, 'Please help arrange a cab to the temple in the morning', 'UPI', false, NULL, NULL, NULL, 5, 'Peaceful stay before darshan', 'Early morning tea arranged for us and the staff helped book a cab. My parents were comfortable and that is what matters.', '2026-03-25 22:13:00+05:30'),  -- harpreet: Hotel Sham Palace, Katra
    (66, 'aditya', 2267, 'YRS2GKTM', DATE '2026-05-15', 3, 2, 0, 1, 1, 'CANCELLED', '2026-03-03 07:01:46+05:30', '2026-04-30 17:19:00+05:30', 'Late check-out if available', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- aditya: The White House, Mussoorie
    (67, 'gurpreet', 2993, 'YRVEYMR4', DATE '2026-06-05', 4, 2, 2, 1, 0, 'COMPLETED', '2026-03-04 19:25:28+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, 3, 'Average, nothing special', 'Room was fine but the bathroom needed some maintenance. Staff were polite and breakfast was okay.', '2026-06-12 18:19:00+05:30'),  -- gurpreet: Hotel Sidharath, Shimla
    (68, 'debashish', 1459, 'YR328GR9', DATE '2026-06-02', 5, 2, 1, 1, 0, 'COMPLETED', '2026-03-05 11:08:43+05:30', NULL, NULL, 'UPI', true, 'E', 4, '2026-05-15 20:00:00+05:30', 1, 'Would not recommend', NULL, '2026-06-09 23:53:00+05:30'),  -- debashish: Comfort Inn, Gangtok
    (69, 'arjun', 1168, 'YRK9N3H5', DATE '2026-03-10', 2, 1, 0, 1, 1, 'COMPLETED', '2026-03-06 15:25:06+05:30', NULL, NULL, 'CARD', false, 'S', 3, '2026-03-07 19:12:00+05:30', 5, 'Would stay again', NULL, '2026-03-14 15:46:00+05:30'),  -- arjun: Skyla Serviced Apartments - Srinagar colony, Hyderabad
    (70, 'priya', 2463, 'YR76A95H', DATE '2026-04-07', 2, 1, 0, 1, 0, 'CANCELLED', '2026-03-26 07:08:15+05:30', '2026-04-01 11:18:00+05:30', 'Late check-out at 2 pm if possible', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- priya: Tri Sea Residency, Chennai
    (71, 'tanvi', 447, 'YRCJJ8TZ', DATE '2026-05-08', 3, 3, 0, 1, 0, 'CANCELLED', '2026-04-01 14:33:57+05:30', '2026-05-05 21:19:00+05:30', NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- tanvi: Chanakya Resort & Rafting, Rishikesh
    (72, 'priya', 2778, 'YRVN2UA9', DATE '2026-05-29', 4, 2, 0, 1, 1, 'COMPLETED', '2026-04-08 21:32:13+05:30', NULL, 'Late check-out if available', 'UPI', true, NULL, NULL, NULL, 5, 'Great value for money', 'Honestly better than hotels charging double. Clean room, hot water on tap and a manager who bends over backwards.', '2026-06-08 22:11:00+05:30'),  -- priya: Hotel Sanjay, Ooty
    (73, 'ananya', 364, 'YRFMG24U', DATE '2026-08-14', 6, 2, 0, 1, 0, 'COMPLETED', '2026-06-24 11:00:11+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, 5, 'Spotless and well run', 'Fresh linen, spotless bathroom, and the AC actually cools. Small things done right.', '2026-08-23 16:18:00+05:30'),  -- ananya: Camp BlueWaters, Leh
    (74, 'siddharth', 1876, 'YRX9PA6B', DATE '2026-07-14', 2, 1, 0, 1, 0, 'COMPLETED', '2026-07-05 18:52:36+05:30', NULL, 'Early check-in around 9 am, arriving by overnight train', 'CARD', false, NULL, NULL, NULL, 4, 'Good for a short stay', 'Reasonable tariff and a fast checkout. Wifi was good enough for video calls.', '2026-07-22 17:57:00+05:30'),  -- siddharth: Hotel Plaza, Mumbai
    (75, 'harpreet', 397, 'YRCDJS4T', DATE '2026-10-26', 4, 2, 2, 1, 0, 'CHECKED_IN', '2026-08-02 08:36:46+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- harpreet: Blue Bird Hotel, Jaipur
    (76, 'pooja', 2854, 'YRW2ZYPC', DATE '2026-09-18', 2, 2, 0, 1, 0, 'CANCELLED', '2026-08-03 08:41:38+05:30', '2026-09-17 22:49:00+05:30', 'Honeymoon trip. No rush at check-in please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- pooja: Hotel Sai Yash, Mahabaleshwar
    (77, 'rahul', 2078, 'YR3EA2B9', DATE '2026-08-26', 2, 1, 0, 1, 0, 'COMPLETED', '2026-08-18 14:41:10+05:30', NULL, NULL, 'UPI', true, NULL, NULL, NULL, 4, 'Solid business hotel', 'Efficient check-in, good breakfast and a decent gym. Evening room service was slow.', '2026-08-29 21:55:00+05:30'),  -- rahul: Hotel Prince Palace Deluxe, Delhi
    (78, 'imran', 2367, 'YR6E8ANV', DATE '2026-09-15', 3, 1, 0, 1, 0, 'COMPLETED', '2026-09-11 19:37:22+05:30', NULL, NULL, 'PAY_AT_HOTEL', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- imran: The Vivek, Delhi
    (79, 'sourav', 1786, 'YRWYR9PG', DATE '2026-10-27', 3, 3, 0, 2, 0, 'CHECKED_IN', '2026-09-14 17:15:46+05:30', NULL, 'Late check-in, our flight lands after midnight', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- sourav: Hotel Prestige, Darjeeling
    (80, 'rohan', 396, 'YR8HCD66', DATE '2026-12-18', 2, 2, 1, 1, 0, 'CONFIRMED', '2026-09-17 20:06:52+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rohan: Blue Country Resort, Panchgani
    (81, 'vikram', 1545, 'YRYBBAWC', DATE '2026-12-26', 4, 2, 2, 1, 1, 'CONFIRMED', '2026-09-21 07:28:29+05:30', NULL, 'Quiet room away from the lift', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- vikram: Colonia De Braganza Resort, Goa
    (82, 'debashish', 2724, 'YRQB6MQZ', DATE '2026-12-26', 4, 2, 1, 1, 0, 'CONFIRMED', '2026-09-23 11:06:50+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- debashish: Hotel Sai Chandan Residency, Puri
    (83, 'abhishek', 3015, 'YR8ZBJRJ', DATE '2026-11-14', 2, 4, 0, 1, 0, 'CONFIRMED', '2026-09-27 14:12:45+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- abhishek: Hotel Satyam Inn, Ujjain
    (84, 'gurpreet', 1889, 'YRPAP8E5', DATE '2026-12-24', 4, 2, 2, 1, 0, 'CONFIRMED', '2026-10-02 14:26:47+05:30', NULL, 'Two rooms next to each other if possible', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- gurpreet: Hotel Prince, Mussoorie
    (85, 'harpreet', 346, 'YRUFRXDP', DATE '2026-12-23', 5, 2, 2, 1, 0, 'CONFIRMED', '2026-10-04 10:22:56+05:30', NULL, 'Baby cot in the room, please', 'UPI', false, 'E', 4, '2026-10-19 14:51:00+05:30', NULL, NULL, NULL, NULL),  -- harpreet: ChanderMukhi Cottage, Manali
    (86, 'karthik', 800, 'YRYU7VY4', DATE '2026-10-08', 2, 1, 0, 1, 0, 'COMPLETED', '2026-10-05 10:57:47+05:30', NULL, 'GST invoice in the company name, please', 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- karthik: ECO Lodge, Kochi
    (87, 'aditya', 447, 'YR24HWSU', DATE '2026-11-20', 2, 4, 0, 2, 0, 'CONFIRMED', '2026-10-08 08:08:36+05:30', NULL, NULL, 'UPI', false, 'E', 1, '2026-10-20 16:44:00+05:30', NULL, NULL, NULL, NULL),  -- aditya: Chanakya Resort & Rafting, Rishikesh
    (88, 'priya', 2751, 'YR58RV37', DATE '2026-11-06', 4, 2, 0, 1, 1, 'CONFIRMED', '2026-10-08 15:37:35+05:30', NULL, 'Honeymoon trip. No rush at check-in please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- priya: Hotel Riddhi Inn, Udaipur
    (89, 'kavya', 2512, 'YRZTAH6T', DATE '2026-12-04', 3, 2, 0, 1, 1, 'CONFIRMED', '2026-10-08 20:01:18+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- kavya: The Regency Hotel, Munnar
    (90, 'priya', 3071, 'YR6VTNQC', DATE '2026-10-20', 2, 1, 0, 1, 0, 'COMPLETED', '2026-10-10 23:08:05+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- priya: Hotel Shivam International, Delhi
    (91, 'rahul', 303, 'YRMVTUBY', DATE '2026-11-24', 2, 2, 0, 1, 0, 'CONFIRMED', '2026-10-14 22:32:03+05:30', NULL, 'Please help arrange a cab to the temple in the morning', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- rahul: Buddha Guest House, Varanasi
    (92, 'manish', 197, 'YR5WV7RB', DATE '2026-12-02', 3, 4, 0, 1, 0, 'CONFIRMED', '2026-10-20 08:18:26+05:30', NULL, 'Pure vegetarian kitchen only, please', 'PAY_AT_HOTEL', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- manish: CCR Residency, Tirupati
    (93, 'arjun', 2857, 'YR7P3EFU', DATE '2026-10-28', 2, 1, 0, 1, 1, 'CHECKED_IN', '2026-10-24 07:21:24+05:30', NULL, 'Need a proper work desk and good wifi', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- arjun: Hotel Royal Star, Delhi
    (94, 'lakshmi', 2102, 'YR7NFDEY', DATE '2026-11-14', 2, 3, 0, 1, 0, 'CONFIRMED', '2026-10-24 12:54:05+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- lakshmi: V K Residency, Tirupati
    (95, 'priya', 85, 'YR64KJQ9', DATE '2026-12-27', 4, 2, 0, 1, 1, 'CONFIRMED', '2026-10-24 16:42:50+05:30', NULL, 'Room on the garden side if you have one', 'UPI', false, 'E', 3, '2026-10-26 14:11:00+05:30', NULL, NULL, NULL, NULL),  -- priya: Bay Luxe, Goa
    (96, 'sneha', 3296, 'YRXHG9WR', DATE '2026-11-20', 3, 3, 0, 1, 0, 'CONFIRMED', '2026-10-24 19:52:31+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- sneha: Villa Theresa Beach Resort, Goa
    (97, 'tanvi', 1813, 'YRG84EV5', DATE '2026-12-04', 3, 2, 0, 1, 0, 'CONFIRMED', '2026-10-25 07:13:20+05:30', NULL, NULL, 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- tanvi: Hotel Panchsheel, Jaipur
    (98, 'shreya', 1067, 'YRYJ8286', DATE '2026-12-11', 3, 3, 0, 1, 0, 'PENDING', '2026-10-27 14:01:02+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- shreya: Sri Puri Palace Guest House, Puri
    (99, 'neha', 1677, 'YRYGQP26', DATE '2026-11-27', 3, 2, 0, 1, 2, 'PENDING', '2026-10-27 15:12:04+05:30', NULL, 'Rooms close to each other for the family', 'PAY_AT_HOTEL', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- neha: Hotel Rajdarshan, Udaipur
    (100, 'arjun', 366, 'YRT2KM54', DATE '2026-12-23', 5, 2, 2, 1, 1, 'CONFIRMED', '2026-10-28 07:16:57+05:30', NULL, 'Pure vegetarian meals only, please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- arjun: Casa Colvale, Goa
    (101, 'ananya', 3370, 'YRHVV94P', DATE '2027-01-14', 3, 1, 0, 1, 0, 'CONFIRMED', '2026-10-28 13:42:33+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- ananya: YMCA International House, Kochi
    (102, 'siddharth', 2404, 'YRCE2QGS', DATE '2027-01-23', 3, 2, 1, 1, 0, 'CONFIRMED', '2026-10-28 15:28:07+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- siddharth: The Raghu Mahal, Udaipur
    (103, 'arjun', 2035, 'YR2SKVMS', DATE '2026-11-17', 2, 1, 0, 1, 1, 'CONFIRMED', '2026-10-28 16:13:08+05:30', NULL, 'Quiet room, I have calls in the evening', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- arjun: Hotel Queens Residency, Gurgaon
    (104, 'ananya', 2687, 'YR8BZFU3', DATE '2026-11-27', 4, 3, 0, 1, 0, 'CONFIRMED', '2026-10-28 16:20:15+05:30', NULL, 'Late check-in, our flight lands after midnight', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- ananya: Hotel Rishi Prasad, Goa
    (105, 'faisal', 3573, 'YRSV8KT2', DATE '2026-12-04', 2, 2, 0, 1, 0, 'CONFIRMED', '2026-10-28 17:16:51+05:30', NULL, 'Hot water at 4 am, please', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- faisal: Hotel Shubham Palace, Ajmer
    (106, 'pooja', 272, 'YRJW3VBN', DATE '2027-02-12', 4, 2, 0, 1, 0, 'CONFIRMED', '2026-10-28 17:38:51+05:30', NULL, 'Room on the garden side if you have one', 'UPI', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- pooja: CAMRON GUEST HOUSE, Goa
    (107, 'meera', 2547, 'YR2DC2UU', DATE '2026-11-12', 2, 1, 0, 1, 0, 'CONFIRMED', '2026-10-28 20:14:05+05:30', NULL, NULL, 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- meera: The Sayanora, Bangalore
    (108, 'karthik', 2673, 'YRZEFSKM', DATE '2027-01-14', 3, 2, 1, 1, 0, 'CONFIRMED', '2026-10-28 20:32:23+05:30', NULL, NULL, 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- karthik: The Willow Hill, Ooty
    (109, 'nandini', 3439, 'YRWG9ZA5', DATE '2026-12-18', 3, 2, 0, 1, 1, 'CONFIRMED', '2026-10-28 22:25:14+05:30', NULL, 'High floor, away from the road', 'CARD', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL),  -- nandini: Woodpecker Holidays, Munnar
    (110, 'imran', 2926, 'YRECPNEY', DATE '2026-12-13', 5, 2, 2, 1, 0, 'CANCELLED', '2026-10-28 23:48:44+05:30', '2026-10-29 02:48:44+05:30', 'Two rooms next to each other if possible', 'NETBANKING', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL);  -- imran: Hotel Shaneel Residency, Srinagar

-- ── 3. book them ───────────────────────────────────────────────────────────
DO $$
DECLARE
    t        demo_trip%ROWTYPE;
    g        demo_guest%ROWTYPE;
    v_guest  integer;
    v_types  integer[];
    v_type   integer;
    v_rooms  integer[];
    v_need   integer;
    v_bid    integer;
    v_out    date;
    v_first  numeric;    -- amount of the first charge (the price at booking time)
    v_total  numeric;    -- price of the stay as it stands now
    v_paid   numeric;
    v_pct    numeric;
    v_n      integer;
    i        integer;
BEGIN
    FOR t IN SELECT * FROM demo_trip ORDER BY trip_no LOOP
        SELECT d.* INTO g FROM demo_guest d WHERE d.key = t.guest_key;
        SELECT guest_id INTO v_guest FROM guests WHERE email = g.email;
        v_out := t.check_in + t.nights;

        -- room type: start at the wanted price tier, move up/around until enough free rooms exist
        SELECT array_agg(room_type_id ORDER BY base_price, room_type_id) INTO v_types FROM room_types WHERE hotel_id = t.hotel_id;
        v_n := cardinality(v_types);
        v_rooms := NULL;
        FOR i IN 0 .. v_n - 1 LOOP
            v_type := v_types[1 + (least(t.rt_tier, v_n - 1) + i) % v_n];
            SELECT greatest(t.rooms, ceil(t.adults::numeric / rt.max_adults), ceil((t.adults + t.children)::numeric / (rt.max_adults + rt.max_children)))::int
              INTO v_need FROM room_types rt WHERE rt.room_type_id = v_type;
            SELECT array_agg(x.room_id) INTO v_rooms
            FROM (SELECT r.room_id FROM rooms r
                  WHERE r.room_type_id = v_type AND r.is_active AND fn_room_is_free(r.room_id, t.check_in, v_out)
                  ORDER BY r.room_id LIMIT v_need) x;
            EXIT WHEN coalesce(cardinality(v_rooms), 0) = v_need;
            v_rooms := NULL;
        END LOOP;
        IF v_rooms IS NULL THEN
            RAISE EXCEPTION 'trip % (hotel %): no room type with enough free rooms', t.trip_no, t.hotel_id;
        END IF;

        INSERT INTO bookings (booking_ref, guest_id, hotel_id, check_in, check_out, adults, children, status, special_request, booked_at, cancelled_at)
        VALUES (t.booking_ref, v_guest, t.hotel_id, t.check_in, v_out, t.adults, t.children, t.status, t.special_request, t.booked_at, t.cancelled_at)
        RETURNING booking_id INTO v_bid;

        -- one line per room, priced night by night for the dates as they stand now
        INSERT INTO booking_rooms (booking_id, room_id, room_subtotal, room_tax)
        SELECT v_bid, rid, q.subtotal, q.tax
        FROM unnest(v_rooms) AS rid
        CROSS JOIN LATERAL (SELECT sum(nightly_rate) AS subtotal, sum(gst_amount) AS tax FROM fn_quote_stay(v_type, t.check_in, v_out)) q;

        SELECT sum(room_subtotal + room_tax) INTO v_total FROM booking_rooms WHERE booking_id = v_bid;
        v_first := v_total;
        IF t.change IS NOT NULL THEN       -- the first charge was for the original dates
            SELECT sum(q.night_total) INTO v_first
            FROM fn_quote_stay(v_type, t.check_in, t.check_in + t.orig_nights, cardinality(v_rooms)) q;
        END IF;

        -- payments (same conventions as the generated dataset)
        IF t.status NOT IN ('PENDING') AND NOT (t.method = 'PAY_AT_HOTEL' AND t.status IN ('CANCELLED', 'NO_SHOW')) THEN
            IF t.first_attempt_failed THEN
                INSERT INTO payments (booking_id, kind, method, status, amount, upi_vpa, card_last4, gateway_ref, created_at)
                VALUES (v_bid, 'CHARGE', t.method, 'FAILED', v_first,
                        CASE WHEN t.method = 'UPI' THEN g.vpa END, CASE WHEN t.method = 'CARD' THEN g.card END,
                        'pay_' || substr(md5('demo-f' || v_bid), 1, 16), t.booked_at + INTERVAL '1 minute');
            END IF;
            INSERT INTO payments (booking_id, kind, method, status, amount, upi_vpa, card_last4, gateway_ref, created_at)
            VALUES (v_bid, 'CHARGE', t.method,
                    CASE WHEN t.method = 'PAY_AT_HOTEL' AND t.status = 'CONFIRMED' THEN 'PENDING' ELSE 'SUCCESS' END::payment_status_t,
                    v_first,
                    CASE WHEN t.method = 'UPI' THEN g.vpa END, CASE WHEN t.method = 'CARD' THEN g.card END,
                    'pay_' || substr(md5('demo-c' || v_bid), 1, 16),
                    CASE WHEN t.method = 'PAY_AT_HOTEL' AND t.status IN ('COMPLETED', 'CHECKED_IN')
                         THEN (t.check_in + TIME '14:00') AT TIME ZONE 'Asia/Kolkata' ELSE t.booked_at + INTERVAL '3 minutes' END);
        END IF;
        -- extended / shortened after booking: the difference is settled like sp_modify_booking does
        IF t.change IS NOT NULL AND t.method <> 'PAY_AT_HOTEL' THEN
            IF v_total > v_first THEN
                INSERT INTO payments (booking_id, kind, method, status, amount, upi_vpa, card_last4, gateway_ref, created_at)
                VALUES (v_bid, 'CHARGE', t.method, 'SUCCESS', v_total - v_first,
                        CASE WHEN t.method = 'UPI' THEN g.vpa END, CASE WHEN t.method = 'CARD' THEN g.card END,
                        'pay_' || substr(md5('demo-x' || v_bid), 1, 16), t.changed_at);
            ELSE
                INSERT INTO payments (booking_id, kind, method, status, amount, upi_vpa, card_last4, gateway_ref, created_at)
                VALUES (v_bid, 'REFUND', t.method, 'SUCCESS', v_first - v_total,
                        CASE WHEN t.method = 'UPI' THEN g.vpa END, CASE WHEN t.method = 'CARD' THEN g.card END,
                        'rfd_' || substr(md5('demo-x' || v_bid), 1, 16), t.changed_at);
            END IF;
        END IF;

        -- cancellation refund: the same policy as sp_cancel_booking, judged on the day it was cancelled
        IF t.status = 'CANCELLED' AND t.method <> 'PAY_AT_HOTEL' THEN
            v_paid := v_total;
            v_pct := CASE WHEN t.check_in - (t.cancelled_at AT TIME ZONE 'Asia/Kolkata')::date >= 7 THEN 1.00
                          WHEN t.check_in - (t.cancelled_at AT TIME ZONE 'Asia/Kolkata')::date >= 2 THEN 0.50 ELSE 0 END;
            IF v_pct > 0 THEN
                INSERT INTO payments (booking_id, kind, method, status, amount, upi_vpa, card_last4, gateway_ref, created_at)
                VALUES (v_bid, 'REFUND', t.method, 'SUCCESS', round(v_paid * v_pct, 2),
                        CASE WHEN t.method = 'UPI' THEN g.vpa END, CASE WHEN t.method = 'CARD' THEN g.card END,
                        'rfd_' || substr(md5('demo-r' || v_bid), 1, 16), t.cancelled_at + INTERVAL '1 hour');
            END IF;
        END IF;

        -- review (trg_reviews_guard: completed stays only, after check-out; trg_reviews_rollup updates the hotel)
        IF t.rating IS NOT NULL THEN
            INSERT INTO reviews (booking_id, rating, title, body, created_at)
            VALUES (v_bid, t.rating, t.review_title, t.review_body, t.reviewed_at);
        END IF;
    END LOOP;
END $$;

ANALYZE guests; ANALYZE bookings; ANALYZE booking_rooms; ANALYZE payments; ANALYZE reviews;
REFRESH MATERIALIZED VIEW mv_city_performance;

SELECT count(*) AS demo_travellers FROM lab.demo_guests;
SELECT status, count(*) AS demo_trips FROM bookings b JOIN lab.demo_guests d USING (guest_id) GROUP BY status ORDER BY 2 DESC;

