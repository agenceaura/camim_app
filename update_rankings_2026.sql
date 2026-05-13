-- 1. Limpiar rankings actuales para evitar duplicados y cargar la data fresca
DELETE FROM public.rankings;

-- 2. Insertar data actualizada desde el CSV (Total Campeonato y Puntos F3)
INSERT INTO public.rankings (category, pilot_name, moto_number, points, last_points) VALUES
('Quads Senior', 'SEBASTIAN FOCHE', 74, 144, 48),
('Quads Senior', 'CLAUDIO KRAL', 77, 125, 44),
('Quads Senior', 'GERMAN WOLEMBERG', 12, 104, 40),
('Quads Senior', 'SANTIAGO FEBRE', 26, 78, 0),
('Quads Senior', 'HERNAN BRESISKI', 841, 75, 0),
('Quads Senior', 'MAURO SILBERMAN', 83, 72, 38),

('MX 3 (Principiantes)', 'JONATHAN ESCHER', 90, 130, 43),
('MX 3 (Principiantes)', 'WALTER CHIMKO', 7, 127, 46),
('MX 3 (Principiantes)', 'MARIANO CARDOZO', 27, 80, 42),
('MX 3 (Principiantes)', 'LUCIANO ROSNISKI', 33, 73, 39),
('MX 3 (Principiantes)', 'ANGEL CORONEL', 25, 63, 17),
('MX 3 (Principiantes)', 'ADRIAN GOLEMBA', 23, 43, 0),
('MX 3 (Principiantes)', 'DAIMON BERGER', 49, 40, 0),
('MX 3 (Principiantes)', 'RAHIR CUSTODIO', 78, 37, 0),
('MX 3 (Principiantes)', 'CESAR PIÑEIRO', 88, 36, 0),
('MX 3 (Principiantes)', 'WALTER NARCISO', 211, 36, 0),
('MX 3 (Principiantes)', 'MARCOS ROBE', 97, 31, 0),
('MX 3 (Principiantes)', 'JONATAN MUSSINI', 22, 28, 0),
('MX 3 (Principiantes)', 'GUIDO KARUCHEK', 299, 17, 0),
('MX 3 (Principiantes)', 'MATIAS RODRIGUEZ', 95, 13, 0),

('Mini Cross A', 'TULIO UMFIER', 65, 92, 44),
('Mini Cross A', 'LIONEL TARNOSKI', 93, 48, 48),

('Mini Cross B', 'BADIALI CHACON', 11, 96, 48),
('Mini Cross B', 'FABIAN KELM', 26, 48, 0),
('Mini Cross B', 'LUAN NARCISO', 211, 44, 0),
('Mini Cross B', 'JOAQUIN ZAPF', 1, 44, 44),
('Mini Cross B', 'AMANDA UNFIER', 65, 40, 0),

('Mini Quads', 'MAXIMO WOLENBERG', 12, 142, 46),
('Mini Quads', 'LAUTARO DE OLIVERA', 57, 88, 46),
('Mini Quads', 'VALENTINA ZADO', 22, 86, 0),
('Mini Quads', 'DENIS BUJAR', 89, 40, 40),
('Mini Quads', 'JEREMI DIBS', 22, 40, 0),
('Mini Quads', 'FAUSTO SILBERMAN', 22, 22, 22),

('Quads B', 'JUAN ARIEL WRUBEL', 95, 109, 40),
('Quads B', 'LAUTARO ZADO', 512, 96, 0),
('Quads B', 'PABLO EMANUEL BULAK', 22, 48, 48),
('Quads B', 'DANIEL CARLOS BUJAR', 989, 44, 44),
('Quads B', 'JONATHAN FRANCO', 958, 40, 0),

('Quads A', 'SANTINO FROY', 4, 142, 48),
('Quads A', 'JUAN GABRIEL KRAL', 8, 134, 44),
('Quads A', 'SEBASTIAN ROSNISKI', 25, 113, 35),
('Quads A', 'FERNANDO FRANCO', 315, 109, 35),
('Quads A', 'MARCOS LANGER', 5, 79, 39),
('Quads A', 'FACUNDO FRANCO', 153, 74, 39),

('Master A', 'ADRIAN MATTJE', 2, 131, 44),
('Master A', 'SANDRO KLEIBERT', 53, 118, 36),
('Master A', 'LUIS CHACON', 11, 96, 48),
('Master A', 'TOMAS SCHRODER', 89, 80, 39),
('Master A', 'GUSTAVO RIOS', 55, 77, 39),
('Master A', 'CRISTIAN OJEDA', 817, 70, 34),

('Master B', 'SANDRO DIAZ', 93, 144, 48),
('Master B', 'MOACIR VOGL', 85, 132, 44),

('VeloNacional 200', 'MOACIR VOGL', 85, 116, 40),
('VeloNacional 200', 'ADRIAN GOLEMBA', 23, 96, 48),
('VeloNacional 200', 'GASTON MELLO', 24, 48, 0),
('VeloNacional 200', 'JONATHAN BOHN', 621, 44, 0),
('VeloNacional 200', 'MAXIMO OTT', 44, 44, 0),
('VeloNacional 200', 'LUCAS CUSTODIO', 78, 44, 44),
('VeloNacional 200', 'JUNIOR NUÑEZ', 18, 40, 0),

('VeloNacional 250', 'SANDRO KARUCHEK', 32, 94, 19),
('VeloNacional 250', 'BERGER DAIMON', 49, 90, 0),
('VeloNacional 250', 'SANDRO DIAZ', 93, 87, 46),
('VeloNacional 250', 'MARIANO CARDOZO', 27, 77, 42),
('VeloNacional 250', 'WALTER NARCISO', 211, 39, 0),
('VeloNacional 250', 'JONATHAN ARIEL GOULART', 25, 38, 0),
('VeloNacional 250', 'MATIAS RODRIGUEZ', 70, 33, 0),
('VeloNacional 250', 'MARIANO YUSHCUV', 56, 27, 27),

('Juniors', 'LUCIANO ROSNISKI', 33, 96, 48),
('Juniors', 'TULIO UMFIER', 65, 63, 19),
('Juniors', 'GUIDO KARUCHEK', 299, 46, 0),
('Juniors', 'JOSUE ANGER', 38, 46, 0),
('Juniors', 'BRUNO GONZALEZ', 22, 44, 44),
('Juniors', 'LIONEL TARNOSKI', 93, 40, 40),

('MX 2', 'SANDRO ARIEL KLEIBERT', 53, 123, 42),
('MX 2', 'MAICOL ANGER', 999, 88, 0),
('MX 2', 'TOMAS SCHRODER', 89, 69, 44),
('MX 2', 'FELIPE BOILINI', 7, 48, 0),
('MX 2', 'GUSTAVO RIOS', 55, 46, 46),
('MX 2', 'VICTOR PETRUSZYNSKI', 24, 41, 0),
('MX 2', 'CRISTIAN OJEDA', 23, 38, 38),

('Open Class', 'DENIS STUCAN', 12, 94, 46),
('Open Class', 'MAICOL ANGER', 999, 84, 0),
('Open Class', 'SANDRO KLEIBERT', 53, 71, 33),
('Open Class', 'LUIS CHACON', 11, 65, 46),
('Open Class', 'ADRIAN MATTJE', 2, 59, 39),
('Open Class', 'JUAN CRUZ GONSESKI', 604, 48, 0),
('Open Class', 'EZEQUIEL RAASCH', 789, 44, 0),
('Open Class', 'MARIANO YUSHCUV', 56, 39, 39),
('Open Class', 'GUSTAVO RIOS', 55, 35, 35),
('Open Class', 'TOMAS SCHRODER', 89, 34, 34),
('Open Class', 'SANDRO DIAZ', 93, 18, 0),
('Open Class', 'CRISTIAN OJEDA', 23, 18, 18);

-- 3. Enlazar automáticamente los perfiles registrados con los nuevos rankings
UPDATE public.rankings r
SET profile_id = p.id
FROM public.profiles p
WHERE LOWER(TRIM(r.pilot_name)) = LOWER(TRIM(p.first_name || ' ' || p.last_name))
   OR LOWER(TRIM(r.pilot_name)) = LOWER(TRIM(p.last_name || ' ' || p.first_name));
