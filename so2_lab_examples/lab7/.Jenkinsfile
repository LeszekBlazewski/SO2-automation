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
                cat << EOF > emails.txt
                krasicki@wp.pl
                naruszewicz@onet.eu
                niemcewicz@o2.pl
                trembecki@gmail.com
                bohomolec@protonmail.com
EOF
                '''
            }
        }
        stage('Test script') {
            steps {
                sh '''#!/bin/bash -ex
                output=$(bash *.sh)
                while IFS= read -r line
                do
                    grep -qw  "$line" <<< "$output"
                done < emails.txt
                echo "All emails found successfully"
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