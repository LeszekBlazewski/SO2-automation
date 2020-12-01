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
                found_emails=$(bash -euo pipefail *.sh)
                while IFS= read -r email
                do
                    grep -qw  "$email" emails.txt
                done <<< "$found_emails"
                
                echo "All emails found successfully"
                '''
            }
        }
    }
     post {
        success { 
            gerritReview labels: [Verified: 1]
            gerritCheck (checks: ['Jenkins:Test': 'SUCCESSFUL'],  
                        url: "${env.BUILD_URL}console")
        }
        unstable { 
            gerritReview labels: [Verified: 0] 
            gerritCheck (checks: ['Jenkins:Test': 'FAILED'],  
                        url: "${env.BUILD_URL}console")
        }
        failure { 
            gerritReview labels: [Verified: -1]
            gerritCheck (checks: ['Jenkins:Test': 'FAILED'],  
                        url: "${env.BUILD_URL}console")
        }
    }
}
