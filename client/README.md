# form_concierge_client

Dart REST client for the Form Concierge Workers API.

The package exposes survey, admin, anonymous-account, response, reply, and configuration endpoints for the Workers API.

Survey submissions accept optional `DeviceInfo` and `metadata`. Collect and store stable IDs or detailed device fields in the host app, then pass them to `submitResponse(deviceInfo: ..., metadata: ...)`. Use `metadata` for app/user/session context such as authenticated `uid`, display name, tenant, plan, or feature flags.
