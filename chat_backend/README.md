# 🚀 Chat App Backend API (Node.js + MySQL + Redis + Socket.io)

An ultra-lightweight, high-performance real-time Chat Backend API built with **Node.js, Express, TypeScript, MySQL (Prisma ORM), Redis, and Socket.io**. Features pure Google OAuth2 login, sub-millisecond Redis caching (all GET requests served from cache), full media support (images, videos, any file sharing, ZIP), forward without download, device gallery auto-save headers, emoji reactions, message replies, unsend, and delete-for-me.

---

## ⚡ Core Highlights

- **Panir Moto Halka & Smooth (Ultra-Fast Performance)**:
  - **Write-Through / Cache-Aside Caching**: Every write hits MySQL first, then immediately syncs into Redis.
  - **Redis-First GET Requests**: All user profiles, settings, chat lists, and message histories are served directly from Redis memory with configured TTLs.
  - **Clean Code Architecture**: Strictly modular. No single file exceeds 250 lines of code.
- **Authentication**: Pure Google Login (Google OAuth2 ID token verification + JWT access & refresh tokens).
- **Messaging & Media**:
  - Multiple image and video sending.
  - Any file sharing (ZIP, RAR, PDF, APK, etc.).
  - **Forwarding without download**: Clones attachment pointers directly on the server without re-downloading or re-uploading.
  - **Media Download with Auto-Save Header**: API returns `X-Auto-Save-Gallery: true` when user has auto-save enabled, allowing mobile/desktop clients to save directly to the device gallery.
  - **User Settings Toggle**: On/off toggle for auto-saving to gallery and media auto-download preferences.
- **Message Operations**:
  - **Unsend (Delete for everyone)**: Replaces text with unsent flag in MySQL & Redis, broadcasts via Socket.
  - **Delete for me**: Hides messages for the requesting user while preserving for others.
  - **Replies**: Quote reply referencing parent message.
  - **Reactions**: Add and toggle emoji reactions (👍, ❤️, 😂, etc.).
- **Docker & VPS Deployment**:
  - Production-ready `Dockerfile` and `docker-compose.yml`.
  - Zero-downtime updates on VPS using `./deploy.sh`.

---

## 📂 Project Structure

```
chat_backend/
├── docker-compose.yml        # Docker compose (App + MySQL + Redis)
├── Dockerfile                # Multi-stage optimized Alpine Dockerfile
├── deploy.sh                 # 1-command VPS deployment script
├── prisma/
│   └── schema.prisma         # MySQL Schema (Users, Chats, Messages, Attachments, Reactions)
├── uploads/                  # Persistent uploads directory
│   ├── avatars/
│   ├── images/
│   ├── videos/
│   └── files/
└── src/
    ├── config/               # Database, Redis, Env, Constants & TTL
    ├── middlewares/          # Auth JWT, Upload Multer, Error, Validation
    ├── utils/                # Response formatter, Token, Logger, File helper
    ├── services/             # Redis Cache Service, Google Auth Service
    ├── modules/
    │   ├── auth/             # Google Login & Token Refresh
    │   ├── user/             # Profile, Avatar & Settings (Auto-save)
    │   ├── chat/             # Direct (1-on-1) & Group conversations
    │   ├── message/          # Messages, Forward, Reply, Unsend, Reactions
    │   ├── media/            # Download & Streaming with Gallery Headers
    │   └── socket/           # Realtime Socket.io, Presence & Typing
    ├── app.ts                # Express application configuration
    └── server.ts             # Entrypoint & Graceful Shutdown
```

---

## 🚀 Quick Start (Local Development)

### 1. Prerequisites
- Node.js (v20+ or v22+)
- Docker & Docker Compose (or local MySQL and Redis)

### 2. Setup Environment
```bash
cp .env.example .env
```
Fill in your Google Client ID and JWT secret in `.env`.

### 3. Start Database & Redis via Docker
```bash
docker compose up -d mysql redis
```

### 4. Push Database Schema & Generate Prisma Client
```bash
npm run prisma:push
```

### 5. Start Development Server (Hot Reload)
```bash
npm run dev
```
The server will start at `http://localhost:5000`.

---

## 🐳 VPS Deployment with Docker

### 1. First-time Deployment
```bash
git clone <your-repo-url>
cd chat_backend
cp .env.example .env # edit environment variables
docker compose up -d --build
docker compose exec app npx prisma db push
```

### 2. Updating on VPS (One Command)
Whenever you push changes, simply execute:
```bash
./deploy.sh
```
This script automatically pulls latest changes, rebuilds containers, runs database schema updates, and verifies health check without manual intervention!

---

## 📡 API Endpoints Documentation

### 1. Authentication (`/api/auth`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/google` | Google SSO Login (body: `{ "idToken": "..." }`) |
| `POST` | `/api/auth/refresh` | Refresh Access Token (body: `{ "refreshToken": "..." }`) |

### 2. Users & Settings (`/api/users`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/users/me` | Get current user profile & settings *(Cached in Redis)* |
| `GET` | `/api/users/search?q=query` | Search users to start new chat *(Cached in Redis)* |
| `GET` | `/api/users/:id` | Get user profile by ID *(Cached in Redis)* |
| `PUT` | `/api/users/profile` | Update profile: `name`, `bio`, `status` |
| `POST` | `/api/users/avatar` | Upload avatar image (multipart form-data: `avatar`) |
| `PUT` | `/api/users/settings` | Update settings: `autoSaveToGallery` (boolean), `mediaAutoDownload` |

### 3. Chats (`/api/chats`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/chats` | Get all user chats with last message & unread status *(Cached in Redis)* |
| `POST` | `/api/chats/direct` | Start or get 1-on-1 direct chat (body: `{ "recipientId": "..." }`) |
| `POST` | `/api/chats/group` | Create group chat (body: `{ "name": "...", "memberIds": [...] }`) |
| `GET` | `/api/chats/:id` | Get chat details *(Cached in Redis)* |

### 4. Messages (`/api/messages`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/messages/:chatId?page=1&limit=30` | Get paginated chat messages *(Served from Redis)* |
| `POST` | `/api/messages` | Send message (multipart: `chatId`, `text`, `replyToId`, `files`) |
| `POST` | `/api/messages/forward` | Forward message without re-downloading (`messageId`, `targetChatIds`) |
| `DELETE` | `/api/messages/:id/unsend` | Unsend message for everyone |
| `DELETE` | `/api/messages/:id/delete-for-me` | Delete message for current user only |
| `POST` | `/api/messages/:id/react` | Toggle emoji reaction (body: `{ "emoji": "❤️" }`) |

### 5. Media & Downloads (`/api/media`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/media/download/:attachmentId` | Download file with `X-Auto-Save-Gallery` header |
| `GET` | `/api/media/stream/:attachmentId` | HTTP 206 Partial Content video/audio streaming |

---

## ⚡ Socket.io Realtime Events

Connect with JWT token in handshake auth:
```javascript
import { io } from "socket.io-client";

const socket = io("http://localhost:5000", {
  auth: { token: "YOUR_JWT_ACCESS_TOKEN" }
});

// Join Chat Room
socket.emit("chat:join", chatId);

// Typing Indicators
socket.emit("typing:start", { chatId });
socket.emit("typing:stop", { chatId });

// Listen for New Messages
socket.on("message:new", (message) => {
  console.log("New message received:", message);
});

// Listen for Unsent Messages
socket.on("message:unsent", ({ messageId, chatId }) => {
  console.log("Message unsent:", messageId);
});

// Listen for Reactions
socket.on("message:reaction", ({ messageId, userId, emoji, action }) => {
  console.log("Reaction update:", emoji, action);
});

// Listen for Online/Offline Presence
socket.on("presence:user_online", ({ userId }) => {});
socket.on("presence:user_offline", ({ userId, lastSeen }) => {});
```

