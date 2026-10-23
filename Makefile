# Common tasks. Everything here also runs in CI (.github/workflows/ios.yml).
SIM ?= iPhone 17 Pro
SPECS ?= ../substratalapps-applications-specs/substratal-application-specs
XCODEBUILD = xcodebuild -project SubstratalHub.xcodeproj -scheme SubstratalHub -skipPackagePluginValidation

.PHONY: project build test test-kit test-ui contract screens run-demo check

project:          ## Regenerate SubstratalHub.xcodeproj from project.yml
	xcodegen generate

build:            ## Build the app for the simulator
	$(XCODEBUILD) -destination 'generic/platform=iOS Simulator' build

test: test-kit test-ui

test-kit:         ## Unit tests for SubstratalKit (routing, versioning, models)
	cd Packages/SubstratalKit && swift test

test-ui:          ## UI smoke test against demo data
	$(XCODEBUILD) -destination 'platform=iOS Simulator,name=$(SIM)' test -only-testing:SubstratalHubUITests

contract:         ## Vendor the latest published openapi.yaml and re-derive the generator's copy
	scripts/sync-openapi.sh

screens:          ## Regenerate ScreenID.swift from the specs (sibling checkout by default)
	scripts/generate-screen-ids.py $(SPECS)

run-demo:         ## Launch in the booted simulator with demo data, signed in
	xcrun simctl launch booted com.substratal.hub -demo YES -autoSignIn YES

check:            ## Fail if the project, contract or screen registry is out of date
	xcodegen generate --quiet && git diff --exit-code -- SubstratalHub.xcodeproj
	scripts/sync-openapi.sh >/dev/null && git diff --exit-code -- api-contract/openapi.yaml Packages/SubstratalKit/Sources/SubstratalAPI/openapi.yaml
