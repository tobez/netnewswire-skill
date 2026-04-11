-- ABOUTME: List NetNewsWire accounts, folders, and feeds.
-- ABOUTME: Usage: osascript list-feeds.applescript [accountName]

on run argv
	set acctFilter to ""
	if (count of argv) ≥ 1 then set acctFilter to item 1 of argv

	tell application "NetNewsWire"
		set output to ""
		if acctFilter is "" then
			set acctList to every account
		else
			set acctList to every account whose name is acctFilter
		end if

		repeat with acct in acctList
			set acctName to name of acct
			set acctActive to active of acct
			set output to output & "ACCOUNT:" & acctName & "|" & acctActive & linefeed

			repeat with f in every feed of acct
				set fName to name of f
				set fUrl to url of f
				set fHome to ""
				try
					set fHome to homepage url of f
				end try
				set output to output & "FEED:" & fName & "|" & fUrl & "|" & fHome & linefeed
			end repeat

			repeat with fld in every folder of acct
				set fldName to name of fld
				set output to output & "FOLDER:" & fldName & linefeed
				repeat with f in every feed of fld
					set fName to name of f
					set fUrl to url of f
					set fHome to ""
					try
						set fHome to homepage url of f
					end try
					set output to output & "FEED:" & fName & "|" & fUrl & "|" & fHome & linefeed
				end repeat
			end repeat
		end repeat
		return output
	end tell
end run
