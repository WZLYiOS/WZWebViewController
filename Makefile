# Makefile

# Define variables

POD_SPEC_PATH := WZWebViewController.podspec

.PHONY: push_podspec

# Set the default target
all: push_podspec

push_podspec:
	pod trunk push $(POD_SPEC_PATH) --allow-warnings --skip-import-validation
