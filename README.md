# SO2-automation

Beachlor thesis on Wrocław University of Science and Technology

## Run

Quick recommendation, run docker-compose in separate terminal in order to see live logs and be sure when to acess gerrit :D

### **Order of scripts is important, please follow allong**

### **NOTE**

[setup_jenkins_user_on_host.sh](setup_jenkins_user_on_host.sh) will ask you for sudo permission since it needs to create jenkins user on host machine and grant him proper permissions. This is necessary to allow Jenkins spawning sibling containers (on host machine) in Pipelines so we are not playing around with dind (docker in docker).

```bash
./setup_jenkins_user_on_host.sh
docker-compose up
./setup_gerrit_repo.sh -p gerrit-http-password
```

What is `gerrit-http-password` ? Sadly in order to configure the whole stack almost all of the gerrit related configuration relays on gerrit REST API so this step has to be performed manually by providing HTTP generated password for administratior in gerrit portal.

**_Alright alright, but how do I retrive the password !_**

Simply navigate to [gerrit](http://localhost:8080) when the container is fully started (INFO com.google.gerrit.pgm.Daemon : Gerrit Code Review 3.2.3 ready in docker log of the container). Skip the plugin installation part, you should be automatically logged in as admin, top right corner settings wheel, left section HTTP Credentials, Click on GENERATE NEW PASSWORD, supply to script.

Go checkout [gerrit](http://localhost:8080) and [jenkins](http://localhost:8081) to see the magic happen !

Also clone the repo locally and push some changes to gerrit to check whether jenkins catches everthing.

**_When restarting_**

During playtime be sure to also clear docker volumes since compose uses them (to make sure you have a fresh install each time you spin up the containers)

## TO DO

0. Refactor on new branch to Gerrit Trigger ?

### Ideas

- Add reverse proxy in front of the containers to easily access given services on user friendly URLS. (caddy could be nice if letsencrypt docker image (SWAG) will not work correctly for localhost)

- Configure Cloud section in JCasC to use docker containers as slaves (also provisioned by jenkins when needed)

# Configuration section to automate everthing

## Jenkins configuration

### 1.Install all the necessary plugins (durning Dockerfile build from plugins.txt):

- docker-workflow (for docker inside pipeline)
- workflow-aggregator (for pipelines support)
- gerrit-code-review (better alternative to gerrit trigger)
- job-dsl (dynamic job configuration)
- configuration-as-code (JCasC)

### 2.JCasC and Configuration as Code

**Overall Jenkins config**

JCasC has been used in order to setup initial jobs for Jenkins, provide credentials for Gerrit jenkins user (JenkinsCI) who has correct permissions set up and configure other basic settings.

**Job setup**

We have a Job definitions [JCasC-Job-DSL-Seed](jenkins/JCasC/jobs.yml) in JCasC config which is reponsible for processing job definitions inside given gerrit repo (groovy definitions inside jobs folder). This Jenkins job is created at container startup by JCasC. This job is not triggered automatically since the Job definitions in Jenkins do not change that often, it can be triggered from Jenkins UI or with curl when needed.

The nice thing is that JobDSL supports many Pipeline configurations and DynamicDSL extends the possibilities for almost every possible Jenkins plugin therefor no more Jenkins UI clicking, simply upload the definitions to given folder and trigger the preconfigured job :) -> Profit ? We have Jenkins job configured as Code which are easly to recreate.

## Gerrit configuration:

All the configuration is done via Gerrit REST API. The only cumbersome settings is the Gerrit HTTP password which is needed in order to query all the endpoints. This has to provided by user therefore there is no place for full automation, the password needs to be retrieved from admin settings in portal.

All the configuration was parametrized with variables so the script could be potentially used in real world scenarions where other authentication is required.

The [setup script](setup_gerrit_repo.sh) does the following:

- Install checks plugin
- Adds Verified label which is no longer automatically setup during Gerrit initialization
- Grants permissions for Adminstrator and Non-interactive users to check plugin and label modification
- Creates Jenkins user with preconfigured password (same password is used in JCasC to configure inital job)
- Creates new gerrit repository
- Adds sample check to repository
- Adds webhook which is required for Gerrit<->Jenkins integration (Communicats with [Gerrit Code Review plugin](https://plugins.jenkins.io/gerrit-code-review/))
- We assume webhooks plugin is already installed on Gerrit (Gerrit docker image has it preinstalled)

# RESOURCES:

https://www.youtube.com/watch?v=pyPMeCW-Q5k -> How [GerritForge](https://gerrit-ci.gerritforge.com/) runs things (tbh this presentation is just the top of the mountain and the plugin does not has a documentation at all)

[Gerrit source code](https://gerrit-review.googlesource.com/) -> Yeah it has been handy when configuring all the stuff :D

[Gerrit Code Review Jenkins plugin](https://plugins.jenkins.io/gerrit-code-review/) -> still under heavy development, no documentation at all but after you grasp the idea it is really powerfull.

[Implement checks in GerritForge](https://gerrit-review.googlesource.com/c/gerrit-ci-scripts/+/224327) -> this has been dug from google conversations in order to make this setup work
