SET client_encoding = 'UTF8';

-- 1. DEPARTMENTS (tên đầy đủ dấu tiếng Việt)
INSERT INTO departments (name, code, description, created_at) VALUES
  ('Khoa Công nghệ Thông tin', 'CNTT', 'Đào tạo ngành Công nghệ thông tin, Kỹ thuật phần mềm, Hệ thống thông tin', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Điện - Điện tử', 'DDT', 'Đào tạo ngành Điện, Điện tử, Tự động hóa', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Cơ khí', 'CK', 'Đào tạo ngành Cơ khí chế tạo, Cơ điện tử', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Xây dựng', 'XD', 'Đào tạo ngành Xây dựng dân dụng và công nghiệp', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Quản trị Kinh doanh', 'QTKD', 'Đào tạo ngành Quản trị, Marketing, Tài chính', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Kinh tế', 'KT', 'Đào tạo ngành Kinh tế, Tài chính ngân hàng, Kế toán', EXTRACT(EPOCH FROM NOW())::BIGINT),
  ('Khoa Ngoại ngữ', 'NN', 'Đào tạo ngành Ngôn ngữ Anh, Nhật, Hàn, Trung', EXTRACT(EPOCH FROM NOW())::BIGINT)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. TEACHERS: 100 per department
INSERT INTO users (email, password_hash, full_name, role, department_id)
SELECT
  'gv' || LPAD((ROW_NUMBER() OVER ())::TEXT, 3, '0') || '@lms.edu.vn',
  '$2a$10$UN9AeMhURtHkCXG9d6.J8g4CUesI8hxKYQKz3v0sE1v5GzYrU9bnO',
  (ARRAY['Nguyễn Văn','Trần Thị','Lê Văn','Phạm Thị','Hoàng Văn','Vũ Thị','Đặng Văn','Bùi Thị','Đỗ Văn','Ngô Thị'])[(((d.dept_idx - 1) * 100 + s.n - 1) % 10) + 1]
    || ' ' ||
  (ARRAY['An','Bình','Cường','Dũng','Em','Phúc','Giang','Hải','Khoa','Lan','Minh','Nam','Oanh','Phong','Quân','Sơn','Tâm','Uyên','Vinh','Yến'])[(((d.dept_idx - 1) * 100 + s.n - 1) % 20) + 1],
  1,
  d.dept_id
FROM
  (SELECT id AS dept_id, ROW_NUMBER() OVER (ORDER BY id) AS dept_idx FROM departments) d
  CROSS JOIN generate_series(1, 100) AS s(n)
ON CONFLICT (email) DO NOTHING;

-- 3. STUDENTS: 10000 per department
INSERT INTO users (email, password_hash, full_name, role, department_id)
SELECT
  'sv' || LPAD((ROW_NUMBER() OVER ())::TEXT, 5, '0') || '@lms.edu.vn',
  '$2a$10$UN9AeMhURtHkCXG9d6.J8g4CUesI8hxKYQKz3v0sE1v5GzYrU9bnO',
  (ARRAY['Nguyễn','Trần','Lê','Phạm','Hoàng','Vũ','Đặng','Bùi','Đỗ','Ngô','Dương','Lý','Hà','Phan','Mai'])[((gn - 1) % 15) + 1]
    || ' ' ||
  (ARRAY['Văn','Thị','Đức','Minh','Thanh','Ngọc','Quốc','Thủy','Hồng','Anh'])[((gn - 1) % 10) + 1]
    || ' ' ||
  (ARRAY['An','Bình','Cường','Dũng','Em','Phúc','Giang','Hải','Khoa','Lan','Minh','Nam','Oanh','Phong','Quân','Sơn','Tâm','Uyên','Vinh','Yến','Đạt','Hùng','Thắng','Linh','Trung','Hà','Tùng','Nga','Tuấn','Hương','Long','Thảo','Kiên','Ngân','Dung','Trang','Huy','Mai','Quang','Hiền'])[((gn - 1) % 40) + 1],
  0,
  dept_id
FROM (
  SELECT
    d.id AS dept_id,
    d.code AS dept_code,
    d.dept_idx,
    s.n AS student_num,
    ((d.dept_idx - 1) * 10000 + s.n) AS gn
  FROM
    (SELECT id, code, ROW_NUMBER() OVER (ORDER BY id) AS dept_idx FROM departments) d
    CROSS JOIN generate_series(1, 10000) AS s(n)
) sub
ON CONFLICT (email) DO NOTHING;

-- 4. STUDENT PROFILES
INSERT INTO student_profiles (user_id, full_name, student_id, major, department_id, student_class, academic_year)
SELECT
  u.id,
  u.full_name,
  d.code || (2022 + ((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id) - 1) / 2500)) || LPAD((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id))::TEXT, 5, '0'),
  d.code,
  d.id,
  d.code || (2022 + ((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id) - 1) / 2500)) || '_' || LPAD((((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id) - 1) % 50) + 1)::TEXT, 2, '0'),
  (2022 + ((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id) - 1) / 2500)) || '-' || (2026 + ((ROW_NUMBER() OVER (PARTITION BY u.department_id ORDER BY u.id) - 1) / 2500))
FROM users u
JOIN departments d ON u.department_id = d.id
WHERE u.role = 0
  AND NOT EXISTS (SELECT 1 FROM student_profiles sp WHERE sp.user_id = u.id);

-- 5. ACADEMIC COURSES — Khoa Công nghệ Thông tin (CNTT)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Lập trình Java',                'INT1340', 3, 'required', 'Ngôn ngữ Java: OOP, Collections, Stream API'),
  ('Cơ sở dữ liệu',               'INT1341', 3, 'required', 'SQL, thiết kế ERD, chuẩn hóa và tối ưu truy vấn'),
  ('Mạng máy tính',                'INT1342', 3, 'required', 'Mô hình OSI, TCP/IP, định tuyến và bảo mật mạng'),
  ('Trí tuệ nhân tạo',             'INT1343', 3, 'required', 'Machine Learning, Neural Network, NLP cơ bản'),
  ('Cấu trúc dữ liệu và giải thuật','INT1344', 3, 'required', 'Mảng, danh sách liên kết, cây, đồ thị và thuật toán sắp xếp'),
  ('Lập trình Web',                'INT1345', 3, 'required', 'HTML, CSS, JavaScript, React và Node.js'),
  ('Hệ điều hành',                 'INT1346', 3, 'required', 'Quản lý tiến trình, bộ nhớ, hệ thống tệp'),
  ('An toàn thông tin',            'INT1347', 3, 'elective', 'Mã hóa, xác thực, tấn công và phòng thủ mạng'),
  ('Phát triển ứng dụng di động',  'INT1348', 3, 'elective', 'Flutter, React Native và phát triển đa nền tảng'),
  ('Đồ án tốt nghiệp',            'INT1499', 6, 'required', 'Đồ án tốt nghiệp ngành Công nghệ Thông tin')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'CNTT'
ON CONFLICT (code) DO NOTHING;

-- 6. ACADEMIC COURSES — Khoa Điện - Điện tử (DDT)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Mạch điện',                   'ELE101', 3, 'required', 'Phân tích mạch điện một chiều và xoay chiều'),
  ('Điện tử số',                  'ELE102', 3, 'required', 'Thiết kế mạch số, cổng logic và flip-flop'),
  ('Xử lý tín hiệu số',          'ELE201', 3, 'required', 'Biến đổi Fourier, lọc số và ứng dụng'),
  ('Hệ thống nhúng',              'ELE202', 3, 'required', 'Lập trình vi điều khiển ARM, RTOS'),
  ('Điện tử công suất',           'ELE301', 3, 'elective', 'Bộ chỉnh lưu, nghịch lưu và biến tần'),
  ('Tự động hoá công nghiệp',     'ELE302', 3, 'elective', 'PLC, SCADA và hệ thống điều khiển'),
  ('Vi điều khiển',               'ELE303', 3, 'required', 'Lập trình vi điều khiển 8051, AVR, PIC'),
  ('Truyền thông công nghiệp',    'ELE401', 3, 'elective', 'Modbus, Profibus, Ethernet công nghiệp'),
  ('Robot học',                    'ELE402', 3, 'elective', 'Động học, điều khiển robot công nghiệp'),
  ('Đồ án tốt nghiệp',           'ELE499', 6, 'required', 'Đồ án tốt nghiệp ngành Điện - Điện tử')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'DDT'
ON CONFLICT (code) DO NOTHING;

-- 7. ACADEMIC COURSES — Khoa Cơ khí (CK)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Cơ học kỹ thuật',             'ME101', 3, 'required', 'Tĩnh học, động học và động lực học'),
  ('Sức bền vật liệu',           'ME102', 3, 'required', 'Ứng suất, biến dạng và phá huỷ vật liệu'),
  ('Nhiệt động lực học',          'ME201', 3, 'required', 'Nguyên lý nhiệt động và truyền nhiệt'),
  ('Thiết kế máy',                'ME202', 3, 'required', 'Thiết kế chi tiết máy: trục, bánh răng, ổ lăn'),
  ('Gia công cơ khí',             'ME301', 3, 'required', 'Tiện, phay, bào, mài và công nghệ CNC'),
  ('CAD/CAM/CNC',                 'ME302', 3, 'elective', 'Thiết kế và lập trình gia công trên máy tính'),
  ('Vật liệu học',                'ME303', 3, 'required', 'Cấu trúc, tính chất cơ lý của kim loại và hợp kim'),
  ('Cơ điện tử',                  'ME401', 3, 'elective', 'Tích hợp cơ khí, điện tử và điều khiển'),
  ('Kỹ thuật ô tô',              'ME402', 3, 'elective', 'Kết cấu động cơ, hệ truyền lực và khung gầm'),
  ('Đồ án tốt nghiệp',           'ME499', 6, 'required', 'Đồ án tốt nghiệp ngành Cơ khí')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'CK'
ON CONFLICT (code) DO NOTHING;

-- 8. ACADEMIC COURSES — Khoa Xây dựng (XD)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Cơ học kết cấu',              'CE101', 3, 'required', 'Phân tích nội lực dầm, khung, giàn'),
  ('Địa kỹ thuật',                'CE102', 3, 'required', 'Cơ học đất, nền móng công trình'),
  ('Kết cấu bê tông cốt thép',   'CE201', 3, 'required', 'Thiết kế cấu kiện bê tông theo TCVN'),
  ('Kết cấu thép',                'CE202', 3, 'required', 'Thiết kế kết cấu thép nhà công nghiệp'),
  ('Thi công xây dựng',           'CE301', 3, 'required', 'Biện pháp thi công đào đất, đổ bê tông, lắp ghép'),
  ('Quản lý dự án xây dựng',     'CE302', 3, 'elective', 'Lập tiến độ, dự toán và quản lý chất lượng'),
  ('Kỹ thuật môi trường',         'CE303', 3, 'elective', 'Cấp thoát nước và xử lý nước thải'),
  ('Quy hoạch đô thị',           'CE401', 3, 'elective', 'Thiết kế đô thị, giao thông và hạ tầng'),
  ('BIM trong xây dựng',          'CE402', 3, 'elective', 'Mô hình thông tin công trình Revit, Navisworks'),
  ('Đồ án tốt nghiệp',           'CE499', 6, 'required', 'Đồ án tốt nghiệp ngành Xây dựng')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'XD'
ON CONFLICT (code) DO NOTHING;

-- 9. ACADEMIC COURSES — Khoa Quản trị Kinh doanh (QTKD)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Quản trị học',                'BA101', 3, 'required', 'Chức năng quản trị: hoạch định, tổ chức, lãnh đạo, kiểm soát'),
  ('Marketing căn bản',           'BA102', 3, 'required', 'Chiến lược 4P, hành vi người tiêu dùng'),
  ('Kế toán đại cương',           'BA201', 3, 'required', 'Nguyên lý kế toán, bảng cân đối và báo cáo tài chính'),
  ('Quản trị tài chính',          'BA202', 3, 'required', 'Giá trị thời gian tiền tệ, quản lý vốn lưu động'),
  ('Quản trị nhân sự',           'BA301', 3, 'required', 'Tuyển dụng, đào tạo, đánh giá và đãi ngộ nhân viên'),
  ('Thương mại điện tử',          'BA302', 3, 'elective', 'Mô hình kinh doanh trực tuyến và thanh toán điện tử'),
  ('Quản trị chuỗi cung ứng',    'BA303', 3, 'elective', 'Logistics, kho bãi và quản lý nhà cung cấp'),
  ('Khởi nghiệp',                'BA401', 3, 'elective', 'Lean Startup, lập kế hoạch kinh doanh'),
  ('Quản trị chiến lược',        'BA402', 3, 'elective', 'Phân tích SWOT, mô hình Porter, chiến lược cạnh tranh'),
  ('Đồ án tốt nghiệp',           'BA499', 6, 'required', 'Đồ án tốt nghiệp ngành Quản trị Kinh doanh')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'QTKD'
ON CONFLICT (code) DO NOTHING;

-- 10. ACADEMIC COURSES — Khoa Kinh tế (KT)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Kinh tế vi mô',              'ECO101', 3, 'required', 'Cung cầu, co giãn, hành vi người tiêu dùng và doanh nghiệp'),
  ('Kinh tế vĩ mô',              'ECO102', 3, 'required', 'GDP, lạm phát, thất nghiệp và chính sách tài khóa'),
  ('Nguyên lý kế toán',          'ECO201', 3, 'required', 'Hệ thống tài khoản, sổ cái và bảng cân đối'),
  ('Tài chính doanh nghiệp',     'ECO202', 3, 'required', 'Quản lý vốn, đầu tư và phân tích tài chính'),
  ('Thống kê kinh tế',           'ECO301', 3, 'required', 'Mô tả dữ liệu, ước lượng, kiểm định giả thuyết'),
  ('Kinh tế lượng',              'ECO302', 3, 'elective', 'Hồi quy tuyến tính, đa biến và chuỗi thời gian'),
  ('Tài chính ngân hàng',        'ECO303', 3, 'elective', 'Tín dụng, lãi suất, quản lý rủi ro ngân hàng'),
  ('Kinh tế quốc tế',            'ECO401', 3, 'elective', 'Thương mại quốc tế, tỷ giá và cán cân thanh toán'),
  ('Thuế và luật thuế',          'ECO402', 3, 'elective', 'Thuế GTGT, TNDN, TNCN và kê khai thuế'),
  ('Đồ án tốt nghiệp',          'ECO499', 6, 'required', 'Đồ án tốt nghiệp ngành Kinh tế')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'KT'
ON CONFLICT (code) DO NOTHING;

-- 11. ACADEMIC COURSES — Khoa Ngoại ngữ (NN)
INSERT INTO academic_courses (name, code, credits, department_id, course_type, description, is_published, created_at)
SELECT c.name, c.code, c.credits, d.id, c.course_type, c.description, true, EXTRACT(EPOCH FROM NOW())::BIGINT
FROM departments d
CROSS JOIN (VALUES
  ('Tiếng Anh giao tiếp',        'ENG101', 2, 'required', 'Kỹ năng nghe nói giao tiếp hàng ngày'),
  ('Ngữ pháp tiếng Anh',         'ENG102', 3, 'required', 'Thì, câu điều kiện, mệnh đề quan hệ'),
  ('Kỹ năng viết học thuật',      'ENG201', 3, 'required', 'Viết luận, tóm tắt và báo cáo bằng tiếng Anh'),
  ('Luyện thi TOEIC',            'ENG202', 3, 'required', 'Luyện đề Listening và Reading TOEIC 4 kỹ năng'),
  ('Tiếng Anh chuyên ngành IT',  'ENG301', 3, 'elective', 'Thuật ngữ CNTT, đọc tài liệu kỹ thuật tiếng Anh'),
  ('Tiếng Nhật N5-N4',           'JPN101', 3, 'elective', 'Hiragana, Katakana, Kanji cơ bản và ngữ pháp N5-N4'),
  ('Tiếng Nhật giao tiếp',       'JPN102', 3, 'elective', 'Hội thoại tiếng Nhật trong đời sống và công việc'),
  ('Tiếng Hàn cơ bản',           'KOR101', 3, 'elective', 'Hangul, ngữ pháp và từ vựng TOPIK I'),
  ('Phiên dịch Anh-Việt',        'ENG401', 3, 'elective', 'Kỹ thuật dịch thuật Anh-Việt và Việt-Anh'),
  ('Đồ án tốt nghiệp',          'ENG499', 6, 'required', 'Đồ án tốt nghiệp ngành Ngoại ngữ')
) AS c(name, code, credits, course_type, description)
WHERE d.code = 'NN'
ON CONFLICT (code) DO NOTHING;

