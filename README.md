# SO2-automation

Beachlor thesis on Wrocław University of Science and Technology

## Run

```bash
./setup_jenkins_user.sh
docker-compose up -d
./setup_gerrit_repo.sh -p gerrit-http-password
```

Checkout [gerrit-repo](http://localhost:8080) and [jenkins](http://localhost:8081) to see the magic happen !

Also clone the repo locally and push some changes to gerrit to check whether jenkins catches everthing.

## TO DO

0. Add admin credentials in JCasC config which will allow jenkins to post messages to gerrit.
   Probably we have to create a new user in gerrit and add him required permissions.

1. Modify JenkinsFile to include post build message sent to gerrit.

2. Modify gerrit Dockerfile to automatically install checks plugin.

3. Integrate checks plugin in gerrit and jenkins.

4. Write instructions in readme which will guide to run the whole PoC.

### Ideas

0. Add reverse proxy in front of the containers to easily access given services on user friendly URLS. (caddy could be nice if letsencrypt (SWAG) will not work correctly for localhost)

1. On Deploy use SWAG (lets encrypt docker image) which has certbot onboard which will take care of automatic cert renewal and will provide SSL for all the urls + implement basic auth for access with secure credentials.

2. Configure Cloud section in JCasC to use docker containers as slaves (also provisioned by jenkins when needed)

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
