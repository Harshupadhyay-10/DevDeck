# Threat model

This document describes what Dev Deck protects, who it protects against, and
which design rules follow from that. It is written before the code so the code
can be judged against it.

## What the system does

A companion app on the Mac listens on the local network. An iPhone or iPad app
discovers it, pairs once, and afterwards sends requests to run predefined
actions. Running an action can execute a shell command as the logged-in user.
That makes the Mac companion a remote code execution surface by design, so the
rest of this document is about keeping that surface as small as possible.

## Assets

- The Mac user account and everything it can reach: SSH keys, cloud
  credentials, tokens, source code, the keychain.
- The list of paired devices and their keys.
- The action definitions (which commands exist and what they do).
- Command output shown on the phone, which may contain secrets.

## Actors

- **Local network attacker.** Another device on the same Wi-Fi who can observe
  or inject traffic and connect to open ports. This is the primary threat.
- **Thief or finder of a paired phone or iPad.**
- **Malicious software on the Mac** that tries to abuse the listener, the
  stored keys or the action definitions.
- **A curious person standing at an unlocked, unattended phone.**

## Out of scope for v1

- A Mac that is already fully compromised.
- An attacker with physical access to an unlocked Mac.
- Attacks that require breaking the platform cryptography itself.

## Design rules

1. **Action identifiers only.** The phone can only ask to run an action by
   identifier. It never sends a command string. A compromised phone or
   connection can trigger existing actions but cannot define new behavior.
2. **The Mac is the source of truth.** Action definitions are created and
   edited on the Mac only. The phone receives a read-only copy for display.
3. **Explicit pairing.** A new device is approved on the Mac screen, with the
   Mac unlocked, using a QR code or PIN. Keys are exchanged once and pinned.
4. **Encrypted and mutually authenticated transport**, with protection against
   replayed and tampered messages.
5. **Revocable devices.** The Mac lists paired devices and can remove any of
   them immediately.
6. **Confirmation for dangerous actions.** Actions marked as destructive need
   an extra confirmation before they run.
7. **No cloud, no accounts, no telemetry.** Nothing leaves the local network
   and nothing is sent to any server operated by the project.
8. **Fail closed.** An unknown device, a bad signature or a malformed message
   ends the connection and is logged locally.
9. **No data collection of any kind.** No analytics, crash reporting or
   advertising components. No identifiers are created for tracking.
10. **No third-party dependencies by default.** Each one must be approved
    individually because it enlarges the supply-chain risk.
11. **Logs stay local and never contain secrets.** Command output is not
    persisted by default.
12. **Native Apple frameworks only.** SwiftUI, Network.framework, CryptoKit and
    the Keychain.

## Threats and planned mitigations

| Threat | Planned mitigation | Status |
| --- | --- | --- |
| Someone on the Wi-Fi connects and runs actions | Pairing required; mutually authenticated encrypted channel; unknown peers dropped | Not implemented |
| Someone on the Wi-Fi records and replays traffic | Per-session keys; message counters or nonces checked on receipt | Not implemented |
| Someone on the Wi-Fi impersonates the Mac during pairing | Pairing secret delivered out of band (QR code or PIN on the Mac screen) and bound to the key exchange | Not implemented |
| Stolen phone is used to run actions | Revoke the device on the Mac; destructive actions need confirmation; optional device passcode check before running | Not implemented |
| Stolen phone is used to define new commands | Phone cannot create or edit actions (rule 2) | Not implemented |
| Malicious Mac software edits action definitions | Store definitions with user-only file permissions; consider integrity protection | Open question |
| Malicious Mac software reads pairing keys | Keep key material in the Keychain, not in plain files | Not implemented |
| Command output leaks secrets to the phone | Output display is opt-in per action; output is not persisted | Not implemented |
| Malformed input crashes or exploits the listener | Strict message size limits; strict decoding; reject unknown fields and versions | Not implemented |
| Port scanning finds the listener | The listener cannot be hidden on a LAN, so it must reveal nothing before authentication | Not implemented |
| Action runs while the Mac is locked | Option to refuse actions when the screen is locked | Open question |

## Open questions

- Which pairing scheme to use, and how much of it can be built from CryptoKit
  primitives without inventing a protocol. This needs its own design note and
  your review before any code.
- How to protect action definitions from tampering by other software running as
  the same user.
- Whether to bind approval of each action run to the phone's local
  authentication (Face ID or passcode).
