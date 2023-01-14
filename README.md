# xcode-release-slack-notifier

Check xcode releases from [Xcode Releases](https://xcodereleases.com/), and when new version released, notify to slack.

# Usage

Simply run script in your ci with cron.

```
./notify-new-xcode.sh
```

When new version released, send to slack.

<img width="459" alt="スクリーンショット 2023-01-14 23 36 19" src="https://user-images.githubusercontent.com/19924081/212477383-dea723f7-6982-4a4c-a65f-7ea591c5cde8.png">

## Setup

Fill constant in scripts.

```
SLACK_WEBHOOK_URL
CHECK_DAY_INTERVAL
```

## Example - CircleCI

Update your `.circleci/config.yml`

```
version: 2.1

executors:
  macos_exec:
    macos:
      xcode: 14.2.0
      shell: /bin/bash --login -eo pipefail

jobs:
  notify-new-xcode:
    executor: macos_exec
    steps:
      - run:
          name: Notify new xcode version
          command: ./notify-new-xcode.sh

workflows:
  notify-new-xcode-test:
    triggers:
      - schedule:
          cron: "0 0 * * *" # every day
          filters:
            branches:
              only: master
    jobs:
      - notify-new-xcode:
```