return function(FileBrowser)
	-- Enums
	-- These are internal really, so i don't think these need to be exposed?
	local NODETYPE_FOLDER = 1
	local NODETYPE_FILE = 2
	-- I may implement more of these later, just defining them now
	local VIEWTYPE_TREE = 0
	local VIEWTYPE_LIST = 1
	local VIEWTYPE_TILES = 2

	local SORTTYPE_NAME = 0
	local SORTTYPE_TIME = 1
	local SORTTYPE_SIZE = 2

	local UserInterfaceTimeFunc = RealTime

	local function GetNodeBounds(Settings, ScrollOffset, AbsIndex, Width, Depth)
		return
				Depth * Settings.NodeDepthWidth,
				(Settings.TallOfOneNode * (AbsIndex - 1)) - ScrollOffset,
				Width - (Depth * Settings.NodeDepthWidth),
				Settings.NodeTall
	end

	-- X is the node's X from GetNodeBounds, which already has the depth in it
	local function GetExpanderBounds(Settings, X, Y, W, H, Padding)
		Padding = Padding or 0
		local Size = Settings.ExpanderSize + Padding

		return math.floor(X + Settings.ExpanderXOffset - (Padding / 2)), math.floor(Y + (H / 2) - (Size / 2)) + 1, Size, Size
	end

	local function GetIconBounds(Settings, X, Y, W, H, Padding)
		local Size = Settings.IconSize + (Padding or 0)

		return math.floor(X + Settings.IconXOffset), math.floor(Y + (H / 2) - (Size / 2)), Size, Size
	end

	local function GetTextPosition(Settings, X, Y, W, H)
		return math.floor(X + Settings.TextXOffset), math.floor(Y + (H / 2))
	end

	local ListTimeWidth, ListSizeWidth = 116, 72
	local ListHeaderTall, NavBarTall = 20, 24

	local function GetListColumns(Width)
		local SizeRight = Width - 6
		local TimeRight = SizeRight - ListSizeWidth
		local NameRight = TimeRight - ListTimeWidth
		return NameRight, TimeRight, SizeRight
	end

	local function GetListTextX(Settings)
		return Settings.LeftmostToExpanderPadding + Settings.IconSize + Settings.IconToTextPadding
	end

	local TruncatedText, TruncatedCount = {}, 0
	local function TruncateText(Text, Font, MaxWidth)
		local Key = Font .. "\0" .. math.floor(MaxWidth) .. "\0" .. Text
		local Cached = TruncatedText[Key]
		if Cached then return Cached end

		surface.SetFont(Font)
		local Result = Text
		if surface.GetTextSize(Text) > MaxWidth then
			local Starts = {}
			for Position in string.gmatch(Text, "()" .. utf8.charpattern) do
				Starts[#Starts + 1] = Position
			end

			Result = "..."
			for Count = #Starts - 1, 1, -1 do
				local Candidate = string.sub(Text, 1, Starts[Count + 1] - 1) .. "..."
				if surface.GetTextSize(Candidate) <= MaxWidth then
					Result = Candidate
					break
				end
			end
		end

		if TruncatedCount > 4096 then
			TruncatedText, TruncatedCount = {}, 0
		end
		TruncatedText[Key] = Result
		TruncatedCount = TruncatedCount + 1
		return Result
	end

	-- Defines GetNumericalFilename
	-- Turns a filename into a list of numbers that can be compared element by element.
	-- This handles things very similarly to how Windows does in terms of sorting (digit runs compare as numbers,
	-- letters are case-insensitive), but also sorts month names by their month number.
	local GetNumericalFilename
	do
		local Digits = {}
		for I = 0, 9 do Digits[tostring(I)] = I end

		-- Lowercased byte per character; underscore sorts after everything else
		local CharToByte = {}
		for I = 1, 255 do CharToByte[string.char(I)] = string.byte(string.lower(string.char(I))) end
		CharToByte["_"] = 2000

		local MonthNames = {"january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"}
		local MonthSeparators = {[""] = true, [" "] = true, ["_"] = true, ["-"] = true}

		-- Numbers at the very start of a name sort before everything else
		local LeadingNumberOffset = 100000000
		local MaxCached = 8192

		-- A month only counts as a whole word: it must start the name or follow a separator, and end the name or precede one
		local function MatchMonth(Lower, Position)
			if not MonthSeparators[string.sub(Lower, Position - 1, Position - 1)] then return end

			for Month = 1, #MonthNames do
				local MonthName = MonthNames[Month]
				local EndPosition = Position + #MonthName - 1

				if string.sub(Lower, Position, EndPosition) == MonthName and MonthSeparators[string.sub(Lower, EndPosition + 1, EndPosition + 1)] then
					return Month, #MonthName
				end
			end
		end

		local NumericalStore, NumericalCount = {}, 0
		function GetNumericalFilename(Name)
			local Cached = NumericalStore[Name]
			if Cached then return Cached end

			local Lower = string.lower(Name)
			local Length = #Lower
			local Result, Count = {}, 0
			local Position = 1

			while Position <= Length do
				local Char = string.sub(Lower, Position, Position)
				local Digit = Digits[Char]

				if Digit then
					local Value = 0

					while Digit do
						Value = (Value * 10) + Digit
						Position = Position + 1
						Digit = Digits[string.sub(Lower, Position, Position)]
					end

					if Count == 0 then Value = Value - LeadingNumberOffset end
					Count = Count + 1
					Result[Count] = Value
				else
					local Month, MonthLength = MatchMonth(Lower, Position)

					if Month then
						Count = Count + 1
						Result[Count] = Month
						Position = Position + MonthLength
					else
						Count = Count + 1
						Result[Count] = CharToByte[Char]
						Position = Position + 1
					end
				end
			end

			-- Cache so this doesn't have to be calculated multiple times, but don't let it grow forever
			if NumericalCount >= MaxCached then
				NumericalStore, NumericalCount = {}, 0
			end
			NumericalStore[Name] = Result
			NumericalCount = NumericalCount + 1

			return Result
		end
	end

	FileBrowser.NODETYPE_FOLDER = NODETYPE_FOLDER
	FileBrowser.NODETYPE_FILE = NODETYPE_FILE
	FileBrowser.VIEWTYPE_TREE = VIEWTYPE_TREE
	FileBrowser.VIEWTYPE_LIST = VIEWTYPE_LIST
	FileBrowser.VIEWTYPE_TILES = VIEWTYPE_TILES
	FileBrowser.SORTTYPE_NAME = SORTTYPE_NAME
	FileBrowser.SORTTYPE_TIME = SORTTYPE_TIME
	FileBrowser.SORTTYPE_SIZE = SORTTYPE_SIZE
	FileBrowser.UserInterfaceTimeFunc = UserInterfaceTimeFunc
	FileBrowser.GetNodeBounds = GetNodeBounds
	FileBrowser.GetExpanderBounds = GetExpanderBounds
	FileBrowser.GetIconBounds = GetIconBounds
	FileBrowser.GetTextPosition = GetTextPosition
	FileBrowser.ListTimeWidth = ListTimeWidth
	FileBrowser.ListSizeWidth = ListSizeWidth
	FileBrowser.ListHeaderTall = ListHeaderTall
	FileBrowser.NavBarTall = NavBarTall
	FileBrowser.GetListColumns = GetListColumns
	FileBrowser.GetListTextX = GetListTextX
	FileBrowser.TruncateText = TruncateText
	FileBrowser.GetNumericalFilename = GetNumericalFilename
end
