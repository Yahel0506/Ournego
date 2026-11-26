# Android AAB compatibility verification — OUR-121

Verification date: 2026-11-25. Artifact: `build/app/outputs/bundle/release/app-release.aab`, built from `main` at `dc626a4` with `flutter build appbundle --release --dart-define-from-file=.env` and the upload key (SHA-256 `12:80:16:10:…:B6:6E`, valid until 2053-09-03). Inspected the bundle itself (bundletool 1.18.1 `validate`, `aapt2` on the base module, `llvm-readelf`, `zipalign`), not the source configuration. The AAB is 52.7 MB.

Flutter printed "Release app bundle failed to strip debug symbols from native libraries" but still produced the signed AAB. The cause was not investigated; check it before the Play upload if native debug symbols are wanted.

## Package, target API and permissions

| Item | Result |
| --- | --- |
| Package / version | `com.ournego.app`, `0.5.0`, versionCode 1 |
| Target / compile SDK | 36 / 36 (minSdk 24, confirmed on device) |
| Launcher activity | `com.ournego.app.MainActivity` |
| Permissions | `ACCESS_FINE_LOCATION`, `INTERNET`, `ACCESS_NETWORK_STATE`, `RECORD_AUDIO`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `com.ournego.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` |
| Gone since OUR-122 | `CALL_PHONE`, `READ_GSERVICES` |

`USE_BIOMETRIC` and `USE_FINGERPRINT` are still contributed transitively (AndroidX biometric). They are declared by SDKs, not by app code; decide before release whether to keep them.

## Architectures and native libraries

`arm64-v8a`, `armeabi-v7a` and `x86_64`, each with `libflutter.so`, `libapp.so` and `libdatastore_shared_counter.so`. `extractNativeLibs=false`.

## 16 KB page sizes (static)

- ELF `LOAD` segment alignment: `arm64-v8a` and `x86_64` `libflutter.so`/`libapp.so` use 0x10000 (64 KB). `libdatastore_shared_counter.so` uses 0x4000 (16 KB) on all three ABIs, as does `armeabi-v7a` `libapp.so`. `armeabi-v7a` `libflutter.so` uses 0x10000. All meet the 16 KB requirement.
- The universal APK generated from the AAB passes `zipalign -c -P 16 -v 4`: every `.so` is stored page-aligned.
- **Not tested at runtime on a 16 KB device.** The local `android-37.2 google_apis_playstore_ps16k` image is empty (incomplete download) and `avdmanager` is not installed. The test devices below use 4 KB pages.

## Install and launch

| Device | Android | Pages | Result |
| --- | --- | --- | --- |
| Samsung Galaxy S24 (`SM_S921B`, arm64-v8a) | 17 (API 37) | 4 KB | Installed from the AAB through bundletool device-specific APKs, versionCode 1 / 0.5.0, `pm grant` of location. `am start -W` returned `Status: ok`, `TotalTime: 631 ms`. The process stayed alive, the crash log was empty, and the onboarding screens rendered and navigated. |

The S24 previously had versionCode 36 of the same package with the same signing key. A lower versionCode cannot replace it, so the app was uninstalled first, which removed its local data (approved by the owner).

## Not covered

- Android 7.0 (API 24, minSdk) and any intermediate versions: no system image available locally.
- 16 KB runtime test (see above).
- Play-installed build and Play App Signing re-signing: no Play Console account yet.
- Google sign-in, location, microphone and photo selection on the new bundle: only launch and onboarding were exercised.
