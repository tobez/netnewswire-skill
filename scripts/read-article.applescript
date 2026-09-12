-- ABOUTME: Return the full content of a single NetNewsWire article by its ID.
-- ABOUTME: Usage: osascript read-article.applescript <articleId>

on run argv
	if (count of argv) < 1 then
		return "ERROR:articleId required"
	end if
	set targetId to item 1 of argv

	tell application "NetNewsWire"
		with timeout of 300 seconds
			repeat with acct in every account
				repeat with nthFeed in every feed of acct
					set found to my findInFeed(nthFeed, targetId)
					if found is not missing value then return found
				end repeat
				repeat with fld in every folder of acct
					repeat with nthFeed in every feed of fld
						set found to my findInFeed(nthFeed, targetId)
						if found is not missing value then return found
					end repeat
				end repeat
			end repeat
		end timeout
		return "ERROR:Article not found"
	end tell
end run

on findInFeed(theFeed, targetId)
	tell application "NetNewsWire"
		with timeout of 300 seconds
			try
				set matched to (every article of theFeed whose (id is targetId))
				if (count of matched) > 0 then
					return my formatArticle(item 1 of matched)
				end if
			on error errMsg number errNum
				-- Re-raise systemic errors so the caller sees them instead of a
				-- misleading "Article not found". Per-feed transient errors are
				-- still swallowed so one bad feed doesn't abort the whole lookup.
				-- Codes:
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
	return missing value
end findInFeed

on formatArticle(a)
	tell application "NetNewsWire"
		set aTitle to ""
		try
			set aTitle to title of a
		end try
		set aUrl to ""
		try
			set aUrl to url of a
		end try
		set aHtml to ""
		try
			set aHtml to html of a
		end try
		set aText to ""
		try
			set aText to contents of a
		end try
		set aSummary to ""
		try
			set aSummary to summary of a
		end try
		set aDate to ""
		try
			set aDate to (published date of a) as string
		end try
		set aRead to read of a
		set aStarred to starred of a
		set aFeed to name of feed of a
		set aAuthors to ""
		try
			repeat with auth in every author of a
				set aAuthors to aAuthors & (name of auth) & ", "
			end repeat
		end try
		return "TITLE:" & aTitle & linefeed & ¬
			"URL:" & aUrl & linefeed & ¬
			"FEED:" & aFeed & linefeed & ¬
			"DATE:" & aDate & linefeed & ¬
			"READ:" & aRead & linefeed & ¬
			"STARRED:" & aStarred & linefeed & ¬
			"AUTHORS:" & aAuthors & linefeed & ¬
			"SUMMARY:" & aSummary & linefeed & ¬
			"HTML:" & aHtml & linefeed & ¬
			"TEXT:" & aText
	end tell
end formatArticle
