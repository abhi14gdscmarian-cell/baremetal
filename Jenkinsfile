
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
    RISCV_BIN = 'C:\\Microchip\\SoftConsole-v2022.2-RISC-V-747\\riscv-unknown-elf-gcc\\bin'
    OPENOCD_BIN = 'C:\\Microchip\\SoftConsole-v2022.2-RISC-V-747\\openocd\\bin'
    OPENOCD_SCRIPTS = 'C:\\Microchip\\SoftConsole-v2022.2-RISC-V-747\\openocd\\share\\openocd\\scripts'
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
        
stage('Clean Build Directories') {
    steps {
        powershell '''
            $ErrorActionPreference = 'Stop'

            $dirs = @(
                'build-ci-firmware',
                'build-ci-tests'
            )

            foreach ($dir in $dirs) {
                $path = Join-Path $env:WORKSPACE $dir

                if (Test-Path $path) {
                    Write-Host "Removing: $path"
                    Remove-Item -LiteralPath $path -Recurse -Force
                }

                if (Test-Path $path) {
                    throw "Failed to clean directory: $path"
                }

                Write-Host "Clean: $dir"
            }

            Write-Host 'Build directories cleaned successfully.'
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
        catchError(
            buildResult: 'SUCCESS',
            stageResult: 'FAILURE',
            message: 'Hardware flashing failed; continuing CI pipeline.'
        ) {
            powershell '''
                $ErrorActionPreference = 'Stop'

                # ----------------------------------------
                # 1. Configure paths
                # ----------------------------------------
                $elf = Join-Path $env:WORKSPACE `
                    $env:FIRMWARE_ELF

                $openocd = Join-Path $env:OPENOCD_BIN `
                    'openocd.exe'

                $gdb = Join-Path $env:RISCV_BIN `
                    'riscv64-unknown-elf-gdb.exe'

                $scripts = $env:OPENOCD_SCRIPTS

                $log = Join-Path $env:WORKSPACE 'openocd.log'
                $err = Join-Path $env:WORKSPACE 'openocd-error.log'

                Write-Host '========================================'
                Write-Host 'Firmware download to RAM'
                Write-Host '========================================'
                Write-Host "Firmware: $elf"

                # ----------------------------------------
                # 2. Verify required files
                # ----------------------------------------
                foreach ($file in @($elf, $openocd, $gdb)) {
                    if ([string]::IsNullOrWhiteSpace($file) -or
                        !(Test-Path -LiteralPath $file)) {
                        throw "Required file not found: $file"
                    }
                }

                if ([string]::IsNullOrWhiteSpace($scripts) -or
                    !(Test-Path -LiteralPath $scripts)) {
                    throw "OpenOCD scripts directory not found: $scripts"
                }

                $config = Join-Path $scripts `
                    'board\\microsemi-riscv.cfg'

                if (!(Test-Path -LiteralPath $config)) {
                    throw "OpenOCD board configuration not found: $config"
                }

                # ----------------------------------------
                # 3. Start OpenOCD
                # ----------------------------------------
                Remove-Item $log, $err -Force `
                    -ErrorAction SilentlyContinue

                Write-Host 'Starting OpenOCD...'

                $proc = Start-Process `
                    -FilePath $openocd `
                    -ArgumentList @(
                        '-s', $scripts,
                        '-f', 'board/microsemi-riscv.cfg'
                    ) `
                    -WorkingDirectory (Split-Path $openocd) `
                    -RedirectStandardOutput $log `
                    -RedirectStandardError $err `
                    -PassThru

                try {
                    # ------------------------------------
                    # 4. Wait for target connection
                    # ------------------------------------
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
                            Write-Host 'OpenOCD output:'
                            Write-Host $output

                            throw 'OpenOCD exited before target connection.'
                        }

                        if ($output -match 'Examined RISCV core') {
                            $connected = $true
                            break
                        }
                    }

                    if (!$connected) {
                        $output = ''

                        if (Test-Path $log) {
                            $output += Get-Content $log -Raw `
                                -ErrorAction SilentlyContinue
                        }

                        if (Test-Path $err) {
                            $output += Get-Content $err -Raw `
                                -ErrorAction SilentlyContinue
                        }

                        Write-Host 'OpenOCD diagnostic output:'
                        Write-Host $output

                        throw 'Target not detected within 20 seconds.'
                    }

                    Write-Host 'Target detected.'
                    Write-Host 'Connecting GDB to OpenOCD...'

                    # ------------------------------------
                    # 5. Download ELF and resume execution
                    # ------------------------------------
                    & $gdb $elf --batch `
                        -ex 'set architecture riscv:rv32' `
                        -ex 'target extended-remote localhost:3333' `
                        -ex 'monitor reset halt' `
                        -ex 'load' `
                        -ex 'monitor resume' `
                        -ex 'detach' `
                        -ex 'quit'

                    if ($LASTEXITCODE -ne 0) {
                        throw "GDB failed with exit code $LASTEXITCODE"
                    }

                    Write-Host 'Firmware download command completed.'
                }
                finally {
                    # ------------------------------------
                    # 6. Stop OpenOCD
                    # ------------------------------------
                    if (!$proc.HasExited) {
                        Stop-Process -Id $proc.Id -Force `
                            -ErrorAction SilentlyContinue
                    }
                }
            '''
            }
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
