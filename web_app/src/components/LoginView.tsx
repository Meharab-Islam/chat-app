import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { MessageSquare, Mail, User, ShieldCheck, ArrowRight, Info } from 'lucide-react';

const GOOGLE_CLIENT_ID = '366527404345-qf56pvo90k61dhqsqlnkbs23kgffoa1v.apps.googleusercontent.com';

declare global {
  interface Window {
    google?: any;
  }
}

export const LoginView: React.FC = () => {
  const { loginWithGoogle, quickLogin } = useAuth();
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isRawIp = /^[0-9.]+$/.test(window.location.hostname);

  useEffect(() => {
    // Only attempt Google GSI button if not on a raw IP address (Google OAuth strictly blocks raw IP origins with Error 400)
    if (!isRawIp && window.google?.accounts?.id) {
      try {
        window.google.accounts.id.initialize({
          client_id: GOOGLE_CLIENT_ID,
          callback: async (response: any) => {
            if (response?.credential) {
              try {
                setIsSubmitting(true);
                setError(null);
                await loginWithGoogle(response.credential);
              } catch (err: any) {
                setError(err.message || 'Google sign-in failed');
              } finally {
                setIsSubmitting(false);
              }
            }
          },
        });

        const btnContainer = document.getElementById('google-btn-container');
        if (btnContainer) {
          window.google.accounts.id.renderButton(btnContainer, {
            theme: 'outline',
            size: 'large',
            width: 320,
            text: 'continue_with',
            shape: 'pill',
          });
        }
      } catch (e) {
        console.warn('Google GSI Init failed:', e);
      }
    }
  }, [loginWithGoogle, isRawIp]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setIsSubmitting(true);
    setError(null);
    try {
      await quickLogin(email.trim(), name.trim() || undefined);
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-indigo-950 via-zinc-950 to-black">
      <div className="w-full max-w-md bg-zinc-900/95 backdrop-blur-xl border border-zinc-800 rounded-3xl p-8 shadow-2xl relative overflow-hidden">
        {/* Subtle decorative glow */}
        <div className="absolute -top-24 -left-24 w-48 h-48 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-24 -right-24 w-48 h-48 bg-violet-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="text-center mb-6 relative">
          <div className="w-16 h-16 bg-gradient-to-tr from-indigo-600 to-violet-500 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-indigo-500/25">
            <MessageSquare className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white mb-1.5">Sign In to ChatApp</h1>
          <p className="text-xs text-zinc-400">Real-time messaging synced across web & mobile</p>
        </div>

        {error && (
          <div className="mb-5 p-3.5 bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-xl">
            {error}
          </div>
        )}

        {isRawIp && (
          <div className="mb-5 p-3 bg-indigo-500/10 border border-indigo-500/20 text-indigo-300 text-xs rounded-xl flex items-start gap-2.5">
            <Info className="w-4 h-4 text-indigo-400 shrink-0 mt-0.5" />
            <span>
              Google disables popup logins on direct IP addresses. Enter your Google email below to sign in directly!
            </span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-zinc-300 mb-1.5 flex items-center gap-1.5">
              <Mail className="w-3.5 h-3.5 text-indigo-400" /> Google or Account Email *
            </label>
            <input
              type="email"
              required
              autoFocus
              placeholder="e.g. newlolipoplive@gmail.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-800/80 border border-zinc-700/80 text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-zinc-300 mb-1.5 flex items-center gap-1.5">
              <User className="w-3.5 h-3.5 text-indigo-400" /> Display Name (Optional)
            </label>
            <input
              type="text"
              placeholder="e.g. Lollipop Live"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-800/80 border border-zinc-700/80 text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full mt-2 py-3 px-4 rounded-xl bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white font-medium text-sm transition shadow-lg shadow-indigo-600/25 flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
          >
            <span>{isSubmitting ? 'Signing in...' : 'Continue to Chat'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        {!isRawIp && (
          <div className="mt-6 pt-5 border-t border-zinc-800/80 flex flex-col items-center">
            <span className="text-[11px] text-zinc-500 mb-3 uppercase tracking-wider font-medium">
              Or with Google One-Tap
            </span>
            <div id="google-btn-container" className="min-h-[44px]"></div>
          </div>
        )}

        <div className="mt-6 pt-4 border-t border-zinc-800/80 flex items-center justify-center gap-2 text-xs text-zinc-500">
          <ShieldCheck className="w-4 h-4 text-emerald-500" />
          <span>Encrypted real-time session</span>
        </div>
      </div>
    </div>
  );
};
