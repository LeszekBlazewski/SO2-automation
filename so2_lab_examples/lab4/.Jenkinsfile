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
                test_dirs=('testing-dir' 'testing-dir/nested')
                test_files=('file-rw' 'file-small-rw' 'file-x')
                for dir in "${test_dirs[@]}"
                do
                    mkdir "$dir"
                    for file in "${test_files[@]}"
                    do
                        size='5M'
                        if [[ "$file" == "file-small-rw" ]]; then
                            size='1M'
                        fi
                        truncate -s "$size" "$dir/$file"
                    done
                done
                chmod +x "testing-dir/file-x"
                chmod +x "testing-dir/nested/file-x"
                '''
            }
        }
        stage('Test script') {
            steps {
                sh '''#!/bin/bash -ex
                source /assert.sh
                dir_to_test='testing-dir'
                correct_files="$dir_to_test/file-rw $dir_to_test/nested/file-rw"
                found_files=$(bash -euo pipefail *.sh "$dir_to_test" 2)
                while IFS= read -r file
                do
                    assert_contain "$correct_files" "$file" "wrong file found"
                done <<< "$found_files"
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
