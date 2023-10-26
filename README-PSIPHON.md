# Psiphon Changes

## List of Changes

This is a summary of the Psiphon specific content changes.

### Change default theme from dark to light

- Remove conf/custom.ini from the .gitignore because we need the custom config to be used for changing the default theme from dark to light.
- Add a conf/custom.ini which sets the default theme to light.
- Remove theme change radio buttons from user preferences form.
- Remove theme change option from nav menu.

### Add custom Psiphon content to email templates

- Remove "Grafana" specific content from email mjml and txt template files.
- Add Psiphon/PDE specific content to email mjml and txt template files.
- Replace Grafana logo with Psiphon logo in email header.
- Generate corresponding new emails.

### Add Psiphon colors and branding to website

- Add Psiphon theme colors to a custom color file.
- Import custom Psiphon orange colors into color palette files.
- Add Psiphon orange colors as "primary" colors for theme color file.
- Replace Grafana orange with Psiphon orange where it is used as an accent color throughout website.
- Replace Grafana gradients with Psiphon orange where used as accent colors.
- Change Favicon, appletouchicon, to Psiphon logos.
- Change app name to Psiphon.
- Add PDE logo as main website header logo, update sizing so it fits properly on page.
- Change content that refers to the application as "Grafana" to "Psiphon" or "PDE".
- Add generated scss file.

### Add Psiphon branding to login page

- Use Psiphon logo on login page instead of Grafana logo .
- Use custom background image on login page.
- Remove Grafana welcome message on login page.
- Change App Title on login page to 'Psiphon Data Engine' instead of Grafana.
- Remove footer links from login page.
- Remove overlay box that doesn't work with light background to look better with our custom content.
- Shift login box higher up on page so it looks better with background image.

### Change website functionality for our requirements

- Remove time range options that we don't want available.
- Limit access to "Dashboards" option in menu to admins and editors only.
- Remove "Help" links in nav for all users.
- In conf/custom.ini set the news feed option to false to hide the news feed
- Hide menu toggle option for users that are not admin or editor.
- Hide search bar for users that are not admin or editor.
- Update home.json file to our custom home.json file.

## Upgrading

These instructions will help you to upgrade to a newer version of Grafana while keeping the custom Psiphon changes.

1. Decide on the release tag you would like to upgrade to from the Grafana repository.
2. Clone the Grafana project from https://github.com/grafana/grafana and checkout the tag for the version you would like to upgrade to. For example `git checkout tags/v9.5.6`, replace v9.5.6 with the tag you are going to upgrade to. You will get a warning about being in a detached state, that is expected.
3. It would be a good idea to make sure you can run the base version at this point. Follow the steps in the Grafana [developer guide](https://github.com/grafana/grafana/blob/main/contribute/developer-guide.md) to build and run a local version of Grafana.
   - If you experience yarn issues, you may need to switch to Node version 16.14.2 with nvm.
   - If you experience issues with `make run`, make sure your installed go version meets the requirement in `go.mod`.
4. Your origin will be the grafana project at this point, but you should switch your origin to be the fork where the branch with the Psiphon changes that you will be referencing exists, and where you will be creating your new branch. For example `git remote set-url origin <ssh_remote_url>`, replacing the url with a reference to your new origin.
5. Create and checkout a new branch named for your new Psiphon version of Grafana. For example `git checkout -b 9.5.6-psiphon`.
6. Merge the reference branch from your new origin into your local copy of the target Grafana version `git merge origin/9.5.1-psiphon`. If you receive an error message about not being able to merge, run `git fetch --all` and try to merge again.
7. You will now have the changes from the reference Psiphon Grafana branch merged into your new Grafana version branch. There will most likely be several changes that will have no conflicts, and some with merge conflicts that need to be worked through. The list of Psiphon Changes above is a good reference point to understand the changes made to create the Psiphon version of Grafana. You can also look at the Merge Conflicts and Upgrade Notes below for help on working through the conflicts.
8. Once the merge is complete, run the project locally to make sure that it works. Follow the steps in the Grafana [developer guide](https://github.com/grafana/grafana/blob/main/contribute/developer-guide.md). Look at the project to make sure that there weren't any changes in the upgrade that require new customizations.
9. It would be a good idea to look through the [Grafana changelog](https://github.com/grafana/grafana/blob/main/CHANGELOG.md) for any changes you think might be relevant to our customizations. Make any relevant changes if needed.
10. If any changes have to be made to the customizations, please update the list above to include those new changes.

### Merge Conflicts and Upgrade Notes

- Several `package.json` files, `lerna.json`, and possibly other files may have merge conflicts that are just changes to the version number. In this case accept the changes that are for the target version number of your upgrade.
- All of the custom Psiphon changes, other than a few specific exceptions, should have comments that describe the change, and all of the comments should include "Psiphon" in the comment, so that it is obvious that this change is part of the Psiphon customizations.
- The name Psiphon is also used for naming custom colors and files where possible to make it obvious that a change was part of the Psiphon customizations.
- The `.txt` files with custom changes don't have comments in them.
- The html files in `public/emails` are generated files and therefore the changes they contain are not commented on. These html files are generated from the email mjml templates in `/emails`. The mjml templates contain customizations, so those customizations also end up in the generated html files. The README inside `public/emails` has information on how to generate/re-generate those files. If there are changes to the mjml templates files, the html files should be re-generated.
