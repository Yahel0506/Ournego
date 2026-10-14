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
replaces the attached file.

## Going to 1.0.0

When the beta ends, merge a commit with a `Release-As: 1.0.0` footer (or edit
the release PR) and remove `bump-minor-pre-major` from the config so breaking
changes bump the major version.
