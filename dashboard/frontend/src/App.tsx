import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import { Toaster } from 'sonner';
import Login from './pages/Login';
import Hub from './pages/Hub';
import Minecraft from './pages/Minecraft';
import { AuthProvider, useAuth } from './hooks/useAuth';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, loading } = useAuth();
  if (loading) return (
    <div className="loading-screen">
      <span className="loading-dot" />
      <span>Loading…</span>
    </div>
  );
  return isAuthenticated ? <>{children}</> : <Navigate to="/" replace />;
};

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AnimatePresence mode="wait">
          <Routes>
            <Route path="/" element={<Login />} />
            <Route path="/hub" element={<ProtectedRoute><Hub /></ProtectedRoute>} />
            <Route path="/minecraft" element={<ProtectedRoute><Minecraft /></ProtectedRoute>} />
          </Routes>
        </AnimatePresence>
        <Toaster theme="dark" toastOptions={{ className: 'bg-[#19191b] border-[#2d2d31] text-[#f4f3ef]' }} />
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
