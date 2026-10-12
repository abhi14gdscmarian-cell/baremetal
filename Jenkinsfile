
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                bat 'git --version'
                bat 'java -version'
                bat 'cmake --version'
                bat 'where riscv64-unknown-elf-gcc'
            }
        }

        stage('Verify Project') {
            steps {
                bat 'dir'
                bat 'type CMakeLists.txt'
            }
        }
    }

    post {
        success {
            echo 'MPFS bare-metal CI checks completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
