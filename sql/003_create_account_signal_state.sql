CREATE TABLE public.account_signal_state (
    workspace_id TEXT PRIMARY KEY,

    product_intent_score INTEGER NOT NULL DEFAULT 0
        CHECK (product_intent_score >= 0),

    product_intent_state TEXT NOT NULL DEFAULT 'low_intent'
        CHECK (
            product_intent_state IN (
                'low_intent',
                'medium_intent',
                'high_intent',
                'commercial_intent'
            )
        ),

    commercial_intent_detected BOOLEAN NOT NULL DEFAULT FALSE,

    important_signal_summary TEXT,

    latest_meaningful_signal_at TIMESTAMPTZ,

    intent_window_start TIMESTAMPTZ,

    calculated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    model_version TEXT NOT NULL DEFAULT 'v1'
);
