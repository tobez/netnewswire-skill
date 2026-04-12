# netnewswire-skill

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that drives [NetNewsWire](https://netnewswire.com/) on
macOS via AppleScript. Browse, search, read, and manage your RSS feeds without leaving the terminal — no MCP server needed.

## What it does

Seven self-contained `.applescript` files cover the core NetNewsWire operations:

- **list-feeds** — accounts, folders, and subscriptions
- **get-articles** — article metadata with `--unread`, `--starred`, `--feed=URL`, `--folder=NAME`, `--limit=N` filters
- **read-article** — full content (HTML + text) of a single article by ID
- **search-articles** — keyword search across all feeds
- **current-article** — whatever is selected in the NNW UI right now
- **mark-articles** — set read/unread/starred/unstarred state
- **subscribe** — add a new feed, optionally into a folder

## Requirements

- macOS with NetNewsWire.app installed and **running**
- `osascript` on PATH (default on macOS)

## Installation

Clone (or symlink) this directory somewhere Claude Code can find it, then register it as a skill source in your Claude Code
settings. See [Claude Code custom skills](https://docs.anthropic.com/en/docs/claude-code/skills) for details.

## Usage

Once installed, just ask Claude about your feeds:

> "Summarize my unread articles"
>
> "Search my feeds for articles about quantization"
>
> "Star the interesting ones and mark the rest as read"

Claude invokes the AppleScript files automatically — you don't need to run them yourself.

If you want to run scripts directly:

```bash
osascript scripts/list-feeds.applescript
osascript scripts/get-articles.applescript --unread --limit=20
osascript scripts/search-articles.applescript "quantization" 25
osascript scripts/mark-articles.applescript starred <articleId>
```

See [SKILL.md](SKILL.md) for full output format documentation, recipes, and gotchas.

## Credits

The AppleScript logic is derived from [jellllly420/netnewswire-mcp](https://github.com/jellllly420/netnewswire-mcp) (declared
MIT) by Zejun Zhao. That project exposes NetNewsWire as an MCP server; this project repackages the underlying AppleScript as a
Claude Code skill. Full credit for working out the NNW scripting dictionary interactions goes upstream.
