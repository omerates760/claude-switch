# claude-switch

> Quickly switch between multiple Claude accounts — **fully isolating Claude Code and Claude Desktop state** (credentials, conversation history, sessions, memory, settings) per profile.

A lightweight macOS shell script that lets you keep e.g. **work** and **personal** Claude accounts completely separated. One command swaps everything.

## Why?

Other account switchers swap only the credential, leaving conversation history, sessions, and memory shared between accounts. That means a chat from your work account is still visible — and even searchable — when you log in with your personal account.

`claude-switch` swaps the **entire profile directory** for both Claude Code and Claude Desktop, so each account has its own:

- Conversation history (`~/.claude/projects/*`, `~/.claude/history.jsonl`)
- Sessions, tasks, plans, memory
- Settings (`settings.json`, `settings.local.json`)
- MCP server configs and OAuth state
- Claude Desktop cookies, IndexedDB, local storage
- Keychain credentials (backed up per profile)

## Requirements

- **macOS 12+** (uses `/usr/bin/security` for Keychain)
- Bash 3.2+ (preinstalled)
- Claude Code and/or Claude Desktop installed

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/omerates760/claude-switch/main/install.sh | bash
```

This installs `claude-switch` to `~/.claude-profiles/claude-switch` and symlinks it to `/opt/homebrew/bin/claude-switch` (or `/usr/local/bin/claude-switch` on Intel Macs).

To install manually:

```sh
git clone https://github.com/omerates760/claude-switch.git
cd claude-switch
./install.sh
```

## Quick start

> **Important:** Quit Claude Desktop (`Cmd+Q`) and exit all running `claude` (Code) sessions before running `init` or switching profiles. Running sessions hold the directory open.

```sh
# 1. Move your current Claude state into a profile (run once)
claude-switch init work

# 2. Add a second profile
claude-switch add personal

# 3. Switch and log in with the other account
claude-switch personal
claude /login            # Code login
open -a Claude           # Then sign into Desktop with the other account

# 4. Going forward — one command swaps everything
claude-switch work
claude-switch personal
claude-switch            # show current + list profiles
```

## Commands

| Command | Description |
|---|---|
| `claude-switch` | List profiles, mark active |
| `claude-switch <name>` | Switch to profile `<name>` |
| `claude-switch init <name>` | First-time setup: move existing `~/.claude` and Desktop state into a profile |
| `claude-switch add <name>` | Create empty profile (login required after switching) |
| `claude-switch remove <name>` | Delete profile and its keychain backups (with confirmation) |
| `claude-switch current` | Print active profile name |

## How it works

```
~/.claude-profiles/
├── .active                    # active profile name
├── work/
│   ├── code/                  # ←  ~/.claude  symlink target
│   └── desktop/               # ←  ~/Library/Application Support/Claude  symlink target
└── personal/
    ├── code/
    └── desktop/

~/.claude                                   → symlink to active profile's code/
~/Library/Application Support/Claude        → symlink to active profile's desktop/
```

Keychain items per profile:

- `Claude Code-credentials-profile-<name>` — backup of Claude Code's OAuth credential
- `Claude Safe Storage-profile-<name>` — backup of Claude Desktop's Electron Safe Storage key

When you switch:

1. The current profile's live Keychain credentials are backed up to its `*-profile-*` items.
2. The `~/.claude` and `~/Library/Application Support/Claude` symlinks are repointed.
3. The target profile's Keychain backups are restored to the live Keychain items.
4. The active profile name is written to `~/.claude-profiles/.active`.

Nothing leaves your Mac. No telemetry, no network calls.

## Security

- Profile directories are created with `chmod 700` (owner-only).
- Credentials never touch plaintext files — they live in the macOS Keychain throughout.
- Keychain backups are stored under separate service names so the OS isolates them with the same protections as the originals.
- The script has no `sudo` requirements and writes only inside `~/.claude-profiles/` and to your Keychain.

## Caveats

- **Quit Claude Desktop and all `claude` (Code) sessions before switching.** The script refuses to run if it detects Claude Desktop running.
- If you reinstall Claude Code or Desktop, the symlinks survive, but make sure no installer recreates the original directories.
- Tested on macOS 14 and 15 (Apple Silicon). Should work on Intel Macs and macOS 12+ but unverified.

## Uninstall / rollback

```sh
# Pick the profile you want to keep as your "real" Claude state
ACTIVE=$(claude-switch current)

# Remove the symlinks and move that profile's data back
rm ~/.claude
mv ~/.claude-profiles/$ACTIVE/code ~/.claude

rm "$HOME/Library/Application Support/Claude"
mv ~/.claude-profiles/$ACTIVE/desktop "$HOME/Library/Application Support/Claude"

# Remove the script and remaining profile data
rm /opt/homebrew/bin/claude-switch    # or /usr/local/bin/claude-switch
rm -rf ~/.claude-profiles

# Optionally clean up Keychain backups
security delete-generic-password -s "Claude Code-credentials-profile-<name>" 2>/dev/null
security delete-generic-password -s "Claude Safe Storage-profile-<name>" 2>/dev/null
```

## License

[MIT](LICENSE) — do whatever you want, no warranty.

## Acknowledgments


This is a community project and is not affiliated with Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic, PBC.
