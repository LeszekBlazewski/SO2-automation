#!/bin/bash

set -e

# Creates new gerrit repo with  webhook for jenkins integration
# NOTE: 
# 1. Http generated password must be provided to script from gerrit portal

source .env

gerrit_username=${GERRIT_USERNAME:-admin}
gerrit_user_password=${GERRIT_USER_HTTP_PASSWORD}
gerrit_url=${GERRIT_CANONICAL_WEB_URL:-http://localhost:8080}
gerrit_domain="${gerrit_url#*//}"
gerrit_authorized_url=http://"${gerrit_username}:${gerrit_user_password}@${gerrit_domain}/a"
gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}

# Check if http password is provided to script

usage() {
    echo "Usage: setup_gerrit_repo.sh -p http-password-from-gerrit"
    echo "Admin HTTP password can be stored in .env under GERRIT_USER_HTTP_PASSWORD variable"
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

# 2. Upload new SSH key for administrator for easier management



# 3. Create new gerrit repository

curl --header "Content-Type: application/json" \
    --request PUT \
    --data '{"description":"Sample project for Jenkins<->gerrit integration"}' \
    "${gerrit_authorized_url}/projects/${gerrit_project_name}"

# 4. Clone new repo to host system with commit-msg hook
commit_msg_hook=$(git rev-parse --git-dir)/hooks/commit-msg 

git clone "${gerrit_authorized_url}/${gerrit_project_name}" && cd "${gerrit_project_name}"
mkdir -p .git/hooks
curl -Lo "${commit_msg_hook}" "${gerrit_authorized_url}"/tools/hooks/commit-msg 
chmod +x "${commit_msg_hook}"

# 5. Add webhook for Jenkins integration in cloned repo
# Webhook looks as follow: jenkins_url/gerrit-webhook/ ex. http://jenkins:8080/gerrit-webhook/
jenkins_url=http://jenkins:8080
git fetch origin refs/meta/config:refs/remotes/origin/meta/config
git checkout meta/config
printf '[remote "jenkins"]\n    url = %s' "${jenkins_url}/gerrit-webhook/" > webhooks.config
git add webhooks.config
git commit -m "Add jenkins webhook"
git push origin meta/config:meta/config

# 4. Add sample Jenkinsfile to repo