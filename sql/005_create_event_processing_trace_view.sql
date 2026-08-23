CREATE OR REPLACE VIEW public.v_event_processing_trace AS
SELECT
    pe.event_id,
    pe.event_type,
    pe.occurred_at,
    pe.product_user_id,
    pe.workspace_id,

    contact_map.hubspot_record_id AS hubspot_contact_id,
    company_map.hubspot_record_id AS hubspot_company_id,

    ass.product_intent_score,
    ass.product_intent_state,
    ass.commercial_intent_detected,
    ass.important_signal_summary,

    pa.attempt_number,
    pa.processing_status,
    pa.qualification_state,
    pa.handoff_status,
    pa.failure_type,
    pa.failure_reason,
    pa.started_at,
    pa.completed_at

FROM public.product_events pe

LEFT JOIN public.identity_map contact_map
    ON contact_map.entity_type = 'product_user'
    AND contact_map.product_id = pe.product_user_id
    AND contact_map.resolution_status = 'resolved'

LEFT JOIN public.identity_map company_map
    ON company_map.entity_type = 'workspace'
    AND company_map.product_id = pe.workspace_id
    AND company_map.resolution_status = 'resolved'

LEFT JOIN public.account_signal_state ass
    ON ass.workspace_id = pe.workspace_id

LEFT JOIN LATERAL (
    SELECT p.*
    FROM public.processing_attempts p
    WHERE p.event_id = pe.event_id
    ORDER BY p.attempt_number DESC
    LIMIT 1
) pa ON TRUE;
