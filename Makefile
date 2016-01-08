XCODE_COMMAND=$(shell { command -v xctool || command -v xcodebuild; } 2>/dev/null)
XCODE_GENERIC_FLAGS=-project 'Shirley.xcodeproj'
XCODE_OSX_FLAGS=-scheme 'Shirley-OSX'
XCODE_IOS_FLAGS=-scheme 'Shirley-iOS'

.PHONY: all clean docs test

all:
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_OSX_FLAGS) build
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_IOS_FLAGS) build

clean:
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_OSX_FLAGS) clean
	$(XCODE_COMMAND) $(XCODE_GENERIC_FLAGS) $(XCODE_IOS_FLAGS) clean

docs:
	jazzy \
		--clean \
		--author "Nate Stedman" \
		--author_url "http://natestedman.com" \
		--github_url "https://github.com/natestedman/Shirley" \
		--github-file-prefix "https://github.com/natestedman/Shirley/tree/master" \
		--module-version "0.1.0" \
		--xcodebuild-arguments -scheme,Shirley-OSX \
		--module Shirley \
		--output Documentation

test:
	xcodebuild $(XCODE_GENERIC_FLAGS) $(XCODE_OSX_FLAGS) test
