local ADDON_NAME = ...
local M = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = M

local ICON_ZOOM = 0.05
local HIDDEN_ALPHA = 0
local SHOWN_ALPHA = 1
local HOVER_LEAVE_DELAY = 0.03
local DEFAULT_BACKGROUND_ALPHA = 0.7

local BAR_ORDER = {
	"main",
	"bar2",
	"bar3",
	"bar4",
	"bar5",
	"bar6",
	"bar7",
	"bar8",
	"stance",
	"pet",
}

local BAR_SPECS = {
	main = {
		key = "main",
		label = "Main Bar",
		frameNames = { "MainActionBar" },
		buttonPrefix = "ActionButton",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar2 = {
		key = "bar2",
		label = "Bar 2",
		frameNames = { "MultiBarBottomLeft" },
		buttonPrefix = "MultiBarBottomLeftButton",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar3 = {
		key = "bar3",
		label = "Bar 3",
		frameNames = { "MultiBarBottomRight" },
		buttonPrefix = "MultiBarBottomRightButton",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar4 = {
		key = "bar4",
		label = "Bar 4",
		frameNames = { "MultiBarRight" },
		buttonPrefix = "MultiBarRightButton",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar5 = {
		key = "bar5",
		label = "Bar 5",
		frameNames = { "MultiBarLeft" },
		buttonPrefix = "MultiBarLeftButton",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar6 = {
		key = "bar6",
		label = "Bar 6",
		frameNames = { "MultiBar5" },
		buttonPrefix = "MultiBar5Button",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar7 = {
		key = "bar7",
		label = "Bar 7",
		frameNames = { "MultiBar6" },
		buttonPrefix = "MultiBar6Button",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	bar8 = {
		key = "bar8",
		label = "Bar 8",
		frameNames = { "MultiBar7" },
		buttonPrefix = "MultiBar7Button",
		buttonCount = 12,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	stance = {
		key = "stance",
		label = "Stance",
		frameNames = { "StanceBar", "StanceBarFrame" },
		buttonPrefix = "StanceButton",
		buttonCount = 10,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
	pet = {
		key = "pet",
		label = "Pet",
		frameNames = { "PetActionBarFrame", "PetActionBar" },
		buttonPrefix = "PetActionButton",
		buttonCount = 10,
		defaultFadeOut = false,
		defaultFadeOutInCombat = false,
	},
}

local DEFAULT_STYLE = {
	borderThickness = 1,
	borderColor = { r = 0, g = 0, b = 0, a = 1 },
	backgroundColor = { r = 0, g = 0, b = 0, a = DEFAULT_BACKGROUND_ALPHA },
}

local VISIBILITY_MODE_VISIBLE = "visible"
local VISIBILITY_MODE_FADE_OUT_OF_COMBAT = "fade"
local VISIBILITY_MODE_FADE_IN_COMBAT = "fade_combat"
local VISIBILITY_MODE_FADE_ALWAYS = "fade_always"

local hoverBars = {}
local hidePending = false
local editModeHooked = false
local RefreshHoverState

M.DB = nil

local function wipeTable(tbl)
	if table.wipe then
		table.wipe(tbl)
		return
	end
	for key in pairs(tbl) do
		tbl[key] = nil
	end
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

local function boolOrDefault(value, defaultValue)
	if value == nil then
		return defaultValue
	end
	return value and true or false
end

local function copyColor(color, fallback)
	color = type(color) == "table" and color or fallback
	return {
		r = clamp(color.r, 0, 1),
		g = clamp(color.g, 0, 1),
		b = clamp(color.b, 0, 1),
		a = clamp(color.a or 1, 0, 1),
	}
end

local function sanitizeStyle(style, fallback)
	fallback = fallback or DEFAULT_STYLE
	style = type(style) == "table" and style or {}
	style.borderThickness = math.floor(clamp(style.borderThickness, 0, 12))
	style.borderColor = copyColor(style.borderColor, fallback.borderColor)
	style.backgroundColor = copyColor(style.backgroundColor, fallback.backgroundColor)
	return style
end

local function copyStyle(style)
	local sanitized = sanitizeStyle(style, DEFAULT_STYLE)
	return {
		borderThickness = sanitized.borderThickness,
		borderColor = copyColor(sanitized.borderColor, DEFAULT_STYLE.borderColor),
		backgroundColor = copyColor(sanitized.backgroundColor, DEFAULT_STYLE.backgroundColor),
	}
end

local function getBarSpec(barKey)
	return BAR_SPECS[barKey]
end

local function getBarFrame(spec)
	if not spec then return nil end
	for _, frameName in ipairs(spec.frameNames or {}) do
		local frame = _G[frameName]
		if frame then
			return frame
		end
	end
	return nil
end

local function ensureDefaults()
	SimpleActionBarsDB = SimpleActionBarsDB or {}
	SimpleActionBarsDB.bars = type(SimpleActionBarsDB.bars) == "table" and SimpleActionBarsDB.bars or {}

	for _, barKey in ipairs(BAR_ORDER) do
		local spec = getBarSpec(barKey)
		if spec then
			local entry = SimpleActionBarsDB.bars[barKey]
			if type(entry) ~= "table" then
				entry = {}
				SimpleActionBarsDB.bars[barKey] = entry
			end

			if barKey == "main" then
				entry.useMainStyle = false
			else
				entry.useMainStyle = boolOrDefault(entry.useMainStyle, true)
			end

			entry.style = sanitizeStyle(entry.style, DEFAULT_STYLE)

			entry.visibility = type(entry.visibility) == "table" and entry.visibility or {}
			local mode = entry.visibility.mode
			if mode ~= VISIBILITY_MODE_VISIBLE
				and mode ~= VISIBILITY_MODE_FADE_OUT_OF_COMBAT
				and mode ~= VISIBILITY_MODE_FADE_IN_COMBAT
				and mode ~= VISIBILITY_MODE_FADE_ALWAYS then
				mode = VISIBILITY_MODE_VISIBLE
			end
			entry.visibility.mode = mode
		end
	end

	M.DB = SimpleActionBarsDB
	return M.DB
end

M.EnsureDefaults = ensureDefaults

local function getBarEntry(barKey)
	if not M.DB then
		ensureDefaults()
	end
	local bars = M.DB and M.DB.bars
	if not bars then return nil end
	return bars[barKey]
end

local function getEffectiveStyle(barKey)
	local entry = getBarEntry(barKey)
	if not entry then
		return DEFAULT_STYLE
	end
	if barKey ~= "main" and entry.useMainStyle then
		local mainEntry = getBarEntry("main")
		if mainEntry and mainEntry.style then
			return mainEntry.style
		end
	end
	return entry.style or DEFAULT_STYLE
end

local function isBarFadeEnabled(barKey)
	local entry = getBarEntry(barKey)
	if not entry or not entry.visibility then
		return false
	end
	local mode = entry.visibility.mode or VISIBILITY_MODE_VISIBLE
	if mode == VISIBILITY_MODE_VISIBLE then
		return false
	end
	if mode == VISIBILITY_MODE_FADE_ALWAYS then
		return true
	end
	if mode == VISIBILITY_MODE_FADE_IN_COMBAT then
		return InCombatLockdown and InCombatLockdown()
	end
	if mode == VISIBILITY_MODE_FADE_OUT_OF_COMBAT then
		return not (InCombatLockdown and InCombatLockdown())
	end
	return false
end

local function ForceTextureHiddenOnShow(texture)
	texture:SetAlpha(0)
	texture:Hide()
end

local function ApplyIconZoom(icon)
	if not icon then
		return
	end
	local inset = ICON_ZOOM * 0.5
	icon:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
end

local function RemoveIconMask(button)
	if not button then
		return
	end
	local icon = button.icon or button.Icon
	local mask = button.IconMask
	if not icon or not mask then
		return
	end
	if icon.RemoveMaskTexture then
		icon:RemoveMaskTexture(mask)
	end
	mask:SetAlpha(0)
	mask:Hide()
	if not mask._simpleActionBarsHideHooked then
		mask:HookScript("OnShow", ForceTextureHiddenOnShow)
		mask._simpleActionBarsHideHooked = true
	end
end

local function HideTexture(texture)
	if not texture then
		return
	end
	texture:SetAlpha(0)
	texture:Hide()
	if not texture._simpleActionBarsHideHooked then
		texture:HookScript("OnShow", ForceTextureHiddenOnShow)
		texture._simpleActionBarsHideHooked = true
	end
end

local function StripDefaultButtonArt(button)
	if not button then
		return
	end
	HideTexture(button.SlotArt)
	HideTexture(button.SlotBackground)
	HideTexture(button.Border)
	HideTexture(button.NormalTexture)
	if button.GetNormalTexture then
		HideTexture(button:GetNormalTexture())
	end
end

local function EnsureSlotVisual(button)
	if not button then return nil, nil end
	local icon = button.icon or button.Icon
	if not icon then return nil, nil end

	if not button._simpleActionBarsBG then
		button._simpleActionBarsBG = button:CreateTexture(nil, "BACKGROUND", nil, -7)
	end

	if not button._simpleActionBarsBorder then
		local border = {}
		border.top = button:CreateTexture(nil, "BORDER", nil, 1)
		border.bottom = button:CreateTexture(nil, "BORDER", nil, 1)
		border.left = button:CreateTexture(nil, "BORDER", nil, 1)
		border.right = button:CreateTexture(nil, "BORDER", nil, 1)
		button._simpleActionBarsBorder = border
	end

	return icon, button._simpleActionBarsBG
end

local function ApplySlotStyle(button, style)
	local icon, bg = EnsureSlotVisual(button)
	if not icon or not bg then
		return
	end

	style = sanitizeStyle(style, DEFAULT_STYLE)

	local thickness = math.floor(clamp(style.borderThickness, 0, 12))
	local borderColor = style.borderColor
	local bgColor = style.backgroundColor
	local pad = math.max(1, thickness)

	bg:ClearAllPoints()
	bg:SetPoint("TOPLEFT", icon, "TOPLEFT", -pad, pad)
	bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", pad, -pad)
	bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a)

	local border = button._simpleActionBarsBorder
	if not border then
		return
	end

	local function applySegment(tex)
		tex:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
		tex:SetShown(thickness > 0)
	end

	applySegment(border.top)
	applySegment(border.bottom)
	applySegment(border.left)
	applySegment(border.right)

	if thickness <= 0 then
		return
	end

	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", icon, "TOPLEFT", -pad, pad)
	border.top:SetPoint("TOPRIGHT", icon, "TOPRIGHT", pad, pad)
	border.top:SetHeight(thickness)

	border.bottom:ClearAllPoints()
	border.bottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -pad, -pad)
	border.bottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", pad, -pad)
	border.bottom:SetHeight(thickness)

	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", icon, "TOPLEFT", -pad, pad)
	border.left:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -pad, -pad)
	border.left:SetWidth(thickness)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPRIGHT", icon, "TOPRIGHT", pad, pad)
	border.right:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", pad, -pad)
	border.right:SetWidth(thickness)
end

local function ApplyButtonCurrentStyle(button)
	if not button then return end
	local barKey = button._simpleActionBarsBarKey or "main"
	ApplySlotStyle(button, getEffectiveStyle(barKey))
end

local function OnStyledButtonShow(button)
	if not button then return end
	local icon = button.icon or button.Icon
	ApplyIconZoom(icon)
	RemoveIconMask(button)
	StripDefaultButtonArt(button)
	ApplyButtonCurrentStyle(button)
end

local function IsEditModeActive()
	return EditModeManagerFrame
		and EditModeManagerFrame.IsEditModeActive
		and EditModeManagerFrame:IsEditModeActive()
end

local function SetBarAlpha(bar, alpha)
	if not bar then
		return
	end
	local currentAlpha = bar:GetAlpha()
	if bar._simpleActionBarsTargetAlpha == alpha and math.abs((currentAlpha or alpha) - alpha) < 0.001 then
		return
	end
	bar._simpleActionBarsTargetAlpha = alpha
	bar:SetAlpha(alpha)
end

local function IsBarHovered(bar)
	if not bar or not bar:IsShown() then
		return false
	end
	if MouseIsOver(bar) then
		return true
	end
	local buttons = bar._simpleActionBarsButtons
	if buttons then
		for i = 1, #buttons do
			local button = buttons[i]
			if button and button:IsShown() and MouseIsOver(button) then
				return true
			end
		end
	end
	return false
end

local function FindHoveredActionBar()
	for _, bar in ipairs(hoverBars) do
		local barKey = bar._simpleActionBarsBarKey
		if isBarFadeEnabled(barKey) and IsBarHovered(bar) then
			return bar
		end
	end
	return nil
end

local function SetActionBarsVisibility(hoveredBar)
	if IsEditModeActive() then
		for i = 1, #hoverBars do
			local bar = hoverBars[i]
			if bar:IsShown() then
				SetBarAlpha(bar, SHOWN_ALPHA)
			end
		end
		return
	end

	for i = 1, #hoverBars do
		local bar = hoverBars[i]
		if bar:IsShown() then
			local barKey = bar._simpleActionBarsBarKey
			if isBarFadeEnabled(barKey) then
				SetBarAlpha(bar, bar == hoveredBar and SHOWN_ALPHA or HIDDEN_ALPHA)
			else
				SetBarAlpha(bar, SHOWN_ALPHA)
			end
		end
	end
end

local function QueueHoverCheck()
	if hidePending then
		return
	end
	hidePending = true
	C_Timer.After(HOVER_LEAVE_DELAY, function()
		hidePending = false
		RefreshHoverState()
	end)
end

local function HoverFrameOnEnter(frame)
	SetActionBarsVisibility(frame and frame._simpleActionBarsOwnerBar)
end

local function HookHover(frame, ownerBar)
	if not frame or frame._simpleActionBarsHoverHooked then
		return
	end
	frame._simpleActionBarsOwnerBar = ownerBar or frame
	frame:HookScript("OnEnter", HoverFrameOnEnter)
	frame:HookScript("OnLeave", QueueHoverCheck)
	frame._simpleActionBarsHoverHooked = true
end

RefreshHoverState = function()
	SetActionBarsVisibility(FindHoveredActionBar())
end

local function HookEditModeState()
	if editModeHooked or not EditModeManagerFrame then
		return
	end
	EditModeManagerFrame:HookScript("OnShow", RefreshHoverState)
	EditModeManagerFrame:HookScript("OnHide", RefreshHoverState)
	editModeHooked = true
end

local function collectBarButtons(spec, bar)
	local buttons = {}
	local seen = {}

	local function addButton(button)
		if button and not seen[button] then
			seen[button] = true
			buttons[#buttons + 1] = button
		end
	end

	if bar and type(bar.actionButtons) == "table" then
		for _, button in ipairs(bar.actionButtons) do
			addButton(button)
		end
	end

	if bar and type(bar.buttons) == "table" then
		for _, button in ipairs(bar.buttons) do
			addButton(button)
		end
	end

	if spec and spec.buttonPrefix then
		for i = 1, (spec.buttonCount or 12) do
			addButton(_G[spec.buttonPrefix .. i])
		end
	end

	return buttons
end

local function StyleButton(button, spec, ownerBar)
	if not button then
		return
	end
	button._simpleActionBarsBarKey = spec and spec.key or "main"
	OnStyledButtonShow(button)
	if not button._simpleActionBarsStyleHooked then
		button:HookScript("OnShow", OnStyledButtonShow)
		button._simpleActionBarsStyleHooked = true
	end
	HookHover(button, ownerBar)
end

local function TrackBar(spec, bar)
	if not bar then
		return
	end

	bar._simpleActionBarsBarKey = spec and spec.key or "main"
	table.insert(hoverBars, bar)

	if not bar._simpleActionBarsHoverTracked then
		HookHover(bar, bar)
		bar:HookScript("OnShow", RefreshHoverState)
		bar:HookScript("OnHide", RefreshHoverState)
		bar._simpleActionBarsHoverTracked = true
	end

	local buttons = collectBarButtons(spec, bar)
	bar._simpleActionBarsButtons = buttons
	for _, button in ipairs(buttons) do
		StyleButton(button, spec, bar)
	end
end

local function RefreshBars()
	ensureDefaults()
	HookEditModeState()
	wipeTable(hoverBars)

	for _, barKey in ipairs(BAR_ORDER) do
		local spec = getBarSpec(barKey)
		local bar = getBarFrame(spec)
		if bar then
			TrackBar(spec, bar)
		end
	end

	RefreshHoverState()
end

M.RefreshBars = RefreshBars

function M:ApplySettings()
	RefreshBars()
end

function M:ScheduleVisibilityReapply()
	if not (C_Timer and C_Timer.After) then
		return
	end
	C_Timer.After(0, RefreshHoverState)
	C_Timer.After(0.1, RefreshHoverState)
end

M.Constants = {
	BAR_ORDER = BAR_ORDER,
	BAR_SPECS = BAR_SPECS,
	DEFAULT_STYLE = DEFAULT_STYLE,
	VISIBILITY_MODE_VISIBLE = VISIBILITY_MODE_VISIBLE,
	VISIBILITY_MODE_FADE_OUT_OF_COMBAT = VISIBILITY_MODE_FADE_OUT_OF_COMBAT,
	VISIBILITY_MODE_FADE_IN_COMBAT = VISIBILITY_MODE_FADE_IN_COMBAT,
	VISIBILITY_MODE_FADE_ALWAYS = VISIBILITY_MODE_FADE_ALWAYS,
}

function M:GetBarSpec(barKey)
	return getBarSpec(barKey)
end

function M:GetBarEntry(barKey)
	return getBarEntry(barKey)
end

function M:CopyStyle(style)
	return copyStyle(style)
end
