import { Chat, Message, User } from '../types';

const HOST = window.location.hostname || 'localhost';
const PORT = (import.meta as any).env?.VITE_SERVER_PORT || (HOST === '107.174.137.29' || window.location.port === '3005' ? '5055' : '5050');
export const SERVER_URL = (import.meta as any).env?.VITE_SERVER_URL || `http://${HOST}:${PORT}`;
export const API_BASE_URL = `${SERVER_URL}/api`;

export const resolveMediaUrl = (url?: string) => {
  if (!url) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  const clean = url.startsWith('/') ? url : `/${url}`;
  return `${SERVER_URL}${clean}`;
};

class ApiService {
  private getToken(): string | null {
    return localStorage.getItem('accessToken');
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = this.getToken();
    const headers: Record<string, string> = {
      ...(options.headers as Record<string, string>),
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    if (!(options.body instanceof FormData) && !headers['Content-Type']) {
      headers['Content-Type'] = 'application/json';
    }

    const res = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });

    const json = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(json.message || `Request failed with status ${res.status}`);
    }
    return json.data !== undefined ? json.data : json;
  }

  // Auth
  async loginWithGoogle(idToken: string) {
    return this.request<{ user: User; tokens: { accessToken: string; refreshToken: string } }>(
      '/auth/google',
      { method: 'POST', body: JSON.stringify({ idToken }) }
    );
  }

  async quickLogin(email: string, name?: string) {
    return this.request<{ user: User; tokens: { accessToken: string; refreshToken: string } }>(
      '/auth/quick-login',
      { method: 'POST', body: JSON.stringify({ email, name }) }
    );
  }

  // User & Profile
  async getMe(): Promise<User> {
    return this.request<User>('/users/me');
  }

  async updateProfile(data: { name?: string; bio?: string; status?: string; avatarUrl?: string }): Promise<User> {
    return this.request<User>('/users/profile', { method: 'PUT', body: JSON.stringify(data) });
  }

  async updateAvatar(file: File): Promise<User> {
    const fd = new FormData();
    fd.append('avatar', file);
    return this.request<User>('/users/avatar', { method: 'POST', body: fd });
  }

  async searchUsers(query: string): Promise<User[]> {
    return this.request<User[]>(`/users/search?q=${encodeURIComponent(query)}`);
  }

  // Chats
  async getMyChats(): Promise<Chat[]> {
    return this.request<Chat[]>('/chats');
  }

  async createDirectChat(recipientId: string): Promise<Chat> {
    return this.request<Chat>('/chats/direct', { method: 'POST', body: JSON.stringify({ recipientId }) });
  }

  async createGroupChat(name: string, memberIds: string[]): Promise<Chat> {
    return this.request<Chat>('/chats/group', { method: 'POST', body: JSON.stringify({ name, memberIds }) });
  }

  async deleteChat(chatId: string): Promise<void> {
    return this.request<void>(`/chats/${chatId}`, { method: 'DELETE' });
  }

  async updateGroup(chatId: string, name?: string, avatarFile?: File): Promise<Chat> {
    const fd = new FormData();
    if (name) fd.append('name', name);
    if (avatarFile) fd.append('avatar', avatarFile);
    return this.request<Chat>(`/chats/${chatId}`, { method: 'PUT', body: fd });
  }

  // Messages
  async getMessages(chatId: string): Promise<Message[]> {
    return this.request<Message[]>(`/messages/${chatId}`);
  }

  async sendMessage(
    chatId: string,
    text?: string,
    files?: File[],
    replyToId?: string,
    onProgress?: (pct: number, loaded: number, total: number) => void
  ): Promise<Message> {
    const fd = new FormData();
    fd.append('chatId', chatId);
    if (text) fd.append('text', text);
    if (replyToId) fd.append('replyToId', replyToId);
    if (files && files.length > 0) {
      files.forEach((f) => fd.append('files', f));
    }

    if (!onProgress || !files || files.length === 0) {
      return this.request<Message>('/messages', { method: 'POST', body: fd });
    }

    return new Promise<Message>((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('POST', `${API_BASE_URL}/messages`);
      const token = this.getToken();
      if (token) xhr.setRequestHeader('Authorization', `Bearer ${token}`);

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const pct = Math.round((e.loaded / e.total) * 100);
          onProgress(pct, e.loaded, e.total);
        }
      };

      xhr.onload = () => {
        try {
          const json = JSON.parse(xhr.responseText || '{}');
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(json.data !== undefined ? json.data : json);
          } else {
            reject(new Error(json.message || `Upload failed with status ${xhr.status}`));
          }
        } catch {
          reject(new Error('Invalid response from server'));
        }
      };

      xhr.onerror = () => reject(new Error('Network error during file upload'));
      xhr.send(fd);
    });
  }

  async searchMessages(chatId: string, query: string): Promise<Message[]> {
    return this.request<Message[]>(`/messages/${chatId}/search?q=${encodeURIComponent(query)}`);
  }

  async markAsRead(chatId: string, lastReadMessageId?: string): Promise<void> {
    return this.request<void>(`/messages/${chatId}/read`, {
      method: 'PUT',
      body: JSON.stringify({ lastReadMessageId }),
    });
  }

  async unsendMessage(messageId: string): Promise<void> {
    return this.request<void>(`/messages/${messageId}/unsend`, { method: 'DELETE' });
  }

  async deleteForMe(messageId: string): Promise<void> {
    return this.request<void>(`/messages/${messageId}/delete-for-me`, { method: 'DELETE' });
  }

  async reactToMessage(messageId: string, emoji: string): Promise<void> {
    return this.request<void>(`/messages/${messageId}/react`, {
      method: 'POST',
      body: JSON.stringify({ emoji }),
    });
  }
}

export const api = new ApiService();

