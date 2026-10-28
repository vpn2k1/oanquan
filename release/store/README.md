# English store submission assets

This folder contains English listing copy in [en.md](en.md) and media captured from the running app. The app's original icon is preserved in `assets/app_icon.png` and `master/icon.png`.

| Store field | File to use | Status |
| --- | --- | --- |
| Google Play app icon | `play/icon-512.png` (512 × 512 PNG) | Ready |
| Google Play feature graphic | `play/feature-graphic.png` (1024 × 500 PNG) | Ready |
| Google Play phone screenshots | `screenshots/play/en/` (five 1920 × 1080 PNGs) | Ready; upload in filename order |
| Google Play preview video | `video/google-play-en.mp4` (1920 × 1080, 25 seconds) | File ready; upload to YouTube and add its URL in Play Console |
| App Store iPhone screenshots | `screenshots/ios/en/` (four 2622 × 1206 JPEGs) | Ready; upload game, setup, local play, then settings |
| App Store iPhone app preview | `video/app-store-iphone-en.mp4` (1920 × 886, 25 seconds) | Ready; optional in App Store Connect |
| App Store iPad screenshots | — | Still needed because the iOS app supports iPad |

The videos show recorded gameplay from the iPhone Simulator. The Play version fills a 16:9 frame with a blurred copy of the same recording behind the uncut game view. Both videos contain a silent stereo audio track. The App Store app icon comes from the app binary.

## Before submission

- Upload the Play video to YouTube as public or unlisted, keep embedding enabled, and turn off ads for the video. Enter the YouTube URL in Play Console; Play Console does not take the MP4 directly.
- Capture iPad screenshots from a running iPad build. A temporary iPad Simulator was created, but its build failed when the machine ran out of disk space; the temporary simulator was removed.
- Supply the public support email, support URL, and privacy policy URL, then complete Google Play Data safety and App Store App Privacy forms after reviewing SDK behavior. The app currently has no visible ads, although the Google Mobile Ads SDK is initialized with test IDs.
- Finish the developer/seller, copyright, distribution, pricing, age rating, signing, and release-build fields. Add the App Store numeric app ID to `lib/app/update/store_links.dart` once the app record exists.

Reference: [Google Play preview asset specifications](https://support.google.com/googleplay/android-developer/answer/9866151), [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), and [Apple app preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications).
