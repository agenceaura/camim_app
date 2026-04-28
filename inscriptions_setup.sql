-- EJECUTAR ESTO EN EL SQL EDITOR DE SUPABASE

CREATE TABLE public.inscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  pilot_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  payment_method TEXT, -- 'mercadopago' o 'transfer'
  payment_status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'rejected'
  receipt_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(event_id, pilot_id) -- Un piloto no puede inscribirse 2 veces al mismo evento
);

-- Para desarrollo rápido sin bloqueos de RLS:
ALTER TABLE public.inscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dev_inscriptions_policy" ON public.inscriptions FOR ALL USING (true);
