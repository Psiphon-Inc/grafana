# 1. CHECK IF UPDATE IS NEEDED

# Get the latest stable tag name from the Psiphon fork of Grafana
LATEST_PSIPHON_TAG="$(git ls-remote --tags --sort "v:refname" "git@github.com:Psiphon-Inc/grafana.git" | awk '{print $2}' | tail -1 | sed 's/refs\/tags\///')"
# Get the latest stable tag name from the base Grafana repository
LATEST_GRAFANA_TAG="$(git ls-remote --tags --sort "v:refname" "git@github.com:grafana/grafana.git" | awk '{print $2}' | sed 's/refs\/tags\///' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)"
# Compare the two tags to see if an update is required.
[ "${LATEST_PSIPHON_TAG}" == "${LATEST_GRAFANA_TAG}-psiphon" ] && exit 0

# 2. SETUP

# Clone the Grafana repository
git clone git@github.com:grafana/grafana.git
cd grafana || exit 1
# An argument can be passed to this script to specify a Grafana version tag to checkout,
# in the format vD.D.D (e.g. v10.0.12). If no argument is provided, the latest stable
# release will be checked out. This is useful if the Psiphon version is behind by several
# versions and we want to make incremental updates. If we automate this, we can probably
# just always just checkout the latest stable release.
[ -n "${1}" ] && LATEST_GRAFANA_TAG="${1}"
git checkout "${LATEST_GRAFANA_TAG}"


# At this point we will run the test suite in the base Grafana version and make note of
# any tests that fail.
yarn install --immutable
yarn test a --watchAll=false --json --outputFile=../testResults.json
# Find tests that failed in the testResults.json file and get the fullName attribute of each.
# Save the fullNames to a variable
FAILED_TESTS_GRAFANA="$(jq -r '.testResults[] | select(.status == "failed") | .assertionResults[] | select(.status == "failed") | .fullName' "../testResults.json")"
rm ../testResults.json
printf '%s\n' "${FAILED_TESTS_GRAFANA[@]}" > ../failedInGrafana.txt

# Set the origin to the Psiphon fork
git remote set-url origin "git@github.com:Psiphon-Inc/grafana.git"
git fetch --all
# Create and checkout a branch named for the new version tag
git checkout -b "$(echo "${LATEST_GRAFANA_TAG}" | sed 's/^v//')-psiphon"

# 3. PERFORM CUSTOM MERGE STEPS

# Copy conf/sample.ini to conf/custom.ini so we get the base Grafana configuration file
# before adding any Psiphon customizations
cp conf/sample.ini conf/custom.ini
# Merge the latest stable tag from origin (which is the Psiphon fork) into the new branch
# we cloned from Grafana
git merge --no-commit "${LATEST_PSIPHON_TAG}"
# Get a list of files with conflicts (just used to compare to later)
CONFLICTED_FILES="$(git diff --name-only --diff-filter=U)"
# Git reset to unstage all files. This is necessary because there are changes that would
# be staged in a normal merge which we do not want to commit.
git reset
# Git add files that are specific custom Psiphon files
git add "README-PSIPHON.md" "packages/grafana-data/src/themes/psiphonTheme.ts" "public/img/"*psiphon*.png "conf/custom.ini"
# Any files that do not exist in the Grafana base, but do exist in the Psiphon tag, other
# than the files listed above, should be deleted. Delete these by removing any untracked
# files that exist after adding the files listed above.
git clean -fd
# Files that were merged without conflict, and are files that contain Psiphon custom
# changes should be added to the commit as git should have merged them correctly. This
# will include any files that contain the string "psiphon change", the files
# public/dashboards/home.json, public/sass/_variables.light.generated.scss, and any txt
# files within the emails/templates folder.

# Add any files that contain the string "psiphon change" and are not in conflict.
# (check for conflict by checking if the file contains the string "<<<<<<< HEAD")
for file in $(git diff --name-only | xargs grep -l -i 'psiphon change' | xargs grep -L -i '<<<<<<< HEAD'); do
    git add "${file}"
done
# If the file public/dashboards/home.json does not have any conflicts, add it to the commit
[ "$(git diff --name-only | grep 'public/dashboards/home.json' | xargs grep -l -i -c '<<<<<<< HEAD')" -eq 0 ] && git add public/dashboards/home.json
# All of the txt files within emails/templates that do not have conflicts should be added to the commit
for file in $(git diff --name-only | grep 'emails/templates' | grep '.txt' | xargs grep -L -i '<<<<<<< HEAD'); do
    git add "${file}"
done
# If the file public/sass/_variables.light.generated.scss does not have any conflicts, add it to the commit
[ "$(git diff --name-only | grep 'public/sass/_variables.light.generated.scss' | xargs grep -l -i -c '<<<<<<< HEAD')" -eq 0 ] && git add public/sass/_variables.light.generated.scss
# Any files that are not in conflict, are not yet added, and are not within the folder
# public/emails, should be checked out to the --ours version (meaning the Grafana base version) and added to the commit.
# These are files that do not contain Psiphon custom changes, so we want to keep the Grafana base version.
for file in $(git diff --name-only | grep -v 'public/emails' | xargs grep -L -i '<<<<<<< HEAD')
do
    git checkout --ours "${file}"
    git add "${file}"
done
# If there are no unstaged files within emails/templates, we can run the script to update the email templates.
# If there are unstaged files, there are conflicts that need to be resolved manually so skip this step.
if [ "$(git diff --name-only | grep -c 'emails/templates')" -eq 0 ]; then
    # Run script to generate email templates
    cd emails || exit
    npm install
    make
    cd ..
    rm emails/package-lock.json
    # Add the generated public/emails files to the commit as long as they are not in conflict
    for file in $(git diff --name-only | grep 'public/emails' | xargs grep -L -i '<<<<<<< HEAD'); do
        git add "${file}"
    done
fi
# Any files that are still not added to the commit, and do not possibly include Psiphon
# custom changed should be checked out to the --ours version and added to the commit.
# The difference between this and the previous loop is that this loop includes files that are in conflict.
# todo: could this loop and the previous loop be combined?
for file in $(git diff --name-only | grep -v 'emails/templates' | grep -v 'public/dashboards/home.json' | grep -v 'public/sass/_variables.light.generated.scss' | grep -v 'public/emails' | xargs grep -L -i 'psiphon change'); do
    git checkout --ours "${file}"
    git add "${file}"
done

# 4.  CHECK STATUS OF MERGE

# If there are still unstaged files, there are conflicts that need to be resolved
# manually. Notify the user and exit.
if [ "$(git diff --name-only | wc -l)" -gt 0 ]; then
    cd ..
    ./reporter.sh 0 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
    exit 1
fi

# 5. RUN TESTS

# Run the test suite again and make note of any tests that fail.
yarn test a --watchAll=false --json --outputFile=../testResults-changed.json
# Find tests that failed in the testResults.json file and save the fullNames to a variable
FAILED_TESTS_CHANGED="$(jq -r '.testResults[] | select(.status == "failed") | .assertionResults[] | select(.status == "failed") | .fullName' ../testResults-changed.json)"
rm ../testResults-changed.json
# Compare the list of failed tests from the base Grafana version to the list of failed
# tests from the Psiphon version. If there are any tests that failed in the Psiphon version
# that did not fail in the base Grafana version, notify the user and exit.
printf '%s\n' "${FAILED_TESTS_CHANGED[@]}" > ../failedInChanged.txt
grep -Fxvf ../failedInGrafana.txt ../failedInChanged.txt > ../failedInChangedOnly.txt
# We want to ignore any tests that we expect to fail because of Psiphon customizations.
# These tests are listed in the file expectedToFail.txt.
grep -Fxvf ../expectedToFail.txt ../failedInChangedOnly.txt > ../failedUnexpectedly.txt
if [ "$(wc -l < ../failedUnexpectedly.txt | tr -d " ")" -gt 0 ]; then
    if [ "${#CONFLICTED_FILES}" -gt 0 ]; then
        cd ..
        ./reporter.sh 1 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    else
        cd ..
        ./reporter.sh 5 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    fi
fi

# Remove txt files that were created for comparing lists of failed tests.
rm ../failedInGrafana.txt ../failedInChanged.txt ../failedInChangedOnly.txt ../failedUnexpectedly.txt

# 6. BUILD
# Attempt to build the project, and notify the user if it fails.
if ! make build; then
    if [ "${#CONFLICTED_FILES}" -gt 0 ]; then
        cd ..
        ./reporter.sh 2 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    else
        cd ..
        ./reporter.sh 6 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    fi
fi

# 7. PUSH
git commit -m "Merge ${LATEST_GRAFANA_TAG} onto ${LATEST_PSIPHON_TAG}"
if ! git push origin "$(echo "${LATEST_GRAFANA_TAG}" | sed 's/^v//')-psiphon"; then
    if [ "${#CONFLICTED_FILES}" -gt 0 ]; then
        cd ..
        ./reporter.sh 3 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    else
        cd ..
        ./reporter.sh 7 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    fi
else
    if [ "${#CONFLICTED_FILES}" -gt 0 ]
    then
        cd ..
        ./reporter.sh 4 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    else
        cd ..
        ./reporter.sh 8 "${LATEST_PSIPHON_TAG}" "${LATEST_GRAFANA_TAG}"
        exit 1
    fi
fi
