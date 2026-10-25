# v0.58.1 installer repair candidate

This branch is for review. Nothing here publishes a release or changes the live
update feeds. Gameplay stays at shared-v0.58, network protocol 3.

The Windows PC and Quest importers now verify all supported original input files
before conversion. The original executable check remains an offline file check;
it does not verify Steam account entitlement.

The original game renders the HUD item atlas on the importing PC's GPU. Exact
pixel hashes can differ between GPUs. Only that generated atlas has a separate
policy: fixed 512 by 1280 dimensions and byte count, valid transparency, bounded
coverage/color measurements for each icon, and an exact local SHA-256 receipt.
The receipt detects changed bytes while the recorded digest is retained; it is
not proof of original-game provenance or cryptographic authenticity of the
generated pixels. Rearranging pixels or changing nonzero alpha can preserve the
statistics, and a regenerated matching receipt can accept such edits. This is a
bounded format and transfer-corruption check. Original-input identity is checked
separately before conversion.
Every other required output retains its exact supported SHA-256. An unsupported
source file, malformed/blank atlas, missing icon, or mismatched receipt is an error.
This candidate has not been tested on the reporter's GPU.

Quest ADB calls pass explicit named string arrays, preserving spaces and compound
shell commands under Windows PowerShell 5.1. Setup checks that the app is closed,
stages and verifies game files before installing, verifies the packaged APK hash,
and uses Android's in-place same-signer update. It never uninstalls, clears app
data, or force-stops an active game. A failed transfer or APK install leaves the
active imports unchanged. A failed import-directory commit attempts rollback;
prior imports remain in the named backup directory. If setup fails after the APK
has installed, close the app and rerun the complete setup before playing.

## Existing installations and retries

- Existing exact-match v0.58 imports need no receipt migration. The v0.58.1 APK
  continues to accept them. Use an in-place APK update; never uninstall first.
- The published v0.58 APK contains CRLF checksum-list lines, which its native
  parser rejects. This candidate packages LF lines. If v0.58 cannot reach the
  menu, run the complete candidate setup or manually install its verified APK
  in place; the in-game updater cannot repair an app that cannot start.
- If v0.58 setup failed at `hud-items.rgba`, run the complete v0.58.1 setup. A newly
  generated GPU variant needs both the new validator APK and its receipt. Do not
  combine the repaired installer with the old v0.58 APK.
- If another import differs, verify the supported Steam files and rerun setup.
  A code-only APK cannot repair missing or stale original game content.
- PC setup can reuse a verified conversion with `-ImportDirectory`. Conversion
  destinations must be new; failed output folders and previous imports remain
  available for diagnosis. The normal setup uses a fresh unique destination.
- Close the game yourself before setup. If Android reports a signer mismatch,
  stop and obtain the matching signed APK; do not uninstall to work around it.

The PC runtime binary remains the verified v0.58 binary (version code 61). Its
installer revision is v0.58.1. The Quest runtime needs the generated-output
validator change and uses version code 62, version name `0.58.1-installer-hud`.
Both retain the same gameplay/content/network revision; this is an installer
repair, with no graphics or gameplay tuning.

## Publication hold

Review the exact candidate hashes and private GitHub build report before release.
Physical Quest installation/upgrade, existing-world preservation on hardware,
PCVR headset play, a second GPU, performance and different-home networking remain
separate acceptance checks. Host tests and an APK build do not establish those.
