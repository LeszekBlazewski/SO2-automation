#!/bin/bash

set -eu

# Setup new DSL Job in gerrit repo and trigger job generation in jenkins instance

source .env

gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
jenkins_url=${JENKINS_URL:-http://localhost:8081}
jenkins_username=${JENKINS_USERNAME:-jenkins}
jenkins_password=${JENKINS_PASSWORD:-jenkins}
jenkins_job_dsl_seed_name=${JENKINS_JOB_DSL_SEED_NAME:-JCasC-Job-DSL-Seed}
sleep_time=5

cd "$gerrit_project_name"

# Add preconfigured JobDSL to create Jenkins Jobs on jenkins-configuration branch
configuration_branch='jenkins-configuration'
jobs_definition_folder='jobs'
git checkout master
git checkout -b "$configuration_branch"
mkdir "$jobs_definition_folder"
cp -a ../jenkins/jobs/. "$jobs_definition_folder"
sed -i "s/gerrit_project_name/${gerrit_project_name}/" "jobs/gerrit_repo_ci_job.groovy"
git add -A
git commit -m "Add JobDSL definition"
git push -u origin  "$configuration_branch"

# Waint until Jenkins is ready
until curl --silent --show-error --location --fail  "${jenkins_url}" --output /dev/null
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
curl -X POST --header "$jenkins_crumb" \
    --user "${jenkins_username}:${jenkins_password}" \
    --cookie "$cookiejar" \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    "${jenkins_url}/job/${jenkins_job_dsl_seed_name}/build"
