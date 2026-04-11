-- ABOUTME: Search NetNewsWire articles by keyword in title and contents.
-- ABOUTME: Usage: osascript search-articles.applescript <query> [limit]

on run argv
	if (count of argv) < 1 then return "ERROR:query required"
	set searchTerm to item 1 of argv
	set maxResults to 20
	if (count of argv) ≥ 2 then set maxResults to (item 2 of argv) as integer

	tell application "NetNewsWire"
		set output to ""
		set matchCount to 0

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

		return output
	end tell
end run

on scanFeed(theFeed, searchTerm, matchCount, maxResults, output)
	tell application "NetNewsWire"
		repeat with a in every article of theFeed
			if matchCount ≥ maxResults then exit repeat
			set aTitle to ""
			try
				set aTitle to title of a
			end try
			set aText to ""
			try
				set aText to contents of a
			end try
			if aTitle contains searchTerm or aText contains searchTerm then
				set aId to id of a
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
			end if
		end repeat
	end tell
	return {output, matchCount}
end scanFeed
