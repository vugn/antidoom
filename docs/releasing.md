# Releasing

One flow ships both builds. Bump `version:` in `pubspec.yaml` (the number after `+` must be higher than
the last Play upload), commit, then:

```bash
git tag v1.0.3 && git push origin main v1.0.3
```

| Workflow | What it does |
| :--- | :--- |
| **Release** | Builds the `foss` APKs and publishes the GitHub release. |
| **Play release** | Builds the `play` bundle, writes release notes (English + Indonesian), uploads to the **internal** testing track, then waits. |

Test the build from the internal track. When it is good, open the run in the Actions tab and
**Review deployments -> Approve**. The `production` job then promotes that same release as a staged
rollout (20% by default; run the workflow by hand to choose another fraction, or finish the rollout in
Play Console).

## Release notes

Play allows 500 characters per language. Before tagging, put the notes in
`android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` and `.../id/changelogs/<versionCode>.txt`
(ask Claude Code: "write the release notes for this version"; it reads the commits and writes both).
Commit them; the workflow uses them as written and shows them in the run summary before you approve.

If those files are missing, `.github/scripts/release_notes.py` writes them: with `ANTHROPIC_API_KEY` set,
Claude turns the commits since the previous `vX.Y.Z` tag into notes in both languages; without it, the
notes are the `feat:` / `fix:` commit subjects in English only.

## One-time setup

1. **Play API access.** Google Cloud: create a project, enable *Google Play Android Developer API*,
   create a service account and download its JSON key. Play Console -> Users and permissions -> invite
   that service account with *Release to production* and *Release apps to testing tracks*.
2. **Secrets** (repo Settings -> Secrets): `PLAY_SERVICE_ACCOUNT_JSON` (the whole JSON file) and,
   optionally, `ANTHROPIC_API_KEY`. `KEYSTORE_*` and `ADMOB_*` are already set.
3. **Environment**: `production` with yourself as required reviewer (already created).
4. **Internal testing**: Play Console -> Testing -> Internal testing -> add a tester list.

The first run for a version cannot upload a bundle whose `versionCode` already exists in Play, so
don't upload the same version by hand as well.
