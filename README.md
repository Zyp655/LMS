<p align="center">
  <h1 align="center">🎓 Alarmm — Learning Management System</h1>
  <p align="center">
    Nền tảng học tập trực tuyến toàn diện cho <strong>Sinh viên</strong>, <strong>Giảng viên</strong> và <strong>Quản trị viên</strong>.
    <br />
    Xây dựng bằng <strong>Flutter</strong> &times; <strong>Dart Frog</strong> theo kiến trúc <strong>Clean Architecture</strong>.
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart_Frog-Backend-00D2B8?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/SQLite-Offline-003B57?logo=sqlite&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/OpenAI-GPT--4o-412991?logo=openai&logoColor=white" />
</p>

---

## 📖 Giới thiệu

**Alarmm** là ứng dụng di động LMS hỗ trợ toàn bộ quy trình giảng dạy và học tập trực tuyến tại môi trường đại học. Hệ thống cung cấp:

- **Quản lý khóa học & bài giảng** với video player, tiến độ học tập, bình luận.
- **Quiz multiplayer** real-time qua WebSocket, bảng xếp hạng.
- **AI Academic Mentor** — chatbot GPT-4o hỗ trợ giải đáp, tóm tắt bài giảng, đề xuất cá nhân hóa.
- **Chống gian lận** — xác minh người học bằng AI Quiz tự động khi xem video.
- **Học offline** — tải nội dung, đồng bộ khi có mạng.
- **Push Notifications** — qua Firebase Cloud Messaging.
- **Hệ thống phân tích** với heatmap, velocity, benchmark.
- **Admin dashboard** quản lý người dùng, khóa học, cấu trúc học thuật.

---

## ✨ Tính năng theo vai trò

### 👨‍🎓 Sinh viên

| Module | Mô tả |
|---|---|
| **Course** | Catalog, xem bài giảng video (Chewie), theo dõi tiến độ, bình luận |
| **Quiz** | Làm quiz, multiplayer real-time (WebSocket), bảng xếp hạng |
| **Schedule** | Thời khóa biểu (Syncfusion Calendar), nhập từ Excel |
| **Analytics** | Dashboard cá nhân: heatmap, velocity, benchmark |
| **Task** | Quản lý công việc cá nhân (CRUD) |
| **Offline** | Tải nội dung, học không cần mạng, tự đồng bộ |
| **Chat** | Chatbot AI Academic Mentor (GPT-4o), Speech-to-Text (Whisper) |
| **Roadmap** | Lộ trình học Backend / Frontend Developer |
| **Discussion** | Thảo luận bài học theo luồng |
| **Profile** | Thành tích, bảng điểm, cài đặt cá nhân |

### 👨‍🏫 Giảng viên

| Module | Mô tả |
|---|---|
| **Teaching** | Dashboard riêng, quản lý lớp/môn, tạo bài giảng, upload video |
| **Quiz** | Tạo quiz, xem kết quả sinh viên |
| **Attendance** | Điểm danh, quản lý submissions |
| **Discussion** | Trả lời thảo luận sinh viên |
| **Notifications** | Push thông báo đến lớp |

### 🛡️ Quản trị viên

| Module | Mô tả |
|---|---|
| **Admin** | Dashboard tổng quát, quản lý user (ban/unban) |
| **Academic** | Quản lý khoa, bộ môn, lớp, môn học |
| **Import** | Nhập sinh viên/giảng viên/môn học từ Excel |
| **Course Mgmt** | Gán giảng viên, tạo/xóa lớp môn học |
| **Tools** | Seed data, migrate, trigger cron jobs |

---

## 🏗️ Kiến trúc

```
Clean Architecture + BLoC/Cubit
│
├── lib/
│   ├── core/                    # Shared: API, theme, routing, utils, widgets
│   │   ├── api/                 # HTTP client, interceptors
│   │   ├── route/               # GoRouter config
│   │   ├── theme/               # Design tokens, app theme
│   │   ├── services/            # FCM, local notifications
│   │   ├── widgets/             # Reusable UI components
│   │   └── utils/               # Helpers, formatters
│   │
│   ├── features/                # 18 feature modules
│   │   └── [feature]/
│   │       ├── data/            # Models, DataSources, Repository Impl
│   │       ├── domain/          # Entities, Repositories (abstract), UseCases
│   │       └── presentation/    # BLoC/Cubit, Pages, Widgets
│   │
│   ├── di/                      # Dependency injection setup
│   └── main.dart                # Entry point
│
├── backend/                     # Dart Frog API Server
│   ├── routes/                  # ~160 REST endpoints (34 route groups)
│   │   ├── auth/                # Login, signup, password reset, FCM
│   │   ├── courses/             # CRUD courses, enrollment
│   │   ├── teaching/            # Teacher-specific APIs
│   │   ├── quiz/                # Quiz CRUD, multiplayer WebSocket
│   │   ├── ai/                  # GPT chat, summarize, verify-watching, STT
│   │   ├── analytics/           # Heatmap, velocity, benchmark, tracking
│   │   ├── admin/               # User mgmt, import, seed, migration
│   │   ├── notifications/       # Push notification dispatch
│   │   └── ...                  # 26 more route groups
│   └── lib/                     # Shared backend logic, DB access
│
└── test/                        # Unit & Widget tests
```

---

## 🛠️ Tech Stack

| Layer | Công nghệ |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.9.2) |
| **State Management** | flutter_bloc, Cubit |
| **Routing** | GoRouter |
| **DI** | GetIt |
| **Backend** | Dart Frog |
| **Database** | PostgreSQL (server), SQLite via sqflite (offline) |
| **Auth** | JWT (custom) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **AI** | OpenAI GPT-4o-mini, Whisper (STT) |
| **Real-time** | WebSocket (web_socket_channel) |
| **Video** | video_player + Chewie |
| **Calendar** | Syncfusion Flutter Calendar |
| **Charts** | fl_chart, percent_indicator |
| **Animations** | flutter_animate, animated_text_kit, shimmer, Rive |
| **Networking** | http |
| **Offline** | sqflite, connectivity_plus, path_provider |
| **Caching** | cached_network_image, shared_preferences |
| **Testing** | flutter_test, mocktail, bloc_test |

---

## 🚀 Cài đặt & Chạy

### Yêu cầu

- Flutter SDK `^3.9.2`
- Dart SDK `^3.9.2`
- PostgreSQL (cho backend)
- Docker (tùy chọn — có sẵn `docker-compose.yaml`)

### 1. Frontend (Mobile App)

```bash
flutter pub get
flutter run
```

### 2. Backend (Dart Frog Server)

```bash
cd backend
dart pub get

# Tạo file .env từ mẫu, cấu hình:
#   DATABASE_URL, JWT_SECRET, OPENAI_API_KEY, ...

dart_frog dev
```

### 3. Database (Docker)

```bash
cd backend
docker-compose up -d
```

### 4. Chạy Tests

```bash
flutter test
```

---

## 📂 Feature Modules

| # | Module | Layers | Vai trò |
|---|---|---|---|
| 1 | `admin` | data · domain · presentation | 🛡️ Admin |
| 2 | `analytics` | data · domain · presentation | 👨‍🎓 👨‍🏫 |
| 3 | `auth` | data · domain · presentation | Tất cả |
| 4 | `chat` | data · domain · presentation | 👨‍🎓 |
| 5 | `course` | data · domain · presentation | 👨‍🎓 |
| 6 | `discussion` | data · domain · presentation | Tất cả |
| 7 | `home` | presentation | Tất cả |
| 8 | `notifications` | data · domain · presentation | Tất cả |
| 9 | `offline` | data · domain · presentation | 👨‍🎓 |
| 10 | `profile` | presentation | 👨‍🎓 |
| 11 | `quiz` | data · domain · presentation | Tất cả |
| 12 | `roadmap` | presentation | 👨‍🎓 |
| 13 | `schedule` | data · domain · presentation | 👨‍🎓 |
| 14 | `search` | data · domain · presentation | Tất cả |
| 15 | `social` | data · domain · presentation | 👨‍🎓 |
| 16 | `task` | data · domain · presentation | 👨‍🎓 |
| 17 | `teaching` | data · domain · presentation | 👨‍🏫 |
| 18 | `user` | data · domain · presentation | Tất cả |

---

## 🔐 Phân quyền

| Role | Giá trị | Màn hình chính |
|---|---|---|
| Sinh viên | `0` | `MainWrapperPage` — 6 tab bottom navigation |
| Giảng viên | `1` | `TeacherHomePage` — dashboard riêng |
| Admin | `2` | `AdminHomePage` — quản trị hệ thống |

---

## 🌐 Backend API Overview

34 route groups, ~160 endpoints:

```
auth/        → login, signup, forgot-password, change-password, fcm-token
courses/     → CRUD, enrollment, progress tracking
teaching/    → Teacher dashboard, class management
quiz/        → CRUD, sessions, multiplayer WebSocket, leaderboard
ai/          → chat, summarize, verify-watching, speech-to-text, extract-document
analytics/   → summary, heatmap, velocity, benchmark, track
admin/       → users, import, seed, migration, ban, academic mgmt
schedule/    → CRUD events, calendar sync
notifications/ → send, history, mark-read
discussions/ → threads, replies
comments/    → lesson comments
tasks/       → personal task CRUD
content/     → file management, uploads
search/      → full-text search
roadmaps/    → learning path progression
enrollments/ → student enrollment
```

---

## 🌍 Đa ngôn ngữ

Hỗ trợ **Tiếng Việt** và **Tiếng Anh** thông qua Flutter Intl (ARB files). Người dùng chuyển đổi ngôn ngữ trong trang Profile.

---

## 📄 License

Private project — All rights reserved.
