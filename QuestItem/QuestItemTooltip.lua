----------------------------------------------------------
-- Add tooltip information to the existing GameTooltip
----------------------------------------------------------
----------------------------------------------------------
function QuestItem_AddTooltip(frame, name, link, quantity, itemCount)
	--QuestItem_OldTooltip(frame, name, link, quality, itemCount);
	if(QuestItem_Settings["Enabled"] == nil or QuestItem_Settings["Enabled"] == false) then
		return;
	end
	
	local tooltip = frame;
	local embed = true;
    if ( not tooltip ) then
		return;
    end
	
    local tooltipInfo = QuestItem_ScanTooltip(frame);
    if ( tooltipInfo[1] ) then
		-- Item not found in the database - look for it of it is a quest item
		if(not QuestItems[name] or QuestItem_SearchString(QuestItems[name].QuestName, QUESTITEM_UNIDENTIFIED) ) then
			-- Check if the item is a Quest Item
			if(QuestItem_IsQuestItem(tooltip) ) then
				local name = tooltipInfo[1].left;

				local QuestName, total, count, texture = QuestItem_FindQuest(name);
				if(not QuestName) then
					QuestItem_UpdateItem(name, QUESTITEM_UNIDENTIFIED, quantity, 0, 3)
				else
					QuestItem_UpdateItem(name, QuestName, count, total, 0)
				end
			end
		end
		-- Quest was found in the database
		if(QuestItems[name]) then
			-- There is data for the current player
			if(QuestItems[name][UnitName("player")]) then
				-- Total and Count is set, and is grater than 0 - don't want to display i.e 1/0
				if( (QuestItems[name].Total and QuestItems[name].Total > 0) and (QuestItems[name][UnitName("player")].Count and QuestItems[name][UnitName("player")].Count > 0) ) then
					tooltip:AddLine(QuestItems[name].QuestName .. " " .. QuestItems[name][UnitName("player")].Count .. "/" .. QuestItems[name].Total, 0.4, 0.5, 0.8);
				else
					tooltip:AddLine(QuestItems[name].QuestName, 0.4, 0.5, 0.8);
				end
				
				-- Check status for quest - if it can't be found change status to abandoned/complete
				if(QuestItems[name][UnitName("player")].QuestStatus ~= 0) then
					if(not QuestItem_FindQuest(name)) then
						QuestItems[name][UnitName("player")].QuestStatus = 1;
					end
				end
				-- Do not display status on the quest if it is unidentified
				if(not QuestItem_SearchString(QuestItems[name].QuestName, QUESTITEM_UNIDENTIFIED) ) then
					-- Display quest status
					if(QuestItems[name][UnitName("player")].QuestStatus == 0) then
						tooltip:AddLine(QUESTITEM_QUESTACTIVE, 0, 1, 0);
					elseif(QuestItems[name][UnitName("player")].QuestStatus == 1 or QuestItems[name][UnitName("player")].QuestStatus == 2) then
						tooltip:AddLine(QUESTITEM_COMPLETEABANDONED, 0.7, 0.7, 07);
					end
				end
			else
				tooltip:AddLine(QuestItems[name].QuestName, 0.4, 0.5, 0.8);
			end
			tooltip:Show();
		end
	end
end

local base_ContainerFrameItemButton_OnEnter;
local base_Chat_OnHyperlinkShow;
local base_GameTooltip_SetLootItem;
local base_ContainerFrame_Update;
local base_GameTooltip_SetInventoryItem;
local base_AIOI_ModifyItemTooltip;
local base_LootLinkItemButton_OnEnter;
local base_IMInv_ItemButton_OnEnter
local base_ItemsMatrixItemButton_OnEnter;

----------------------------------
-- [[ Hook tooltip functions ]] --
----------------------------------
function QuestItem_HookTooltip()

	-- Hook in alternative Chat/Hyperlinking code
	base_Chat_OnHyperlinkShow = ChatFrame_OnHyperlinkShow;
	ChatFrame_OnHyperlinkShow = QuestItem_Chat_OnHyperlinkShow;
		
	-- ContainerFrame
	base_ContainerFrameItemButton_OnEnter = ContainerFrameItemButton_OnEnter;
	ContainerFrameItemButton_OnEnter = QuestItem_ContainerFrameItemButton_OnEnter;
	base_ContainerFrame_Update = ContainerFrame_Update;
	ContainerFrame_Update = QuestItem_ContainerFrameItemButton_Update;

	base_GameTooltip_SetLootItem = GameTooltip.SetLootItem;
	GameTooltip.SetLootItem = QuestItem_GameTooltip_SetLootItem;
	
	base_GameTooltip_SetInventoryItem = GameTooltip.SetInventoryItem;
	GameTooltip.SetInventoryItem = QuestItem_GameTooltip_SetInventoryItem;

	--[[ LootLink support - grabbed from Norganna's EnhTooltip ]]--
	-- Hook the LootLink tooltip function
	if(LootLinkItemButton_OnEnter ~= nil) then
		base_LootLinkItemButton_OnEnter = LootLinkItemButton_OnEnter;
		LootLinkItemButton_OnEnter = QuestItem_LootLinkItemButton_OnEnter;
		QuestItem_Debug("Hooking to LootLink");
	end
	
	--[[ AllInOneInventory support - grabbed from Norganna's EnhTooltip ]]--
	if (AllInOneInventory_ModifyItemTooltip ~= nil) then
		base_AIOI_ModifyItemTooltip = AllInOneInventory_ModifyItemTooltip;
		AllInOneInventory_ModifyItemTooltip = QuestItem_AIOI_ModifyItemTooltip;
		QuestItem_Debug("Hooking to AIOI");
	end
end

--[[ LootLink support - grabbed from Norganna's EnhTooltip ]]--
function QuestItem_getLootLinkLink(name)
	local itemLink = ItemLinks[name];
	if (itemLink and itemLink.c and itemLink.i and LootLink_CheckItemServer(itemLink, QuestItem_getLootLinkServer())) then
		local item = string.gsub(itemLink.i, "(%d+):(%d+):(%d+):(%d+)", "%1:0:%3:%4");
		local link = "|c"..itemLink.c.."|Hitem:"..item.."|h["..name.."]|h|r";
		return link;
	end
	return nil;
end

function QuestItem_getLootLinkServer()
	return LootLinkState.ServerNamesToIndices[GetCVar("realmName")];
end

--[[ LootLink support - grabbed from Norganna's EnhTooltip ]]--
function QuestItem_LootLinkItemButton_OnEnter()
	base_LootLinkItemButton_OnEnter();

	local name = this:GetText();
	local link = QuestItem_getLootLinkLink(name);
	if (link) then
		local quality = QuestItem_qualityFromLink(link);
		QuestItem_AddTooltip(LootLinkTooltip, name, link, quality, 0)
	end
end

--------------------------------------------------
-- [[ Hook up with AllInOneInventory tooltip ]] --
--------------------------------------------------
function QuestItem_AIOI_ModifyItemTooltip(bag, slot, tooltipName)
	base_AIOI_ModifyItemTooltip(bag, slot, tooltipName);

	local tooltip = getglobal(tooltipName);
	if (not tooltip) then
		tooltip = getglobal("GameTooltip");
	end
	
	if (not tooltip) then 
		return false; 
	end

	local link = GetContainerItemLink(bag, slot);
	local name = QuestItem_nameFromLink(link);
	if (name) then
		local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot);
		if (quality == nil) then 
			quality = QuestItem_qualityFromLink(link); 
		end
		QuestItem_AddTooltip(GameTooltip, name, link, itemCount, 0)
	end
end
--------------------------------------
-- [[ Set tooltip for bank items ]] --
--------------------------------------
function QuestItem_GameTooltip_SetInventoryItem(this, unit, slot)
	local hasItem, hasCooldown, repairCost = base_GameTooltip_SetInventoryItem(this, unit, slot);

	local link = GetInventoryItemLink(unit, slot);
	if (link) then
		local name = QuestItem_nameFromLink(link);
		local quantity = GetInventoryItemCount(unit, slot);
		local quality = GetInventoryItemQuality(unit, slot);
		if (quality == nil) 
			then quality = QuestItem_qualityFromLink(link); 
		end
		QuestItem_AddTooltip(GameTooltip, name, link, quality, quantity)
	end
	return hasItem, hasCooldown, repairCost;
end

--------------------------------------
-- [[ Set tooltip for loot items ]] --
--------------------------------------
function QuestItem_GameTooltip_SetLootItem(this, slot)
	base_GameTooltip_SetLootItem(this, slot);
	local link = GetLootSlotLink(slot);
	local name = QuestItem_nameFromLink(link);
	if (name) then
		local texture, item, quantity, quality = GetLootSlotInfo(slot);
		
		if (quality == nil) then 
			quality = QuestItem_qualityFromLink(link); 
		end

		QuestItem_AddTooltip(GameTooltip, name, link, quantity, quantity)
	end
end

------------------------------------------------------
-- [[ QuestItem_ContainerFrameItemButton_OnEnter ]] --
------------------------------------------------------
function QuestItem_ContainerFrameItemButton_OnEnter()
	base_ContainerFrameItemButton_OnEnter();
	
	local frameID = this:GetParent():GetID();
	local buttonID = this:GetID();
	local link = GetContainerItemLink(frameID, buttonID);
	local name = QuestItem_nameFromLink(link);
	
	if (name) then
		local texture, itemCount, locked, quality, readable = GetContainerItemInfo(frameID, buttonID);
		if (quality==nil or quality==-1) then 
			quality = QuestItem_qualityFromLink(link); 
		end

		QuestItem_AddTooltip(GameTooltip, name, link, quantity, itemCount)
	end
end

----------------------------------------
-- [[ Set tooltip for linked items ]] --
----------------------------------------
function QuestItem_Chat_OnHyperlinkShow(link, button)
	base_Chat_OnHyperlinkShow(link, button);
	if (ItemRefTooltip:IsVisible()) then
		local name = ItemRefTooltipTextLeft1:GetText();
		if (name) then
			local fabricatedLink = "|cff000000|H"..link.."|h["..name.."]|h|r";
			
			QuestItem_AddTooltip(ItemRefTooltip, name, fabricatedLink, -1, 1, 0);
		end
	end
end

function QuestItem_ContainerFrameItemButton_Update(frame)
	base_ContainerFrame_Update(frame);
	--QuestItem_Debug("QuestItem_ContainerFrameItemButton_OnUpdate");
end

----------------------------------
-- [[ QuestItem_NameFromLink ]] --
----------------------------------
function QuestItem_nameFromLink(link)
	local name;
	if( not link ) then
		return nil;
	end
	for name in string.gfind(link, "|c%x+|Hitem:%d+:%d+:%d+:%d+|h%[(.-)%]|h|r") do
		return name;
	end
	return nil;
end

---------------------------
-- [[ qualityFromLink ]] --
---------------------------
function QuestItem_qualityFromLink(link)
	local color;
	if (not link) then return nil; end
	for color in string.gfind(link, "|c(%x+)|Hitem:%d+:%d+:%d+:%d+|h%[.-%]|h|r") do
		if (color == "ffa335ee") then return 4;--[[ Epic ]] end
		if (color == "ff0070dd") then return 3;--[[ Rare ]] end
		if (color == "ff1eff00") then return 2;--[[ Uncommon ]] end
		if (color == "ffffffff") then return 1;--[[ Common ]] end
		if (color == "ff9d9d9d") then return 0;--[[ Poor ]] end
	end
	return -1;
end

-- The code below is not in use. It is a backup in case ItemsMatrix breaks something
--[[

	--[[ ItemsMatrix support - grabbed from Norganna's EnhTooltip ]]--
	if(IMInv_ItemButton_OnEnter ~= nil) then
		base_IMInv_ItemButton_OnEnter = IMInv_ItemButton_OnEnter;
		IMInv_ItemButton_OnEnter = QuestItem_IMInv_ItemButton_OnEnter;
		
		base_ItemsMatrixItemButton_OnEnter = ItemsMatrixItemButton_OnEnter;
		ItemsMatrixItemButton_OnEnter = QuestItem_ItemsMatrixItemButton_OnEnter;
		QuestItem_Debug("Hooking to ItemsMatrix");
	end
local function QuestItem_fakeLink(item, quality, name)
	if (quality == nil) then 
		quality = -1; 
	end
	if (name == nil) then 
		name = "unknown"; 
	end
	local color = "ffffff";
	if (quality == 4) then color = "a335ee";
	elseif (quality == 3) then color = "0070dd";
	elseif (quality == 2) then color = "1eff00";
	elseif (quality == 0) then color = "9d9d9d";
	end
	return "|cff"..color.. "|H"..item.."|h["..name.."]|h|r";
end

--[[ ItemsMatrix support - grabbed from Norganna's EnhTooltip ]]--
function QuestItem_IMInv_ItemButton_OnEnter()
	base_IMInv_ItemButton_OnEnter();
	if(not IM_InvList) then 
		return; 
	end
	local id = this:GetID();

	if(id == 0) then
		id = this:GetParent():GetID();
	end
	
	local offset = FauxScrollFrame_GetOffset(ItemsMatrix_IC_ScrollFrame);
	local item = IM_InvList[id + offset];

	if (not item) then 
		return; 
	end
	local imlink = ItemsMatrix_GetHyperlink(item.name);
	local link = QuestItem_fakeLink(imlink, item.quality, item.name);
	if (link) then
		QuestItem_AddTooltip(GameTooltip, item.name, link, item.quality, item.count, 0)
	end
end

--[[ ItemsMatrix support - grabbed from Norganna's EnhTooltip ]]--
function QuestItem_ItemsMatrixItemButton_OnEnter()
	base_ItemsMatrixItemButton_OnEnter();
	local imlink = ItemsMatrix_GetHyperlink(this:GetText());
	if (imlink) then
		local name = this:GetText();
		local link = fakeLink(imlink, -1, name);
		
		QuestItem_AddTooltip(GameTooltip, name, link, -1, 1);
	end
end

]]--