# CLIPBench signing and notarization procedure

This document records the procedure used to Developer ID-sign and notarize the
CLIPBench test package for distribution outside the Mac App Store.

## Package paths

```text
Package directory:  /Users/thomas/Downloads/CLIPBench-Test
Executable:         /Users/thomas/Downloads/CLIPBench-Test/clipbench
Notarization ZIP:   /Users/thomas/Downloads/CLIPBench-Test-signed.zip
```

The package directory contains the executable, converted CLIP-DataComp model,
tokenizer, licences, third-party notices, model provenance, tester instructions,
and `SHA256SUMS.txt`.

The packaged executable is an arm64 command-line tool requiring macOS 27 or
later.

## Signing configuration

```text
Developer ID identity: Developer ID Application: Thomas Evensen (93M47F4H9T)
Team ID:               93M47F4H9T
Notarytool profile:    RsyncUI
```

Use the **Developer ID Application** certificate for the executable. A
Developer ID Installer certificate is for signed installer packages and is not
the correct identity for this standalone executable.

The `RsyncUI` keychain profile contains the credentials used by `notarytool`.
It does not contain or replace the Developer ID Application signing
certificate.

## 1. Confirm the signing identity

List usable code-signing identities:

```sh
security find-identity -v -p codesigning
```

The output must include an identity similar to:

```text
Developer ID Application: Thomas Evensen (93M47F4H9T)
```

The Team ID by itself is not a signing identity. For example, this is
incomplete and will produce `no identity found`:

```text
Developer ID Application: 93M47F4H9T
```

If `security find-identity` reports `0 valid identities found`, open:

1. Xcode → Settings → Accounts.
2. Select the Apple account and team.
3. Select **Manage Certificates**.
4. Confirm that a Developer ID Application certificate is installed.

Also open Keychain Access → login → My Certificates, expand the Developer ID
Application certificate, and confirm that its private key appears underneath
it. A certificate without the corresponding private key cannot sign software.

## 2. Sign the executable

Sign the unpacked executable before creating the final ZIP:

```sh
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Thomas Evensen (93M47F4H9T)" \
  "/Users/thomas/Downloads/CLIPBench-Test/clipbench"
```

The options used here are important:

- `--force` replaces the linker-generated/ad-hoc signature.
- `--options runtime` enables the hardened runtime required for notarization.
- `--timestamp` requests a secure Apple timestamp.
- `--sign` selects the complete Developer ID Application identity.

The following message is expected and indicates that the old signature was
replaced:

```text
clipbench: replacing existing signature
```

## 3. Verify the signature

Verify the signed executable:

```sh
codesign --verify --strict --verbose=4 \
  "/Users/thomas/Downloads/CLIPBench-Test/clipbench"

codesign -dvvv \
  "/Users/thomas/Downloads/CLIPBench-Test/clipbench"
```

The verification should report:

```text
valid on disk
satisfies its Designated Requirement
Authority=Developer ID Application: Thomas Evensen (93M47F4H9T)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
TeamIdentifier=93M47F4H9T
```

It must also show a timestamp and:

```text
flags=0x10000(runtime)
```

Running `spctl --assess --type execute` directly on this bare executable can
report:

```text
rejected (the code is valid but does not seem to be an app)
```

That result is expected for a standalone command-line executable and does not
mean the Developer ID signature is invalid. Use `codesign --verify` to verify
the executable signature.

## 4. Regenerate the package checksums

Code signing changes the executable. Therefore, any checksum created before
signing is stale and must be regenerated.

```sh
cd "/Users/thomas/Downloads/CLIPBench-Test"

find . -type f ! -name SHA256SUMS.txt \
  -exec shasum -a 256 {} + |
  LC_ALL=C sort -k 2 > SHA256SUMS.txt
```

Verify every packaged file:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

Every file should report `OK`.

## 5. Create a clean signed ZIP

Create the ZIP only after signing and regenerating the checksums:

```sh
cd "/Users/thomas/Downloads"

/bin/rm -f "/Users/thomas/Downloads/CLIPBench-Test-signed.zip"

COPYFILE_DISABLE=1 /usr/bin/zip -r -X \
  "CLIPBench-Test-signed.zip" \
  "CLIPBench-Test"
```

Validate the archive before uploading it:

```sh
unzip -t "/Users/thomas/Downloads/CLIPBench-Test-signed.zip"

shasum -a 256 \
  "/Users/thomas/Downloads/CLIPBench-Test-signed.zip"
```

Do not change the executable or other package files after creating this ZIP.
If anything changes, repeat the checksum and ZIP steps.

## 6. Submit the ZIP for notarization

```sh
xcrun notarytool submit \
  --keychain-profile "RsyncUI" \
  --wait \
  "/Users/thomas/Downloads/CLIPBench-Test-signed.zip"
```

A successful submission ends with:

```text
Processing complete
status: Accepted
```

If Apple reports `Invalid`, retrieve the detailed log using the submission ID:

```sh
xcrun notarytool log SUBMISSION-ID \
  --keychain-profile "RsyncUI"
```

Information about any submission can be retrieved with:

```sh
xcrun notarytool info SUBMISSION-ID \
  --keychain-profile "RsyncUI"
```

## 7. Stapling

Do **not** run `xcrun stapler staple` on the ZIP or the bare `clipbench`
executable. ZIP archives and standalone executables cannot carry a stapled
notarization ticket.

For this ZIP distribution, Gatekeeper retrieves the notarization ticket from
Apple when the downloaded software is checked. If a stapled ticket and offline
verification are required, distribute the signed executable inside a
notarized `.pkg` or `.dmg` and staple that supported container.

## Accepted CLIPBench-Test submission

The following package was successfully accepted by Apple's notary service on
30 July 2026:

```text
Archive:
  /Users/thomas/Downloads/CLIPBench-Test-signed.zip

Submission ID:
  40189f29-fcc1-4c80-afc7-201d1c61d229

Status:
  Accepted

Archive SHA-256:
  8984fe382f644570fdfbffdfa00e38394c2620547525f0965efa102ba9425fc2
```

The accepted archive passed ZIP integrity validation, and the packaged
executable passed strict `codesign` verification.

Publish the accepted ZIP without modifying or recompressing it. Retain its
SHA-256 value and submission ID with the release records.

## Corrected Makefile example

The signing target must actually run `codesign`. Stapling is not part of the
ZIP workflow.

```make
CLIPBENCH_PACKAGE_DIR := /Users/thomas/Downloads/CLIPBench-Test
CLIPBENCH_BINARY := $(CLIPBENCH_PACKAGE_DIR)/clipbench
CLIPBENCH_SIGNED_ZIP := /Users/thomas/Downloads/CLIPBench-Test-signed.zip
CLIPBENCH_SIGN_IDENTITY := Developer ID Application: Thomas Evensen (93M47F4H9T)
CLIPBENCH_NOTARY_PROFILE := RsyncUI

.PHONY: sign checksums zip notarize verify

sign:
	codesign --force --options runtime --timestamp \
		--sign "$(CLIPBENCH_SIGN_IDENTITY)" \
		"$(CLIPBENCH_BINARY)"

verify:
	codesign --verify --strict --verbose=4 "$(CLIPBENCH_BINARY)"
	codesign -dvvv "$(CLIPBENCH_BINARY)"

checksums:
	cd "$(CLIPBENCH_PACKAGE_DIR)" && \
		find . -type f ! -name SHA256SUMS.txt \
		-exec shasum -a 256 {} + | \
		LC_ALL=C sort -k 2 > SHA256SUMS.txt
	cd "$(CLIPBENCH_PACKAGE_DIR)" && \
		shasum -a 256 -c SHA256SUMS.txt

zip:
	/bin/rm -f "$(CLIPBENCH_SIGNED_ZIP)"
	cd "/Users/thomas/Downloads" && \
		COPYFILE_DISABLE=1 /usr/bin/zip -r -X \
		"$(notdir $(CLIPBENCH_SIGNED_ZIP))" \
		"$(notdir $(CLIPBENCH_PACKAGE_DIR))"
	unzip -t "$(CLIPBENCH_SIGNED_ZIP)"

notarize:
	xcrun notarytool submit \
		--keychain-profile "$(CLIPBENCH_NOTARY_PROFILE)" \
		--wait \
		"$(CLIPBENCH_SIGNED_ZIP)"
```

Run the targets in this order:

```sh
make sign
make verify
make checksums
make zip
make notarize
```

## Apple references

- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

