# Custom theme adoption (second consumer)

Use this checklist when adding `activeadmin_batched_export` to another ActiveAdmin 4 app with its own design system.

## 1. Install the gem

```ruby
gem "activeadmin_batched_export"
```

## 2. Pin Stimulus (automatic)

The engine adds `batched_export_controller` to `ActiveAdmin.importmap`. Confirm your admin layout loads `javascript_importmap_tags "active_admin"`.

To replace the controller, pin your own file and set:

```ruby
ActiveAdmin::BatchedExport.configure do |config|
  config.stimulus_controller = "my-batched-export"
end
```

## 3. Override styles only

```ruby
ActiveAdmin::BatchedExport.configure do |config|
  config.styles = ActiveAdmin::BatchedExport::Styles.new(
    card: "rounded-lg border border-slate-200 bg-slate-50 p-6",
    primary_button: "btn btn-primary",
    secondary_button: "btn btn-outline",
    back_link: "link link-primary"
  )
end
```

## 4. Override partials for full layout control

Copy partials from the gem into `app/views/active_admin/batched_export/`. Start with `workspace.html.erb` if you only need structure changes; override `_actions.html.erb` for button components.

## 5. Locale

Gem ships English under `active_admin.batched_export_page`. Add host-app locale overrides for other languages.

## 6. Verify

- Index page CSV link points to `/admin/<resource>/batched_export`
- Workspace loads metadata and batch chunks
- Column selection and filters match the index scope
