# Dev Deck

A customizable button deck for developers. Run it on an iPhone or iPad and
trigger actions on your Mac over the local network: git commands, scripts,
launching and quitting apps.

Status: early development. Nothing here is usable yet.

## Principles

- No accounts, no analytics, no servers. Everything stays on your local network.
- The phone sends action identifiers, never raw commands. Actions are defined
  and stored on the Mac.
- Native Apple frameworks only, with no third-party dependencies by default.
- Requires iOS 26, iPadOS 26 and macOS 26 or later.

## Layout

- `Packages/DevDeckKit`: shared protocol and model code, kept small and tested.
- `docs/`: threat model and design notes.
- `SECURITY.md`: security policy.

The Mac companion and the iOS app are added as Xcode targets in later commits.
