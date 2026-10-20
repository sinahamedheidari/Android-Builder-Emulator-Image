# Android Builder and Emulator Docker Image
A Docker-based environment for building Android applications and running automated UI tests in a consistent, isolated, and reproducible setup. Simplifies test execution by providing the required tools and dependencies in a preconfigured Docker image, making it suitable for local development and CI/CD pipelines.

## How to build

Build the Docker image:

```bash
docker build -t android-builder-emulator:latest .
```

Run Gradle inside the container to build the Android application:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  android-builder-emulator:latest \
  gradle app:assembleDebug
```

The project directory is mounted at `/workspace`. The generated APK is available on the host at:

```text
app/build/outputs/apk/debug/app-debug.apk
```

For a release build, use `app:assembleRelease` if your project is configured for release builds and signing.

## How to run UI tests

This example builds the main and instrumentation test APKs, starts the Android emulator, installs both APKs, and runs the instrumentation tests.

Replace `com.example.app` with your app's actual package and test package configuration.

```bash
docker run --rm \
  --name android-ui-test \
  -v "$PWD:/workspace" \
  -w /workspace \
  android-builder-emulator:latest \
  bash -lc '
    set -e

    # Build the application and instrumentation test APKs
    gradle app:assembleDebug app:assembleDebugAndroidTest

    # Start the emulator in the background
    emulator -avd "$AVD_NAME" \
      -no-window \
      -no-audio \
      -no-boot-anim \
      -gpu swiftshader_indirect \
      -accel off &

    # Wait for the emulator to connect
    adb wait-for-device

    # Wait until Android has completed booting
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" = "1" ]; do
      sleep 2
    done

    # Install the main application APK
    adb install -r \
      app/build/outputs/apk/debug/app-debug.apk

    # Install the instrumentation test APK
    adb install -r \
      app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk

    # Run the instrumentation tests
    adb shell am instrument -w \
      com.example.app.test/androidx.test.runner.AndroidJUnitRunner
  '
```

### What the commands do

- `app:assembleDebug` builds the main application APK.
- `app:assembleDebugAndroidTest` builds the instrumentation test APK.
- `emulator -avd "$AVD_NAME"` starts the AVD configured in the Docker image.
- `adb wait-for-device` waits for the emulator to become available.
- `sys.boot_completed` waits for Android to finish booting.
- `adb install -r` installs or updates each APK.
- `am instrument -w` runs the instrumentation tests and waits for their results.

### Notes

- Update `com.example.app.test` and `androidx.test.runner.AndroidJUnitRunner` to match your project's test application ID and instrumentation runner.
- The APK paths above assume the `app` module uses the standard debug output directories.
- `-accel off` enables software emulation, which may be slow. If the Docker host supports KVM, pass `--device /dev/kvm` to `docker run` and use `-accel on` instead.
- For CI pipelines, ensure instrumentation test failures produce a nonzero exit code so the pipeline fails when tests fail.