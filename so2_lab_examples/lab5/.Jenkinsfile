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
                dir_to_test='testing-dir'
                mkdir "$dir_to_test"
                mdkir "$dir_to_test"/aaa
                touch "$dir_to_test"/kajak
                touch "$dir_to_test"/aaa/bbb
                '''
            }
        }
        stage('Test script') {
            steps {
                sh '''
                source assert.sh
                dir_to_test='testing-dir'
                stdout=$(bash *.sh "$dir_to_test")
                assert_contain "$stdout" " $dir_to_test/kajak"
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