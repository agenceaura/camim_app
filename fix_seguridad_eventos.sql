-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE (Panel Izquierdo > SQL Editor > New Query)

-- Al usar políticas RLS más complejas a veces se bloquean escrituras si el usuario de la DB no puede leer la tabla profiles.
-- Para desarrollo, vamos a simplificar la seguridad temporalmente para que tu Admin pueda guardar tranquilamente:

DROP POLICY IF EXISTS "Admins pueden modificar eventos" ON public.events;

CREATE POLICY "Modificar eventos dev" ON public.events
  FOR ALL USING (true);
