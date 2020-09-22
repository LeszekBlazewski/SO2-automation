# SO2-automation

Beachlor thesis on Wrocław University of Science and Technology

## Run

```bash
./setup_jenkins_user.sh
```

## TO DO

### Now

0. CHECK IF MOVING TO OUTISE MAIN GIT REPO THE SCRIPT WOULD WORK

1. Fix setup_gerrit_repo.sh to use ssh and make sure that the whole script works with webhook configuration

2. Try to make preconfigured jenkins job which will have all the necessary permissions (mulitbranch pipeline with gerrit source and credentials for admin used in gerrit)

### Production

1. Add reverse proxy in front of the containers to easily access given services on user friendly URLS. (caddy could be nice if letsencrypt (SWAG) will not work correctly for localhost)

2. On Deploy use SWAG (lets encrypt) which has certbot onboard which will take care of automatic cert renewal and will provide SSL for all the urls + implement basic auth for access with secure credentials.

### Check

1. Check if gerrit webhooks are working correctly with Jenkins (new patchest triggers jenkins job)

2. Check if after uploading credentials for gerrit user in Jenkins, Jenkins is able to post messages to gerrit after build have sucessfully finished.

# Configuration section to automate everthing

## Jenkins configuration

### 1.Install all the necessary plugins (durning Dockerfile build from plugins.txt):

- docker-workflow (for docker inside pipeline)
- workflow-aggregator (for pipelines support)
- gerrit-code-review (better alternative to gerrit trigger)

### 2.Add preconfigured multibranch pipeline to Jenkins which will have all settings setup to fetch changes by SCM from gerrit repo:

- It would be nice if Jenkins would add a multibranch project per repo automatically when new repo is created in gerrit. (JCasC maybe ?)

- If not possible configure one Job which will listen for changes from the main repo.

### 3. Automatically add admin persmissions (gerrit user) to Jenkins (need to be fetched from gerrit) [Would be nice if security credentials could be stored in JCasC config but they need to be retrieved from Gerrit by using REST API] -> this should allow jenkins job builds to post success/error messages to gerrit.

## Gerrit configuration:

### 1.For PoC use become user to not use authentication.

### 2.Durning setup automate the install of gerrit webhooks plugin (also configuration file for jenkins server is needed) -> plugin is installed automatically when using official gerrit docker image.

### 3. Automatically upload the SSH key to gerrit in order to make SSH work for the commit hook which adds ID.

# RESOURCES:

https://www.youtube.com/watch?v=pyPMeCW-Q5k
