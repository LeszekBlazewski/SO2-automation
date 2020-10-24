pipeline {
    agent {
        dockerfile{
                filename('.Dockerfile')
        }
    }
    stages {
        stage('Syntax check') {
            steps {
                sh 'shellcheck *.sh'
            }
        }
        stage('Prepare test environment') {
            steps {
                sh '''#!/bin/bash -ex
                dir_to_test='testing-dir'
                mkdir "$dir_to_test"
                truncate -s 5M "$dir_to_test"/big-file-rw.txt
                truncate -s 5M "$dir_to_test"/big-file-x.txt
                chmod +x "$dir_to_test"/big-file-x.txt
                '''
            }
        }
        stage('Test script') {
            steps {
                sh '''#!/bin/bash -ex
                source /assert.sh
                dir_to_test='testing-dir'
                correct_file="$dir_to_test"/big-file-rw.txt
                assert_not_empty $(bash *.sh "$dir_to_test" 2 | grep "$correct_file")
                '''
            }
        }
    }
     post {
        success { 
            gerritReview labels: [Verified: 1]
            gerritCheck (checks: ['Jenkins:Test': 'SUCCESSFUL'],  url: "${env.BUILD_URL}console")
        }
        unstable { 
            gerritReview labels: [Verified: 0] 
            gerritCheck (checks: ['Jenkins:Test': 'FAILED'],  url: "${env.BUILD_URL}console")
        }
        failure { 
            gerritReview labels: [Verified: -1]
            gerritCheck (checks: ['Jenkins:Test': 'FAILED'],  url: "${env.BUILD_URL}console")
        }
    }
}