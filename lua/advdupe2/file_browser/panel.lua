return function(FileBrowser)
	local VIEWTYPE_TREE  = FileBrowser.VIEWTYPE_TREE
	local VIEWTYPE_LIST  = FileBrowser.VIEWTYPE_LIST
	local VIEWTYPE_TILES = FileBrowser.VIEWTYPE_TILES
	local SORTTYPE_NAME  = FileBrowser.SORTTYPE_NAME
	local SORTTYPE_TIME  = FileBrowser.SORTTYPE_TIME
	local SORTTYPE_SIZE  = FileBrowser.SORTTYPE_SIZE
	local ListHeaderTall = FileBrowser.ListHeaderTall
	local NavBarTall     = FileBrowser.NavBarTall
	local GetListColumns = FileBrowser.GetListColumns
	local GetListTextX   = FileBrowser.GetListTextX
	local GetSkinTextColor = FileBrowser.GetSkinTextColor
	local DrawSkinPanel    = FileBrowser.DrawSkinPanel
	local DrawSkinState    = FileBrowser.DrawSkinState
	local GetStateTextColor = FileBrowser.GetStateTextColor

	local PANEL = {}
	Derma_Hook(PANEL, "PerformLayout", "Layout", "Panel")

	function PANEL:Paint(w, h)
		DrawSkinPanel(self:GetSkin(), "Panel", 0, 0, w, h)
	end

	function PANEL:PerformLayout(w, h)
		if not self.Browser then return end

		local ViewType = self.Browser:GetViewType()
		local Top      = 24

		local ShowNavBar = ViewType ~= VIEWTYPE_TREE
		self.NavBar:SetVisible(ShowNavBar)
		if ShowNavBar then
			self.NavBar:SetPos(0, Top)
			self.NavBar:SetSize(w, NavBarTall)
			Top = Top + NavBarTall
		end

		local ShowHeader = ViewType == VIEWTYPE_LIST
		self.ListHeader:SetVisible(ShowHeader)
		if ShowHeader then
			self.ListHeader:SetPos(0, Top)
			self.ListHeader:SetSize(w, ListHeaderTall)
			Top = Top + ListHeaderTall
		end

		self.Browser:SetPos(0, Top)
		self.Browser:SetSize(w, math.max(h - Top, 0))

		local BtnX
		local BtnPad = 6
		if self.LeftsideButtons then
			BtnX = BtnPad
			for _, Button in ipairs(self.LeftsideButtons) do
				Button:SetPos(BtnX, 4 + (Button.OffsetY or 0))
				BtnX = BtnX + Button:GetWide() + BtnPad
			end
		end

		if self.RightsideButtons then
			BtnX = w
			for _, Button in ipairs(self.RightsideButtons) do
				BtnX = BtnX - Button:GetWide() - BtnPad
				Button:SetPos(BtnX, 4 + (Button.OffsetY or 0))
			end
		end
	end

	local function UpdateClientFiles(Browser)
		local Tree     = Browser.TreeView
		local OpenPath = Tree.CurrentFolder ~= Tree and Tree.CurrentFolder.Path or nil

		Browser:EndSearch()
		Tree:Clear()
		Tree:Expand()

		for _, RootFolder in ipairs(Browser.Settings.RootFolders) do
			Browser:AddRootFolder(RootFolder)
		end

		Browser:ResetNavigation(OpenPath and Browser:FindFolderByPath(OpenPath))
	end

	function PANEL:AddLeftsideDivider()
		self.LeftsideButtons = self.LeftsideButtons or {}

		local Panel = self:Add "DPanel"
		Panel:SetSize(2, 16)
		Panel.Paint = function(Divider, w, h) surface.SetDrawColor(GetSkinTextColor(Divider:GetSkin(), 50)) surface.DrawRect(0, 0, w, h) end

		self.LeftsideButtons[#self.LeftsideButtons + 1] = Panel
	end

	function PANEL:AddRightsideDivider()
		self.RightsideButtons = self.RightsideButtons or {}

		local Panel = self:Add "DPanel"
		Panel:SetSize(2, 16)
		Panel.Paint = function(Divider, w, h) surface.SetDrawColor(GetSkinTextColor(Divider:GetSkin(), 50)) surface.DrawRect(0, 0, w, h) end

		self.RightsideButtons[#self.RightsideButtons + 1] = Panel
	end

	function PANEL:AddLeftsideButton(Icon, Tooltip, Action, Index)
		self.LeftsideButtons = self.LeftsideButtons or {}

		local Button = self:Add "DImageButton"
		Button:SetMaterial("icon16/" .. Icon .. ".png")
		Button:SizeToContents()
		Button:SetTooltip(Tooltip)
		Button:SetTooltipDelay(0)
		Button.DoClick = Action

		table.insert(self.LeftsideButtons, Index or #self.LeftsideButtons + 1, Button)
		self:InvalidateLayout()

		return Button
	end

	function PANEL:AddRightsideButton(Icon, Tooltip, Action, Index)
		self.RightsideButtons = self.RightsideButtons or {}

		local Button = self:Add "DImageButton"
		Button:SetMaterial("icon16/" .. Icon .. ".png")
		Button:SizeToContents()
		Button:SetTooltip(Tooltip)
		Button:SetTooltipDelay(0)
		Button.DoClick = Action

		table.insert(self.RightsideButtons, Index or #self.RightsideButtons + 1, Button)
		self:InvalidateLayout()

		return Button
	end

	local COLOR_SELECTED = color_white
	local COLOR_UNSELECTED = Color(143, 143, 143, 143)

	local ICON_SORT_UP   = Material("icon16/bullet_arrow_up.png")
	local ICON_SORT_DOWN = Material("icon16/bullet_arrow_down.png")

	function PANEL:CreateNavBar()
		local Settings = self.Settings
		local Browser = self.Browser
		local Tree    = Browser.TreeView

		local Bar = self:Add("Panel")
		self.NavBar = Bar

		local function AddNavButton(Icon, Tooltip, Action, IsEnabled)
			local Button = Bar:Add("DImageButton")
			Button:SetImage("icon16/" .. Icon .. ".png")
			Button:SetStretchToFit(false)
			Button:SetSize(20, 20)
			Button:SetTooltip(Tooltip)
			Button:SetTooltipDelay(0)
			Button.DoClick = Action
			Button.Think = function(b) b.m_Image:SetImageColor(IsEnabled() and COLOR_SELECTED or COLOR_UNSELECTED) end
			return Button
		end

		Bar.Buttons = {
			AddNavButton("arrow_left",  "Back",    function() Browser:NavigateBack()    end, function() return Browser:CanNavigateBack()    end),
			AddNavButton("arrow_right", "Forward", function() Browser:NavigateForward() end, function() return Browser:CanNavigateForward() end),
			AddNavButton("arrow_up",    "Up",      function() Browser:NavigateUp()      end, function() return Browser:CanNavigateUp()      end),
		}

		local Path = Bar:Add("Panel")
		Bar.Path   = Path
		Path.Items = {}

		function Path:Paint(w, h)
			local Skin = self:GetSkin()
			DrawSkinPanel(Skin, "Normal", 0, 0, w, h)

			local TextColor = GetStateTextColor(Skin, "Normal")
			for _, Item in ipairs(self.Items) do
				if Item.ClassName == "DLabel" and not Item:IsHovered() then Item:SetTextColor(TextColor) end
			end
			if not self.Ellipsis:IsHovered() then self.Ellipsis:SetTextColor(TextColor) end
		end

		local function PaintSegment(Segment, w, h)
			if Segment:IsHovered() then
				local TextColor = DrawSkinState(Segment:GetSkin(), "Hovered", 0, 0, w, h)
				if Segment.ClassName == "DLabel" then Segment:SetTextColor(TextColor) end
			end
		end

		local function AddLabel(Text)
			local Label = Path:Add("DLabel")
			Label:SetFont(Settings.NodeFont)
			Label:SetText(Text)
			Label:SetDark(true)
			Label:SetContentAlignment(5)
			Label:SizeToContentsX(12)
			return Label
		end

		Path.Ellipsis = AddLabel("...")
		Path.Ellipsis:SetMouseInputEnabled(true)
		Path.Ellipsis:SetTooltip("Hidden folders")
		Path.Ellipsis:SetTooltipDelay(0)
		Path.Ellipsis.Paint = PaintSegment
		Path.Ellipsis.DoClick = function()
			local Menu = DermaMenu()
			for _, Node in ipairs(Path.Hidden or {}) do
				Menu:AddOption(Node.Text or "", function() Browser:NavigateTo(Node) end):SetIcon("icon16/folder.png")
			end
			Menu:Open()
		end

		local function AddSegment(Node)
			local Segment
			if Node == Tree then
				Segment = Path:Add("DImageButton")
				Segment:SetImage("icon16/house.png")
				Segment:SetStretchToFit(false)
				Segment:SetWide(24)
				Segment:SetTooltip("All folders")
				Segment:SetTooltipDelay(0)
			else
				Segment = AddLabel(Node.Text or "")
				Segment:SetMouseInputEnabled(true)
			end

			Segment.Node    = Node
			Segment.Paint   = PaintSegment
			Segment.DoClick = function() Browser:NavigateTo(Node) end
			Path.Items[#Path.Items + 1] = Segment
		end

		function Path:Rebuild(Current)
			for _, Item in ipairs(self.Items) do Item:Remove() end
			table.Empty(self.Items)

			local Chain = {}
			local Node  = Current
			while Node and Node ~= Tree do
				table.insert(Chain, 1, Node)
				Node = Node.ParentNode
			end

			AddSegment(Tree)
			for _, Folder in ipairs(Chain) do
				Path.Items[#Path.Items + 1] = AddLabel(">")
				AddSegment(Folder)
			end

			self.CurrentFolder = Current
			self:InvalidateLayout()
		end

		function Path:Think()
			if self.CurrentFolder ~= Tree.CurrentFolder then
				self:Rebuild(Tree.CurrentFolder)
			end
		end

		function Path:PerformLayout(w, h)
			local Items = self.Items
			if #Items == 0 then return end

			local Total = 0
			for _, Item in ipairs(Items) do Total = Total + Item:GetWide() end

			local First = 2
			if Total > w then
				local Used = Items[1]:GetWide() + self.Ellipsis:GetWide()
				First = #Items + 1
				while First > 2 and Used + Items[First - 1]:GetWide() <= w do
					First = First - 1
					Used  = Used + Items[First]:GetWide()
				end
			end

			local X = 0
			local function Place(Item)
				Item:SetVisible(true)
				Item:SetPos(X, 0)
				Item:SetTall(h)
				X = X + Item:GetWide()
			end

			Place(Items[1])
			self.Ellipsis:SetVisible(First > 2)
			if First > 2 then Place(self.Ellipsis) end

			self.Hidden = {}
			for I = 2, #Items do
				if I >= First then
					Place(Items[I])
				else
					Items[I]:SetVisible(false)
					if Items[I].Node then self.Hidden[#self.Hidden + 1] = Items[I].Node end
				end
			end
		end

		function Bar:PerformLayout(w, h)
			local X = 4
			for _, Button in ipairs(self.Buttons) do
				Button:SetPos(X, (h - 20) / 2)
				X = X + 22
			end

			self.Path:SetPos(X + 2, 2)
			self.Path:SetSize(math.max(w - X - 8, 0), h - 4)
		end
	end

	function PANEL:CreateListHeader()
		local Settings = self.Settings
		local Browser = self.Browser
		local Tree    = Browser.TreeView

		local Header = self:Add("Panel")
		Header:SetMouseInputEnabled(true)
		self.ListHeader = Header

		local Columns = {
			{Text = "Name",     SortType = SORTTYPE_NAME, Align = TEXT_ALIGN_LEFT},
			{Text = "Modified", SortType = SORTTYPE_TIME, Align = TEXT_ALIGN_RIGHT},
			{Text = "Size",     SortType = SORTTYPE_SIZE, Align = TEXT_ALIGN_RIGHT},
		}

		local function UpdateColumnBounds()
			local Width = Header:GetWide() - (Tree.VBar:IsVisible() and Tree.VBar:GetWide() or 0)
			local NameRight, TimeRight, SizeRight = GetListColumns(Width)

			Columns[1].Left, Columns[1].Right, Columns[1].TextX = 0,         NameRight, GetListTextX(Settings)
			Columns[2].Left, Columns[2].Right, Columns[2].TextX = NameRight, TimeRight, TimeRight
			Columns[3].Left, Columns[3].Right, Columns[3].TextX = TimeRight, Width,     SizeRight
		end

		local function GetHoveredColumn()
			if not Header:IsHovered() then return end

			local MouseX = Header:CursorPos()
			for _, Column in ipairs(Columns) do
				if MouseX >= Column.Left and MouseX < Column.Right then return Column end
			end
		end

		function Header:Paint(w, h)
			local Skin = self:GetSkin()

			UpdateColumnBounds()
			DrawSkinPanel(Skin, "Normal", 0, 0, w, h)

			local Hovered = GetHoveredColumn()
			for _, Column in ipairs(Columns) do
				local TextColor = GetStateTextColor(Skin, "Normal")
				if Column == Hovered then
					TextColor = DrawSkinState(Skin, "Hovered", Column.Left, 0, Column.Right - Column.Left, h)
				end

				draw.SimpleText(Column.Text, Settings.NodeFont, Column.TextX, h / 2, TextColor, Column.Align, TEXT_ALIGN_CENTER)

				if Tree.SortType == Column.SortType then
					local TextWidth = surface.GetTextSize(Column.Text)
					local ArrowX    = Column.Align == TEXT_ALIGN_LEFT and (Column.TextX + TextWidth + 2) or (Column.TextX - TextWidth - 18)

					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(Tree.Ascending and ICON_SORT_UP or ICON_SORT_DOWN)
					surface.DrawTexturedRect(ArrowX, (h / 2) - 8, 16, 16)
				end
			end

			surface.SetDrawColor(GetSkinTextColor(Skin, 50))
			surface.DrawRect(0, h - 1, w, 1)
		end

		function Header:OnMousePressed(Code)
			if Code ~= MOUSE_LEFT then return end

			UpdateColumnBounds()
			local Column = GetHoveredColumn()
			if not Column then return end

			if Tree.SortType == Column.SortType then
				Browser:SetAscending(not Tree.Ascending)
			else
				Browser:SetSortType(Column.SortType)
			end
		end
	end

	function PANEL:Think()
		if not self.Browser then return end

		local ViewType = self.Browser:GetViewType()
		if ViewType ~= self.LastViewType then
			self.LastViewType = ViewType
			self:InvalidateLayout()
		end
	end

	function PANEL:Init()
		self:SetPaintBackgroundEnabled(false)
	end

	function PANEL:Setup(Settings)
		self.Settings = Settings or error("No settings provided")
		Settings:Flush()

		self.Browser = vgui.CreateFromTable(FileBrowser.BrowserTable, self)
		self.Browser:Setup(Settings)
		self:CreateNavBar()
		self:CreateListHeader()
		UpdateClientFiles(self.Browser)

		self.SearchAll     = self:AddLeftsideButton("folder_magnify", "Search all root folders", function()
			self.Browser:StartSearch(self.Browser.TreeView)
		end)
		self.SearchAll.OffsetY = -1 -- the icon sits low
		do
			self:AddLeftsideDivider()
			self.SwitchToTree  = self:AddLeftsideButton("application_side_tree", "Tree view", function() self.Browser:SetViewType(VIEWTYPE_TREE) end)
			self.SwitchToList  = self:AddLeftsideButton("application_view_detail", "List view", function() self.Browser:SetViewType(VIEWTYPE_LIST) end)
			self.SwitchToTiles = self:AddLeftsideButton("application_view_tile", "Tile view", function() self.Browser:SetViewType(VIEWTYPE_TILES) end)

			self.SwitchToTree.Think  = function(b) b.m_Image:SetImageColor(self.Browser:GetViewType() == VIEWTYPE_TREE and COLOR_SELECTED or COLOR_UNSELECTED) end
			self.SwitchToList.Think  = function(b) b.m_Image:SetImageColor(self.Browser:GetViewType() == VIEWTYPE_LIST and COLOR_SELECTED or COLOR_UNSELECTED) end
			self.SwitchToTiles.Think = function(b) b.m_Image:SetImageColor(self.Browser:GetViewType() == VIEWTYPE_TILES and COLOR_SELECTED or COLOR_UNSELECTED) end
		end
		do
			self:AddLeftsideDivider()
			self.SwitchToName  = self:AddLeftsideButton("text_replace", "Sort by Name", function() self.Browser:SetSortType(SORTTYPE_NAME) end)
			self.SwitchToTime  = self:AddLeftsideButton("time", "Sort by Time", function() self.Browser:SetSortType(SORTTYPE_TIME) end)

			self.SwitchAscending  = self:AddLeftsideButton("arrow_up", "Sort Ascending", function() self.Browser:SetAscending(true) end)
			self.SwitchDescending  = self:AddLeftsideButton("arrow_down", "Sort Descending", function() self.Browser:SetAscending(false) end)

			self.SwitchAscending.Think  = function(b) b.m_Image:SetImageColor(self.Browser.TreeView.Ascending and COLOR_SELECTED or COLOR_UNSELECTED) end
			self.SwitchDescending.Think  = function(b) b.m_Image:SetImageColor(not self.Browser.TreeView.Ascending and COLOR_SELECTED or COLOR_UNSELECTED) end

			self.SwitchToName.Think  = function(b) b.m_Image:SetImageColor(self.Browser.TreeView.SortType == SORTTYPE_NAME and COLOR_SELECTED or COLOR_UNSELECTED) end
			self.SwitchToTime.Think  = function(b) b.m_Image:SetImageColor(self.Browser.TreeView.SortType == SORTTYPE_TIME and COLOR_SELECTED or COLOR_UNSELECTED) end
		end
		self.Refresh = self:AddRightsideButton("arrow_refresh", "Refresh Files", function(button)
			self.Browser:ClearAllUserPrompts()
			self.SettingsPanel = nil
			self.SettingsButton:SetImage("icon16/cog.png")
			UpdateClientFiles(self.Browser)
		end)
		self:AddRightsideDivider()
		self.SettingsButton = self:AddRightsideButton("cog", "Settings", function() self:OpenSettings() end)

		for _, Callback in ipairs(Settings.CreatedCallbacks) do
			Callback(self)
		end
	end

	function PANEL:OpenSettings()
		local Settings = self.Settings
		if self.SettingsPanel then
			self.SettingsPanel:Close()
			self.SettingsPanel = nil
			self.SettingsButton:SetImage("icon16/cog.png")
			return
		end

		self.SettingsButton:SetImage("icon16/cog_delete.png")

		local Panel = self.Browser:PushUserPrompt()
		self.SettingsPanel = Panel

		Panel:SetBlocking(true)
		Panel:SetDock(FILL)
		Panel:SetCover(true)
		Panel.Panel:GetCanvas():DockPadding(8, 4, 8, 8)

		-- Same split as DNumSlider so every row lines up
		local function SetLabelWidth(Row, Label)
			Row.PerformLayout = function(_, w) Label:SetWide(w / 2.4) end
		end

		local function CreateDivider()
			local Div = Panel:Add("DPanel")
			Div:Dock(TOP)
			Div:DockMargin(0, 4, 0, 4)
			Div:SetTall(1)
			Div.Paint = function(Divider, w, h) surface.SetDrawColor(GetSkinTextColor(Divider:GetSkin(), 50)) surface.DrawRect(0, 0, w, h) end
		end

		local function CreateConvarSlider(Key, Text, Min, Max, Decimals)
			local CV = Settings:GetConVar(Key)

			local Slider = Panel:Add("DNumSlider")
			Slider:Dock(TOP)
			Slider:SetText(Text)
			Slider:SetDark(true)
			Slider:SetMinMax(Min, Max)
			Slider:SetDecimals(Decimals or 0)
			Slider:SetConVar(CV:GetName())
			Slider:SetTooltip(CV:GetHelpText())
			Slider.Scratch.PaintScratchWindow = function(s)
				if not s:GetActive() then return end
				if s:GetZoom() == 0 then s:SetZoom(s:IdealZoom()) end

				local w, h = 400, 200
				local x, y = s:LocalToScreen(0, h + 24)

				x = x + s:GetWide() * 0.5 - w * 0.5
				y = y - 8 - h

				if x + w + 32 > ScrW() then x = ScrW() - w - 32 end
				if y + h + 32 > ScrH() then y = ScrH() - h - 32 end
				if x < 32 then x = 32 end
				if y < 32 then y = 32 end

				if render then render.SetScissorRect(x, y, x + w, y + h, true) end
					s:DrawScreen(x, y, w, h)
				if render then render.SetScissorRect(x, y, w, h, false) end
			end
		end

		local function CreateConvarEntry(Key, Text)
			local CV = Settings:GetConVar(Key)

			local Row = Panel:Add("Panel")
			Row:Dock(TOP)
			Row:DockMargin(0, 4, 0, 4)
			Row:SetTall(20)

			local Name = Row:Add("DLabel")
			Name:Dock(LEFT)
			Name:SetText(Text)
			Name:SetDark(true)
			Name:SetMouseInputEnabled(true)
			Name:SetTooltip(CV:GetHelpText())
			SetLabelWidth(Row, Name)

			local Entry = Row:Add("DTextEntry")
			Entry:Dock(FILL)
			Entry:SetConVar(CV:GetName())

			return Row, CV
		end

		local function CreateConvarIconEntry(Key, Text)
			local Row, CV = CreateConvarEntry(Key, Text)

			local Pick = Row:Add("DButton")
			Pick:SetText("")
			Pick:Dock(RIGHT)
			Pick:DockMargin(4, 0, 0, 0)
			Pick:SetWide(Row:GetTall())
			Pick:SetTooltip("Pick an icon")

			local Icon = Pick:Add("DImage")
			Icon:SetSize(16, 16)
			Icon:SetMouseInputEnabled(false)

			function Pick:PerformLayout(w, h)
				Icon:SetPos(math.floor((w - 16) / 2), math.floor((h - 16) / 2))
			end

			function Pick:Think()
				local Path = CV:GetString()
				if Path ~= self.IconPath then
					self.IconPath = Path
					Icon:SetImage(Path)
				end
			end

			function Pick:DoClick()
				local Frame = vgui.Create("DFrame")
				Frame:SetTitle(Text)
				Frame:SetSize(480, 360)
				Frame:Center()
				Frame:MakePopup()

				local Icons = Frame:Add("DIconBrowser")
				Icons:Dock(FILL)
				Icons:SelectIcon(CV:GetString())
				Icons.OnChange = function()
					CV:SetString(Icons:GetSelectedIcon())
				end
			end
		end

		CreateConvarSlider("PromptOpenTime", "Prompt Open Time", 0, 1, 2)
		CreateConvarSlider("PromptCloseTime", "Prompt Close Time", 0, 1, 2)
		CreateConvarSlider("MaxTimeToDoubleClick", "Double Click Time", 0.1, 1, 2)
		CreateDivider()
		CreateConvarSlider("NodeTall", "Node Height", 12, 64)
		CreateConvarSlider("NodePadding", "Node Spacing", 0, 16)
		CreateConvarSlider("NodeDepthWidth", "Indent Width", 0, 64)
		CreateDivider()
		CreateConvarEntry("NodeFont", "Font")
		CreateConvarIconEntry("IconFolderEmpty", "Empty Folder Icon")
		CreateConvarIconEntry("IconFolderContains", "Folder Icon")
		CreateConvarIconEntry("IconFile", "File Icon")
		CreateDivider()
		CreateConvarSlider("ExpanderSize", "Expander Size", 8, 32)
		CreateConvarSlider("IconSize", "Icon Size", 8, 64)
		CreateConvarSlider("LeftmostToExpanderPadding", "Expander Padding", 0, 32)
		CreateConvarSlider("ExpanderToIconPadding", "Icon Padding", 0, 32)
		CreateConvarSlider("IconToTextPadding", "Text Padding", 0, 32)
		CreateDivider()
		CreateConvarSlider("TileIconSize", "Tile Icon Size", 16, 128)
		CreateDivider()

		local Reset = Panel:Add("DButton")
		Reset:Dock(TOP)
		Reset:DockMargin(0, 4, 0, 0)
		Reset:SetTall(22)
		Reset:SetText("Reset to Defaults")
		Reset.DoClick = function() Settings:ResetToDefaults() end
	end

	FileBrowser.PanelTable = vgui.RegisterTable(PANEL, "Panel")

	function FileBrowser.Create(Settings, Parent)
		local Panel = vgui.CreateFromTable(FileBrowser.PanelTable, Parent)
		Panel:Setup(Settings)
		return Panel
	end
end
