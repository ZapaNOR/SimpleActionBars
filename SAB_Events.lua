local ADDON_NAME = ...
local M = _G[ADDON_NAME]
if not M then return end

SLASH_SIMPLEACTIONBARS1 = "/sab"
SLASH_SIMPLEACTIONBARS2 = "/simpleactionbars"
SlashCmdList["SIMPLEACTIONBARS"] = function(msg)
	msg = (msg or ""):lower()
	if msg == "" or msg == "settings" or msg == "config" or msg == "options" then
		if M.OpenSettings then
			M:OpenSettings()
		end
		return
	end
	if M.PrintSlashHelp then
		M:PrintSlashHelp()
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
eventFrame:RegisterEvent("PET_BAR_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		local addonName = arg1
		if addonName == ADDON_NAME then
			if M.EnsureDefaults then
				M:EnsureDefaults()
			end
			if M.CreateSettingsPanel then
				M:CreateSettingsPanel()
			end
			if M.RefreshBars then
				M:RefreshBars()
			end
		elseif addonName == "Blizzard_ActionBar" or addonName == "Blizzard_EditMode" then
			if M.RefreshBars then
				M:RefreshBars()
			end
		end
		return
	end

	if event == "PLAYER_LOGIN" then
		if M.EnsureDefaults then
			M:EnsureDefaults()
		end
		if M.CreateSettingsPanel then
			M:CreateSettingsPanel()
		end
		if M.RefreshBars then
			M:RefreshBars()
		end
		if M.PrintSlashHelp then
			M:PrintSlashHelp()
		end
		return
	end

	if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		if M.RefreshBars then
			M:RefreshBars()
		end
		if M.ScheduleVisibilityReapply then
			M:ScheduleVisibilityReapply()
		end
		return
	end

	if event == "EDIT_MODE_LAYOUTS_UPDATED" or event == "UPDATE_SHAPESHIFT_FORMS" or event == "PET_BAR_UPDATE" then
		if M.RefreshBars then
			M:RefreshBars()
		end
		if M.RefreshSettingsTab then
			M:RefreshSettingsTab()
		end
	end
end)
