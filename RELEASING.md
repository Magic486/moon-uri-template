# Release process

This checklist keeps GitHub, Gitlink, and mooncakes.io releases reproducible.
No release command should be run until the final namespace and repository URL
are confirmed.

## 1. Confirm release identity

Update these fields and every provisional namespace reference:

```mbt
// moon.mod
name = "YOUR_MOONCAKES_USERNAME/moon-uri-template"
repository = "https://github.com/OWNER/moon-uri-template"
```

The mooncakes namespace must begin with the publisher's mooncakes username.
The GitHub repository owner may be a different user or organization.

## 2. Prepare both public repositories

1. Create the public GitHub repository and make its real default branch the
   branch containing the release.
2. Import that GitHub repository into Gitlink, or add separate `github` and
   `gitlink` remotes.
3. Push the same commit to both remotes.
4. On both web pages, verify the default branch shows the README, LICENSE,
   source, tests, CI configuration, proposal, and full commit history.

Do not assume the default branch is named `main`; inspect the hosting settings.

## 3. Run the release gate

Install the two hash-pinned differential-test dependencies in an isolated
Python environment, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools/release_preflight.ps1 `
  -RequireReleaseMetadata `
  -ExpectedNamespace "USERNAME/moon-uri-template" `
  -ExpectedRepository "https://github.com/OWNER/moon-uri-template"
```

The gate regenerates conformance evidence, checks formatting and warnings,
builds and tests all four supported backends, validates the public API,
compares two independent implementations, and inspects the exact mooncakes
archive contents. It never invokes `moon publish`.

## 4. Cut version 0.1.0

1. Replace `Unreleased` in `CHANGELOG.md` with `0.1.0 - YYYY-MM-DD`.
2. Commit only the reviewed release metadata and generated API files.
3. Confirm GitHub Actions succeeds on the remote default branch.
4. Create an annotated `v0.1.0` tag pointing to that exact commit.
5. Push the branch and tag to GitHub and Gitlink.

## 5. Publish to mooncakes.io

Authenticate with `moon login`, inspect `moon package --list` once more, and
then run the state-changing command:

```bash
moon publish --frozen
```

After publication, verify the mooncakes.io package page, install
`USERNAME/moon-uri-template@0.1.0` in a fresh temporary module, and run the
README scalar example. Record the package URL and successful remote CI run in
`STATUS.md`.

## 6. Final submission evidence

Submit:

- the GitHub repository URL;
- the synchronized Gitlink repository URL;
- the mooncakes.io package URL;
- `output/pdf/moon-uri-template-project-proposal.pdf`.

The proposal must be regenerated after replacing its provisional namespace
and adding the project GitHub URL.

```powershell
python tools/generate_proposal_pdf.py `
  --namespace "USERNAME/moon-uri-template" `
  --repository "https://github.com/OWNER/moon-uri-template"
```
