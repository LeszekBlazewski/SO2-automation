# SO2-automation

Beachlor thesis on Wrocław University of Science and Technology

## TO DO

1. Add reverse proxy in front of the containers to easily access given services on user friendly URLS. (caddy could be nice if letsencrypt (SWAG) will not work correctly for localhost)

2. On Deploy use SWAG (lets encrypt) which has certbot onboard which will take care of automatic cert renewal and will provide SSL for all the urls + implement basic auth for access with secure credentials.

# Configuration section to automate everthing

## Jenkins configuration

### 1.Install all the necessary plugins (durning Dockerfile build from plugins.txt):

- docker-workflow (for docker inside pipeline)
- workflow-aggregator (for docker inside pipeline)
- gerrit-code-review (new version of gerrit trigger)

### 2.Add preconfigured multibranch pipeline to Jenkins which will have all settings setup to fetch changes by SCM from gerrit repo:

- It would be nice if Jenkins would add a multibranch project per repo automatically when new repo is created in gerrit. (JCaC maybe ?)

- If not possible configure one Job which will listen for changes from the main repo.

### 3. Automatically add admin persmissions (gerrit user) to Jenkins (need to be fetched from gerrit)

## Gerrit configuration:

### 1.For PoC use become user to not use authentication.

### 2.Durning setup automate the install of gerrit webhooks plugin (also configuration file for jenkins server is needed)

### 3. Automatically upload the SSH key to gerrit in order to make SSH work for the commit hook which adds ID.

# RESOURCES:

https://www.youtube.com/watch?v=pyPMeCW-Q5k
