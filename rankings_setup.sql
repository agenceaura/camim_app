-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE

-- 1. Crear la tabla de rankings si no existe
CREATE TABLE IF NOT EXISTS public.rankings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category text NOT NULL,
  pilot_name text NOT NULL,
  moto_number integer,
  points integer DEFAULT 0,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Limpiar la tabla antes de insertar (para evitar duplicados al re-ejecutar)
DELETE FROM public.rankings;

-- 2. Habilitar RLS
ALTER TABLE public.rankings ENABLE ROW LEVEL SECURITY;

-- 3. Políticas (Eliminar antes de crear para evitar errores de duplicado)
DROP POLICY IF EXISTS "Rankings visibles para todos" ON public.rankings;
CREATE POLICY "Rankings visibles para todos" ON public.rankings
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins pueden gestionar rankings" ON public.rankings;
CREATE POLICY "Admins pueden gestionar rankings" ON public.rankings
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- 4. Insertar datos provisionales
INSERT INTO public.rankings (category, pilot_name, moto_number, points) VALUES
('Mini Cross A', 'TULIO UMFIER', 65, 48),

('Mini Cross B', 'BADIALI CHACON', 11, 48),
('Mini Cross B', 'FABIAN KELM', 26, 48),
('Mini Cross B', 'LUAN NARCISO', 211, 44),
('Mini Cross B', 'AMANDA UMFIER', 65, 40),

('Juniors', 'Luciano Rosniski', 33, 48),
('Juniors', 'Guido Karuchek', 299, 46),
('Juniors', 'Josue Anger', 38, 46),
('Juniors', 'Tulio Umfier', 65, 44),

('Quads Damas', 'Sofia Wrubel', 95, 46),
('Quads Damas', 'valentina zado', 22, 46),

('Master A', 'Adrian Mattje', 2, 87),
('Master A', 'Sandro Kleibert', 53, 82),
('Master A', 'Luis chacon', 11, 48),
('Master A', 'Tomas Schroder', 89, 41),
('Master A', 'gustavo rios', 55, 38),
('Master A', 'cristian ojeda', 817, 36),

('Master B', 'sandro diaz', 93, 96),
('Master B', 'moacir vogl', 85, 88),

('Mini Quads', 'Maximo Wolenberg', 12, 96),
('Mini Quads', 'Valentina Zado', 22, 86),
('Mini Quads', 'Lautaro De Olivera', 57, 42),
('Mini Quads', 'Jeremi Dibs', 22, 40),

('Quads A', 'santino froy', 4, 94),
('Quads A', 'JUAN gabriel kral', 8, 90),
('Quads A', 'Sebastian Rosniski', 25, 78),
('Quads A', 'Fernando Franco', 315, 74),
('Quads A', 'Marcos Langer', 5, 40),
('Quads A', 'facundo franco', 153, 35),

('Quads B', 'lautaro zado', 512, 96),
('Quads B', 'juan ariel wrubel', 95, 69),
('Quads B', 'Jonathan Franco', 958, 40),

('VeloNacional 200', 'moacir vogl', 85, 76),
('VeloNacional 200', 'gaston mello', 24, 48),
('VeloNacional 200', 'Adrian Golemba', 23, 48),
('VeloNacional 200', 'jonathan bohn', 621, 44),
('VeloNacional 200', 'Maximo Ott', 44, 44),
('VeloNacional 200', 'Junior Nuñez', 18, 40),

('VeloNacional 250', 'daimon berguer', 49, 90),
('VeloNacional 250', 'sandro karuchek', 32, 75),
('VeloNacional 250', 'sandro diaz', 93, 41),
('VeloNacional 250', 'walter narciso', 211, 39),
('VeloNacional 250', 'jonathan ariel goulart', 25, 38),
('VeloNacional 250', 'mariano cardozo', 27, 35),
('VeloNacional 250', 'matias rodriguez', 70, 33),

('Quads Senior', 'Sebastian Foche', 74, 96),
('Quads Senior', 'Claudio Kral', 77, 81),
('Quads Senior', 'Santiago Febre', 26, 78),
('Quads Senior', 'Hernan Bresiski', 841, 75),
('Quads Senior', 'German Wolenberg', 12, 64),
('Quads Senior', 'Mauro Silberman', 83, 34),

('MX 3 (Principiantes)', 'Jonathan Escher', 90, 87),
('MX 3 (Principiantes)', 'Walter Chimko', 7, 81),
('MX 3 (Principiantes)', 'Angel Coronel', 25, 46),
('MX 3 (Principiantes)', 'Adrian Golemba', 23, 43),
('MX 3 (Principiantes)', 'Daimon Berger', 49, 40),
('MX 3 (Principiantes)', 'Mariano Cardozo', 27, 38),
('MX 3 (Principiantes)', 'Rahir Custodio', 78, 37),
('MX 3 (Principiantes)', 'Cesar Piñeiro', 88, 36),
('MX 3 (Principiantes)', 'Walter Narciso', 211, 36),
('MX 3 (Principiantes)', 'Luciano Rosniski', 33, 34),
('MX 3 (Principiantes)', 'Marcos Robe', 97, 31),
('MX 3 (Principiantes)', 'Jonatan Mussini', 22, 28),
('MX 3 (Principiantes)', 'Guido Karuchek', 299, 17),
('MX 3 (Principiantes)', 'Matias Rodriguez', 95, 13),

('MX 2', 'Maicol Anger', 999, 88),
('MX 2', 'Sandro Ariel Kleibert', 53, 81),
('MX 2', 'Felipe Boilini', 7, 48),
('MX 2', 'Victor Petruszynski', 24, 41),
('MX 2', 'Tomas Schroder', 89, 25),

('Open Class', 'Maicol Anger', 999, 84),
('Open Class', 'Juan Cruz Gonseski', 604, 48),
('Open Class', 'Denis Stucan', 12, 48),
('Open Class', 'Ezequiel Raasch', 789, 44),
('Open Class', 'Sandro Kleibert', 53, 38),
('Open Class', 'Adrian Mattje', 2, 20),
('Open Class', 'Luis Chacon', 11, 19),
('Open Class', 'Sandro Diaz', 93, 18);

-- 5. Enlazar automáticamente los perfiles registrados con los rankings
UPDATE public.rankings r
SET profile_id = p.id
FROM public.profiles p
WHERE LOWER(TRIM(r.pilot_name)) = LOWER(TRIM(p.first_name || ' ' || p.last_name));
