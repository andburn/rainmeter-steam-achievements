function Initialize()

	msSteam = SKIN:GetMeasure("MeasureSteamAchievements")
	mtTitle = SKIN:GetMeter("AchievementTitle")
	mtDetail = SKIN:GetMeter("AchievementDetail")
	
end -- function Initialize

function Update()

	local sHtml = ReadFile("sample.txt")

	--SKIN:Bang('!UpdateMeasure MeasureSteam')
	--sHtml = msMeasureSteam:GetStringValue()
	
	if string.len(sHtml) ~= 0 then
	
		local lineCount = 0
		local Rows = {}
		local Complete = {}
		local currentRow = 0
		local processRow = false
		
		for l in string.gmatch(sHtml, "[^\n]*") do
			-- percentages
			local cp, tt, pct = string.match(l, "(%d+) of (%d+) %((%d+)%%%)")
			if pct ~= nil then
				SKIN:Bang('!SetOption AchievementsComplete Text \"[' .. cp .. '/' .. tt .. '] ' .. pct .. '%\"')
				SKIN:Bang('!SetOption MeasureCompletion MaxValue ' .. tt)
				SKIN:Bang('!SetOption MeasureCompletion Formula ' .. cp)
			end
			
			-- play time
			-- <div id="tsblVal">10.9h</div>
			local pt = string.match(l, "<div id=\"tsblVal\">([%a%d%.]+)</div>")
			if pt ~= nil then
				SKIN:Bang('!SetOption TimePlayed Text \"' .. pt .. '\"')
			end
			
			-- achievements			
			local ac = string.match(l, "<div class=\"achieveRow\">")			
			if ac ~= nil then
				table.insert(Rows, {
					Image       = nil,
					Date        = nil,
					Title       = nil,
					Description = nil
					}
				)
				currentRow = currentRow + 1
				processRow = true
			end
			
			if processRow then
				local img = string.match(l, "<img src=\"(.-)\">")
				if img ~= nil then
					Rows[currentRow].Image = img
				end
				local d, m, y, hrs, mins, ampm = string.match(l, "Unlocked (%d+) (%a+), (%d+) @ (%d+):(%d+)(%a+)")
				if ampm ~= nil then
					Rows[currentRow].Date = ConvertDate(d, m, y, hrs, mins, ampm)
				end
				d, m, hrs, mins, ampm = string.match(l, "Unlocked (%d+) (%a+) @ (%d+):(%d+)(%a+)")
				if ampm ~= nil then
					local tm = os.time()
					Rows[currentRow].Date = ConvertDate(d, m, os.date("%Y",tm), hrs, mins, ampm)
				end
				local title = string.match(l, "<h3 class=\"ellipsis\">(.-)</h3>")
				if title ~= nil then
					Rows[currentRow].Title = title
				end
				local descrp = string.match(l, "<h5>(.-)</h5>")
				if descrp ~= nil then
					Rows[currentRow].Description = descrp
					-- last item needed in a row, don't process anymore
					processRow = false
				end
			end
			lineCount = lineCount + 1
		end
		
		-- sort rows by date
		table.sort(Rows, SortByDate)

		-- for idx,val in ipairs(Rows) do
			-- if val.Title ~= nil then print(val.Title) end
			-- if val.Description ~= nil then print(val.Description) end			
			-- if val.Image ~= nil then print(val.Image) end
			-- if val.Date ~= nil then print(val.Date) end
		-- end			
		
		local dateString = os.date("%d %b %Y", Rows[1].Date)
		
		SKIN:Bang('!SetOption AchievementTitle Text \"' .. Rows[1].Title .. '\"')
		SKIN:Bang('!SetOption AchievementDetail Text \"' .. Rows[1].Description .. '\"')
		SKIN:Bang('!SetOption AchievementDate Text \"' .. dateString .. '\"')
		
		print(Rows[1].Image)
		SKIN:Bang('!SetOption MeasureSteamImage URL \"' .. Rows[1].Image .. '\"')
		SKIN:Bang('!UpdateMeasure MeasureSteamImage')
	end	
	
end -- function Update


function SortByDate(a, b)
	if a.Date == nil then
		return false
	end
	if b.Date == nil then
		return true
	end
	return a.Date >= b.Date
end

function ConvertDate(d, m, y, hrs, mins, ampm)
	--print(d .. ", " .. m .. ", " .. y .. ", " .. hrs .. ", " .. mins .. ", " .. ampm)
	local months = {
		jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6,
		jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12
	}
	local mnum = months[string.lower(m)]
	local hrs24 = hrs
	if string.lower(ampm) == "pm" then
		hrs24 = (hrs + 12) % 24
	end
	return os.time({ year=y, day=d, month=mnum, hour=hrs24, min=mins })
end

function ReadFile(FilePath)
	-- HANDLE RELATIVE PATH OPTIONS.
	FilePath = SKIN:MakePathAbsolute(FilePath)
	print(FilePath)
	-- OPEN FILE.
	local File = io.open(FilePath)

	-- HANDLE ERROR OPENING FILE.
	if not File then
		print('ReadFile: unable to open file at ' .. FilePath)
		return
	end

	-- READ FILE CONTENTS AND CLOSE.
	local Contents = File:read('*all')
	File:close()

	return Contents
end

function WriteFile(FilePath, Contents)
	-- HANDLE RELATIVE PATH OPTIONS.
	FilePath = SKIN:MakePathAbsolute(FilePath)

	-- OPEN FILE.
	local File = io.open(FilePath, 'w')

	-- HANDLE ERROR OPENING FILE.
	if not File then
		print('WriteFile: unable to open file at ' .. FilePath)
		return
	end

	-- WRITE CONTENTS AND CLOSE FILE
	File:write(Contents)
	File:close()

	return true
end