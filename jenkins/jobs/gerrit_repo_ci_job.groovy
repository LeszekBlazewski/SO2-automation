multibranchPipelineJob('gerrit-jenkins-test-CI') {
    description('Sample job for Jenkins<->Gerrit integration')
    branchSources {
        branchSource {
            source {
                gerrit {
                    id('gerrit-ci-branch-source')
                    remote('http://gerrit:8080/gerrit-jenkins-test')
                    credentialsId('')
                    insecureHttps(false)
                    traits {
                        changeDiscoveryTrait {
                            queryString('')
                        }
                        refSpecsSCMSourceTrait {
                            templates {
                                refSpecTemplate {
                                    value('+refs/heads/*:refs/remotes/@{remote}/*')
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