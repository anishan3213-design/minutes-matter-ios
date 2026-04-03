# Minutes Matter (iOS)

SwiftUI app for wildfire awareness: personal hub, active fire map, check-ins, family links, and an **emergency responder** mode with field map and assignments. It talks to **Supabase** (auth and profiles) and the **Minutes Matter web API** on Vercel for Flameo context, fires, shelters, and responder endpoints.

## Requirements

- Xcode 15+ (Swift 5)
- iOS **16.0** deployment target
- Apple Developer account for device builds/signing

## Configuration

Client-safe keys live in the target **`Info.plist`** at the repo root (`INFOPLIST_FILE = Info.plist`). Set:

| Key | Purpose |
|-----|---------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous (publishable) key |
| `GOOGLE_PLACES_KEY` or `GOOGLE_PLACES_API_KEY` | Google Places Autocomplete / Details (address search) |
| `GOOGLE_GEOCODING_API_KEY` | Geocoding (if used by your build) |
| `GOOGLE_ROUTES_API_KEY` | Routes (if used by your build) |

The default API base URL is set in `Minutes Matter/WildfireAlert/Utils/Config.swift` (`AppConfig.apiBaseURL`).

**Do not commit production secrets to a public repository.** Prefer Xcode build configurations, `.xcconfig` files excluded from git, or CI secrets.

## Dependencies

- **[supabase-swift](https://github.com/supabase/supabase-swift)** — resolved via Swift Package Manager in Xcode.

## Build & run

1. Clone the repo and open **`Minutes Matter.xcodeproj`**.
2. Select the **Minutes Matter** scheme and a simulator or device.
3. Build (**⌘B**) and run (**⌘R**).

Command-line build example:

```bash
xcodebuild -scheme "Minutes Matter" -destination "generic/platform=iOS" build
```

## Project layout

- `Minutes Matter/WildfireAlert/` — app sources (tabs, auth flows, hub, map, responder, services, models).
- `Minutes Matter.xcodeproj/` — Xcode project.
- `Info.plist` — bundled keys and usage strings (e.g. location).

## Bundle identifier

`com.minutesmatter.wildfirealert`

## License

If no license file is present in the repository, all rights are reserved by the project owners unless stated otherwise.
