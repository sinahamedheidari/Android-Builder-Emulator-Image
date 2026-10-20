# Use an Android SDK base image with Android SDK tools preinstalled
FROM ghcr.io/cirruslabs/android-sdk:36

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# -------------------------
# Environment variables
# -------------------------
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
ENV ANDROID_HOME=/opt/android-sdk-linux
# Android Virtual Device (AVD)
ENV AVD_NAME=ci-avd
ENV GRADLE_HOME=/opt/gradle
ENV KOTLIN_HOME=/opt/kotlinc
ENV PATH=$PATH:${GRADLE_HOME}/bin:${KOTLIN_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools
# Gradle dependencies and build caches directory
ENV GRADLE_USER_HOME=/opt/gradle-cache

# -------------------------
# Install system dependencies
# -------------------------

RUN set -ex \
    && apt-get update \
    && apt-get install -y \
        vim \
        zip \
        cmake \ 
        ninja-build \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Install Gradle
# -------------------------
ARG GRADLE_VERSION=8.13

RUN cd /opt \
    && wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip gradle-${GRADLE_VERSION}-bin.zip \
    && mv gradle-${GRADLE_VERSION} gradle \
    && rm gradle-*.zip

# -------------------------
# Install Kotlin compiler
# -------------------------
ARG KOTLIN_VERSION=2.2.10

RUN cd /opt \
    && wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip \
    && unzip kotlin-compiler-${KOTLIN_VERSION}.zip \
    && rm kotlin-compiler-${KOTLIN_VERSION}.zip

# -------------------------
# Install Android NDK
# -------------------------
ARG NDK_MAJOR_VERSION=r27
ARG NDK_VERSION=27.0.12077973

RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip \
    && unzip android-ndk-${NDK_VERSION}-linux.zip \
    && mkdir -p ${ANDROID_SDK_ROOT}/ndk/ \
    && mv android-ndk-${NDK_MAJOR_VERSION} ${ANDROID_SDK_ROOT}/ndk/${NDK_VERSION} \
    && rm android-ndk-${NDK_VERSION}-linux.zip

# -------------------------
# Install Android emulator system image
# -------------------------

# Specify the Android API level used by the emulator
ARG ANDROID_API=35

# Define the Google APIs x86_64 system image package
ARG SYSTEM_IMAGE="system-images;android-${ANDROID_API};google_apis;x86_64"

RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sys-img/google_apis/x86_64-${ANDROID_API}_r09.zip \
    && mkdir -p ${ANDROID_SDK_ROOT}/system-images/android-${ANDROID_API}/google_apis \
    && unzip x86_64-${ANDROID_API}_r09.zip -d ${ANDROID_SDK_ROOT}/system-images/android-${ANDROID_API}/google_apis \
    && rm x86_64-${ANDROID_API}_r09.zip

# -------------------------
# Create Android Virtual Device (AVD)
# -------------------------

RUN echo "no" | avdmanager create avd \
    --force \
    --name $AVD_NAME \
    --package "system-images;android-${ANDROID_API};google_apis;x86_64" \
    --device "pixel_2"