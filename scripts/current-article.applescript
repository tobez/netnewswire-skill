-- ABOUTME: Return the currently selected article in the NetNewsWire UI.
-- ABOUTME: Usage: osascript current-article.applescript

tell application "NetNewsWire"
	set a to current article
	if a is missing value then return "ERROR:No article selected"

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
	set aId to id of a
	set aRead to read of a
	set aStarred to starred of a
	set aFeed to name of feed of a
	return "ID:" & aId & linefeed & ¬
		"TITLE:" & aTitle & linefeed & ¬
		"URL:" & aUrl & linefeed & ¬
		"FEED:" & aFeed & linefeed & ¬
		"DATE:" & aDate & linefeed & ¬
		"READ:" & aRead & linefeed & ¬
		"STARRED:" & aStarred & linefeed & ¬
		"SUMMARY:" & aSummary & linefeed & ¬
		"HTML:" & aHtml & linefeed & ¬
		"TEXT:" & aText
end tell
