-- ABOUTME: Search NetNewsWire articles by keyword in title and body content.
-- ABOUTME: Usage: osascript search-articles.applescript <query> [limit]

on run argv
	if (count of argv) < 1 then return "ERROR:query required"
	set searchTerm to item 1 of argv
	set maxResults to 20
	if (count of argv) ≥ 2 then set maxResults to (item 2 of argv) as integer

	tell application "NetNewsWire"
		set output to ""
		set matchCount to 0

		with timeout of 300 seconds
			repeat with acct in every account
				if matchCount ≥ maxResults then exit repeat

				repeat with nthFeed in every feed of acct
					if matchCount ≥ maxResults then exit repeat
					set {output, matchCount} to my scanFeed(nthFeed, searchTerm, matchCount, maxResults, output)
				end repeat

				repeat with fld in every folder of acct
					if matchCount ≥ maxResults then exit repeat
					repeat with nthFeed in every feed of fld
						if matchCount ≥ maxResults then exit repeat
						set {output, matchCount} to my scanFeed(nthFeed, searchTerm, matchCount, maxResults, output)
					end repeat
				end repeat
			end repeat
		end timeout

		return output
	end tell
end run

on scanFeed(theFeed, searchTerm, matchCount, maxResults, output)
	tell application "NetNewsWire"
		with timeout of 300 seconds
			try
				-- NetNewsWire's RSS parser always puts the body in `html`; some
				-- Atom feeds populate `contents` and/or `summary` instead. OR all
				-- four so both feed formats match, mirroring NetNewsWire's own
				-- search over contentHTML/contentText/summary.
				set matched to (every article of theFeed whose (title contains searchTerm or html contains searchTerm or contents contains searchTerm or summary contains searchTerm))
				repeat with a in matched
					if matchCount ≥ maxResults then exit repeat
					set aId to id of a
					set aTitle to ""
					try
						set aTitle to title of a
					end try
					set aUrl to ""
					try
						set aUrl to url of a
					end try
					set aDate to ""
					try
						set aDate to (published date of a) as string
					end try
					set aFeed to name of feed of a
					set isRead to read of a
					set isStarred to starred of a
					set output to output & "ARTICLE:" & aId & "|" & aTitle & "|" & aUrl & "|" & isRead & "|" & isStarred & "|" & aDate & "|" & aFeed & linefeed
					set matchCount to matchCount + 1
				end repeat
			on error errMsg number errNum
				-- Re-raise systemic errors so the caller sees them instead of a
				-- truncated result. Per-feed transient errors are still swallowed
				-- so one bad feed doesn't kill an otherwise-working search. Codes:
				--   -128  user cancelled
				--   -600  application not running
				--   -609  connection invalid
				--   -1712 Apple Event timed out (despite the outer 300s wrapper)
				--   -1743 not authorized (automation permission denied)
				if errNum is -128 or errNum is -600 or errNum is -609 or errNum is -1712 or errNum is -1743 then
					error errMsg number errNum
				end if
			end try
		end timeout
	end tell
	return {output, matchCount}
end scanFeed
