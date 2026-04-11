-- ABOUTME: Return the full content of a single NetNewsWire article by its ID.
-- ABOUTME: Usage: osascript read-article.applescript <articleId>

on run argv
	if (count of argv) < 1 then
		return "ERROR:articleId required"
	end if
	set targetId to item 1 of argv

	tell application "NetNewsWire"
		repeat with acct in every account
			repeat with nthFeed in every feed of acct
				repeat with a in every article of nthFeed
					if (id of a) is targetId then return my formatArticle(a)
				end repeat
			end repeat
			repeat with fld in every folder of acct
				repeat with nthFeed in every feed of fld
					repeat with a in every article of nthFeed
						if (id of a) is targetId then return my formatArticle(a)
					end repeat
				end repeat
			end repeat
		end repeat
		return "ERROR:Article not found"
	end tell
end run

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
