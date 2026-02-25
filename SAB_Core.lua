local ADDON_NAME = ...
local M = _G[ADDON_NAME] or {}
_G[ADDON_NAME] = M

local ICON_ZOOM = 0.05
local ICON_ZOOM_MIN = 0
local ICON_ZOOM_MAX = 0.4
local HIDDEN_ALPHA = 0
local SHOWN_ALPHA = 1
local HOVER_LEAVE_DELAY = 0.03
local DEFAULT_BACKGROUND_ALPHA = 0.7

local Media = LibStub and LibStub("LibSharedMedia-3.0", true)

local FONT_FACE_DEFAULT = "__DEFAULT__"
local FONT_OUTLINE_DEFAULT = "default"
local FONT_SIZE_MIN = 0
local FONT_SIZE_MAX = 32
local TEXT_OFFSET_MIN = -200
local TEXT_OFFSET_MAX = 200

local LEGACY_FONT_FACE_MAP = {
	default = FONT_FACE_DEFAULT,
	friz = "Friz Quadrata TT",
	arial = "Arial Narrow",
	morpheus = "Morpheus",
	skurri = "Skurri",
}

local FONT_OUTLINE_FLAGS = {
	default = nil,
	none = "",
	outline = "OUTLINE",
	thick = "THICKOUTLINE",
	mono = "MONOCHROME",
	mono_outline = "OUTLINE,MONOCHROME",
	mono_thick = "THICKOUTLINE,MONOCHROME",
}

local FONT_OUTLINE_LABELS = {
	default = "Blizzard Default",
	none = "None",
	outline = "Outline",
	thick = "Thick Outline",
	mono = "Monochrome",
	mono_outline = "Outline + Monochrome",
	mono_thick = "Thick + Monochrome",
}

local FONT_OUTLINE_ORDER = {
	"default",
	"none",
	"outline",
	"thick",
	"mono",
	"mono_outline",
	"mono_thick",
}

local FONT_OUTLINE_KEYS = {}
for _, key in ipairs(FONT_OUTLINE_ORDER) do
	FONT_OUTLINE_KEYS[key] = true
end

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
	icon = {
		borderThickness = 2,
		borderColor = { r = 0, g = 0, b = 0, a = 1 },
		backgroundColor = { r = 0, g = 0, b = 0, a = DEFAULT_BACKGROUND_ALPHA },
		iconZoom = 0.15,
	},
	fontFace = "Expressway",
	keybind = {
		fontFace = "Expressway",
		fontSize = 16,
		fontColor = { r = 1, g = 1, b = 1, a = 1 },
		fontOutline = "outline",
		textShadow = false,
		xOffset = -3,
		yOffset = -3,
	},
	stacks = {
		fontFace = "Expressway",
		fontSize = 14,
		fontColor = { r = 1, g = 1, b = 1, a = 1 },
		fontOutline = "outline",
		textShadow = false,
		xOffset = -3,
		yOffset = 3,
	},
	macro = {
		fontFace = "Expressway",
		fontSize = 14,
		fontColor = { r = 1, g = 1, b = 1, a = 1 },
		fontOutline = "outline",
		textShadow = false,
		xOffset = 0,
		yOffset = 3,
	},
	hideMacroText = true,
}

local VISIBILITY_MODE_VISIBLE = "visible"
local VISIBILITY_MODE_FADE_OUT_OF_COMBAT = "fade"
local VISIBILITY_MODE_FADE_IN_COMBAT = "fade_combat"
local VISIBILITY_MODE_FADE_ALWAYS = "fade_always"

local hoverBars = {}
local hidePending = false
local editModeHooked = false
local blizzardButtonUpdateHooked = false
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
		return defaultValue and true or false
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

local function isValidMediaFont(fontName)
	if fontName == FONT_FACE_DEFAULT then
		return true
	end
	if type(fontName) ~= "string" or fontName == "" then
		return false
	end
	return Media and Media.IsValid and Media:IsValid("font", fontName) or false
end

local function sanitizeFontFace(fontFace, fallback)
	local fallbackFont = type(fallback) == "string" and fallback or FONT_FACE_DEFAULT
	local requestedFont = type(fontFace) == "string" and fontFace or fallbackFont

	local legacyMapped = LEGACY_FONT_FACE_MAP[requestedFont]
	if legacyMapped then
		requestedFont = legacyMapped
	end

	if isValidMediaFont(requestedFont) then
		return requestedFont
	end

	-- Preserve explicit non-empty selections even if media registration happens later.
	if type(requestedFont) == "string" and requestedFont ~= "" then
		return requestedFont
	end

	local fallbackMapped = LEGACY_FONT_FACE_MAP[fallbackFont]
	if fallbackMapped then
		fallbackFont = fallbackMapped
	end

	if isValidMediaFont(fallbackFont) then
		return fallbackFont
	end

	if type(fallbackFont) == "string" and fallbackFont ~= "" then
		return fallbackFont
	end

	return FONT_FACE_DEFAULT
end

local function resolveSharedFontFace(style, fallback)
	style = type(style) == "table" and style or {}
	fallback = type(fallback) == "table" and fallback or DEFAULT_STYLE

	local requested = style.fontFace
	if requested == nil and type(style.keybind) == "table" then
		requested = style.keybind.fontFace
	end
	if requested == nil and type(style.stacks) == "table" then
		requested = style.stacks.fontFace
	end
	if requested == nil and type(style.macro) == "table" then
		requested = style.macro.fontFace
	end

	local fallbackFont = fallback.fontFace
	if fallbackFont == nil and type(fallback.keybind) == "table" then
		fallbackFont = fallback.keybind.fontFace
	end
	if fallbackFont == nil and type(fallback.stacks) == "table" then
		fallbackFont = fallback.stacks.fontFace
	end
	if fallbackFont == nil and type(fallback.macro) == "table" then
		fallbackFont = fallback.macro.fontFace
	end

	return sanitizeFontFace(requested, fallbackFont or FONT_FACE_DEFAULT)
end

local function sanitizeIconStyle(iconStyle, fallbackIcon, legacyStyle)
	iconStyle = type(iconStyle) == "table" and iconStyle or {}
	fallbackIcon = type(fallbackIcon) == "table" and fallbackIcon or DEFAULT_STYLE.icon
	legacyStyle = type(legacyStyle) == "table" and legacyStyle or {}
	local borderThickness = iconStyle.borderThickness
	if borderThickness == nil then
		borderThickness = legacyStyle.borderThickness
	end
	if borderThickness == nil then
		borderThickness = fallbackIcon.borderThickness
	end

	return {
		borderThickness = math.floor(clamp(borderThickness, 0, 12)),
		borderColor = copyColor(iconStyle.borderColor or legacyStyle.borderColor, fallbackIcon.borderColor),
		backgroundColor = copyColor(iconStyle.backgroundColor or legacyStyle.backgroundColor, fallbackIcon.backgroundColor),
		iconZoom = clamp(iconStyle.iconZoom or legacyStyle.iconZoom or fallbackIcon.iconZoom or ICON_ZOOM, ICON_ZOOM_MIN, ICON_ZOOM_MAX),
	}
end

local function sanitizeTextStyle(textStyle, fallbackText, legacyStyle)
	textStyle = type(textStyle) == "table" and textStyle or {}
	fallbackText = type(fallbackText) == "table" and fallbackText or DEFAULT_STYLE.keybind
	legacyStyle = type(legacyStyle) == "table" and legacyStyle or {}

	local fontSize = textStyle.fontSize
	if fontSize == nil then
		fontSize = legacyStyle.fontSize
	end
	if fontSize == nil then
		fontSize = fallbackText.fontSize
	end

	local xOffset = textStyle.xOffset
	if xOffset == nil then
		xOffset = fallbackText.xOffset
	end

	local yOffset = textStyle.yOffset
	if yOffset == nil then
		yOffset = fallbackText.yOffset
	end

	return {
		fontFace = sanitizeFontFace(textStyle.fontFace or legacyStyle.fontFace, fallbackText.fontFace),
		fontSize = math.floor(clamp(fontSize, FONT_SIZE_MIN, FONT_SIZE_MAX)),
		fontColor = copyColor(textStyle.fontColor or legacyStyle.fontColor, fallbackText.fontColor),
		fontOutline = FONT_OUTLINE_KEYS[textStyle.fontOutline or legacyStyle.fontOutline]
			and (textStyle.fontOutline or legacyStyle.fontOutline)
			or fallbackText.fontOutline
			or FONT_OUTLINE_DEFAULT,
		textShadow = boolOrDefault(textStyle.textShadow, boolOrDefault(legacyStyle.textShadow, boolOrDefault(fallbackText.textShadow, true))),
		xOffset = clamp(xOffset, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX),
		yOffset = clamp(yOffset, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX),
	}
end

local function sanitizeStyle(style, fallback)
	fallback = type(fallback) == "table" and fallback or DEFAULT_STYLE
	style = type(style) == "table" and style or {}
	local sharedFontFace = resolveSharedFontFace(style, fallback)

	local keybind = sanitizeTextStyle(style.keybind, fallback.keybind, style)
	local stacks = sanitizeTextStyle(style.stacks, fallback.stacks, style)
	local macro = sanitizeTextStyle(style.macro, fallback.macro, style)
	keybind.fontFace = sharedFontFace
	stacks.fontFace = sharedFontFace
	macro.fontFace = sharedFontFace

	return {
		icon = sanitizeIconStyle(style.icon, fallback.icon, style),
		fontFace = sharedFontFace,
		keybind = keybind,
		stacks = stacks,
		macro = macro,
		hideMacroText = boolOrDefault(style.hideMacroText, boolOrDefault(fallback.hideMacroText, false)),
	}
end

local function copyStyle(style)
	return sanitizeStyle(style, DEFAULT_STYLE)
end

local function applyColorInPlace(target, source)
	target = type(target) == "table" and target or {}
	source = type(source) == "table" and source or {}
	target.r = source.r
	target.g = source.g
	target.b = source.b
	target.a = source.a
	return target
end

local function applyTextStyleInPlace(target, source)
	target = type(target) == "table" and target or {}
	source = type(source) == "table" and source or {}
	target.fontFace = source.fontFace
	target.fontSize = source.fontSize
	target.fontOutline = source.fontOutline
	target.textShadow = source.textShadow
	target.xOffset = source.xOffset
	target.yOffset = source.yOffset
	target.fontColor = applyColorInPlace(target.fontColor, source.fontColor)
	return target
end

local function applyStyleInPlace(target, source)
	target = type(target) == "table" and target or {}
	source = type(source) == "table" and source or {}

	target.icon = type(target.icon) == "table" and target.icon or {}
	target.icon.borderThickness = source.icon and source.icon.borderThickness or DEFAULT_STYLE.icon.borderThickness
	target.icon.iconZoom = source.icon and source.icon.iconZoom or DEFAULT_STYLE.icon.iconZoom
	target.icon.borderColor = applyColorInPlace(target.icon.borderColor, source.icon and source.icon.borderColor or DEFAULT_STYLE.icon.borderColor)
	target.icon.backgroundColor = applyColorInPlace(target.icon.backgroundColor, source.icon and source.icon.backgroundColor or DEFAULT_STYLE.icon.backgroundColor)

	target.fontFace = source.fontFace or DEFAULT_STYLE.fontFace or FONT_FACE_DEFAULT
	target.keybind = applyTextStyleInPlace(target.keybind, source.keybind or DEFAULT_STYLE.keybind)
	target.stacks = applyTextStyleInPlace(target.stacks, source.stacks or DEFAULT_STYLE.stacks)
	target.macro = applyTextStyleInPlace(target.macro, source.macro or DEFAULT_STYLE.macro)
	target.keybind.fontFace = target.fontFace
	target.stacks.fontFace = target.fontFace
	target.macro.fontFace = target.fontFace
	target.hideMacroText = boolOrDefault(source.hideMacroText, DEFAULT_STYLE.hideMacroText)

	return target
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

local function getLegacyStyle(db)
	if type(db) ~= "table" or type(db.bars) ~= "table" then
		return nil
	end

	local main = db.bars.main
	if type(main) == "table" and type(main.style) == "table" then
		return main.style
	end

	for _, barKey in ipairs(BAR_ORDER) do
		local entry = db.bars[barKey]
		if type(entry) == "table" and type(entry.style) == "table" then
			return entry.style
		end
	end

	return nil
end

local function ensureDefaults()
	SimpleActionBarsDB = SimpleActionBarsDB or {}
	SimpleActionBarsDB.bars = type(SimpleActionBarsDB.bars) == "table" and SimpleActionBarsDB.bars or {}
	local rawStyle = type(SimpleActionBarsDB.style) == "table" and SimpleActionBarsDB.style or getLegacyStyle(SimpleActionBarsDB) or {}
	local sanitizedStyle = sanitizeStyle(rawStyle, DEFAULT_STYLE)
	SimpleActionBarsDB.style = applyStyleInPlace(rawStyle, sanitizedStyle)

	for _, barKey in ipairs(BAR_ORDER) do
		local spec = getBarSpec(barKey)
		if spec then
			local entry = SimpleActionBarsDB.bars[barKey]
			if type(entry) ~= "table" then
				entry = {}
				SimpleActionBarsDB.bars[barKey] = entry
			end

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
	if not M.DB then
		ensureDefaults()
	end
	local style = M.DB and M.DB.style
	if type(style) == "table" then
		return style
	end
	return DEFAULT_STYLE
end

local function ResolveButtonStyle(button)
	if not button then
		return DEFAULT_STYLE
	end
	local style = getEffectiveStyle(button._simpleActionBarsBarKey)
	if type(style) ~= "table" then
		return DEFAULT_STYLE
	end
	return style
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

local function ApplyIconZoom(icon, zoom)
	if not icon then
		return
	end
	local inset = clamp(zoom or ICON_ZOOM, ICON_ZOOM_MIN, ICON_ZOOM_MAX) * 0.5
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

local function CollectCooldownFrames(button)
	local frames = {}
	local seen = {}

	local function add(frame, kind)
		if frame and frame.ClearAllPoints and frame.SetPoint and not seen[frame] then
			seen[frame] = true
			frame._simpleActionBarsCooldownKind = kind
			frames[#frames + 1] = frame
		end
	end

	add(button and button.cooldown, "main")
	add(button and button.Cooldown, "main")
	add(button and button.chargeCooldown, "charge")
	add(button and button.ChargeCooldown, "charge")
	add(button and button.lossOfControlCooldown, "loc")
	add(button and button.LossOfControlCooldown, "loc")

	local buttonName = button and button.GetName and button:GetName()
	if buttonName then
		add(_G[buttonName .. "Cooldown"], "main")
		add(_G[buttonName .. "ChargeCooldown"], "charge")
		add(_G[buttonName .. "LossOfControlCooldown"], "loc")
	end

	return frames
end

local function GetCooldownFrames(button)
	if not button then
		return {}
	end
	local cached = button._simpleActionBarsCooldownFrames
	if cached and #cached > 0 then
		return cached
	end
	local frames = CollectCooldownFrames(button)
	if #frames > 0 then
		button._simpleActionBarsCooldownFrames = frames
	end
	return frames
end

local function ApplyCooldownBounds(button, icon, pad)
	local cooldownFrames = GetCooldownFrames(button)
	for i = 1, #cooldownFrames do
		local cooldown = cooldownFrames[i]
		local framePad = pad
		if cooldown._simpleActionBarsCooldownKind == "charge" then
			framePad = 0
		end
		cooldown:ClearAllPoints()
		cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", -framePad, framePad)
		cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", framePad, -framePad)
	end
end

local function ApplyFontDefinition(fontString, textStyle)
	if not fontString or not fontString.GetFont or not fontString.SetFont then
		return
	end

	local currentPath, currentSize, currentFlags = fontString:GetFont()
	local path = currentPath
	if textStyle.fontFace ~= FONT_FACE_DEFAULT and Media and Media.Fetch then
		local fetchedPath = Media:Fetch("font", textStyle.fontFace, true)
		if fetchedPath then
			path = fetchedPath
		end
	end
	local size = textStyle.fontSize and textStyle.fontSize > 0 and textStyle.fontSize or currentSize or 10
	local flags = FONT_OUTLINE_FLAGS[textStyle.fontOutline]
	if flags == nil then
		flags = currentFlags or ""
	end

	if path then
		fontString:SetFont(path, size, flags)
	end
end

local function ApplyFontShadow(fontString, textStyle)
	if not fontString then
		return
	end
	if not fontString._simpleActionBarsShadowCaptured then
		fontString._simpleActionBarsShadowCaptured = true
		if fontString.GetShadowColor then
			local r, g, b, a = fontString:GetShadowColor()
			fontString._simpleActionBarsShadowColor = { r or 0, g or 0, b or 0, a == nil and 1 or a }
		end
		if fontString.GetShadowOffset then
			local x, y = fontString:GetShadowOffset()
			fontString._simpleActionBarsShadowOffset = { x or 1, y or -1 }
		end
	end

	if textStyle.textShadow then
		if fontString.SetShadowColor then
			local color = fontString._simpleActionBarsShadowColor
			if not color or (color[4] or 0) <= 0.01 then
				color = { 0, 0, 0, 1 }
			end
			fontString:SetShadowColor(color[1], color[2], color[3], color[4])
		end
		if fontString.SetShadowOffset then
			local offset = fontString._simpleActionBarsShadowOffset
			if not offset or (math.abs(offset[1] or 0) <= 0.01 and math.abs(offset[2] or 0) <= 0.01) then
				offset = { 1, -1 }
			end
			fontString:SetShadowOffset(offset[1], offset[2])
		end
	else
		if fontString.SetShadowColor then
			fontString:SetShadowColor(0, 0, 0, 0)
		end
		if fontString.SetShadowOffset then
			fontString:SetShadowOffset(0, 0)
		end
	end
end

local function ApplyFontToText(fontString, textStyle)
	ApplyFontDefinition(fontString, textStyle)

	if not fontString then
		return
	end

	if fontString.SetTextColor then
		local color = textStyle.fontColor or { r = 1, g = 1, b = 1, a = 1 }
		fontString:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
	end

	ApplyFontShadow(fontString, textStyle)
end

local function CollectCooldownTextLabels(cooldown)
	local labels = {}
	local seen = {}

	local function addLabel(label)
		if label and label.GetObjectType and label:GetObjectType() == "FontString" and label.GetFont and label.SetFont and not seen[label] then
			seen[label] = true
			labels[#labels + 1] = label
		end
	end

	local function addRegions(frame)
		if not (frame and frame.GetRegions) then
			return
		end
		local regions = { frame:GetRegions() }
		for i = 1, #regions do
			addLabel(regions[i])
		end
	end

	addLabel(cooldown and cooldown.text)
	addLabel(cooldown and cooldown.Text)
	addLabel(cooldown and cooldown.timerText)
	addLabel(cooldown and cooldown.TimerText)
	addRegions(cooldown)

	if cooldown and cooldown.GetChildren then
		local children = { cooldown:GetChildren() }
		for i = 1, #children do
			local child = children[i]
			addLabel(child)
			addRegions(child)
		end
	end

	return labels
end

local function GetCooldownTextLabels(cooldown)
	if not cooldown then
		return {}
	end
	local cached = cooldown._simpleActionBarsTextLabels
	if cached and #cached > 0 then
		return cached
	end
	local labels = CollectCooldownTextLabels(cooldown)
	if #labels > 0 then
		cooldown._simpleActionBarsTextLabels = labels
	end
	return labels
end

local function ApplyCooldownTextFontToFrame(cooldown, textStyle)
	if not cooldown then
		return
	end
	local labels = GetCooldownTextLabels(cooldown)
	for i = 1, #labels do
		ApplyFontDefinition(labels[i], textStyle)
		ApplyFontShadow(labels[i], textStyle)
	end
end

local function ApplyCooldownTextFont(button, style)
	if not button or not style then
		return
	end

	local cooldownFrames = GetCooldownFrames(button)
	for i = 1, #cooldownFrames do
		local cooldown = cooldownFrames[i]
		cooldown._simpleActionBarsOwnerButton = button
		ApplyCooldownTextFontToFrame(cooldown, style.keybind)

		if not cooldown._simpleActionBarsFontHooked then
			cooldown._simpleActionBarsFontHooked = true

			local function reapply(frame)
				local ownerButton = frame and frame._simpleActionBarsOwnerButton
				if not ownerButton then
					return
				end
				local currentStyle = ResolveButtonStyle(ownerButton)
				ApplyCooldownTextFontToFrame(frame, currentStyle.keybind)
			end

			if cooldown.HookScript then
				cooldown:HookScript("OnShow", reapply)
			end

			if hooksecurefunc and cooldown.SetCooldown then
				hooksecurefunc(cooldown, "SetCooldown", reapply)
			end
		end
	end
end

local function ApplyTextPlacement(label, button, point, relativePoint, xOffset, yOffset)
	if not (label and label.ClearAllPoints and label.SetPoint and button) then
		return
	end
	label:ClearAllPoints()
	label:SetPoint(point, button, relativePoint, xOffset or 0, yOffset or 0)
end

local function ResolveMacroTextLabel(button)
	if not button then
		return nil
	end
	local label = button.Name or button.name
	if label then
		return label
	end
	local buttonName = button.GetName and button:GetName()
	if not buttonName then
		return nil
	end
	return _G[buttonName .. "Name"]
end

local function ApplyButtonFontStyle(button, style)
	if not button then
		return
	end

	local buttonName = button.GetName and button:GetName()
	local keybindLabel = button.HotKey or button.hotkey
	local stacksLabel = button.Count or button.count
	local macroLabel = ResolveMacroTextLabel(button)

	if buttonName then
		keybindLabel = keybindLabel or _G[buttonName .. "HotKey"]
		stacksLabel = stacksLabel or _G[buttonName .. "Count"]
	end

	if macroLabel and macroLabel.HookScript and not macroLabel._simpleActionBarsMacroShowHooked then
		macroLabel._simpleActionBarsMacroShowHooked = true
		macroLabel._simpleActionBarsOwnerButton = button
		macroLabel:HookScript("OnShow", function(label)
			local ownerButton = label._simpleActionBarsOwnerButton
			if not ownerButton then
				return
			end
			local currentStyle = ResolveButtonStyle(ownerButton)
			ApplyFontToText(label, currentStyle.macro)
			ApplyTextPlacement(label, ownerButton, "BOTTOM", "BOTTOM", currentStyle.macro.xOffset, currentStyle.macro.yOffset)
			if currentStyle.hideMacroText then
				label:SetAlpha(0)
				label:Hide()
			else
				label:SetAlpha(1)
				if label.Show and label.GetText and (label:GetText() or "") ~= "" then
					label:Show()
				end
			end
		end)
	end

	if keybindLabel then
		ApplyFontToText(keybindLabel, style.keybind)
		ApplyTextPlacement(keybindLabel, button, "TOPRIGHT", "TOPRIGHT", style.keybind.xOffset, style.keybind.yOffset)
	end

	if stacksLabel then
		ApplyFontToText(stacksLabel, style.stacks)
		ApplyTextPlacement(stacksLabel, button, "BOTTOMRIGHT", "BOTTOMRIGHT", style.stacks.xOffset, style.stacks.yOffset)
	end

	if macroLabel then
		ApplyFontToText(macroLabel, style.macro)
		ApplyTextPlacement(macroLabel, button, "BOTTOM", "BOTTOM", style.macro.xOffset, style.macro.yOffset)
		if style.hideMacroText then
			macroLabel:SetAlpha(0)
			if macroLabel.Hide then
				macroLabel:Hide()
			end
		else
			macroLabel:SetAlpha(1)
			if macroLabel.Show and macroLabel.GetText and (macroLabel:GetText() or "") ~= "" then
				macroLabel:Show()
			end
		end
	end
end

local function ApplySlotStyle(button, iconStyle)
	local icon, bg = EnsureSlotVisual(button)
	if not icon or not bg then
		return
	end

	local thickness = math.floor(clamp(iconStyle.borderThickness, 0, 12))
	local borderColor = iconStyle.borderColor
	local bgColor = iconStyle.backgroundColor
	local pad = math.max(1, thickness)

	bg:ClearAllPoints()
	bg:SetPoint("TOPLEFT", icon, "TOPLEFT", -pad, pad)
	bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", pad, -pad)
	bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
	ApplyCooldownBounds(button, icon, pad)

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

local function ApplyButtonDynamicStyle(button, style)
	if not (button and style) then
		return
	end
	ApplyIconZoom(button.icon or button.Icon, style.icon.iconZoom)
	ApplyButtonFontStyle(button, style)
	ApplyCooldownTextFont(button, style)
end

local function ApplyButtonCurrentStyle(button)
	if not button then return end
	local style = ResolveButtonStyle(button)
	ApplySlotStyle(button, style.icon)
	ApplyButtonDynamicStyle(button, style)
end

local function OnStyledButtonShow(button)
	if not button then return end
	RemoveIconMask(button)
	StripDefaultButtonArt(button)
	ApplyButtonCurrentStyle(button)
end

local function HookBlizzardButtonUpdateFunctions()
	if blizzardButtonUpdateHooked then
		return
	end

	local function reapplyStyle(button)
		if not button or not button._simpleActionBarsBarKey then
			return
		end
		local style = ResolveButtonStyle(button)
		ApplyButtonDynamicStyle(button, style)
	end

	local updateFunctions = {
		"ActionButton_Update",
		"ActionButton_UpdateText",
		"PetActionButton_Update",
		"StanceButton_Update",
	}

	for i = 1, #updateFunctions do
		local functionName = updateFunctions[i]
		if type(_G[functionName]) == "function" then
			hooksecurefunc(functionName, reapplyStyle)
		end
	end

	local mixinHooks = {
		{ mixin = _G.ActionBarActionButtonMixin, method = "Update" },
		{ mixin = _G.ActionBarActionButtonMixin, method = "UpdateText" },
		{ mixin = _G.ActionBarActionButtonMixin, method = "UpdateHotkeys" },
		{ mixin = _G.PetActionButtonMixin, method = "Update" },
		{ mixin = _G.PetActionButtonMixin, method = "UpdateText" },
		{ mixin = _G.StanceButtonMixin, method = "Update" },
	}

	for i = 1, #mixinHooks do
		local entry = mixinHooks[i]
		if entry.mixin and type(entry.mixin[entry.method]) == "function" then
			hooksecurefunc(entry.mixin, entry.method, function(button)
				reapplyStyle(button)
			end)
		end
	end

	blizzardButtonUpdateHooked = true
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
	HookBlizzardButtonUpdateFunctions()
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
	FONT_FACE_DEFAULT = FONT_FACE_DEFAULT,
	FONT_OUTLINE_DEFAULT = FONT_OUTLINE_DEFAULT,
	FONT_SIZE_MIN = FONT_SIZE_MIN,
	FONT_SIZE_MAX = FONT_SIZE_MAX,
	ICON_ZOOM_MIN = ICON_ZOOM_MIN,
	ICON_ZOOM_MAX = ICON_ZOOM_MAX,
	TEXT_OFFSET_MIN = TEXT_OFFSET_MIN,
	TEXT_OFFSET_MAX = TEXT_OFFSET_MAX,
	FONT_OUTLINE_LABELS = FONT_OUTLINE_LABELS,
	FONT_OUTLINE_ORDER = FONT_OUTLINE_ORDER,
}

function M:GetBarSpec(barKey)
	return getBarSpec(barKey)
end

function M:GetBarEntry(barKey)
	return getBarEntry(barKey)
end

function M:GetStyle()
	if not M.DB then
		ensureDefaults()
	end
	return M.DB and M.DB.style
end

function M:CopyStyle(style)
	return copyStyle(style)
end
