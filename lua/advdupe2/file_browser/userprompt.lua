return function(FileBrowser)
	local DrawSkinPanel = FileBrowser.DrawSkinPanel
	local GetSkinTextColor = FileBrowser.GetSkinTextColor
	local GetStateTextColor = FileBrowser.GetStateTextColor

	local function ColorLabels(Panel, TextColor)
		for _, Child in ipairs(Panel:GetChildren()) do
			if Child.ClassName == "DLabel" and Child:GetTextColor() ~= TextColor then Child:SetTextColor(TextColor) end
			ColorLabels(Child, TextColor)
		end
	end

	local function PaintUserPrompt(Panel, w, h)
		local Skin = Panel:GetSkin()

		DrawSkinPanel(Skin, "Panel", 0, 0, w, h)
		surface.SetDrawColor(GetSkinTextColor(Skin, 50))
		surface.DrawOutlinedRect(0, 0, w, h)

		ColorLabels(Panel, GetStateTextColor(Skin, "Panel"))
	end

	-- This is a user prompt class, see Browser's UserPrompt stack methods

	local USERPROMPT_MT = {}
	local USERPROMPT = setmetatable({}, USERPROMPT_MT)

	do
		function USERPROMPT:Init(Browser)
			self.Browser = Browser
			self.Blocking = false

			self.Panel = Browser:Add("DScrollPanel")
			self.Panel.Paint = PaintUserPrompt
			self.Panel:SetAlpha(0)
		end

		function USERPROMPT:GetPanel() return self.Panel end

		function USERPROMPT:Add(Type)
			return self.Panel:Add(Type)
		end

		function USERPROMPT_MT:__call(Browser)
			if not IsValid(Browser) then return error ("Cannot create a headless node (we need a browser)") end

			local Node = setmetatable({}, {__index = USERPROMPT})
			Node:Init(Browser)

			return Node
		end

		function USERPROMPT:GetBlocking() return self.Blocking or false end
		function USERPROMPT:SetBlocking(Blocking) self.Blocking = Blocking and true or false end

		function USERPROMPT:Destroy()
			if IsValid(self.Panel) then
				self.Panel:Remove()
			end
		end

		function USERPROMPT:SetDock(Dock)
			self.Dock = Dock
		end

		-- Covers the whole browser, for things like the settings page
		function USERPROMPT:SetCover(Cover)
			self.Cover = Cover and true or false
		end

		local DockPadding = 4

		function USERPROMPT:DoThink()
			if self.Closing then return false end

			local Browser = self.Browser
			local ParentWidth, ParentHeight = Browser:GetWide(), Browser:GetTall()

			local PosX, PosY
			local SizeW, SizeH

			local ContentWide, ContentTall = self.Panel:ChildrenSize()
			ContentTall = math.min(ContentTall, ParentHeight - 32)
			local Dock = self.Dock
			if not Dock then error("No dock??") end

			if self.Cover then
				PosX, PosY, SizeW, SizeH = 0, 0, ParentWidth, ParentHeight
			elseif Dock == TOP or Dock == BOTTOM then
				SizeW = ParentWidth - (DockPadding * 2)
				SizeH = math.ceil(ContentTall)
				PosX = DockPadding

				if Dock == TOP then
					PosY = DockPadding
				else
					PosY = ParentHeight - SizeH - DockPadding
				end
			elseif Dock == FILL then
				SizeW = math.ceil(ContentWide - (DockPadding * 2))
				SizeH = math.ceil(ContentTall)
				PosX = math.floor((ParentWidth / 2) - (SizeW / 2))
				PosY = math.floor((ParentHeight / 2) - (SizeH / 2) - (DockPadding / 2))
			end

			self.Panel:SetPos(PosX, PosY)
			self.Panel:SetSize(SizeW, SizeH)
			self.Panel:SetAlpha(255)

			return true
		end

		-- Call this to close; the prompt is removed on the browser's next think.
		-- This also forces Blocking back to false for main UI panel.
		function USERPROMPT:Close()
			if self.OnClose and not self.Closing then self:OnClose() end

			self.Blocking = false
			self.Closing = true
		end
	end

	FileBrowser.USERPROMPT = USERPROMPT
	FileBrowser.PaintUserPrompt = PaintUserPrompt
end
