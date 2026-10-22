
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
        FIRMWARE_ELF = 'build-ci-firmware\\mpfs-blank-baremetal.elf'
        FIRMWARE_BUILD_DIR = 'build-ci-firmware'
        TEST_BUILD_DIR = 'build-ci-tests'
        TOOLCHAIN_FILE = 'riscv64-unknown-elf-toolchain.cmake'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                echo 'Source code checked out successfully.'
                bat 'git log -1 --pretty=format:"Commit Hash: %%H%%nAuthor: %%an%%nEmail: %%ae%%nDate: %%ad%%nMessage: %%s"'
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
        
stage('Flash Firmware to RAM') {
    steps {
        powershell '''
            $ErrorActionPreference = 'Stop'

            $elf = Join-Path $env:WORKSPACE `
                'build-ci-firmware\\mpfs-blank-baremetal.elf'

            $openocd = Join-Path $env:OPENOCD_BIN 'openocd.exe'
            $gdb = Join-Path $env:RISCV_BIN `
                'riscv64-unknown-elf-gdb.exe'

            $scripts = $env:OPENOCD_SCRIPTS
            $log = Join-Path $env:WORKSPACE 'openocd.log'
            $err = Join-Path $env:WORKSPACE 'openocd-error.log'

            # Verify the required files first.
            foreach ($file in @($elf, $openocd, $gdb)) {
                if (!(Test-Path $file)) {
                    throw "Required file not found: $file"
                }
            }

            if (!(Test-Path $scripts)) {
                throw "OpenOCD scripts directory not found: $scripts"
            }

            Write-Host "Firmware: $elf"
            Write-Host "Checking programmer and target..."

            Remove-Item $log, $err -Force `
                -ErrorAction SilentlyContinue

            # Use only the board configuration appropriate for
            # the actual target and installed SoftConsole version.
            $config = Join-Path $scripts 'board\\microsemi-riscv.cfg'

            if (!(Test-Path $config)) {
                throw "Board configuration not found: $config"
            }

            $proc = Start-Process `
                -FilePath $openocd `
                -ArgumentList @(
                    '-s', $scripts,
                    '-f', 'board/microsemi-riscv.cfg'
                ) `
                -RedirectStandardOutput $log `
                -RedirectStandardError $err `
                -PassThru

            try {
                $deadline = (Get-Date).AddSeconds(20)
                $connected = $false

                while ((Get-Date) -lt $deadline) {
                    Start-Sleep -Milliseconds 500

                    $output = ''
                    if (Test-Path $log) {
                        $output += Get-Content $log -Raw `
                            -ErrorAction SilentlyContinue
                    }
                    if (Test-Path $err) {
                        $output += Get-Content $err -Raw `
                            -ErrorAction SilentlyContinue
                    }

                    if ($proc.HasExited) {
                        throw "OpenOCD exited. Review its logs."
                    }

                    if ($output -match 'Examined RISCV core') {
                        $connected = $true
                        break
                    }
                }

                if (!$connected) {
                    throw "Target not detected within 20 seconds. Check FlashPro4, JTAG, power, and OpenOCD logs."
                }

                Write-Host "Target detected. Downloading firmware..."

                & $gdb $elf --batch `
                    -ex 'set architecture riscv:rv32' `
                    -ex 'target extended-remote localhost:3333' `
                    -ex 'monitor reset halt' `
                    -ex 'load' `
                    -ex 'monitor resume' `
                    -ex 'detach' `
                    -ex 'quit'

                if ($LASTEXITCODE -ne 0) {
                    throw "GDB download failed with exit code $LASTEXITCODE"
                }

                Write-Host "SUCCESS: Firmware downloaded and execution resumed."
            }
            finally {
                if (!$proc.HasExited) {
                    Stop-Process -Id $proc.Id -Force
                }
            }
        '''
        }
    }

        
        stage('Show Commit Details') {
            steps {
                bat 'git log -1 --format="Commit: %%h%%nAuthor: %%an%%nEmail: %%ae%%nMessage: %%s"'
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Firmware build and enabled unit tests completed.'
        }

        failure {
            echo 'FAILURE: Review the first failing stage in Console Output12.'
        }

        always {
            echo 'MPFS bare-metal CI pipeline finished Completely1.'
        }
    }
}
