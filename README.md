# SquadUp

Flutter app (Material 3) for finding gaming teammates: login/sign-up, Home dashboard, Find Team,
Games, Chats, Groups, News, Settings, game stats (sample data), safety tools, legal pages,
looking-for-group, events, and an in-app Assistant. All data is mock data; there is no backend yet.

## Run it
1. Install Flutter (https://docs.flutter.dev/get-started/install).
2. Open a terminal in this folder and generate the platform folders (android, ios, web...):
       flutter create . --project-name squadup --platforms=web,android,ios
   (This keeps lib/main.dart and pubspec.yaml; if it asks, do not overwrite them.)
3. Install packages:
       flutter pub get
4. Run in Chrome:
       flutter run -d chrome --web-port 3001

## Structure
- lib/main.dart  - the whole app in one file (logos are embedded as base64 inside it)
- assets/logos/  - the sharpened logo PNGs, for reference/use in store listings
- pubspec.yaml   - dependencies: image_picker, url_launcher

## Before a public launch
- Replace the demo/mock data with a real backend (accounts, chat, notifications, moderation).
- Fill in affiliate IDs (kAffiliateIds) and store link formats near "Store / affiliate links".
- Have a lawyer review the Terms, Privacy Policy and Community Guidelines templates.
- The code was never compiled in the environment it was written in; fix any small errors on first run.
