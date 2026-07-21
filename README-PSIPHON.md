# Psiphon Changes

This branch (`12.3.1-psiphon`) is Grafana OSS v12.3.1 plus the Psiphon
customizations described below. Every intentional change in source files is
marked with a comment containing the word "Psiphon" so the full delta can be
found with a search for `Psiphon` (binary assets, `.txt` email templates, and
generated files excepted).

## List of Changes

This is a summary of the Psiphon specific content changes.

### Change default theme from dark to light

- Remove theme change selector from user preferences form
  (`public/app/core/components/SharedPreferences/SharedPreferences.tsx`).
- Remove theme change option from the command palette
  (`public/app/features/commandPalette/actions/staticActions.ts`).
- Note: the default theme itself is now set via `grafana.ini`
  (`users.default_theme = light`) in the helm chart, not in this repository.
  See "Removed customizations" below.

### Add custom Psiphon content to email templates

- Remove "Grafana" specific content from email mjml and txt template files in
  `emails/templates/`.
- Add Psiphon/PDE specific content to email mjml and txt template files.
- Replace Grafana logo with Psiphon logo in email header partial.
- Regenerate the files in `public/emails/` by running `make` in `emails/`
  (requires `npm install` in `emails/` first).
- `public/emails/alert_notification.html` and
  `public/emails/alert_notification.txt` have no corresponding template and are
  edited directly (legacy alerting emails; only used by tests since Grafana 11).
- New in 12.x: `passwordless_verify_existing_user` and
  `passwordless_verify_new_user` templates exist upstream. They inherit the
  Psiphon header/footer partials automatically when regenerated.

### Add Psiphon colors and branding to website

- Add Psiphon theme colors in
  `packages/grafana-data/src/themes/psiphonTheme.ts`.
- Import Psiphon orange colors into `createColors.ts` and expose them on the
  theme as `theme.colors.psiphon`.
- Use Psiphon orange as "primary" color for the light theme.
- Replace Grafana orange/gradients with Psiphon orange where used as accent
  colors (`Tab.tsx`, `TimeRangePicker.tsx` UTC label, command palette
  `ResultItem.tsx`, `QueryOperationAction.tsx`).
- Change favicon and apple-touch icon to Psiphon logos and app title to
  "Psiphon" (`pkg/api/index.go`).
- Add PDE logo in two variants: the wide wordmark (726x45,
  `psiphon_pde_icon.png`) in the top bar with custom sizing
  (`SingleTopBar.tsx` / `Branding.MenuLogo`), and the square Psiphon icon
  (`psiphon-logo-512x512.png`) in the mega menu header where the wordmark does
  not fit next to the org switcher and dock button
  (`MegaMenuHeader.tsx` / `Branding.MenuLogoIcon`).
- Change `$blue-base` to Psiphon orange in
  `public/sass/_variables.light.generated.scss`.

### Add Psiphon branding to login page

- Use Psiphon logo on login page instead of Grafana logo (`Branding.tsx`).
- Use custom background image on login page.
- Remove Grafana welcome message on login page (`LoginLayout.tsx`).
- Change App Title to 'Psiphon Data Engine' instead of Grafana.
- Remove footer links from login page.
- Remove overlay box background that doesn't work with the custom image.
- Shift login box higher up on page so it looks better with background image.
- Note: `Branding.LoginTitle` is kept as a field (12.x's
  `PasswordlessConfirmationForm` assigns to it) but it is never rendered.

### Change website functionality for our requirements

- Limit access to "Dashboards", "Starred", "Explore", "Drilldown", and
  "Alerting" nav sections to admins and editors only
  (`pkg/services/navtree/navtreeimpl/navtree.go`). "Drilldown" is new in 12.x
  and is gated for the same reason as "Explore".
- Remove "Help" links in nav for all users (same file). This also removes the
  Help button from the top bar, which reads the same nav node.
- Hide the mega menu (toggle button, overlay, and the 12.x docked mode) for
  users that are not admin or editor (`AppChrome.tsx`, `SingleTopBar.tsx`).
  Viewers see the plain PDE logo instead of the menu toggle.
- Hide search / command palette trigger for users that are not admin or editor
  (`SingleTopBar.tsx`).
- Update `public/dashboards/home.json` to our custom home dashboard.

## Removed customizations (12.3.1 upgrade)

The following customizations from the `11.0.0-psiphon` branch were removed
during the 12.3.1 upgrade to shrink the fork. Do not re-add them when
upgrading; they are handled by configuration in the
`helm-charts` repository (`charts/pde-dashboards/values.yaml`) instead.

- **`conf/custom.ini` (deleted).** It was a 1,500-line copy of the defaults
  file whose only real settings were `users.default_theme = light` and
  `news.news_feed_enabled = false`. Both are plain Grafana settings and are now
  set in `grafana.ini` in the helm chart values. The corresponding `.gitignore`
  edit was also dropped.
- **Time range quick options patch
  (`packages/grafana-ui/src/components/DateTimePickers/options.ts`).** Grafana
  now supports configuring the time picker quick ranges via the
  `[time_picker] quick_ranges` ini setting, so the curated list moved to
  `grafana.ini` in the helm chart values.
- **All Dockerfile fixes.** The fixes carried on the 11.0 branch
  (`project.json`/`nx.json` copy, `pkg/build/wire` go.mod copy, LICENSE copy
  ordering, arm64 binutils-gold) were adopted upstream; the v12.3.1 Dockerfile
  needs no changes.
- **`TopSearchBar.tsx` / `NavToolbar.tsx` patches.** These files were removed
  upstream in the 12.x single-top-bar redesign. The equivalent behaviour
  (hide menu and search for viewers) is implemented in `SingleTopBar.tsx` and
  `AppChrome.tsx`.

## Building and publishing the Docker image

There is no CI for this; images are built and pushed manually using the stock
upstream `Dockerfile`.

```sh
# Production image (cluster nodes are linux/amd64)
docker buildx build \
  --platform linux/amd64 \
  -t docker.psiphon.io/pde/grafana:12.3.1-psiphon \
  .

docker push docker.psiphon.io/pde/grafana:12.3.1-psiphon
```

Notes:

- Name the tag after the branch (`<grafana version>-psiphon`) so the image and
  source stay traceable to each other.
- For a quick local test build on Apple Silicon, drop `--platform linux/amd64`
  to build a native arm64 image (much faster; do not push it).
- The build is fully self-contained (Node and Go run inside the build) and
  needs no local toolchain. Expect it to take a while and to need 8GB+ of
  memory available to Docker.

## Upgrading

These instructions will help you to upgrade to a newer version of Grafana while
keeping the custom Psiphon changes.

1. Decide on the release tag you would like to upgrade to from the Grafana
   repository. Prefer the version matching `appVersion` of the
   [grafana helm chart](https://github.com/grafana/helm-charts) release you
   intend to deploy.
2. Fetch the tag from upstream and create the new branch from it, for example:
   `git remote add upstream https://github.com/grafana/grafana.git`,
   `git fetch upstream tag v12.3.1 --no-tags`,
   `git checkout -b 12.3.1-psiphon v12.3.1`.
3. Bring over the Psiphon changes from the previous `-psiphon` branch. For
   small version jumps a direct merge can work
   (`git merge origin/<previous>-psiphon`). For larger jumps (major versions)
   a direct merge drags in thousands of obsolete conflicts from the old
   release branch; in that case record the merge without content
   (`git merge -s ours origin/<previous>-psiphon`) and re-apply the delta of
   the previous branch explicitly, for example with
   `git diff <upstream base>..origin/<previous>-psiphon -- <file> | git apply --3way`
   per file, using the change list above as the checklist. This is how the
   11.0 -> 12.3.1 upgrade was done.
4. Re-generate the emails (`cd emails && npm install && make`).
5. Run `yarn install --immutable`, `yarn typecheck`, and eslint on the touched
   files. Build the Go packages you touched (`go build ./pkg/...`).
6. Look through the [Grafana changelog](https://github.com/grafana/grafana/blob/main/CHANGELOG.md)
   and What's New for anything relevant to our customizations (nav/chrome
   changes are the usual suspects).
7. Build the Docker image and verify it locally before deploying: login
   branding, light-only theme, viewer role sees no menu/search/explore, emails
   render, ClickHouse datasource loads, and a copy of a production
   `grafana.db` migrates and its dashboards render.
8. If any changes have to be made to the customizations, update the lists
   above.

### Merge conflicts and upgrade notes

- Several `package.json` files, `lerna.json`, and possibly other files may have
  merge conflicts that are just changes to the version number. In this case
  accept the changes that are for the target version number of your upgrade.
- All of the custom Psiphon changes, other than a few specific exceptions,
  should have comments that describe the change, and all of the comments should
  include "Psiphon" in the comment, so that it is obvious that this change is
  part of the Psiphon customizations.
- The name Psiphon is also used for naming custom colors and files where
  possible to make it obvious that a change was part of the Psiphon
  customizations.
- The `.txt` files with custom changes don't have comments in them.
- The html files in `public/emails` are generated files and therefore the
  changes they contain are not commented on. These html files are generated
  from the email mjml templates in `/emails`. The mjml templates contain
  customizations, so those customizations also end up in the generated html
  files. The README inside `public/emails` has information on how to
  generate/re-generate those files. If there are changes to the mjml template
  files, the html files should be re-generated.
