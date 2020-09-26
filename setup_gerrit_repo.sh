#!/bin/bash

set -e

# Creates new gerrit repo with  webhook for jenkins integration
# NOTE: 
# Http generated password must be provided to script from gerrit portal

source .env

gerrit_username=${GERRIT_USERNAME:-admin}
gerrit_user_password=${GERRIT_USER_HTTP_PASSWORD}
gerrit_user_email=${GERRIT_USER_EMAIL:-"admin@example.com"}
gerrit_url=${GERRIT_CANONICAL_WEB_URL:-http://localhost:8080}
gerrit_domain="${gerrit_url#*//}"
gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
jenkins_username=${JENKINS_USERNAME:-jenkins}
jenkins_password=${JENKINS_PASSWORD:-jenkins}
jenkins_url=${JENKINS_URL:-http://localhost:8081}
sleep_time=5

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

# Add new label with proper permissions in All-Projects repo for CI builds/tests

# Install checks plugin
plugin_id="checks"
plugin_source='"https://gerrit-ci.gerritforge.com/job/plugin-checks-bazel-stable-3.2/18//artifact/bazel-bin/plugins/checks/checks.jar"'
curl --header "Content-Type: application/json" \
    --request PUT \
    --data '{"url":'"${plugin_source}"'}' \
    "${gerrit_authorized_url}/plugins/${plugin_id}.jar"

# Grant permissions to checks plugin for Administrators group in All-Projects repo
curl --header "Content-Type: application/json" \
    --request POST \
    --data '{"add":{"GLOBAL_CAPABILITIES":{"permissions":{"checks-administrateCheckers":{"rules":{"Administrators":{"action":"ALLOW","added":true}},"added":true}}}},"remove":{}}' \
    "${gerrit_authorized_url}/projects/All-Projects/access"

# Create Jenkins user in gerrit
curl --header "Content-Type: application/json" \
    --request PUT \
    --data '{"name":"JenkinsCI", "http_password":"'"${jenkins_password}"'"}' \
    "${gerrit_authorized_url}/accounts/${jenkins_username}"

# Create new gerrit repository
curl --header "Content-Type: application/json" \
    --request PUT \
    --data '{"description":"Sample project for Jenkins<->gerrit integration","create_empty_commit":true}' \
    "${gerrit_authorized_url}/projects/${gerrit_project_name}"

# Create new check for Jenkins job display in sample gerrit repo

# Clone new repo to host system with commit-msg hook
commit_msg_hook=$(git rev-parse --git-dir)/hooks/commit-msg 
git clone "${gerrit_authorized_url}/${gerrit_project_name}" && cd "${gerrit_project_name}"
mkdir -p .git/hooks
curl -Lo "${commit_msg_hook}" "${gerrit_authorized_url}"/tools/hooks/commit-msg 
chmod +x "${commit_msg_hook}"

# Save gerrit user credentials in local git config
git config user.name "${gerrit_username}" --local
git config user.email "${gerrit_user_email}" --local

# Add webhook for Jenkins integration in cloned repo
git fetch origin refs/meta/config:refs/remotes/origin/meta/config
git checkout meta/config
cp ../gerrit/webhooks.config .
git add webhooks.config
git commit -m "Add jenkins webhook"
git push origin meta/config:meta/config

# Add sample Jenkinsfile with preconfigured JobDSL to repo
git checkout master
cp ../jenkins/Jenkinsfile .
mkdir jobs
cp -a ../jenkins/jobs/. jobs
git add -A
git commit -m "Add Jenkinsfile and JobDSL"
git push origin HEAD:refs/for/master

# Waint until Jenkins is ready
until curl --silent --location --fail  "${jenkins_url}" --output /dev/null
do
    echo "Jenkins unavailable, sleeping for ${sleep_time}"
    sleep "${sleep_time}"
done

# Run the JobDSL discovery job
cookiejar="$(mktemp)"
jenkins_crumb=$(curl -s -u "${jenkins_username}:${jenkins_password}" \
    --cookie-jar "$cookiejar" \
    "$jenkins_url"'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)'
    )
curl -X POST -s -u "${jenkins_username}:${jenkins_password}" \
    --cookie "$cookiejar" \
    -H "$jenkins_crumb" \
    "${jenkins_url}/job/JCasC-Job-DSL-Seed/build"