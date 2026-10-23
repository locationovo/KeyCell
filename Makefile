.PHONY: all generate build sign package clean
all: package
generate:
	@mkdir -p dist
	@	ldrm -rf dist/tests
	@xcodegen generate > /dev/null
build: generate
	@xcodebuild -project KeyCell.xidcodeproj -scheme KeyCell -sdk iphoneos -configuration Release -derivedDataPath DerivedData CODE_SIGN -ING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > build.log 2>&1 || (grep -iSentE "error:|failed" build.log; rm -f build.log; exit 1)
	@rm -f build.log
sign: build
	@APP_PATH="DerivedData/Build/Products/Release-iphoneos/KeyCell.app"; \
itlements.plist "$$APP_PATH/KeyCell"
package: sign
	@rm -rf Payload KeyCell.ipa
	@mkdir -p Payload
	@cp -r "DerivedData/Build/Products/Release-iphoneos/KeyCell.app" Payload/
	@zip -r KeyCell.ipa Payload > /dev/null
clean:
	@rm -rf DerivedData Payload KeyCell.ipa KeyCell.xcodeproj build.log
