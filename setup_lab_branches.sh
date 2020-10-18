#!/bin/bash

set -eu

# Creates sample branches with tasks, Jenkins validation and .gitreview in students repo for lab{4,5,7}.

if ! command -v rsync &> /dev/null; then
    echo "rsync not found, please install the command and rerun the script"
    exit 1
fi

source .env

gerrit_project_name=${GERRIT_PROJECT_NAME:-gerrit-jenkins-test}
lab_examples_dir='../so2_lab_examples'

cd "$gerrit_project_name"

# Create branch for each folder declared in lab examples folder
find "$lab_examples_dir" -maxdepth 1 -mindepth 1 -type d -print | while read -r dir_path
do
    dir_name=${dir_path##*/}
    git checkout -b "$dir_name"
    rsync -r --exclude='*.sh' "$lab_examples_dir/$dir_name/" .
    git add -A
    git commit -m "Initial commit for $dir_name"
    git push -u origin "$dir_name"
    rm -r *
done

 echo "Sample branches  for students have been created !"