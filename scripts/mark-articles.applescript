-- ABOUTME: Mark one or more NetNewsWire articles as read/unread/starred/unstarred.
-- ABOUTME: Usage: osascript mark-articles.applescript <read|unread|starred|unstarred> <id1> [id2 ...]

on run argv
	if (count of argv) < 2 then return "ERROR:usage: <action> <id1> [id2 ...]"
	set action to item 1 of argv
	set idList to items 2 thru -1 of argv

	if action is "read" or action is "unread" then
		set propName to "read"
	else if action is "starred" or action is "unstarred" then
		set propName to "starred"
	else
		return "ERROR:invalid action: " & action
	end if

	if action is "read" or action is "starred" then
		set propValue to true
	else
		set propValue to false
	end if

	tell application "NetNewsWire"
		set matchCount to 0
		repeat with acct in every account
			repeat with nthFeed in every feed of acct
				repeat with a in every article of nthFeed
					set aId to id of a
					if my idIsInList(aId, idList) then
						if propName is "read" then
							set read of a to propValue
						else
							set starred of a to propValue
						end if
						set matchCount to matchCount + 1
					end if
				end repeat
			end repeat
			repeat with fld in every folder of acct
				repeat with nthFeed in every feed of fld
					repeat with a in every article of nthFeed
						set aId to id of a
						if my idIsInList(aId, idList) then
							if propName is "read" then
								set read of a to propValue
							else
								set starred of a to propValue
							end if
							set matchCount to matchCount + 1
						end if
					end repeat
				end repeat
			end repeat
		end repeat
		return "MARKED:" & matchCount
	end tell
end run

on idIsInList(anId, idList)
	repeat with candidate in idList
		if (candidate as text) is anId then return true
	end repeat
	return false
end idIsInList
