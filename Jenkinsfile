
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    parameters {
        booleanParam(
            name: 'RUN_UNIT_TESTS',
            defaultValue: true,
            description: 'Configure, build, and run host-side GoogleTest unit tests'
        )
    }

    environment {
        // Update this path if SoftConsole is installed elsewhere.
        RISCV_BIN = 'C:\\Microchip\\SoftConsole-v2022.2-RISC-V-747\\riscv-unknown-elf-gcc\\bin'

        FIRMWARE_BUILD_DIR = 'build-ci-firmware'
        TEST_BUILD_DIR = 'build-ci-tests'
        TOOLCHAIN_FILE = 'riscv64-unknown-elf-toolchain.cmake'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                echo 'Source code checked out successfully.'
                bat 'git log -1 --oneline'
            }
        }

        stage('Verify Tools') {
            steps {
                bat '''
                    @echo off
                    echo ==== Git ====
                    git --version
                    if errorlevel 1 exit /b 1

                    echo ==== Java ====
                    java -version
                    if errorlevel 1 exit /b 1

                    echo ==== CMake ====
                    cmake --version
                    if errorlevel 1 exit /b 1

                    echo ==== Make ====
                    where.exe mingw32-make
                    if errorlevel 1 exit /b 1
                '''

                withEnv(["PATH+RISCV=${env.RISCV_BIN}"]) {
                    bat '''
                        @echo off
                        echo ==== RISC-V compiler ====
                        if not exist "%RISCV_BIN%\\riscv64-unknown-elf-gcc.exe" (
                            echo ERROR: RISC-V compiler not found.
                            echo Check RISCV_BIN in the Jenkinsfile.
                            exit /b 1
                        )

                        where.exe riscv64-unknown-elf-gcc
                        riscv64-unknown-elf-gcc --version
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Validate Project Files') {
            steps {
                bat '''
                    @echo off
                    if not exist CMakeLists.txt (
                        echo ERROR: Root CMakeLists.txt not found.
                        exit /b 1
                    )

                    if not exist "%TOOLCHAIN_FILE%" (
                        echo ERROR: RISC-V toolchain file not found.
                        exit /b 1
                    )

                    echo ==== Project files ====
                    dir
                '''
            }
        }

        stage('Configure Firmware') {
            steps {
                withEnv(["PATH+RISCV=${env.RISCV_BIN}"]) {
                    bat '''
                        @echo off
                        cmake -S . -B "%FIRMWARE_BUILD_DIR%" ^
                            -G "MinGW Makefiles" ^
                            -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%" ^
                            -DCMAKE_BUILD_TYPE=Debug

                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Build Firmware') {
            steps {
                withEnv(["PATH+RISCV=${env.RISCV_BIN}"]) {
                    bat '''
                        @echo off
                        cmake --build "%FIRMWARE_BUILD_DIR%" --parallel 4
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Configure Unit Tests') {
            when {
                expression { params.RUN_UNIT_TESTS }
            }
            steps {
                bat '''
                    @echo off
                    cmake -S . -B "%TEST_BUILD_DIR%" ^
                        -G "MinGW Makefiles" ^
                        -DBUILD_GTEST=ON ^
                        -DCMAKE_BUILD_TYPE=Debug

                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Build Unit Tests') {
            when {
                expression { params.RUN_UNIT_TESTS }
            }
            steps {
                bat '''
                    @echo off
                    cmake --build "%TEST_BUILD_DIR%" --parallel 4
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Run Unit Tests') {
            when {
                expression { params.RUN_UNIT_TESTS }
            }
            steps {
                bat '''
                    @echo off
                    ctest --test-dir "%TEST_BUILD_DIR%" --output-on-failure
                    if errorlevel 1 exit /b 1
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Firmware build and enabled unit tests completed.'
        }

        failure {
            echo 'FAILURE: Review the first failing stage in Console Output.'
        }

        always {
            echo 'MPFS bare-metal CI pipeline finished.'
        }
    }
}
