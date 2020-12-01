#!/bin/bash

set -eu

# Creates sample change with  script in preconfigured repo which triggers Jenkins build
# We assume that Jenkins and gerrit are already running and Jenkins has his jobs preconfigured

source .env

gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
gerrit_url=${GERRIT_CANONICAL_WEB_URL:-http://localhost:8080}
jenkins_url=${JENKINS_URL:-http://localhost:8081}

cd "$gerrit_project_name"

# Propose sample change with JenkinsFile and script
git checkout master
cp -a ../so2_lab_examples/lab4/. .
cp ../.Dockerfile .
git add -A
git commit -m "Add sample script and Jenkinsfile + Dockerfile for validation"
git push origin HEAD:refs/for/master

echo "Sucess ! Quickly check:"
echo "Gerrit changes: ${gerrit_url}"
echo "Jenkins running your jobs: ${jenkins_url}"
