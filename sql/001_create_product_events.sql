CREATE TABLE public.product_events (
    event_id TEXT PRIMARY KEY,

    event_type TEXT NOT NULL CHECK (
        event_type IN (
            'signup_completed',
            'workspace_created',
            'core_workflow_created',
            'core_workflow_executed',
            'teammate_invited',
            'integration_connected',
            'usage_threshold_reached',
            'upgrade_intent_detected'
        )
    ),

    occurred_at TIMESTAMPTZ NOT NULL,

    product_user_id TEXT NOT NULL,

    workspace_id TEXT,

    event_properties JSONB NOT NULL DEFAULT '{}'::jsonb,

    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT event_properties_must_be_object
        CHECK (jsonb_typeof(event_properties) = 'object')
);

CREATE INDEX idx_product_events_workspace_occurred_at
    ON public.product_events (workspace_id, occurred_at DESC);

CREATE INDEX idx_product_events_product_user
    ON public.product_events (product_user_id);
