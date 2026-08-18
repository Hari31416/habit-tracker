ANDROID_HOME ?= $(HOME)/Library/Android/sdk
ADB := $(shell which adb 2>/dev/null || echo $(ANDROID_HOME)/platform-tools/adb)
EMULATOR := $(shell which emulator 2>/dev/null || echo $(ANDROID_HOME)/emulator/emulator)

PACKAGE_NAME := com.productivity.habits
MAIN_ACTIVITY := $(PACKAGE_NAME).MainActivity
DEFAULT_AVD := $(shell $(EMULATOR) -list-avds 2>/dev/null | head -n 1)
AVD ?= $(DEFAULT_AVD)

.PHONY: help build build-release test lint clean install uninstall emulator-list emulator-start emulator-stop emulator-wait start stop restart run debug logcat flutter-run flutter-run-android flutter-build-apk flutter-test flutter-analyze flutter-codegen codegen kotlin-build kotlin-build-release kotlin-test kotlin-lint kotlin-clean kotlin-install kotlin-run

help: ## Show this help message
	@echo "Usage: make [target] [AVD=avd_name]"
	@echo ""
	@echo "Default Android (Flutter):"
	@echo "  make build           - Build the debug APK via Flutter"
	@echo "  make build-release   - Build the release APK via Flutter"
	@echo "  make test            - Run all Flutter unit and widget tests"
	@echo "  make lint            - Run Flutter code analysis"
	@echo "  make clean           - Clean Flutter and Gradle build artifacts"
	@echo "  make run             - Complete pipeline: ensure emulator, build, and launch Flutter app"
	@echo "  make codegen         - Run build_runner for Drift/Riverpod codegen"
	@echo ""
	@echo "Flutter Aliases:"
	@echo "  make flutter-run     - Ensure emulator, then run Flutter app on Android"
	@echo "  make flutter-build-apk - Build debug APK via Flutter"
	@echo "  make flutter-test    - Run all Flutter unit and widget tests"
	@echo "  make flutter-analyze - Run Flutter code analysis"
	@echo "  make flutter-codegen - Run build_runner for Drift/Riverpod codegen"
	@echo ""
	@echo "Native Android Reference (Kotlin):"
	@echo "  make kotlin-build    - Build native Kotlin debug APK (assembleDebug)"
	@echo "  make kotlin-build-release - Build native Kotlin release APK (assembleRelease)"
	@echo "  make kotlin-test     - Run native Kotlin unit tests"
	@echo "  make kotlin-lint     - Run native Kotlin Android lint check"
	@echo "  make kotlin-clean    - Clean native Kotlin build artifacts"
	@echo "  make kotlin-install  - Build and install native Kotlin debug APK"
	@echo "  make kotlin-run      - Complete pipeline: ensure emulator, build, install & launch Kotlin app"
	@echo ""
	@echo "Emulator & Device:"
	@echo "  make emulator-list   - List all available Android Virtual Devices (AVDs)"
	@echo "  make emulator-start  - Start the emulator in background (uses $(AVD))"
	@echo "  make emulator-stop   - Gracefully stop/shutdown running emulator"
	@echo "  make emulator-wait   - Wait for device/emulator to finish booting"
	@echo ""
	@echo "Run & Debug:"
	@echo "  make install         - Build and install debug APK on connected device"
	@echo "  make start           - Launch the app on running device/emulator"
	@echo "  make stop            - Force-stop the app process"
	@echo "  make restart         - Force-stop and restart the app"
	@echo "  make debug           - Alias for make run"
	@echo "  make logcat          - Stream logs for the application"
	@echo "  make uninstall       - Uninstall the app from connected device/emulator"
	@echo ""

build: ## Build Flutter debug APK
	flutter build apk --debug --android-skip-build-dependency-validation

build-release: ## Build Flutter release APK
	flutter build apk --release --android-skip-build-dependency-validation

test: ## Run Flutter unit and widget tests
	flutter test

lint: ## Run Flutter analyzer
	flutter analyze

clean: ## Clean Flutter and Gradle build artifacts
	flutter clean
	./gradlew clean

install: build ## Install debug APK on connected device
	$(ADB) install -r build/app/outputs/flutter-apk/app-debug.apk

uninstall: ## Uninstall app from device
	$(ADB) uninstall $(PACKAGE_NAME) || true

codegen: flutter-codegen ## Alias for flutter-codegen

emulator-list: ## List available AVDs
	@$(EMULATOR) -list-avds

emulator-start: ## Start emulator in background
	@if [ -z "$(AVD)" ]; then \
		echo "No AVD found. Create one in Android Studio or specify AVD=<name>"; \
		exit 1; \
	fi
	@echo "Starting emulator: $(AVD)..."
	@nohup $(EMULATOR) -avd $(AVD) -netdelay none -netspeed full > /dev/null 2>&1 &

emulator-stop: ## Stop running emulator
	@echo "Stopping emulator..."
	@$(ADB) emu kill 2>/dev/null || $(ADB) -e emu kill 2>/dev/null || true
	@echo "Emulator stopped."

emulator-wait: ## Wait for emulator to boot
	@echo "Waiting for device to connect..."
	@$(ADB) wait-for-device
	@echo "Waiting for boot animation to complete..."
	@while [ "$$($(ADB) shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do \
		sleep 2; \
	done
	@echo "Device is ready!"

start: ## Launch MainActivity on connected device
	$(ADB) shell am start -n $(PACKAGE_NAME)/$(MAIN_ACTIVITY)

stop: ## Force-stop app process
	$(ADB) shell am force-stop $(PACKAGE_NAME)

restart: stop start ## Restart app

run: ## Ensure device, build, install, and launch Flutter app
	@DEVICES=$$($(ADB) devices | grep -v "List" | grep "device" | wc -l | tr -d ' '); \
	if [ "$$DEVICES" -eq "0" ]; then \
		echo "No active Android device/emulator detected."; \
		$(MAKE) emulator-start; \
		$(MAKE) emulator-wait; \
	fi; \
	ANDROID_DEVICE=$$($(ADB) devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $$1}'); \
	if [ -n "$$ANDROID_DEVICE" ]; then \
		echo "Running Flutter app on Android device: $$ANDROID_DEVICE"; \
		flutter run -d "$$ANDROID_DEVICE" --android-skip-build-dependency-validation; \
	else \
		flutter run -d android-arm64 --android-skip-build-dependency-validation; \
	fi

debug: run ## Alias for run

logcat: ## Stream app logs
	$(ADB) logcat -v color --pid=$$($(ADB) shell pidof -s $(PACKAGE_NAME)) || $(ADB) logcat | grep --color=auto $(PACKAGE_NAME)

flutter-run: run ## Ensure emulator and run Flutter app on Android

flutter-run-android: run ## Alias for flutter-run

flutter-build-apk: build ## Build debug APK with Flutter

flutter-test: test ## Run Flutter unit and widget tests

flutter-analyze: lint ## Run Flutter analyzer

flutter-codegen: ## Run build_runner for code generation
	dart run build_runner build --delete-conflicting-outputs

kotlin-build: ## Build native Kotlin debug APK (assembleDebug)
	./gradlew assembleDebug

kotlin-build-release: ## Build native Kotlin release APK (assembleRelease)
	./gradlew assembleRelease

kotlin-test: ## Run native Kotlin unit tests
	./gradlew testDebugUnitTest

kotlin-lint: ## Run native Kotlin lint
	./gradlew lintDebug

kotlin-clean: ## Clean native Kotlin build
	./gradlew clean

kotlin-install: ## Build and install native Kotlin debug APK
	./gradlew installDebug

kotlin-run: ## Ensure device, build, install, and launch Kotlin app
	@DEVICES=$$($(ADB) devices | grep -v "List" | grep "device" | wc -l | tr -d ' '); \
	if [ "$$DEVICES" -eq "0" ]; then \
		echo "No active device/emulator detected."; \
		$(MAKE) emulator-start; \
		$(MAKE) emulator-wait; \
	fi
	./gradlew installDebug
	$(MAKE) start

