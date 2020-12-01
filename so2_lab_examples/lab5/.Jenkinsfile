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
                palindrome="kajak"
                palindrome_path="$dir_to_test/$palindrome"
                nested_palindrome_path="$dir_to_test/nested/$palindrome"
                mkdir "$dir_to_test" "$dir_to_test/nested"
                touch "$palindrome_path" "$nested_palindrome_path"
                touch "$dir_to_test"/not-palindrome
                '''
            }
        }
        stage('Test script') {
            steps {
                sh '''#!/bin/bash -ex
                source /assert.sh
                dir_to_test='testing-dir'
                palindrome="kajak"
                palindrome_path="$dir_to_test/$palindrome"
                nested_palindrome_path="$dir_to_test/nested/$palindrome"
                correct_files="$palindrome_path $nested_palindrome_path"
                found_files=$(bash -euo pipefail *.sh "$dir_to_test")

                # verify stdout
                while IFS= read -r path
                do
                    assert_contain "$correct_files" "$path" "wrong path in stodout found"
                done <<< "$found_files" 

                # verify contents of file
                while IFS= read -r path
                do
                    assert_contain "$correct_files" "$path" "wrong path in file found"
                done < *.txt
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
