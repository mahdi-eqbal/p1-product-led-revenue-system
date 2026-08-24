const body = $json.body ?? {};

const allowedEventTypes = new Set([
    "signup_completed",
    "workspace_created",
    "core_workflow_created",
    "core_workflow_executed",
    "teammate_invited",
    "integration_connected",
    "usage_threshold_reached",
    "upgrade_intent_detected"
]);

const workspaceRequiredEvents = new Set([
    "workspace_created",
    "core_workflow_created",
    "core_workflow_executed",
    "teammate_invited",
    "integration_connected",
    "usage_threshold_reached",
    "upgrade_intent_detected"
]);

const errors = [];

const eventId =
    typeof body.event_id === "string"
        ? body.event_id.trim()
        : "";

const eventType =
    typeof body.event_type === "string"
        ? body.event_type.trim().toLowerCase()
        : "";

const productUserId =
    typeof body.product_user_id === "string"
        ? body.product_user_id.trim()
        : "";

const workspaceId =
    typeof body.workspace_id === "string"
        ? body.workspace_id.trim()
        : null;

const email =
    typeof body.email === "string"
        ? body.email.trim().toLowerCase()
        : null;

if (!eventId) {
    errors.push("event_id is required");
}

if (!eventType) {
    errors.push("event_type is required");
} else if (!allowedEventTypes.has(eventType)) {
    errors.push(`unsupported event_type: ${eventType}`);
}

if (!productUserId) {
    errors.push("product_user_id is required");
}

if (
    workspaceRequiredEvents.has(eventType) &&
    !workspaceId
) {
    errors.push(
        `workspace_id is required for ${eventType}`
    );
}

let occurredAt = null;

if (!body.occurred_at) {
    errors.push("occurred_at is required");
} else {
    const parsedDate = new Date(body.occurred_at);

    if (Number.isNaN(parsedDate.getTime())) {
        errors.push("occurred_at must be a valid timestamp");
    } else {
        occurredAt = parsedDate.toISOString();
    }
}

let eventProperties = {};

if (body.properties !== undefined) {
    if (
        body.properties === null ||
        typeof body.properties !== "object" ||
        Array.isArray(body.properties)
    ) {
        errors.push("properties must be a JSON object");
    } else {
        eventProperties = body.properties;
    }
}

return {
    json: {
        validation_status:
            errors.length === 0 ? "valid" : "invalid",

        validation_errors: errors,

        event_id: eventId || null,
        event_type: eventType || null,
        occurred_at: occurredAt,
        product_user_id: productUserId || null,
        workspace_id: workspaceId,
        email: email,

        event_properties: eventProperties,

        received_at: new Date().toISOString()
    }
};
