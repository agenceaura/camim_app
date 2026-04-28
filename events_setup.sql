-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE (Panel Izquierdo > SQL Editor > New Query)

-- 1. Crear la tabla de eventos (calendario)
CREATE TABLE public.events (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  subtitle text,
  days_text text,
  location_name text,
  latitude double precision,
  longitude double precision,
  schedule jsonb,
  speedhive_link text,
  is_active boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Insertar una fila inicial de prueba (para que la app tenga qué mostrar y editar)
INSERT INTO public.events (title, subtitle, days_text, location_name, latitude, longitude, schedule, speedhive_link, is_active)
VALUES (
  'Gran Premio Misiones', 
  'FECHA 1', 
  'Sáb 25 - Dom 26 de Mayo', 
  'Circuito Posadas, Misiones', 
  -27.367083, 
  -55.896083, 
  '[{"time": "08:00", "event": "Apertura de inscripciones y técnica"}]'::jsonb, 
  'https://speedhive.mylaps.com/events/3363194',
  true
);

-- 3. Habilitar Seguridad RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- 4. Cualquiera puede "leer" el evento activo (es público para la app)
CREATE POLICY "Eventos visibles para todos" ON public.events
  FOR SELECT USING (true);

-- 5. Solo los admins pueden Modificar (Actualizar/Crear)
CREATE POLICY "Admins pueden modificar eventos" ON public.events
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );
