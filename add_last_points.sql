-- EJECUTAR EN EL SQL EDITOR DE SUPABASE
-- 1. Agregar columna para los puntos de la última fecha
ALTER TABLE public.rankings ADD COLUMN IF NOT EXISTS last_points integer DEFAULT 0;

-- 2. Comentario para documentar
COMMENT ON COLUMN public.rankings.last_points IS 'Puntos sumados específicamente en la última fecha/evento.';
