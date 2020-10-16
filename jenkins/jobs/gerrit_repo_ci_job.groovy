multibranchPipelineJob('gerrit-jenkins-test-CI') {
    description('Sample job for Jenkins<->Gerrit integration')
    branchSources {
        branchSource {
            source {
                gerrit {
                    id('gerrit-ci-branch-source')
                    credentialsId('gerrit-jenkins-user')
                    remote('http://gerrit:8080/a/gerrit_project_name')
                    insecureHttps(false)
                    traits {
                        changeDiscoveryTrait {
                            queryString('')
                        }
                        refSpecsSCMSourceTrait {
                            templates {
                                refSpecTemplate {
                                    value('+refs/changes/*:refs/remotes/@{remote}/*')
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(10)
        }
    }
}