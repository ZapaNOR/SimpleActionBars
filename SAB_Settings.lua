local ADDON_NAME = ...
local M = _G[ADDON_NAME]
if not M then return end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local Media = LibStub and LibStub("LibSharedMedia-3.0", true)
local CONST = M.Constants or {}

local BAR_ORDER = CONST.BAR_ORDER or {}
local BAR_SPECS = CONST.BAR_SPECS or {}
local DEFAULT_STYLE = CONST.DEFAULT_STYLE or {}
local FONT_FACE_DEFAULT = CONST.FONT_FACE_DEFAULT or "__DEFAULT__"
local FONT_OUTLINE_DEFAULT = CONST.FONT_OUTLINE_DEFAULT or "default"
local FONT_SIZE_MIN = CONST.FONT_SIZE_MIN or 0
local FONT_SIZE_MAX = CONST.FONT_SIZE_MAX or 32
local ICON_ZOOM_MIN = CONST.ICON_ZOOM_MIN or 0
local ICON_ZOOM_MAX = CONST.ICON_ZOOM_MAX or 0.4
local TEXT_OFFSET_MIN = CONST.TEXT_OFFSET_MIN or -200
local TEXT_OFFSET_MAX = CONST.TEXT_OFFSET_MAX or 200
local FONT_OUTLINE_LABELS = CONST.FONT_OUTLINE_LABELS or {}
local FONT_OUTLINE_ORDER = CONST.FONT_OUTLINE_ORDER or {}
local VISIBILITY_MODE_VISIBLE = CONST.VISIBILITY_MODE_VISIBLE or "visible"
local VISIBILITY_MODE_FADE_OUT_OF_COMBAT = CONST.VISIBILITY_MODE_FADE_OUT_OF_COMBAT or "fade"
local VISIBILITY_MODE_FADE_IN_COMBAT = CONST.VISIBILITY_MODE_FADE_IN_COMBAT or "fade_combat"
local VISIBILITY_MODE_FADE_ALWAYS = CONST.VISIBILITY_MODE_FADE_ALWAYS or "fade_always"

M._settingsFrame = M._settingsFrame or nil
M._settingsPanel = M._settingsPanel or nil
M._settingsTabs = M._settingsTabs or nil
M._selectedSettingsTab = M._selectedSettingsTab or "style"

local function getFontOptions()
	local fonts = {
		[FONT_FACE_DEFAULT] = "Blizzard Default",
	}
	local order = { FONT_FACE_DEFAULT }
	if not (Media and Media.HashTable) then
		return fonts, order
	end

	local names = {}
	for fontName in pairs(Media:HashTable("font") or {}) do
		names[#names + 1] = fontName
	end
	table.sort(names, function(a, b)
		return string.upper(a) < string.upper(b)
	end)

	for i = 1, #names do
		local name = names[i]
		fonts[name] = name
		order[#order + 1] = name
	end

	return fonts, order
end

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

local function getStyle()
	if not M.GetStyle then
		return nil
	end
	return M:GetStyle()
end

local function refreshSettingsTab()
	if not M._settingsTabs then
		return
	end
	M._settingsTabs:SelectTab(M._selectedSettingsTab or "style")
end

M.RefreshSettingsTab = refreshSettingsTab

local function addFontWarning(container, fontOrder)
	if #fontOrder > 1 then
		return
	end
	local fontWarning = AceGUI:Create("Label")
	fontWarning:SetText("LibSharedMedia-3.0 not found. Only Blizzard default font is available.")
	fontWarning:SetFullWidth(true)
	container:AddChild(fontWarning)
end

local function buildIconControls(container, style)
	local iconStyle = style.icon or {}
	local defaultIcon = DEFAULT_STYLE.icon or {}

	local thickness = AceGUI:Create("Slider")
	thickness:SetLabel("Border Thickness")
	thickness:SetSliderValues(0, 12, 1)
	thickness:SetValue(iconStyle.borderThickness or defaultIcon.borderThickness or 1)
	thickness:SetCallback("OnValueChanged", function(_, _, value)
		iconStyle.borderThickness = math.floor(clamp(value, 0, 12))
		M:ApplySettings()
	end)
	thickness:SetFullWidth(true)
	container:AddChild(thickness)

	local borderColor = AceGUI:Create("ColorPicker")
	borderColor:SetLabel("Border Color")
	if borderColor.SetHasAlpha then
		borderColor:SetHasAlpha(true)
	end
	local defaultBorderColor = defaultIcon.borderColor or { r = 1, g = 1, b = 1, a = 1 }
	local bc = iconStyle.borderColor or defaultBorderColor
	borderColor:SetColor(bc.r, bc.g, bc.b, bc.a or 1)
	borderColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		iconStyle.borderColor = { r = r, g = g, b = b, a = a }
		M:ApplySettings()
	end)
	borderColor:SetFullWidth(true)
	container:AddChild(borderColor)

	local backgroundColor = AceGUI:Create("ColorPicker")
	backgroundColor:SetLabel("Background Color")
	if backgroundColor.SetHasAlpha then
		backgroundColor:SetHasAlpha(true)
	end
	local defaultBackgroundColor = defaultIcon.backgroundColor or { r = 0, g = 0, b = 0, a = 0.7 }
	local bgc = iconStyle.backgroundColor or defaultBackgroundColor
	backgroundColor:SetColor(bgc.r, bgc.g, bgc.b, bgc.a or 1)
	backgroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		iconStyle.backgroundColor = { r = r, g = g, b = b, a = a }
		M:ApplySettings()
	end)
	backgroundColor:SetFullWidth(true)
	container:AddChild(backgroundColor)

	local iconZoom = AceGUI:Create("Slider")
	iconZoom:SetLabel("Icon Zoom (%)")
	iconZoom:SetSliderValues(math.floor(ICON_ZOOM_MIN * 100), math.floor(ICON_ZOOM_MAX * 100), 1)
	iconZoom:SetValue(math.floor(clamp((iconStyle.iconZoom or defaultIcon.iconZoom or 0) * 100, ICON_ZOOM_MIN * 100, ICON_ZOOM_MAX * 100) + 0.5))
	iconZoom:SetCallback("OnValueChanged", function(_, _, value)
		iconStyle.iconZoom = clamp(value / 100, ICON_ZOOM_MIN, ICON_ZOOM_MAX)
		M:ApplySettings()
	end)
	iconZoom:SetFullWidth(true)
	container:AddChild(iconZoom)
end

local function buildSharedFontControls(container, style, fontOptions, fontOrder)
	local fontFace = AceGUI:Create("Dropdown")
	fontFace:SetLabel("Font")
	fontFace:SetList(fontOptions, fontOrder)
	fontFace:SetValue(style.fontFace or (DEFAULT_STYLE.fontFace or FONT_FACE_DEFAULT))
	fontFace:SetFullWidth(true)
	fontFace:SetCallback("OnValueChanged", function(_, _, value)
		style.fontFace = value
		style.keybind = style.keybind or {}
		style.stacks = style.stacks or {}
		style.macro = style.macro or {}
		style.keybind.fontFace = value
		style.stacks.fontFace = value
		style.macro.fontFace = value
		M:ApplySettings()
	end)
	container:AddChild(fontFace)

	addFontWarning(container, fontOrder)
end

local function buildTextControls(container, textStyle, defaults)
	local fontSize = AceGUI:Create("Slider")
	fontSize:SetLabel("Font Size (0 = Blizzard default)")
	fontSize:SetSliderValues(FONT_SIZE_MIN, FONT_SIZE_MAX, 1)
	fontSize:SetValue(textStyle.fontSize or defaults.fontSize or FONT_SIZE_MIN)
	fontSize:SetCallback("OnValueChanged", function(_, _, value)
		textStyle.fontSize = math.floor(clamp(value, FONT_SIZE_MIN, FONT_SIZE_MAX))
		M:ApplySettings()
	end)
	fontSize:SetFullWidth(true)
	container:AddChild(fontSize)

	local fontColor = AceGUI:Create("ColorPicker")
	fontColor:SetLabel("Font Color")
	if fontColor.SetHasAlpha then
		fontColor:SetHasAlpha(true)
	end
	local defaultFontColor = defaults.fontColor or { r = 1, g = 1, b = 1, a = 1 }
	local fc = textStyle.fontColor or defaultFontColor
	fontColor:SetColor(fc.r, fc.g, fc.b, fc.a or 1)
	fontColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		textStyle.fontColor = { r = r, g = g, b = b, a = a }
		M:ApplySettings()
	end)
	fontColor:SetFullWidth(true)
	container:AddChild(fontColor)

	local fontOutline = AceGUI:Create("Dropdown")
	fontOutline:SetLabel("Outline")
	fontOutline:SetList(FONT_OUTLINE_LABELS, FONT_OUTLINE_ORDER)
	fontOutline:SetValue(textStyle.fontOutline or defaults.fontOutline or FONT_OUTLINE_DEFAULT)
	fontOutline:SetFullWidth(true)
	fontOutline:SetCallback("OnValueChanged", function(_, _, value)
		textStyle.fontOutline = value
		M:ApplySettings()
	end)
	container:AddChild(fontOutline)

	local textShadow = AceGUI:Create("CheckBox")
	textShadow:SetLabel("Shadow")
	textShadow:SetValue(textStyle.textShadow == nil and true or (textStyle.textShadow and true or false))
	textShadow:SetFullWidth(true)
	textShadow:SetCallback("OnValueChanged", function(_, _, value)
		textStyle.textShadow = value and true or false
		M:ApplySettings()
	end)
	container:AddChild(textShadow)

	local xOffset = AceGUI:Create("Slider")
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(TEXT_OFFSET_MIN, TEXT_OFFSET_MAX, 1)
	xOffset:SetValue(textStyle.xOffset or defaults.xOffset or 0)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		textStyle.xOffset = clamp(value, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX)
		M:ApplySettings()
	end)
	xOffset:SetFullWidth(true)
	container:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(TEXT_OFFSET_MIN, TEXT_OFFSET_MAX, 1)
	yOffset:SetValue(textStyle.yOffset or defaults.yOffset or 0)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		textStyle.yOffset = clamp(value, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX)
		M:ApplySettings()
	end)
	yOffset:SetFullWidth(true)
	container:AddChild(yOffset)
end

local function buildStyleControls(container)
	local style = getStyle()
	if not style then
		return
	end

	local fontOptions, fontOrder = getFontOptions()
	style.icon = style.icon or {}
	style.keybind = style.keybind or {}
	style.stacks = style.stacks or {}
	style.macro = style.macro or {}
	style.fontFace = style.fontFace or style.keybind.fontFace or style.stacks.fontFace or style.macro.fontFace or DEFAULT_STYLE.fontFace or FONT_FACE_DEFAULT

	local fontGroup = AceGUI:Create("InlineGroup")
	fontGroup:SetTitle("Font")
	fontGroup:SetLayout("List")
	fontGroup:SetFullWidth(true)
	container:AddChild(fontGroup)
	buildSharedFontControls(fontGroup, style, fontOptions, fontOrder)

	local iconGroup = AceGUI:Create("InlineGroup")
	iconGroup:SetTitle("Icon")
	iconGroup:SetLayout("List")
	iconGroup:SetFullWidth(true)
	container:AddChild(iconGroup)
	buildIconControls(iconGroup, style)

	local keybindGroup = AceGUI:Create("InlineGroup")
	keybindGroup:SetTitle("Keybind")
	keybindGroup:SetLayout("List")
	keybindGroup:SetFullWidth(true)
	container:AddChild(keybindGroup)
	buildTextControls(keybindGroup, style.keybind, (DEFAULT_STYLE.keybind or {}))

	local stacksGroup = AceGUI:Create("InlineGroup")
	stacksGroup:SetTitle("Stacks")
	stacksGroup:SetLayout("List")
	stacksGroup:SetFullWidth(true)
	container:AddChild(stacksGroup)
	buildTextControls(stacksGroup, style.stacks, (DEFAULT_STYLE.stacks or {}))

	local macroGroup = AceGUI:Create("InlineGroup")
	macroGroup:SetTitle("Macro Text")
	macroGroup:SetLayout("List")
	macroGroup:SetFullWidth(true)
	container:AddChild(macroGroup)
	buildTextControls(macroGroup, style.macro, (DEFAULT_STYLE.macro or {}))

	local hideMacroText = AceGUI:Create("CheckBox")
	hideMacroText:SetLabel("Hide Macro Text")
	hideMacroText:SetValue(style.hideMacroText and true or false)
	hideMacroText:SetFullWidth(true)
	hideMacroText:SetCallback("OnValueChanged", function(_, _, value)
		style.hideMacroText = value and true or false
		M:ApplySettings()
	end)
	macroGroup:AddChild(hideMacroText)
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

local function buildStyleTab(container)
	container:SetLayout("Fill")

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	container:AddChild(scroll)

	buildStyleControls(scroll)

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
		[VISIBILITY_MODE_FADE_IN_COMBAT] = "Fade in combat",
		[VISIBILITY_MODE_FADE_OUT_OF_COMBAT] = "Fade out of combat",
		[VISIBILITY_MODE_FADE_ALWAYS] = "Fade",
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
					and value ~= VISIBILITY_MODE_FADE_IN_COMBAT
					and value ~= VISIBILITY_MODE_FADE_OUT_OF_COMBAT
					and value ~= VISIBILITY_MODE_FADE_ALWAYS then
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
