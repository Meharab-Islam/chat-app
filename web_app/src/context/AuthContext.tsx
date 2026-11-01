import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types';
import { api } from '../services/api';
import { initSocket, disconnectSocket } from '../services/socket';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  loginWithGoogle: (idToken: string) => Promise<void>;
  quickLogin: (email: string, name?: string) => Promise<void>;
  logout: () => void;
  updateProfile: (data: { name?: string; bio?: string; status?: string; avatarUrl?: string }) => Promise<void>;
  updateAvatar: (file: File) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem('accessToken'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const init = async () => {
      const savedToken = localStorage.getItem('accessToken');
      if (savedToken) {
        try {
          const profile = await api.getMe();
          setUser(profile);
          setToken(savedToken);
          initSocket(savedToken);
        } catch (err) {
          console.warn('Failed to load profile, session expired', err);
          logout();
        }
      }
      setIsLoading(false);
    };
    init();
  }, []);

  const handleAuthSuccess = (userData: User, tokens: { accessToken: string; refreshToken: string }) => {
    setUser(userData);
    setToken(tokens.accessToken);
    localStorage.setItem('accessToken', tokens.accessToken);
    localStorage.setItem('refreshToken', tokens.refreshToken);
    initSocket(tokens.accessToken);
  };

  const loginWithGoogle = async (idToken: string) => {
    setIsLoading(true);
    try {
      const res = await api.loginWithGoogle(idToken);
      handleAuthSuccess(res.user, res.tokens);
    } finally {
      setIsLoading(false);
    }
  };

  const quickLogin = async (email: string, name?: string) => {
    setIsLoading(true);
    try {
      const res = await api.quickLogin(email, name);
      handleAuthSuccess(res.user, res.tokens);
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    disconnectSocket();
  };

  const updateProfile = async (data: { name?: string; bio?: string; status?: string; avatarUrl?: string }) => {
    const updated = await api.updateProfile(data);
    setUser((prev) => (prev ? { ...prev, ...updated } : updated));
  };

  const updateAvatar = async (file: File) => {
    const updated = await api.updateAvatar(file);
    setUser((prev) => (prev ? { ...prev, avatarUrl: updated.avatarUrl } : updated));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        loginWithGoogle,
        quickLogin,
        logout,
        updateProfile,
        updateAvatar,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
};

