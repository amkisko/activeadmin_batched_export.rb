# Importmap chunk assembly as js

## Decisions

Rename chunk_assembly.mjs to chunk_assembly.js. Draw pins only on ActiveAdmin.importmap after active_admin.importmap.

## Effects

Host importmap no longer lists export module names. ActiveAdmin importmap lists the controller and chunk_assembly pins. The chunk asset is served as text/javascript.

## Next

Shipped in 0.3.2. make release when ready to tag and push the gem.

## Source

usr/docs/issues/20260907161700_importmap-chunk-assembly-mime.md. lib/activeadmin/batched_export/engine.rb.
