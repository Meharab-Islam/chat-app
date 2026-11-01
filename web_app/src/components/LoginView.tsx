import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { MessageSquare, Sparkles, UserCheck, ArrowRight, ShieldCheck } from 'lucide-react';

const GOOGLE_CLIENT_ID = '366527404345-qf56pvo90k61dhqsqlnkbs23kgffoa1v.apps.googleusercontent.com';

declare global {
  interface Window {
    google?: any;
  }
}

export const LoginView: React.FC = () => {
  const { loginWithGoogle, quickLogin } = useAuth();
  const [customEmail, setCustomEmail] = useState('');
  const [customName, setCustomName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Initialize Google One Tap / Sign-In Button
    if (window.google?.accounts?.id) {
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
    }
  }, [loginWithGoogle]);

  const handleQuickSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customEmail.trim()) return;
    setIsSubmitting(true);
    setError(null);
    try {
      await quickLogin(customEmail.trim(), customName.trim() || undefined);
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const demoAccounts = [
    { name: 'Meharab Islam', email: 'iammeharabislam@gmail.com' },
    { name: 'Alice Developer', email: 'alice@example.com' },
    { name: 'Bob Engineer', email: 'bob@example.com' },
  ];

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-indigo-900 via-zinc-900 to-black">
      <div className="w-full max-w-md bg-zinc-900/90 backdrop-blur-xl border border-zinc-800 rounded-3xl p-8 shadow-2xl">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-tr from-indigo-600 to-violet-500 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-indigo-500/30">
            <MessageSquare className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white mb-2">Welcome to ChatApp Web</h1>
          <p className="text-sm text-zinc-400">Ultra fast real-time messaging across web & mobile</p>
        </div>

        {error && (
          <div className="mb-6 p-3 bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-xl">
            {error}
          </div>
        )}

        <div className="space-y-6">
          <div className="flex flex-col items-center">
            <div id="google-btn-container" className="min-h-[44px]"></div>
          </div>

          <div className="relative flex items-center justify-center">
            <div className="border-t border-zinc-800 w-full"></div>
            <span className="bg-zinc-900 px-3 text-xs text-zinc-500 font-medium uppercase tracking-wider">
              Or Fast Login
            </span>
          </div>

          {/* Quick presets */}
          <div className="space-y-2">
            <label className="text-xs font-semibold uppercase tracking-wider text-zinc-400 flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-indigo-400" /> Demo Accounts (Click to test)
            </label>
            <div className="grid grid-cols-1 gap-2">
              {demoAccounts.map((acc) => (
                <button
                  key={acc.email}
                  disabled={isSubmitting}
                  onClick={() => quickLogin(acc.email, acc.name)}
                  className="flex items-center justify-between p-3 rounded-xl bg-zinc-800/60 hover:bg-zinc-800 border border-zinc-700/50 hover:border-indigo-500/50 text-left transition-all group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-indigo-500/20 text-indigo-400 font-bold flex items-center justify-center text-xs">
                      {acc.name[0]}
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-zinc-200 group-hover:text-white">{acc.name}</div>
                      <div className="text-[11px] text-zinc-500">{acc.email}</div>
                    </div>
                  </div>
                  <ArrowRight className="w-4 h-4 text-zinc-500 group-hover:text-indigo-400 transition" />
                </button>
              ))}
            </div>
          </div>

          {/* Custom quick login */}
          <form onSubmit={handleQuickSubmit} className="space-y-3 pt-2 border-t border-zinc-800/80">
            <div>
              <label className="block text-xs font-medium text-zinc-400 mb-1">Your Name</label>
              <input
                type="text"
                placeholder="e.g. John Doe"
                value={customName}
                onChange={(e) => setCustomName(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-zinc-800/70 border border-zinc-700 text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-zinc-400 mb-1">Email Address *</label>
              <input
                type="email"
                required
                placeholder="name@domain.com"
                value={customEmail}
                onChange={(e) => setCustomEmail(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-zinc-800/70 border border-zinc-700 text-sm text-white placeholder-zinc-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-2.5 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-medium text-sm transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <UserCheck className="w-4 h-4" />
              {isSubmitting ? 'Signing in...' : 'Sign In with Email'}
            </button>
          </form>
        </div>

        <div className="mt-8 pt-4 border-t border-zinc-800 flex items-center justify-center gap-2 text-xs text-zinc-500">
          <ShieldCheck className="w-4 h-4 text-emerald-500" />
          <span>Encrypted real-time session</span>
        </div>
      </div>
    </div>
  );
};

