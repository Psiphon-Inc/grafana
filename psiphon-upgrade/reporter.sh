# Need to get the env variables from the .env file
[ -f ".env" ] || { echo "'.env' file does not exist, aborting"; exit 1; }
source .env

[ -z "${SLACK_TOKEN}" ] && { echo "'SLACK_TOKEN' value is empty, aborting"; exit 1; }

# Function to send a report to slack
sendReport() {
    curl -X POST -H "Content-Type: application/json" \
    -d '{
            "blocks": [
                {
                    "type": "header",
                    "text": {
    			        "type": "plain_text",
    			        "text": "Grafana Upgrade Status"
    		        }
                },
                {
			        "type": "divider"
		        },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*Upgrade Status*: '"${1}"'"
                    }
                },
                {
                    "type": "section",
    		        "text": {
    			        "type": "mrkdwn",
                        "text": "*Information*: '"${2}"'"
    		        },
                },
                {
                    "type": "section",
    		        "text": {
    			        "type": "mrkdwn",
                        "text": "*Conflicts*: '"${3}"'"
    		        },
                },
                                {
                    "type": "section",
    		        "text": {
    			        "type": "mrkdwn",
                        "text": "*Tests*: '"${4}"'"
    		        },
                },
                {
                    "type": "section",
    		        "text": {
    			        "type": "mrkdwn",
                        "text": "*Build*: '"${5}"'"
    		        },
                },
                {
                    "type": "section",
    		        "text": {
    			        "type": "mrkdwn",
                        "text": "*Git*: '"${6}"'"
    		        },
                },
                {
                    "type": "divider"
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*Next Steps*: '"${7}"'"
                    }
                }
            ]
        }' \
    "https://hooks.slack.com/services/${SLACK_TOKEN}"
}

# All possible scenarios for the update process

# No update required (No report sent in this case.)
# Merge Failed (unresolved conflicts)
# Merge Success - auto-resolved conflicts -> Tests Fail
# Merge Success - auto-resolved conflicts -> Tests Pass -> Build Fail
# Merge Success - auto-resolved conflicts -> Tests Pass -> Build Success -> Push Fail
# Merge Success - auto-resolved conflicts -> Tests Pass -> Build Success -> Push Success
# Merge Success - no conflicts -> Tests Fail
# Merge Success - no conflicts -> Tests Pass -> Build Fail
# Merge Success - no conflicts -> Tests Pass -> Build Success -> Push Fail
# Merge Success - no conflicts -> Tests Pass -> Build Success -> Push Success

# This script requires an argument which can be any number from 0 to 8 (incl). Each number
# represents a different scenario for the update process and the report will be sent
# accordingly

# Latest Psiphon tag and latest Grafana tag should be passed by the second and third arguments
LATEST_PSIPHON_TAG="${2}"
LATEST_GRAFANA_TAG="${3}"

case "${1}" in
    0)
        # Merge Failed (unresolved conflicts)
        sendReport "Merge failed. :x:" \
        "Attempted to merge Grafana *${LATEST_GRAFANA_TAG}* onto tag: *${LATEST_PSIPHON_TAG}*." \
        "Conflicts found. :exclamation:" \
        "N/A" \
        "N/A" \
        "N/A" \
        "Resolve conflicts and run the remaining steps. :exclamation:"
        ;;
    1)
        # Merge Success - auto-resolved conflicts -> Tests Fail
        sendReport "Merge successful, but tests failed. :warning:" \
        "Merged tag Grafana *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were conflicts but they were automatically merged" \
        "Tests failed in the Psiphon version, which were not expected to fail, and did not fail in the Grafana base version :warning:" \
        "N/A" \
        "N/A" \
        "Review failed tests and resolve any issues. :exclamation:"
        ;;
    2)
        # Merge Success - auto-resolved conflicts -> Tests Pass -> Build Fail
        sendReport "Merge successful, but build failed. :x:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were conflicts but they were automatically merged" \
        "All tests passed." \
        "Build failed. :exclamation:" \
        "N/A" \
        "Review build errors and resolve any issues. :exclamation:"
        ;;
    3)
        # Merge Success - auto-resolved conflicts -> Tests Pass -> Build Success -> Push Fail
        sendReport "Merge successful, but push failed. :x:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were conflicts but they were automatically merged" \
        "All tests passed." \
        "Build was successful." \
        "There was a problem with the new branch. :exclamation:" \
        "Check git status and resolve any issues. :exclamation:"
        ;;
    4)
        # Merge Success - auto-resolved conflicts -> Tests Pass -> Build Success -> Push Success
        sendReport "Merge successful. :white_check_mark:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were conflicts but they were automatically merged" \
        "All tests passed." \
        "Build was successful." \
        "Created new branch for version $LATEST_GRAFANA_TAG and pushed to remote." \
        "Review changes and create new release. :git: https://github.com/Psiphon-Inc/grafana/compare/master...Psiphon-Inc:grafana:${LATEST_GRAFANA_TAG}-psiphon"
        ;;
    5)
        # Merge Success - no conflicts -> Tests Fail
        sendReport "Merge successful but tests failed. :warning:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were no conflicts." \
        "Tests failed in the Psiphon version, which were not expected to fail, and did not fail in the Grafana base version :warning:" \
        "N/A" \
        "N/A" \
        "Review failed tests and resolve any issues. :exclamation:"
        ;;
    6)
        # Merge Success - no conflicts -> Tests Pass -> Build Fail
        sendReport "Merge successful but build failed. :x:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were no conflicts." \
        "All tests passed." \
        "Build failed. :exclamation:" \
        "N/A" \
        "Review build errors and resolve any issues. :exclamation:"
        ;;
    7)
        # Merge Success - no conflicts -> Tests Pass -> Build Success -> Push Fail
        sendReport "Merge successful but push failed. :x:" \
        "Merged tag *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were no conflicts." \
        "All tests passed." \
        "Build was successful." \
        "There was a problem with the new branch. :exclamation:" \
        "Check git status and resolve any issues. :exclamation:"
        ;;
    8)
        # Merge Success - no conflicts -> Tests Pass -> Build Success -> Push Success
        sendReport "Merge successful. :white_check_mark:" \
        "Merged tag Grafana *${LATEST_GRAFANA_TAG}* onto tag *${LATEST_PSIPHON_TAG}*." \
        "There were no conflicts." \
        "All tests passed." \
        "Build was successful." \
        "Created new branch for version ${LATEST_GRAFANA_TAG} and pushed to remote." \
        "Review changes and create new release. :git: https://github.com/Psiphon-Inc/grafana/compare/master...Psiphon-Inc:grafana:${LATEST_GRAFANA_TAG}-psiphon"
        ;;
    *)
        echo "Invalid argument. Please enter a number from 0 to 9 (inclusive)."
        ;;
esac

# Todo - "Tests failed in the Psiphon version, but not in the Grafana version :warning: \n ${FAILED_CHANGED_ONLY[*]}" \
