---
name: netnewswire
description:
  Use when the user wants to browse, search, read, or manage their NetNewsWire RSS feeds on macOS — list feeds, fetch
  unread/starred articles, read full article content, mark articles read/starred, search across feeds, or subscribe to a new
  feed. Requires NetNewsWire running locally; talks to it directly via AppleScript (no MCP server needed).
---

# NetNewsWire (AppleScript)

Drive the NetNewsWire macOS app directly via `osascript`. Covers the same surface as the NetNewsWire MCP server but with zero
process/server overhead — each operation is a self-contained `.applescript` file invoked on demand.

## When to use

- User asks to summarize unread articles, star interesting items, mark things read
- User wants to search their RSS subscriptions by keyword
- User wants a feed index, a per-folder view, or to subscribe to a new feed
- Any NetNewsWire-related workflow on macOS where you don't want to install/run an MCP server

## Prerequisites

- macOS with NetNewsWire.app installed **and running** (scripts will error otherwise)
- `osascript` on `PATH` (default on macOS)

Verify NetNewsWire is running before invoking anything else:

```bash
osascript -e 'tell application "System Events" to (name of processes) contains "NetNewsWire"'
```

Returns `true`/`false`.

## Scripts

All scripts live in `scripts/` next to this file. Invoke as:

```bash
osascript scripts/<name>.applescript [args...]
```

| Script                        | Purpose                              | Args                                                              | Mutating? |
| ----------------------------- | ------------------------------------ | ----------------------------------------------------------------- | --------- |
| `list-feeds.applescript`      | List accounts, folders, feeds        | `[accountName]`                                                   | no        |
| `get-articles.applescript`    | Fetch article metadata with filters  | `[--limit=N] [--unread] [--starred] [--feed=URL] [--folder=NAME]` | no        |
| `read-article.applescript`    | Full content of one article by ID    | `<articleId>`                                                     | no        |
| `search-articles.applescript` | Keyword search across feeds          | `<query> [limit]`                                                 | no        |
| `current-article.applescript` | Article currently selected in the UI | —                                                                 | no        |
| `mark-articles.applescript`   | Set read/unread/starred state        | `<read\|unread\|starred\|unstarred> <id1> [id2 ...]`              | **yes**   |
| `subscribe.applescript`       | Add a new feed                       | `<feedUrl> [folderName]`                                          | **yes**   |

Mutating operations change user state. `mark-articles` is easily reversed (toggle back); `subscribe` adds a feed that would
require manual unsubscribe to undo.

## Output formats

Scripts return **plain text**, pipe-delimited or `KEY:value` per line. Parse by splitting on `\n` and then on `|`.

### list-feeds

```text
ACCOUNT:<name>|<active>
FEED:<name>|<url>|<homepageUrl>
FOLDER:<name>
FEED:<name>|<url>|<homepageUrl>
...
```

`FEED:` lines that appear before any `FOLDER:` line belong to the account (top level). `FEED:` lines after a `FOLDER:` line
belong to that folder until the next `FOLDER:` or `ACCOUNT:` line.

### get-articles / search-articles

```text
ARTICLE:<id>|<title>|<url>|<read>|<starred>|<date>|<feedName>|<summary>
```

`read`/`starred` are `true`/`false`. `search-articles` omits the trailing `|<summary>` field. Dates come from AppleScript
`as string` (locale-formatted, e.g. `Saturday, 23 August 2025 at 02.00.00`).

### read-article / current-article

Multi-line, newline-separated records:

```text
TITLE:...
URL:...
FEED:...
DATE:...
READ:true|false
STARRED:true|false
AUTHORS:Name, Name, ...
SUMMARY:...
HTML:...
TEXT:...
```

`HTML:` and `TEXT:` payloads may themselves span many lines. Parse by scanning for the known keys and accumulating lines in
between. `current-article` additionally starts with `ID:<articleId>`.

### mark-articles

`MARKED:<n>` on success, or `ERROR:<reason>`. The count is how many articles matched the supplied IDs.

### subscribe

`OK` on success, or `ERROR:<reason>` (e.g. folder not found).

## Recipes

**Daily unread summary:**

```bash
osascript scripts/get-articles.applescript --unread --limit=50
```

Then for each ARTICLE line, fetch full body with `read-article.applescript <id>` only for the ones worth expanding. Star the
interesting ones:

```bash
osascript scripts/mark-articles.applescript starred <id1> <id2>
osascript scripts/mark-articles.applescript read <id3> <id4> <id5>
```

**Topic research across all feeds:**

```bash
osascript scripts/search-articles.applescript "quantization" 25
```

**Add a feed to a specific folder:**

```bash
osascript scripts/subscribe.applescript https://example.com/feed.xml webdev
```

## Gotchas

- **NetNewsWire must be running.** If not, scripts fail with an AppleScript `-600` / "not running" error. Start the app first.
- **Don't use `allFeeds` in AppleScript.** `allFeeds of account` returns every feed _including those inside folders_, causing
  duplicate iteration. All scripts here use `every feed of account` (top level only) and then iterate `every folder of account`
  separately. If you modify or add scripts, do the same.
- **Article IDs** are whatever the feed provides — often a URL, sometimes a path slug, sometimes a bare GUID. Pass them through
  verbatim; don't normalize.
- **Pipe characters in titles** are extraordinarily rare but possible. If a parser needs to be bulletproof, split on the
  **first** `|` per known field rather than naive `split("|")`.
- **Locale-formatted dates.** If you need a parseable timestamp, use the article URL or `read-article` and pull it from the HTML
  — AppleScript's `date as string` is not machine-friendly.
- **Script timing:** `get-articles` iterates every article of every feed. On a large library (hundreds of feeds × thousands of
  articles) a run can take several seconds. Use `--limit` and the feed/folder filters aggressively. `search-articles`,
  `read-article`, and `mark-articles` instead filter per feed with a NetNewsWire-side `whose` clause and allow each Apple event
  up to 300 s, so on large libraries they can still take tens of seconds or more — when invoking them from the Bash tool, pass a
  timeout of at least 300000 ms.
- **`read-article` checks feeds one by one** until the ID matches (a missing ID visits every feed). For repeated lookups in a
  session, prefer a single `get-articles` call and cache the metadata.
- **`search-articles` matches case-insensitively** across title, `html`, `contents`, and `summary`, so a term appearing only in
  markup (e.g. a URL or tag attribute) can match too.
- **Batch `mark-articles` calls.** The script filters articles via a single per-feed `whose` predicate, so 50 IDs in one
  invocation cost about the same as 1; many single-ID invocations cost N× as much. ~200 IDs per call is a sane practical
  ceiling.

## Extending

To add a new operation, drop a new `.applescript` in `scripts/` following the same conventions:

1. `on run argv` parses its own arguments (use `--key=value` for flag-style, positional otherwise).
2. Use `every feed of acct` + `every folder of acct` — never `allFeeds`.
3. Return plain text: either pipe-delimited rows with a `TAG:` prefix or multi-line `KEY:value` records.
4. Errors go to stdout as `ERROR:<reason>` — the caller grep/branches on that prefix.

NetNewsWire's AppleScript dictionary (open NetNewsWire.app in Script Editor → File → Open Dictionary) is the source of truth for
available properties.

## Credits

The AppleScript logic in this skill is derived from
[`jellllly420/netnewswire-mcp`](https://github.com/jellllly420/netnewswire-mcp) (declared MIT) by Zejun Zhao. That project
exposes the same NetNewsWire surface as an MCP server; this project repackages the underlying AppleScript as a Claude skill so
no MCP server needs to run. Full credit for figuring out the NNW scripting dictionary interactions goes upstream.
