-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE PARA HABILITAR NOTIFICACIONES

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  body text NOT NULL,
  type text DEFAULT 'info' NOT NULL, -- info, alert, success, birthday, news
  target_role text DEFAULT 'all' NOT NULL, -- all, pilot, spectator
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Políticas de Seguridad
DROP POLICY IF EXISTS "Notificaciones visibles para todos según rol" ON public.notifications;
CREATE POLICY "Notificaciones visibles para todos según rol" ON public.notifications
  FOR SELECT USING (
    target_role = 'all' OR 
    (SELECT role::text FROM public.profiles WHERE id = auth.uid()) = target_role::text
  );

DROP POLICY IF EXISTS "Admins pueden enviar notificaciones" ON public.notifications;
CREATE POLICY "Admins pueden enviar notificaciones" ON public.notifications
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT id FROM public.profiles WHERE role::text = 'admin')
  );

-- Habilitar Realtime para esta tabla
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
