-- ABOUTME: Mark NetNewsWire articles read/unread/starred/unstarred via id-filtered whose clause.
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
		set propValue to "true"
	else
		set propValue to "false"
	end if

	set totalIds to count of idList

	-- Build "id is \"X\" or id is \"Y\" or ..." predicate. NetNewsWire's
	-- scripting layer does not implement the `is in {...}` membership
	-- operator for `id` (silently returns no matches), so an explicit
	-- `or` chain is required.
	set predicate to ""
	repeat with i from 1 to totalIds
		set escapedId to my escapeForApplescript(item i of idList as text)
		if i is 1 then
			set predicate to "id is \"" & escapedId & "\""
		else
			set predicate to predicate & " or id is \"" & escapedId & "\""
		end if
	end repeat

	-- The whose clause is evaluated by NetNewsWire in one Apple Event per
	-- feed instead of one per article, which collapses N+1 IPC down to one
	-- per feed. Early-exit at both the account and feed level once every
	-- requested ID has matched. The outer `with timeout of 300 seconds`
	-- keeps individual Apple Events from defaulting to -1712 on huge
	-- libraries. Per-feed try/on error swallows transient single-feed
	-- glitches but re-raises the systemic codes the caller actually needs
	-- to see (-128 user cancelled, -600 app not running, -609 connection
	-- invalid, -1712 outer timeout exceeded, -1743 automation not
	-- authorized) instead of returning a misleading MARKED:0.
	set scriptText to "tell application \"NetNewsWire\"
	set matchCount to 0
	set totalIds to " & totalIds & "
	with timeout of 300 seconds
		repeat with acct in every account
			if matchCount ≥ totalIds then exit repeat
			repeat with nthFeed in every feed of acct
				if matchCount ≥ totalIds then exit repeat
				try
					set matched to (every article of nthFeed whose (" & predicate & "))
					repeat with a in matched
						set " & propName & " of a to " & propValue & "
						set matchCount to matchCount + 1
					end repeat
				on error errMsg number errNum
					if errNum is -128 or errNum is -600 or errNum is -609 or errNum is -1712 or errNum is -1743 then
						error errMsg number errNum
					end if
				end try
			end repeat
			repeat with fld in every folder of acct
				if matchCount ≥ totalIds then exit repeat
				repeat with nthFeed in every feed of fld
					if matchCount ≥ totalIds then exit repeat
					try
						set matched to (every article of nthFeed whose (" & predicate & "))
						repeat with a in matched
							set " & propName & " of a to " & propValue & "
							set matchCount to matchCount + 1
						end repeat
					on error errMsg number errNum
						if errNum is -128 or errNum is -600 or errNum is -609 or errNum is -1712 or errNum is -1743 then
							error errMsg number errNum
						end if
					end try
				end repeat
			end repeat
		end repeat
	end timeout
	return \"MARKED:\" & matchCount
end tell"

	return run script scriptText
end run

on escapeForApplescript(s)
	set s to my replaceText(s, "\\", "\\\\")
	set s to my replaceText(s, "\"", "\\\"")
	return s
end escapeForApplescript

on replaceText(theText, searchString, replacementString)
	set savedDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to searchString
	set theItems to text items of theText
	set AppleScript's text item delimiters to replacementString
	set newText to theItems as text
	set AppleScript's text item delimiters to savedDelims
	return newText
end replaceText
