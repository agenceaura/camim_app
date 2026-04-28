-- SQL PARA LA FUNCIÓN "EN VIVO"
CREATE TABLE IF NOT EXISTS public.live_results (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
  category text NOT NULL,
  status text DEFAULT 'No iniciado', -- 'No iniciado', 'Manga 1', 'Manga 2', 'Finalizado'
  manga_1_results text,
  manga_2_results text,
  total_points text,
  is_active boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.live_results ENABLE ROW LEVEL SECURITY;

-- Políticas
DROP POLICY IF EXISTS "Resultados en vivo visibles para todos" ON public.live_results;
CREATE POLICY "Resultados en vivo visibles para todos" ON public.live_results
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins pueden gestionar resultados en vivo" ON public.live_results;
CREATE POLICY "Admins pueden gestionar resultados en vivo" ON public.live_results
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );
