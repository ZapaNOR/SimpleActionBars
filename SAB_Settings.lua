local ADDON_NAME = ...
local M = _G[ADDON_NAME]
if not M then return end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local CONST = M.Constants or {}

local BAR_ORDER = CONST.BAR_ORDER or {}
local BAR_SPECS = CONST.BAR_SPECS or {}
local DEFAULT_STYLE = CONST.DEFAULT_STYLE or {}
local VISIBILITY_MODE_VISIBLE = CONST.VISIBILITY_MODE_VISIBLE or "visible"
local VISIBILITY_MODE_FADE = CONST.VISIBILITY_MODE_FADE or "fade"
local VISIBILITY_MODE_FADE_COMBAT = CONST.VISIBILITY_MODE_FADE_COMBAT or "fade_combat"

M._settingsFrame = M._settingsFrame or nil
M._settingsPanel = M._settingsPanel or nil
M._settingsTabs = M._settingsTabs or nil
M._selectedSettingsTab = M._selectedSettingsTab or "style"

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function getBarSpec(barKey)
	return BAR_SPECS[barKey]
end

local function getBarEntry(barKey)
	if not M.GetBarEntry then
		return nil
	end
	return M:GetBarEntry(barKey)
end

local function refreshSettingsTab()
	if not M._settingsTabs then
		return
	end
	M._settingsTabs:SelectTab(M._selectedSettingsTab or "style")
end

M.RefreshSettingsTab = refreshSettingsTab

local function buildStyleControls(container, barKey)
	local entry = getBarEntry(barKey)
	if not entry then
		return
	end
	local style = entry.style

	local thickness = AceGUI:Create("Slider")
	thickness:SetLabel("Slot Border Thickness")
	thickness:SetSliderValues(0, 12, 1)
	thickness:SetValue(style.borderThickness or DEFAULT_STYLE.borderThickness or 1)
	thickness:SetCallback("OnValueChanged", function(_, _, value)
		style.borderThickness = math.floor(clamp(value, 0, 12))
		M:ApplySettings()
	end)
	thickness:SetFullWidth(true)
	container:AddChild(thickness)

	local borderColor = AceGUI:Create("ColorPicker")
	borderColor:SetLabel("Slot Border Color")
	if borderColor.SetHasAlpha then
		borderColor:SetHasAlpha(true)
	end
	local defaultBorderColor = DEFAULT_STYLE.borderColor or { r = 1, g = 1, b = 1, a = 1 }
	local bc = style.borderColor or defaultBorderColor
	borderColor:SetColor(bc.r, bc.g, bc.b, bc.a or 1)
	borderColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		style.borderColor = { r = r, g = g, b = b, a = a }
		M:ApplySettings()
	end)
	borderColor:SetFullWidth(true)
	container:AddChild(borderColor)

	local backgroundColor = AceGUI:Create("ColorPicker")
	backgroundColor:SetLabel("Slot Background Color")
	if backgroundColor.SetHasAlpha then
		backgroundColor:SetHasAlpha(true)
	end
	local defaultBackgroundColor = DEFAULT_STYLE.backgroundColor or { r = 0, g = 0, b = 0, a = 0.7 }
	local bgc = style.backgroundColor or defaultBackgroundColor
	backgroundColor:SetColor(bgc.r, bgc.g, bgc.b, bgc.a or 1)
	backgroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		style.backgroundColor = { r = r, g = g, b = b, a = a }
		M:ApplySettings()
	end)
	backgroundColor:SetFullWidth(true)
	container:AddChild(backgroundColor)
end

local function finalizeScrollLayout(scroll)
	if not scroll then
		return
	end
	if scroll.DoLayout then
		scroll:DoLayout()
	end
	if scroll.FixScroll then
		scroll:FixScroll()
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if not scroll then
				return
			end
			if scroll.DoLayout then
				scroll:DoLayout()
			end
			if scroll.FixScroll then
				scroll:FixScroll()
			end
		end)
	end
end

local function applyMainStyleToAllBars()
	local mainEntry = getBarEntry("main")
	if not mainEntry or not mainEntry.style or not M.CopyStyle then
		return
	end

	local mainStyle = M:CopyStyle(mainEntry.style)
	for _, barKey in ipairs(BAR_ORDER) do
		if barKey ~= "main" then
			local entry = getBarEntry(barKey)
			if entry then
				entry.useMainStyle = true
				entry.style = M:CopyStyle(mainStyle)
			end
		end
	end
	M:ApplySettings()
	refreshSettingsTab()
end

local function buildStyleTab(container)
	container:SetLayout("Fill")

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	container:AddChild(scroll)

	local copyButton = AceGUI:Create("Button")
	copyButton:SetText("Use Main Bar Style On All Bars")
	copyButton:SetFullWidth(true)
	copyButton:SetCallback("OnClick", function()
		applyMainStyleToAllBars()
	end)
	scroll:AddChild(copyButton)

	for _, barKey in ipairs(BAR_ORDER) do
		local spec = getBarSpec(barKey)
		local entry = getBarEntry(barKey)
		if spec and entry then
			local group = AceGUI:Create("InlineGroup")
			group:SetTitle(spec.label)
			group:SetLayout("List")
			group:SetFullWidth(true)
			scroll:AddChild(group)

			if barKey ~= "main" then
				local useMainStyle = AceGUI:Create("CheckBox")
				useMainStyle:SetLabel("Use same style as Main Bar")
				useMainStyle:SetValue(entry.useMainStyle and true or false)
				useMainStyle:SetFullWidth(true)
				useMainStyle:SetCallback("OnValueChanged", function(_, _, value)
					entry.useMainStyle = value and true or false
					M:ApplySettings()
					refreshSettingsTab()
				end)
				group:AddChild(useMainStyle)

				if entry.useMainStyle then
					local info = AceGUI:Create("Label")
					info:SetText("Using Main Bar style.")
					info:SetFullWidth(true)
					group:AddChild(info)
				else
					buildStyleControls(group, barKey)
				end
			else
				buildStyleControls(group, barKey)
			end
		end
	end

	finalizeScrollLayout(scroll)
end

local function buildVisibilityTab(container)
	container:SetLayout("Fill")

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	container:AddChild(scroll)

	local modeOptions = {
		[VISIBILITY_MODE_VISIBLE] = "Visible",
		[VISIBILITY_MODE_FADE] = "Fade out",
		[VISIBILITY_MODE_FADE_COMBAT] = "Fade out in combat",
	}

	for _, barKey in ipairs(BAR_ORDER) do
		local spec = getBarSpec(barKey)
		local entry = getBarEntry(barKey)
		if spec and entry and entry.visibility then
			local group = AceGUI:Create("InlineGroup")
			group:SetTitle(spec.label)
			group:SetLayout("List")
			group:SetFullWidth(true)
			scroll:AddChild(group)

			local modeDropdown = AceGUI:Create("Dropdown")
			modeDropdown:SetLabel("Visibility")
			modeDropdown:SetList(modeOptions)
			modeDropdown:SetValue(entry.visibility.mode or VISIBILITY_MODE_VISIBLE)
			modeDropdown:SetFullWidth(true)
			modeDropdown:SetCallback("OnValueChanged", function(_, _, value)
				if value ~= VISIBILITY_MODE_VISIBLE
					and value ~= VISIBILITY_MODE_FADE
					and value ~= VISIBILITY_MODE_FADE_COMBAT then
					return
				end
				entry.visibility.mode = value
				M:ApplySettings()
			end)
			group:AddChild(modeDropdown)
		end
	end

	finalizeScrollLayout(scroll)
end

local function createSettingsWindow()
	if M._settingsFrame then
		M._settingsFrame:Show()
		return M._settingsFrame
	end

	if not AceGUI then
		print("SimpleActionBars: AceGUI-3.0 not loaded. Check Libraries/Init.xml in SAB.")
		return nil
	end

	if M.EnsureDefaults then
		M:EnsureDefaults()
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Simple Action Bars")
	frame:SetWidth(640)
	frame:SetHeight(600)
	frame:SetLayout("Fill")
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		M._settingsFrame = nil
		M._settingsTabs = nil
	end)

	local tabs = AceGUI:Create("TabGroup")
	tabs:SetTabs({
		{ text = "Style", value = "style" },
		{ text = "Visibility", value = "visibility" },
	})
	tabs:SetLayout("List")
	tabs:SetTitle(" ")
	tabs:SetCallback("OnGroupSelected", function(container, _, group)
		M._selectedSettingsTab = group
		container:ReleaseChildren()
		if group == "visibility" then
			buildVisibilityTab(container)
		else
			buildStyleTab(container)
		end
	end)

	frame:AddChild(tabs)
	M._settingsTabs = tabs
	tabs:SelectTab(M._selectedSettingsTab or "style")

	M._settingsFrame = frame
	return frame
end

function M:OpenSettings()
	local frame = createSettingsWindow()
	if not frame then
		return
	end
	if frame.Show then
		frame:Show()
	end
	if frame.frame and frame.frame.Raise then
		frame.frame:Raise()
	end
end

function M:CreateSettingsPanel()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then
		return
	end
	if M._settingsPanel then
		return
	end

	local panel = CreateFrame("Frame")
	panel.name = "SimpleActionBars"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("SimpleActionBars")

	local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	desc:SetWidth(520)
	desc:SetJustifyH("LEFT")
	desc:SetText("Settings open in a separate window. Use the button below or type /sab.")

	local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	button:SetSize(200, 24)
	button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
	button:SetText("Open Settings")
	button:SetScript("OnClick", function()
		M:OpenSettings()
	end)

	local category = Settings.RegisterCanvasLayoutCategory(panel, "SimpleActionBars")
	Settings.RegisterAddOnCategory(category)
	M._settingsPanel = panel
end

function M:PrintSlashHelp()
	print("|cFF9CDF95Simple|rActionBars: '|cFF9CDF95/sab|r' for in-game configuration.")
end

M.CreateSettingsWindow = createSettingsWindow
