-- SQL PARA EL MINI JUEGO "MOTO DASH"
CREATE TABLE IF NOT EXISTS public.game_scores (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  score integer NOT NULL DEFAULT 0,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.game_scores ENABLE ROW LEVEL SECURITY;

-- Políticas
DROP POLICY IF EXISTS "Puntajes visibles para todos" ON public.game_scores;
CREATE POLICY "Puntajes visibles para todos" ON public.game_scores
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Usuarios pueden subir sus propios puntajes" ON public.game_scores;
CREATE POLICY "Usuarios pueden subir sus propios puntajes" ON public.game_scores
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propios puntajes" ON public.game_scores;
CREATE POLICY "Usuarios pueden actualizar sus propios puntajes" ON public.game_scores
  FOR UPDATE USING (auth.uid() = profile_id);
