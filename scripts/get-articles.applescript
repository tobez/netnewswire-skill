-- ABOUTME: Fetch article metadata from NetNewsWire with optional filters.
-- ABOUTME: Usage: osascript get-articles.applescript [--limit=N] [--unread] [--starred] [--feed=URL] [--folder=NAME]

on run argv
	set maxArticles to 50
	set modeUnread to false
	set modeStarred to false
	set filterFeedUrl to ""
	set filterFolderName to ""

	repeat with a in argv
		set s to a as text
		if s starts with "--limit=" then
			set maxArticles to (text 9 thru -1 of s) as integer
		else if s is "--unread" then
			set modeUnread to true
		else if s is "--starred" then
			set modeStarred to true
		else if s starts with "--feed=" then
			set filterFeedUrl to text 8 thru -1 of s
		else if s starts with "--folder=" then
			set filterFolderName to text 10 thru -1 of s
		end if
	end repeat

	tell application "NetNewsWire"
		set output to ""
		set articleCount to 0

		if filterFeedUrl is not "" then
			repeat with acct in every account
				if articleCount ≥ maxArticles then exit repeat
				repeat with nthFeed in every feed of acct
					if articleCount ≥ maxArticles then exit repeat
					if url of nthFeed is filterFeedUrl then
						set {output, articleCount} to my collectArticles(nthFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
					end if
				end repeat
				repeat with fld in every folder of acct
					if articleCount ≥ maxArticles then exit repeat
					repeat with nthFeed in every feed of fld
						if articleCount ≥ maxArticles then exit repeat
						if url of nthFeed is filterFeedUrl then
							set {output, articleCount} to my collectArticles(nthFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
						end if
					end repeat
				end repeat
			end repeat
		else if filterFolderName is not "" then
			repeat with acct in every account
				if articleCount ≥ maxArticles then exit repeat
				repeat with fld in every folder of acct
					if articleCount ≥ maxArticles then exit repeat
					if name of fld is filterFolderName then
						repeat with nthFeed in every feed of fld
							if articleCount ≥ maxArticles then exit repeat
							set {output, articleCount} to my collectArticles(nthFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
						end repeat
					end if
				end repeat
			end repeat
		else
			repeat with acct in every account
				if articleCount ≥ maxArticles then exit repeat
				repeat with nthFeed in every feed of acct
					if articleCount ≥ maxArticles then exit repeat
					set {output, articleCount} to my collectArticles(nthFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
				end repeat
				repeat with fld in every folder of acct
					if articleCount ≥ maxArticles then exit repeat
					repeat with nthFeed in every feed of fld
						if articleCount ≥ maxArticles then exit repeat
						set {output, articleCount} to my collectArticles(nthFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
					end repeat
				end repeat
			end repeat
		end if

		return output
	end tell
end run

on collectArticles(theFeed, articleCount, maxArticles, modeUnread, modeStarred, output)
	tell application "NetNewsWire"
		if modeUnread then
			set matched to (get every article of theFeed whose read is false)
		else if modeStarred then
			set matched to (get every article of theFeed whose starred is true)
		else
			set matched to (get every article of theFeed)
		end if

		repeat with a in matched
			if articleCount ≥ maxArticles then exit repeat
			set aId to id of a
			set aTitle to ""
			try
				set aTitle to title of a
			end try
			set aUrl to ""
			try
				set aUrl to url of a
			end try
			set aSummary to ""
			try
				set aSummary to summary of a
			end try
			set aDate to ""
			try
				set aDate to (published date of a) as string
			end try
			set aFeed to name of feed of a
			set isRead to read of a
			set isStarred to starred of a
			set output to output & "ARTICLE:" & aId & "|" & aTitle & "|" & aUrl & "|" & isRead & "|" & isStarred & "|" & aDate & "|" & aFeed & "|" & aSummary & linefeed
			set articleCount to articleCount + 1
		end repeat
	end tell
	return {output, articleCount}
end collectArticles
