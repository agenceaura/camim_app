-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE (Panel Izquierdo > SQL Editor > New Query)

-- Agrega la columna speedhive_link para guardar el link de resultados de cada fecha
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS speedhive_link text;
