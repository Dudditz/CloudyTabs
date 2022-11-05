--[[
	Cloudy TradeSkill
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local numTabs = 0
local searchTxt = ''
local filterMats, filterSkill
local skinUI, loadedUI
local function InitDB()
	-- Create new DB if needed --
	if (not CTradeSkillDB) then
		CTradeSkillDB = {}
		CTradeSkillDB['Size'] = 30
		CTradeSkillDB['Fade'] = true
		CTradeSkillDB['Unlock'] = false
		CTradeSkillDB['Level'] = true
	end
	if not CTradeSkillDB['Tabs'] then CTradeSkillDB['Tabs'] = {} end

	-- Load UI addons --
	if IsAddOnLoaded('Aurora') then
		skinUI = 'Aurora'
		loadedUI = unpack(Aurora)
	elseif IsAddOnLoaded('ElvUI') then
		skinUI = 'ElvUI'
		loadedUI = unpack(ElvUI):GetModule('Skins')
	end
end


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyTradeSkill')
f:RegisterEvent('PLAYER_LOGIN')
f:RegisterEvent('TRADE_SKILL_LIST_UPDATE')
f:RegisterEvent('TRADE_SKILL_DATA_SOURCE_CHANGED')

	--- Check Current Tab ---
	local function isCurrentTab(self)
		if self.tooltip and IsCurrentSpell(self.tooltip) then
			if ProfessionsFrame:IsShown() and (self.isSub == 0) then
				CTradeSkillDB['Panel'] = C_TradeSkillUI.GetBaseProfessionInfo()
				--restoreFilters()
			end
			self:SetChecked(true)
			--self:RegisterForClicks()
		else
			self:SetChecked(false)
			self:RegisterForClicks('AnyUp')
		end
	end

	--- Add Tab Button ---
	local function addTab(id, index, isSub)
		local name, icon, tabType
		if (id == 134020) then
			name, icon = select(2, C_ToyBox.GetToyInfo(134020))
			tabType = 'toy'
		else	
			if (id == 127652) then
			name, icon = select(2, C_ToyBox.GetToyInfo(127652))
			tabType = 'toy'
		else	
			if (id == 153039) then
			name, icon = select(2, C_ToyBox.GetToyInfo(153039))
			tabType = 'toy'
		else	
			if (id == 163211) then
			name, icon = select(2, C_ToyBox.GetToyInfo(163211))
			tabType = 'toy'
		else
			name, _, icon = GetSpellInfo(id)
			if (id == 126462) then
				tabType = 'item'
			else
				tabType = 'spell'
			end
		end
		end
		end
		end
		if (not name) or (not icon) then return end

		local tab = _G['CTradeSkillTab' .. index] or CreateFrame('CheckButton', 'CTradeSkillTab' .. index, ProfessionsFrame, 'SpellBookSkillLineTabTemplate, SecureActionButtonTemplate')
		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('TRADE_SKILL_SHOW')
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab.id = id
		tab.isSub = isSub
		tab.tooltip = name
		tab:SetNormalTexture(icon)
		tab:SetAttribute('type', tabType)
		tab:SetAttribute(tabType, name)

		if skinUI and not tab.skinned then
			local checkedTexture
			if (skinUI == 'Aurora') then
				checkedTexture = 'Interface\\AddOns\\Aurora\\media\\CheckButtonHilight'
			elseif (skinUI == 'ElvUI') then
				checkedTexture = tab:CreateTexture(nil, 'HIGHLIGHT')
				checkedTexture:SetColorTexture(1, 1, 1, 0.3)
				checkedTexture:SetInside()
				--tab:SetHighlightTexture()
			end
			tab:SetCheckedTexture(checkedTexture)
			tab:GetNormalTexture():SetTexCoord(.08, .92, .08, .92)
			tab:GetRegions():Hide()
			tab.skinned = true
		end

		isCurrentTab(tab)
		tab:Show()
	end

	--- Remove Tab Buttons ---
	local function removeTabs()
		for i = 1, numTabs do
			local tab = _G['CTradeSkillTab' .. i]
			if tab and tab:IsShown() then
				tab:UnregisterEvent('TRADE_SKILL_SHOW')
				tab:UnregisterEvent('CURRENT_SPELL_CAST_CHANGED')
				tab:Hide()
			end
		end
	end

	--- Sort Tabs ---
	local function sortTabs()
		local index = 1
		for i = 1, numTabs do
			local tab = _G['CTradeSkillTab' .. i]
			if tab then
				if CTradeSkillDB['Tabs'][tab.id] == true then
					tab:SetPoint('TOPLEFT', ProfessionsFrame, 'TOPRIGHT', skinUI and 1 or 0, (-44 * index) + (-40 * tab.isSub))
					tab:Show()
					index = index + 1
				--else
					--tab:Hide()
				end
			end
		end
	end

	--- Check Profession Useable ---
	local function isUseable(id)
		local name = GetSpellInfo(id)
		return IsUsableSpell(name)
	end

	--- Update Profession Tabs ---
	local function updateTabs(init)
		if init and CTradeSkillDB['Panel'] then return end
		local mainTabs, subTabs = {}, {}

		local _, class = UnitClass('player')
		if class == 'DEATHKNIGHT' and isUseable(53428) then
			tinsert(mainTabs, 53428) --RuneForging
		elseif class == 'ROGUE' and isUseable(1804) then
			tinsert(subTabs, 1804) --PickLock
		end

		if C_ToyBox.IsToyUsable(134020) then
			tinsert(subTabs, 134020) --ChefHat
		end
		if C_ToyBox.IsToyUsable(127652) then
			tinsert(subTabs, 127652) --Felflame Campfire
		end
		if C_ToyBox.IsToyUsable(153039) then
			tinsert(subTabs, 153039) --Crystalline Campfire
		end
		if C_ToyBox.IsToyUsable(163211) then
			tinsert(subTabs, 163211) --Akunda's Fire Sticks
		end
		if GetItemCount(87216) ~= 0 then
			tinsert(subTabs, 126462) --ThermalAnvil
		end

		local prof1, prof2, arch, fishing, cooking = GetProfessions()
		local profs = {prof1, prof2, cooking}
		for _, prof in pairs(profs) do
			local num, offset, line, _, _, spec = select(5, GetProfessionInfo(prof))
			if (spec and spec ~= 0) then num = 1 end
			for i = 1, num do
				if not IsPassiveSpell(offset + i, BOOKTYPE_PROFESSION) then
					local _, id = GetSpellBookItemInfo(offset + i, BOOKTYPE_PROFESSION)
					if (i == 1) then
						tinsert(mainTabs, id)
						if init and not CTradeSkillDB['Panel'] then
							CTradeSkillDB['Panel'] = line
							return
						end
					else
						tinsert(subTabs, id)
					end
				end
			end
		end

		local sameTabs = true
		for i = 1, #mainTabs + #subTabs do
			local id = mainTabs[i] or subTabs[i - #mainTabs]
			if CTradeSkillDB['Tabs'][id] == nil then
				CTradeSkillDB['Tabs'][id] = true
				sameTabs = false
			end
		end

		if not sameTabs or (numTabs ~= #mainTabs + #subTabs) then
			removeTabs()
			numTabs = #mainTabs + #subTabs

			for i = 1, numTabs do
				local id = mainTabs[i] or subTabs[i - #mainTabs]
				addTab(id, i, mainTabs[i] and 0 or 1)
			end
			sortTabs()
		end
	end

--- Force ESC Close ---
hooksecurefunc('ToggleGameMenu', function()
	if CTradeSkillDB['Unlock'] and ProfessionsFrame:IsShown() then
		C_TradeSkillUI.CloseTradeSkill()
		HideUIPanel(GameMenuFrame)
	end
end)

--- Create Option Menu ---
local function createOptions()
	--- Dropdown Menu ---
	local function CTSDropdown_Init(self, level)
		local info = UIDropDownMenu_CreateInfo()
		if level == 1 then
			info.text = f:GetName()
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info.isTitle = false
			info.disabled = false
			info.isNotRadio = true
			info.notCheckable = false
			info.keepShownOnClick = true

			info.text = 'UI ' .. ACTION_SPELL_AURA_REMOVED_BUFF
			info.func = function()
				CTradeSkillDB['Fade'] = not CTradeSkillDB['Fade']
				fadeState()
			end

			info.func = nil
			info.checked = 	nil
			info.notCheckable = true
			info.hasArrow = true

			info.text = PRIMARY
			info.value = 1
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level)

			info.text = SECONDARY
			info.value = 2
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level)
		elseif level == 2 then
			info.isNotRadio = true
			info.keepShownOnClick = true
			if UIDROPDOWNMENU_MENU_VALUE == 1 then
				for i = 1, numTabs do
					local tab = _G['CTradeSkillTab' .. i]
					if tab and (tab.isSub == 0) then
						info.text = tab.tooltip
						info.func = function()
							CTradeSkillDB['Tabs'][tab.id] = not CTradeSkillDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = CTradeSkillDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
				for i = 1, numTabs do
					local tab = _G['CTradeSkillTab' .. i]
					if tab and (tab.isSub == 1) then
						info.text = tab.tooltip
						info.func = function()
							CTradeSkillDB['Tabs'][tab.id] = not CTradeSkillDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = CTradeSkillDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end
	end
	local menu = CreateFrame('Frame', 'CTSDropdown', nil, 'UIDropDownMenuTemplate')
	UIDropDownMenu_Initialize(CTSDropdown, CTSDropdown_Init, 'MENU')

	--- Option Button ---
	local button = CreateFrame('Button', 'CTSOption', ProfessionsFrame.CloseButton, 'UIMenuButtonStretchTemplate')
	button:SetScript('OnClick', function(self) ToggleDropDownMenu(1, nil, CTSDropdown, self, 2, -6) end)
	button:SetPoint('RIGHT', ProfessionsFrame.CloseButton, 'LEFT', -8, 0)
	button:SetText(GAMEOPTIONS_MENU)
	button:SetSize(80, 22)
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetPoint('RIGHT')
	button.Icon:Hide()

	if (skinUI == 'Aurora') then
		loadedUI.ReskinFilterButton(button)
	elseif (skinUI == 'ElvUI') then
		button:StripTextures(true)
		button:CreateBackdrop('Default', true)
		button.backdrop:SetAllPoints()
	end
end


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		InitDB()
		updateTabs(true)
		createOptions()
		
	elseif (event == 'TRADE_SKILL_DATA_SOURCE_CHANGED') then
		if not InCombatLockdown() then
			updateTabs()
		end
	end
end)
