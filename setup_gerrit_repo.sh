#!/bin/bash

set -eu

# Creates new gerrit repo with  webhook and checks for jenkins integration 
# NOTE: Http generated password must be provided to script from gerrit portal

source .env

gerrit_username=${GERRIT_USERNAME:-admin}
gerrit_user_password=${GERRIT_USER_HTTP_PASSWORD}
gerrit_user_email=${GERRIT_USER_EMAIL:-"admin@example.com"}
gerrit_url=${GERRIT_CANONICAL_WEB_URL:-http://localhost:8080}
gerrit_domain="${gerrit_url#*//}"
gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
jenkins_username=${JENKINS_USERNAME:-jenkins}
jenkins_password=${JENKINS_PASSWORD:-jenkins}

usage() {
    echo "Usage: setup_gerrit_repo.sh -p http-password-from-gerrit"
    echo "Admin HTTP password can also be stored in .env under GERRIT_USER_HTTP_PASSWORD variable"
    exit 1
}

if [[ -z "$gerrit_user_password" ]]; then
    while getopts ":p:" opt; do
        case ${opt} in
            p )
                gerrit_user_password=$OPTARG
            ;;
            * )
                usage
            ;;
        esac
    done
shift $((OPTIND-1))

if [[ -z "${gerrit_user_password}" ]]; then
    usage
fi
fi

# Encode gerrit password
encoded_gerrit_password=$(python3 -c "from urllib.parse import quote; print(quote('''$gerrit_user_password''', safe=''))")

# Http url with gerrit user credentials
gerrit_authorized_url=http://"${gerrit_username}:${encoded_gerrit_password}@${gerrit_domain}/a"

# Install checks plugin
plugin_id="checks"
plugin_source='"https://gerrit-ci.gerritforge.com/job/plugin-checks-bazel-stable-3.2/18//artifact/bazel-bin/plugins/checks/checks.jar"'
curl --header "Content-Type: application/json" \
    --request PUT \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"url":'"${plugin_source}"'}' \
    "${gerrit_authorized_url}/plugins/${plugin_id}.jar"

# Add new label Verified
# If you modify this you probably have to modify update_permission_rules_request.json also.
label_name="Verified"
label_values='"values": {
    "-1": "Fails",
    "0": "No score",
    "+1": "Verified"
    }
'

curl --header "Content-Type: application/json" \
    --request POST \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"commit_message": "Create '"${label_name}"' label", '"${label_values}"'}' \
    "${gerrit_authorized_url}/projects/All-Projects/labels/${label_name}"

# Create new Students group
group_name='Students'
curl --header "Content-Type: application/json" \
    --request PUT \
    --silent \
    --show-error \
    --output /dev/null \
    --data '"description":"Students group which allows access only to user branches", "owner":"Administrators"' \
    "${gerrit_authorized_url}/groups/${group_name}"

# Create new students group repo template

# Grant permissions for:
# 1. Label Code-Review on refs/heads/* -> Non-interactive users
# 2. READ refs/* -> Non-interactive users
# 3. checks-administrateCheckers -> Administrators, Non-interactive users
# 4. Label Verified on refs/heads/* ->  Administrators, Non-interactive users
permission_request_file='./gerrit/update_permission_rules_request.json'
curl --header "Content-Type: application/json" \
    --request POST \
    --silent \
    --show-error \
    --output /dev/null \
    --data @"${permission_request_file}" \
    "${gerrit_authorized_url}/projects/All-Projects/access"

# Create Jenkins user in gerrit
curl --header "Content-Type: application/json" \
    --request PUT \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"name":"JenkinsCI", "email": "jenkins@example.com", "groups":["Non-Interactive Users"], "http_password":"'"${jenkins_password}"'"}' \
    "${gerrit_authorized_url}/accounts/${jenkins_username}"

# Create new gerrit repository
curl --header "Content-Type: application/json" \
    --request PUT \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"description":"Sample project for Jenkins<->gerrit integration", "permissions_only": false, "parent": "", "create_empty_commit":true}' \
    "${gerrit_authorized_url}/projects/${gerrit_project_name}"

# Create new check for Jenkins job in ${gerrit_project_name} gerrit repo
# Adjust variables in check request
check_request_file='./gerrit/create_check_request.json'
sed -i "s/gerrit_project_name/${gerrit_project_name}/" "$check_request_file"

curl --header "Content-Type: application/json" \
    --request POST \
    --silent \
    --show-error \
    --output /dev/null \
    --data @"${check_request_file}" \
    "${gerrit_authorized_url}/plugins/checks/checkers/"

# Clone new repo to host system with commit-msg hook
rm -rf "$gerrit_project_name"
git clone "${gerrit_authorized_url}/${gerrit_project_name}" && cd "${gerrit_project_name}"
mkdir -p .git/hooks
commit_msg_hook=$(git rev-parse --git-dir)/hooks/commit-msg 
curl -sSLo "${commit_msg_hook}" "${gerrit_authorized_url}"/tools/hooks/commit-msg 
chmod +x "${commit_msg_hook}"

# Save gerrit user credentials in local git config
git config --local user.name "${gerrit_username}" 
git config --local user.email "${gerrit_user_email}"

# Add webhook for Jenkins integration in cloned repo
git fetch origin refs/meta/config:refs/remotes/origin/meta/config
git checkout meta/config
cp ../gerrit/webhooks.config .
git add webhooks.config
git commit -m "Add jenkins webhook"
git push origin meta/config:meta/config

cd ..

# Post build configuration of Jenkins Jobs
./setup_jenkins_gerrit_jobs.sh

# Create sample change in gerrit repo for demo
./test_resources/create_gerrit_change.sh