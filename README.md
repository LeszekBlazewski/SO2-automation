# SO2-automation

Beachlor thesis on Wrocław University of Science and Technology

## First plan

Docker compose file with

1. Jenkins container

2. Gerrit container

Jenkins has auto plugin installed which allows Gerrit integrations

Auto Gerrit configuration at first just basic setup with become.

Gerrit container should have a test repo inside configured.

Test script which clones a repo from inside Gerrit container and runs some tests on it.
