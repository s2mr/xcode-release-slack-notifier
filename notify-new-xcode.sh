#!/bin/bash

set -eu

#### SETTING VALUE YOURSELF ####

# example: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
# ref: https://api.slack.com/messaging/webhooks#posting_with_webhooks
SLACK_WEBHOOK_URL=''

# How many days do you run this script every other day?
# Check this value equally to ci cron interval.
CHECK_DAY_INTERVAL=1

#### SETTING VALUE YOURSELF ####

FETCH_URL='https://xcodereleases.com/data.json'

echo "Check new Xcode version via xcodereleases.com"

latestXcodeJson=$(curl --silent $FETCH_URL | jq ".[0]")
requiresMac=$(echo "$latestXcodeJson" | jq -r .requires)
swiftVersion=$(echo "$latestXcodeJson" | jq -r .compilers.swift[0].number)
swiftBuild=$(echo "$latestXcodeJson" | jq -r .compilers.swift[0].build)
developmentPhase=$(echo "$latestXcodeJson" | jq -r ".version.release | to_entries[0].key") # `rc`, `gm`, `release`, ...
developmentPhaseUppered=$(echo "$developmentPhase" | tr '[:lower:]' '[:upper:]')
developmentNumber=$(echo "$latestXcodeJson" | jq -r ".version.release | to_entries[0].value") # `true`, `1`, `2`, ...
iOSVersion=$(echo "$latestXcodeJson" | jq -r .sdks.iOS[0].number)
iOSBuild=$(echo "$latestXcodeJson" | jq -r .sdks.iOS[0].build)
xcodeVersion=$(echo "$latestXcodeJson" | jq -r .version.number)
xcodeBuild=$(echo "$latestXcodeJson" | jq -r .version.build)
downloadUrl=$(echo "$latestXcodeJson" | jq -r .links.download.url)
releaseNoteUrl=$(echo "$latestXcodeJson" | jq -r .links.notes.url)
releaseYear=$(echo "$latestXcodeJson" | jq -r .date.year)
releaseMonth=$(echo "$latestXcodeJson" | jq -r .date.month)
releaseDay=$(echo "$latestXcodeJson" | jq -r .date.day)
releaseDate=${releaseYear}-${releaseMonth}-${releaseDay}

todayDate=$(date "+%Y-%-m-%-d")
releaseUnixTime=$(date -j -f "%Y-%m-%d" "${releaseDate}" +%s)
todayUnixTime=$(date -j -f "%Y-%m-%d" "${todayDate}" +%s)
elapsedDay=$(( (todayUnixTime - releaseUnixTime) / 60 / 60 / 24 ))

if [ $elapsedDay -gt $CHECK_DAY_INTERVAL ]
then
    echo "Skip slack post."
    exit 0
fi

if [ "$developmentPhaseUppered" = "RELEASE" ]
then
    xcodeVersionText="${xcodeVersion}"
else
    xcodeVersionText="${xcodeVersion} ( ${developmentPhaseUppered}${developmentNumber} )"
fi

slackPayloadJson=$(cat << EOS
{
	"blocks": [
		{
			"type": "header",
			"text": {
				"type": "plain_text",
				"text": "Xcode ${xcodeVersionText} is released!",
				"emoji": true
			}
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*Build:*\n${xcodeBuild}"
				},
				{
					"type": "mrkdwn",
					"text": "*Requires:*\nmacOS ${requiresMac}+"
				},
				{
					"type": "mrkdwn",
					"text": "*Swift:*\n${swiftVersion} (${swiftBuild})"
				},
				{
					"type": "mrkdwn",
					"text": "*iOS:*\n${iOSVersion} (${iOSBuild})"
				}
			]
		},
		{
			"type": "actions",
			"elements": [
				{
					"type": "button",
					"text": {
						"type": "plain_text",
						"emoji": true,
						"text": "Download"
					},
					"url": "${downloadUrl}"
				},
				{
					"type": "button",
					"text": {
						"type": "plain_text",
						"emoji": true,
						"text": "Release Notes"
					},
					"url": "${releaseNoteUrl}"
				}
			]
		}
	]
}
EOS
)

curl --silent -o /dev/null -X POST -H "Content-type: application/json" --data "$slackPayloadJson" "$SLACK_WEBHOOK_URL"
echo "Send message to slack."
