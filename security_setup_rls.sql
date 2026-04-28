-- ==========================================
-- POLÍTICAS DE SEGURIDAD ESTRICTAS (RLS) FIX RECURSIÓN
-- ==========================================

-- 0. CREAR FUNCIÓN PARA EVITAR RECURSIÓN INFINITA
-- Esta función chequea si el usuario es admin de forma rápida y segura
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función separada para Administradores y Organizadores (solo lectura QR)
CREATE OR REPLACE FUNCTION public.is_admin_or_organizer()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND (role = 'admin' OR role = 'organizer')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. TABLA `profiles`
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins total access to profiles" ON profiles;
CREATE POLICY "Admins total access to profiles" 
ON profiles FOR ALL 
USING ( public.is_admin() );

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
USING ( auth.uid() = id );

DROP POLICY IF EXISTS "Profiles are visible to everyone" ON profiles;
CREATE POLICY "Profiles are visible to everyone"
ON profiles FOR SELECT
USING ( auth.role() = 'authenticated' );

-- 2. TABLA `inscriptions`
ALTER TABLE inscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage inscriptions" ON inscriptions;
CREATE POLICY "Admins manage inscriptions" 
ON inscriptions FOR ALL 
USING ( public.is_admin() );

DROP POLICY IF EXISTS "Pilots view own inscriptions" ON inscriptions;
CREATE POLICY "Pilots view own inscriptions" 
ON inscriptions FOR SELECT 
USING ( pilot_id = auth.uid() );

DROP POLICY IF EXISTS "Pilots insert own inscriptions" ON inscriptions;
CREATE POLICY "Pilots insert own inscriptions" 
ON inscriptions FOR INSERT 
WITH CHECK ( pilot_id = auth.uid() );

DROP POLICY IF EXISTS "Pilots update own inscriptions" ON inscriptions;
CREATE POLICY "Pilots update own inscriptions" 
ON inscriptions FOR UPDATE 
USING ( pilot_id = auth.uid() )
WITH CHECK ( payment_status = 'pending' );

-- 3. TABLA `check_ins`
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage checkins" ON check_ins;
CREATE POLICY "Admins manage checkins" 
ON check_ins FOR ALL 
USING ( public.is_admin_or_organizer() );

DROP POLICY IF EXISTS "Users view own checkins" ON check_ins;
CREATE POLICY "Users view own checkins" 
ON check_ins FOR SELECT 
USING ( profile_id = auth.uid() );
