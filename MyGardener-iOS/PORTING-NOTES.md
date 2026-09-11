# Porting notes

The hardened JavaScript baseline remains the reference for behavior. Native v1 intentionally converts the core user workflows rather than embedding the web app in a WebView.

## Deliberate design decisions

- Native reminders use iOS local notification scheduling rather than browser/PWA polling.
- Apple Reminders and Calendar are integrated through EventKit as an optional reminder destination.
- API keys are stored in Keychain.
- App state is a Codable JSON document in Application Support, with explicit export/import.
- The monitoring engine uses actual site conditions and container size instead of the older fixed-capacity assumptions.
- Calendar event ranges handle cross-year windows.
- Ornamental fruit/seed production is not automatically treated as a harvest event.
- Raw research JSON is available under Advanced Research but is not duplicated throughout the consumer profile.

## Next native milestone after device test

1. Verify layout, navigation, persistence, weather and permission flows on a physical iPhone.
2. Add a browser-state migration/export bridge if desired.
3. Port/bundle the validated nationwide Thrive climate raster and MapKit overlays.
4. Add BackgroundTasks/push strategy only after deciding whether weather alerts should be evaluated locally on refresh or server-side for guaranteed background delivery.
