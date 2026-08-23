REVOKE ALL PRIVILEGES
ON TABLE
    public.product_events,
    public.identity_map,
    public.account_signal_state,
    public.processing_attempts
FROM anon, authenticated;

ALTER TABLE public.product_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.identity_map ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_signal_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.processing_attempts ENABLE ROW LEVEL SECURITY;
