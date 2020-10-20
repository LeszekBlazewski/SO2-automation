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
                sh '''
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
                sh '''
                source assert.sh
                output=$(bash *.sh)
                while IFS= read -r line
                do
                    email_from_file=$(grep -w "$line" <<< "$output")
                    assert_eq "$email_from_file" "line"
                done < emails.txt
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