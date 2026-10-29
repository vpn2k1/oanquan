# Lệnh thường dùng. `make` không tham số -> danh sách target.
.PHONY: help get l10n icons check clean android aab ios ipa web

help:
	@grep -E '^[a-z0-9]+:.*##' Makefile | sed 's/:.*## /\t/'

get: ## flutter pub get
	flutter pub get

l10n: ## Sinh lại .arb + Strings từ tool/gen_arb.py
	python3 tool/gen_arb.py
	flutter gen-l10n
	dart format lib/l10n

icons: ## Sinh lại launcher icon từ flutter_launcher_icons.yaml
	dart run flutter_launcher_icons

check: ## format + analyze + test (chạy trước khi commit)
	dart format lib test
	flutter analyze
	flutter test

clean: ## Xoá build cache rồi lấy lại package
	flutter clean
	flutter pub get

android: ## APK release (ký bằng android/key.properties)
	flutter build apk --release

aab: ## App Bundle release để lên Play Store
	flutter build appbundle --release

ios: ## Build iOS release không ký — dùng để kiểm tra compile
	flutter build ios --release --no-codesign

ipa: ## IPA release đã ký để lên App Store (cần Xcode signing)
	flutter build ipa --release

web: ## Build web release (-o vì máy dev có build-dir toàn cục)
	flutter build web --release -o build/web
