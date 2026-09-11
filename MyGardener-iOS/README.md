# MyGardener — Native iOS SwiftUI test build

This is the first native iPhone conversion of the hardened Plant Watch / MyGardener JavaScript baseline.

## Included in the native build

- SwiftUI tabs: Today, Plants, Calendar, Water, More
- Open-Meteo live weather, hourly forecast and 7-day outlook
- Native plant collection with editable specimen/site fields
- Plant details, consumer-facing research sections, structured pests/diseases
- Dated plant journal notes
- Plant-specific reminders
- Exact local iOS notifications through `UNUserNotificationCenter`
- Optional Apple Reminders / Apple Calendar integration through EventKit
- Plant death/history and permanent removal
- Canonical calendar events with Today / Week / Month / Season and event filters
- Root-zone storage, ET₀ plant demand, container cold vulnerability, frost/heat/waterlogging alert hooks
- Gemini research using a Keychain-stored API key
- JSON garden backup/import
- Native Thrive summary for the calibrated McKinney climate vector, including seasonal `-S` behavior

## Open in Xcode on the MacBook

1. Clone or download the `LayJak/Agents` repository.
2. Open the `MyGardener-iOS` folder.
3. Double-click `MyGardener.xcodeproj`.
4. In Xcode select the **MyGardener** target → **Signing & Capabilities**.
5. Choose your Apple ID / Development Team. If `com.mygardener.app` is unavailable, change it to a unique bundle identifier such as `com.leightonj.mygardener`.
6. Connect your iPhone and select it as the run destination.
7. Press **Run ▶**.
8. Accept notification, Calendar, and Reminders permissions when you use those features.

A paid Apple Developer membership is not required for the first direct device test, although free provisioning can require periodic re-signing. TestFlight/App Store distribution does require the normal Apple Developer/App Store Connect flow.

## App icon note

The repository contains a valid 1024×1024 placeholder app icon so the asset catalog is complete and Xcode can build without a missing-icon error. Replace `MyGardener/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` with the final approved MyGardener icon before distribution.

## Important native-v1 limitation

The nationwide PRISM/AHS/Thrive raster is not silently approximated. The first native build includes the Thrive rules and calibrated McKinney climate vector for device validation; nationwide raster rendering remains the next map-specific port.

## Validation performed before transfer

- Swift sources were parsed with Swift 6.2.
- Platform-independent model/calendar/monitoring/Thrive code was type-checked.
- Final iOS SDK compilation and signing must be performed in Xcode on macOS.
