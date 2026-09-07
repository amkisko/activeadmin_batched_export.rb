# Importmap chunk assembly MIME

## Decisions

Pin batched export modules on ActiveAdmin.importmap only, after the active_admin.importmap initializer. Ship chunk assembly as chunk_assembly.js. Do not pin the host Rails.application.importmap.

Rails 7.2 and 8.1 have no :mjs MIME. Propshaft then sends an empty Content-Type. Chromium refuses the module. Host javascript_importmap_tags also modulepreloads those pins on non-admin pages.

## Effects

Dummy ActiveAdmin.importmap.packages previously omitted the export pins when the engine drew after load_config_initializers. Host map must stay free of those names. GET of the chunk pin asset must be 200 with media type text/javascript.

## Next

Ship in the next gem version. Hosts that registered Mime::Type for mjs or copied engine pins onto the host map can drop those workarounds after upgrade.

## Source

lib/activeadmin/batched_export/engine.rb. app/assets/javascripts/activeadmin_batched_export/chunk_assembly.js. spec/requests/importmap_javascript_mime_spec.rb.
