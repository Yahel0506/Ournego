# Release Process

Ournego uses [Semantic Versioning](https://semver.org), [Conventional Commits](https://www.conventionalcommits.org)
and [release-please](https://github.com/googleapis/release-please) to publish
releases automatically. While the app is in beta the version stays in `0.y.z`.

## Commit format

Every commit that lands on `main` must follow:

```text
<type>(<optional scope>)<optional !>: <description>
```

| Type | Use for | Version bump (while `0.x`) | In changelog |
| --- | --- | --- | --- |
| `feat` | A new user-facing feature | minor (`0.1.0` → `0.2.0`) | Features |
| `fix` | A bug fix | patch (`0.1.0` → `0.1.1`) | Bug Fixes |
| `perf` | A performance improvement | patch | Performance |
| `revert` | Reverting a previous change | patch | Reverts |
| `refactor`, `docs`, `test`, `build`, `ci`, `chore`, `style` | Everything else | none | hidden |

Add `!` after the type/scope, or a `BREAKING CHANGE:` footer, for a breaking
change. While the version is `0.x` that bumps the **minor** number; from `1.0.0`
on it bumps the **major** number.

Examples:

```text
feat(map): add zone search
fix(auth): handle expired sessions (OUR-129)
feat(business)!: require a category when registering
docs: explain the release process
```

Commits of type `refactor`, `docs`, `test`, `build`, `ci`, `chore` and `style`
never create a release on their own; they ship with the next `feat`/`fix`.

### Enforcement

- **Locally:** enable the commit hook once per clone:
  `git config core.hooksPath .githooks`
- **CI:** the `Commit Lint` workflow checks the title and every commit of each
  pull request (`tool/check_commit_subjects.sh`). Merge commits are ignored.
- Use **squash merge** with a Conventional Commit title, or rebase merge, so
  `main` only contains valid subjects. A plain merge commit is ignored by
  release-please, but the commits inside it still count.

## How a release happens

1. Work lands on `main` through pull requests.
2. On every push to `main`, the `Release` workflow runs release-please. It opens
   (or updates) a pull request named `chore(main): release X.Y.Z` that bumps
   `version:` in `pubspec.yaml` and prepends the new entries to `CHANGELOG.md`.
3. When you are ready to ship, **merge that release PR**. release-please creates
   the `vX.Y.Z` tag and the GitHub release with the changelog as notes.
4. The same workflow builds the signed APK from that tag
   (`--build-name X.Y.Z`, `--build-number` = workflow run number) and attaches
   it to the release as `ournego-beta-X.Y.Z.apk` (for example
   `ournego-beta-0.2.0.apk`), so the downloaded file already carries its version.

Each version keeps its own release, so older APKs stay downloadable. The
`https://github.com/Yahel0506/Ournego/releases/latest` page always shows the
newest one. The release notes are the changelog entry for that version, written
by release-please.

## Android upload key and Play bundles

The upload key is the private key used to authenticate AAB uploads to Google
Play. With Play App Signing enabled, Google keeps the separate app-signing key
and uses it for APKs delivered to users. Keep the upload keystore and
`android/key.properties` outside Git. Release APK and AAB builds fail unless
all four properties are present and the referenced keystore exists. Debug
builds need no upload key. Profile builds use it when configured and otherwise
use the local debug key. [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)

The current release keystore signs Ournego's GitHub APKs. Use that same
keystore for the first Play upload and later updates so every build keeps the
same upload certificate. Create a new upload key only for a new app or after
Google approves a reset for an enrolled Play app. When creating one, do so
interactively so passwords do not appear in shell history:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties` with restrictive file permissions. Gradle
resolves `storeFile` relative to `android/`:

```properties
storeFile=upload-keystore.jks
storePassword=<keystore password>
keyAlias=upload
keyPassword=<key password>
```

Keep at least two independently recoverable copies of the keystore in access
controlled storage outside the repository. Encrypt an offline backup and keep
its recovery phrase in a separate password manager. For example, GNU Privacy
Guard can create an encrypted backup interactively:

```bash
gpg --symmetric --cipher-algo AES256 \
  --output /secure-backup/ournego-upload-keystore.jks.gpg \
  android/upload-keystore.jks
```

To recover it, decrypt to a temporary path outside the repository, compare its
certificate with the recorded upload certificate, then place it under
`android/` and recreate `key.properties` from the password manager:

```bash
gpg --output /secure-temporary-path/upload-keystore.jks \
  --decrypt /secure-backup/ournego-upload-keystore.jks.gpg
keytool -list -v -keystore /secure-temporary-path/upload-keystore.jks -alias upload
```

Record the upload certificate SHA-1 and SHA-256 when the key is created. The
certificate is safe to share with Play Console and Google Cloud. Never store
the keystore passwords beside the backup. If an enrolled Play upload key is
lost or compromised, request an upload-key reset in Play Console and update
the protected local and GitHub Actions copies only after Google confirms the
reset. The Play app-signing key remains separate. See [Google's key guidance](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en).

Build a versioned AAB from the current `version:` in `pubspec.yaml`. Set a
build number greater than the last version uploaded to Play:

```bash
flutter build appbundle --release \
  --build-name=0.5.0 \
  --build-number=36 \
  --dart-define-from-file=.env
```

Update the example version and build number for each upload. This produces
`build/app/outputs/bundle/release/app-release.aab`. Verify its contents and
signature before uploading it to a Play test track:

```bash
jarsigner -verify build/app/outputs/bundle/release/app-release.aab
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Compare the certificate fingerprint with the saved release certificate. The
Android CI workflow uses a short lived throwaway key to build a smoke-test APK.
Its certificate is not the upload key and must never be used for a Play upload.

Flutter's final AAB check also needs Android SDK Command-line Tools, including
`apkanalyzer`. Install them from Android Studio's SDK Manager if Flutter reports
that it could not inspect the generated bundle.

## Configuration

| File | Purpose |
| --- | --- |
| `release-please-config.json` | Release type, changelog sections, pre-1.0 bump rules |
| `.release-please-manifest.json` | Current released version (`0.1.0` to start) |
| `.github/workflows/release.yml` | release-please + signed APK build |
| `.github/workflows/commit-lint.yml` | Conventional Commits check on pull requests |
| `tool/check_commit_subjects.sh` | The commit subject validator used by the hook and CI |

The history before the setup is ignored (`bootstrap-sha` in the config), so the
first changelog only lists commits made afterwards.

## One-time repository setup

- **Settings → Actions → General → Workflow permissions:** allow *Read and write
  permissions* and enable *Allow GitHub Actions to create and approve pull
  requests*. Without the latter, release-please cannot open the release PR.
- *(Optional)* Create a secret `RELEASE_PLEASE_TOKEN` with a personal access
  token (`contents` and `pull requests` write). Pull requests opened with the
  default `GITHUB_TOKEN` do not trigger other workflows, so with the token the
  Android CI and Commit Lint checks also run on the release PR.
- The signing and `.env` secrets used by the APK build are listed in
  `.github/workflows/release.yml`.

## Rebuilding an APK

Run the `Release` workflow manually (**Actions → Release → Run workflow**) and
give it an existing tag such as `v0.2.0`. It rebuilds the APK from that tag and
replaces the attached file. To rebuild a Play AAB locally, use the versioned
command above with the matching upload key.

## Going to 1.0.0

When the beta ends, merge a commit with a `Release-As: 1.0.0` footer (or edit
the release PR) and remove `bump-minor-pre-major` from the config so breaking
changes bump the major version.

## Debug and release side by side

Debug builds install as `com.ournego.app.debug` and show up as **Ournego Debug**;
release (and profile) builds keep `com.ournego.app` and **Ournego**. They are
different apps for Android, so a debug run never replaces or wipes the release
install, and they can be installed at the same time.

- `android/app/src/debug/google-services.json` is the Firebase config used by
  debug builds only (same project, package `com.ournego.app.debug`); the
  `google-services` plugin fails the build without a client for the package.
  Register the debug app in Firebase and replace the file if you need its own
  analytics data.
- **Google Sign-In** needs an Android OAuth client in Google Cloud for
  `com.ournego.app.debug` with the SHA-1 of the debug key (`./gradlew
  signingReport`), alongside the existing `com.ournego.app` clients. Without it
  the Google login fails on debug builds only.
- Use `com.ournego.app.debug` in `adb` commands for debug builds.
