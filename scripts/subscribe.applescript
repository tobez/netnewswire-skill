-- ABOUTME: Subscribe NetNewsWire to a new RSS/Atom feed URL.
-- ABOUTME: Usage: osascript subscribe.applescript <feedUrl> [folderName]

on run argv
	if (count of argv) < 1 then return "ERROR:feedUrl required"
	set feedUrl to item 1 of argv
	set folderName to ""
	if (count of argv) ≥ 2 then set folderName to item 2 of argv

	tell application "NetNewsWire"
		if folderName is "" then
			make new feed at first account with properties {url:feedUrl}
			return "OK"
		else
			repeat with acct in every account
				repeat with fld in every folder of acct
					if name of fld is folderName then
						make new feed at fld with properties {url:feedUrl}
						return "OK"
					end if
				end repeat
			end repeat
			return "ERROR:Folder not found: " & folderName
		end if
	end tell
end run
