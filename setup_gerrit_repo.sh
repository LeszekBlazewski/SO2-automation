#!/bin/bash

set -eu

# Creates new gerrit repo with  webhook and checks for jenkins integration 
# NOTE: Http generated password must be provided to script from gerrit portal

if ! command -v jq &> /dev/null; then
    echo "jq not found, please install the command and rerun the script."
    exit 1
fi

source .env

gerrit_username=${GERRIT_USERNAME:-admin}
gerrit_user_password=${GERRIT_USER_HTTP_PASSWORD}
gerrit_user_email=${GERRIT_USER_EMAIL:-"admin@example.com"}
gerrit_url=${GERRIT_CANONICAL_WEB_URL:-http://localhost:8080}
gerrit_domain="${gerrit_url#*//}"
gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
gerrit_template_repo_name=${GERRIT_TEMPLATE_REPO_NAME:-'Students-Template-Projects'}
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
plugin_source='"https://gerrit-ci.gerritforge.com/view/Plugins-stable-3.2/job/plugin-checks-bazel-stable-3.2/lastSuccessfulBuild/artifact/bazel-bin/plugins/checks/checks.jar"'
curl --header "Content-Type: application/json" \
    --request PUT \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"url":'"${plugin_source}"'}' \
    "${gerrit_authorized_url}/plugins/${plugin_id}.jar"

# Grant permissions for checks-administrateCheckers -> Administrators, Non-interactive users (used by admin to create checks and by jenkins to update status on gui)
permission_request_file='./gerrit/update_permission_rules_request.json'
curl --header "Content-Type: application/json" \
    --request POST \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --data @"${permission_request_file}" \
    "${gerrit_authorized_url}/projects/All-Projects/access"

# Create new students repo template
./setup_students_template.sh  "$gerrit_authorized_url" "$gerrit_username" "$gerrit_user_email" "$gerrit_template_repo_name"

# Create Jenkins user in gerrit
curl --header "Content-Type: application/json" \
    --request PUT \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --data '{"name":"JenkinsCI", "email": "jenkins@example.com", "groups":["Non-Interactive Users"], "http_password":"'"${jenkins_password}"'"}' \
    "${gerrit_authorized_url}/accounts/${jenkins_username}"

# Create new sample gerrit repository
request_data=$(cat <<-END
    {
        "name": "$gerrit_project_name",
        "description": "Sample project for Jenkins<->gerrit integration", 
        "permissions_only": false, 
        "parent": "$gerrit_template_repo_name", 
        "create_empty_commit": true, 
        "owners": ["Administrators"]
    }
END
)

curl --header "Content-Type: application/json" \
    --request PUT \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --data "$request_data" \
    "${gerrit_authorized_url}/projects/${gerrit_project_name}"

# Create new check for Jenkins job in ${gerrit_project_name} gerrit repo
request_data=$(cat <<-END
    {
        "uuid": "Jenkins:Test", 
        "name": "Jenkins Test", 
        "description": "Test code on Jenkins Job", 
        "repository": "$gerrit_project_name", 
        "query": "", 
        "blocking": []
    }
END
)

curl --header "Content-Type: application/json" \
    --request POST \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    --data "$request_data" \
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
git fetch origin refs/meta/config
git checkout FETCH_HEAD
cp ../gerrit/webhooks.config .
git add webhooks.config
git commit -m "Add jenkins webhook"
git push origin HEAD:refs/meta/config

cd ..

# Post build configuration of Jenkins Jobs
./setup_jenkins_gerrit_jobs.sh

# Setup example lab branches
./setup_lab_branches.sh

# Create sample change in gerrit repo for demo
./test_resources/create_gerrit_change.sh
