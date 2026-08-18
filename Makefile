ANDROID_HOME ?= $(HOME)/Library/Android/sdk
ADB := $(shell which adb 2>/dev/null || echo $(ANDROID_HOME)/platform-tools/adb)
EMULATOR := $(shell which emulator 2>/dev/null || echo $(ANDROID_HOME)/emulator/emulator)

PACKAGE_NAME := com.productivity.habits
MAIN_ACTIVITY := $(PACKAGE_NAME).MainActivity
DEFAULT_AVD := $(shell $(EMULATOR) -list-avds 2>/dev/null | head -n 1)
AVD ?= $(DEFAULT_AVD)

.PHONY: help build build-release test lint clean install uninstall emulator-list emulator-start emulator-stop emulator-wait start stop restart run debug logcat flutter-run flutter-run-android flutter-build-apk flutter-test flutter-analyze flutter-codegen

help: ## Show this help message
	@echo "Usage: make [target] [AVD=avd_name]"
	@echo ""
	@echo "Native Android (Kotlin):"
	@echo "  make build           - Build the debug APK (assembleDebug)"
	@echo "  make build-release   - Build the release APK (assembleRelease)"
	@echo "  make test            - Run all unit tests"
	@echo "  make lint            - Run Android lint check"
	@echo "  make clean           - Clean build artifacts"
	@echo "  make run             - Complete pipeline: ensure emulator, build, install & launch Kotlin app"
	@echo ""
	@echo "Flutter Android:"
	@echo "  make flutter-run     - Ensure emulator, then run Flutter app on Android (alias: flutter-run-android)"
	@echo "  make flutter-build-apk - Build debug APK via Flutter"
	@echo "  make flutter-test    - Run all Flutter unit and widget tests"
	@echo "  make flutter-analyze - Run Flutter code analysis"
	@echo "  make flutter-codegen - Run build_runner for Drift/Riverpod codegen"
	@echo ""
	@echo "Emulator & Device:"
	@echo "  make emulator-list   - List all available Android Virtual Devices (AVDs)"
	@echo "  make emulator-start  - Start the emulator in background (uses $(AVD))"
	@echo "  make emulator-stop   - Gracefully stop/shutdown running emulator"
	@echo "  make emulator-wait   - Wait for device/emulator to finish booting"
	@echo ""
	@echo "Run & Debug:"
	@echo "  make install         - Build and install the debug APK on connected device"
	@echo "  make start           - Launch the app on running device/emulator"
	@echo "  make stop            - Force-stop the app process"
	@echo "  make restart         - Force-stop and restart the app"
	@echo "  make debug           - Alias for make run"
	@echo "  make logcat          - Stream logs for the application"
	@echo "  make uninstall       - Uninstall the app from connected device/emulator"
	@echo ""

build: ## Build debug APK
	./gradlew assembleDebug

build-release: ## Build release APK
	./gradlew assembleRelease

test: ## Run unit tests
	./gradlew testDebugUnitTest

lint: ## Run lint
	./gradlew lintDebug

clean: ## Clean build
	./gradlew clean

install: ## Build and install debug APK
	./gradlew installDebug

uninstall: ## Uninstall app from device
	$(ADB) uninstall $(PACKAGE_NAME) || true

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

run: ## Ensure device, build, install, and launch app
	@DEVICES=$$($(ADB) devices | grep -v "List" | grep "device" | wc -l | tr -d ' '); \
	if [ "$$DEVICES" -eq "0" ]; then \
		echo "No active device/emulator detected."; \
		$(MAKE) emulator-start; \
		$(MAKE) emulator-wait; \
	fi
	./gradlew installDebug
	$(MAKE) start

debug: run ## Alias for run

logcat: ## Stream app logs
	$(ADB) logcat -v color --pid=$$($(ADB) shell pidof -s $(PACKAGE_NAME)) || $(ADB) logcat | grep --color=auto $(PACKAGE_NAME)

flutter-run: ## Ensure emulator and run Flutter app on Android
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

flutter-run-android: flutter-run ## Alias for flutter-run

flutter-build-apk: ## Build debug APK with Flutter
	flutter build apk --debug --android-skip-build-dependency-validation

flutter-test: ## Run Flutter unit and widget tests
	flutter test

flutter-analyze: ## Run Flutter analyzer
	flutter analyze

flutter-codegen: ## Run build_runner for code generation
	dart run build_runner build --delete-conflicting-outputs

