# Dev Deck

Native Apple app: an iPhone/iPad deck that triggers predefined actions on a
Mac over the local network. Read docs/THREAT_MODEL.md before any change.

## Hard rules

- Stop and ask before touching anything security-related: pairing, crypto,
  authentication, network listeners, command execution, entitlements,
  Keychain, permissions, privacy strings. Say what and why, then wait.
- The phone sends action identifiers only, never command strings.
- No third-party dependencies. Apple frameworks only.
- No accounts, analytics, telemetry or crash reporting. No calls to any server.
- Security-relevant code lives in a folder named Security.
- Targets iOS 26, iPadOS 26 and macOS 26. Pure SwiftUI; system components and
  Liquid Glass first.
- Never read or write secrets, keys, tokens or .env files.

## Git

- Commit locally only. Never push, amend, rewrite history or force anything.
- One logical change per commit, and every commit builds.
- Imperative subject under 72 characters; body explains why when not obvious.
- No em dashes anywhere (code, docs, commits). No emoji.
- No attribution trailers or tool mentions in commit messages.

## Working

- Pure-Swift logic gets Swift Testing tests. Run
  `swift test --package-path Packages/DevDeckKit`.
- Say plainly when something is unverified or was not built.
