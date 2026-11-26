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

`.github/scripts/release_notes.py` reads the commits since the previous `vX.Y.Z` tag and asks Claude
for short user-facing notes in both languages (500 characters each, Play's limit). They are shown in
the run summary before you approve. Write commit subjects as `feat:` / `fix:` lines a user would
understand. Without `ANTHROPIC_API_KEY`, or if the call fails, the notes are the `feat:`/`fix:`
subjects in English.

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
