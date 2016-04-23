QUESTLINK_VERSION = "0.1";
DEBUG = false;
str_unidentified = "Unidentified quest";


local base_ContainerFrameItemButton_OnEnter
local lOriginal_ContainerFrameItemButton_OnEnter;
-- QuestItem array
QuestItems = {};

function QuestItem_AddTooltip(frame, name, quantity, item)
	local tooltip = getglobal("GameTooltip");
    if ( not tooltip ) then
		return;
    end
	
    local tooltipInfo = QuestItem_ScanTooltip("GameTooltip");
    if ( tooltipInfo[1] ) then
		-- Check if the item is not a Quest Item
		if(QuestItem_IsQuestItem(tooltip) ) then
			local name = tooltipInfo[1].left;
			
			-- Item not found in the database - look for it
			if(not QuestItems[name] or QuestItem_SearchString(QuestItems[name].QuestName, str_unidentified) ) then
				local QuestName = QuestItem_FindQuest(name);
				if(not QuestName) then
					QuestItem_UpdateItem(name, str_unidentified, quantity, 0, 3)
				else
					QuestItem_UpdateItem(name, QuestName, quantity, 0, 0)
				end
			end
			-- Quest was found in the database
			if(QuestItems[name]) then
				tooltip:AddLine(QuestItems[name].QuestName, 0.4, 0.5, 0.8);
				if(QuestItems[name][UnitName("player")]) then
					-- Check status for quest - if it can't be found change status to abandoned/complete
					if(QuestItems[name][UnitName("player")].QuestStatus ~= 0) then
						if(not QuestItem_FindQuest(name)) then
							QuestItems[name][UnitName("player")].QuestStatus = 1;
						end
					end
					-- Do not display count if the quest is unidentified
					if(not QuestItem_SearchString(QuestItems[name].QuestName, str_unidentified) ) then
						-- Display quest status
						if(QuestItems[name][UnitName("player")].QuestStatus == 0) then
							tooltip:AddLine("Quest is active", 0, 1, 0);
						elseif(QuestItems[name][UnitName("player")].QuestStatus == 1 or QuestItems[name][UnitName("player")].QuestStatus == 2) then
							tooltip:AddLine("Quest is complete or abandoned", 0.7, 0.7, 0.7);
						end
					end
				end				
				tooltip:Show();
			end
		end
	end
end

-- Find out if an item is a quest item by searching the text in the tooltip
function QuestItem_IsQuestItem(frame)
	local tooltip = getglobal("GameTooltipTextLeft"..2);
	if(tooltip and tooltip:GetText()) then
		local str = string.gsub(tooltip:GetText(), "(Quest Item)", "%1")
		if(str == "Quest Item") then
			return true;
		end
	end
	return false;
end

-- Look for the item in the text string
function QuestItem_SearchString(text, item)
	if(string.find(text, item) ) then
		return true;
	end
	return false;
end

--/// Updates the database with item and quest mappings
function QuestItem_UpdateItem(item, quest, count, total, status)
	-- If item doesn't exist, add quest name and total item count to it
	if(not QuestItems[item]) then
		QuestItems[item] = {};
		QuestItems[item].QuestName = quest;
	end
	if(QuestItem_SearchString(QuestItems[item].QuestName, str_unidentified) and not QuestItem_SearchString(quest, QuestItems[item].QuestName) ) then
		QuestItems[item].QuestName = quest;
	end

	if(not QuestItems[item][UnitName("player")]) then
		QuestItems[item][UnitName("player")] = {};
	end
	-- Have some bugs where the item text is taken as the count and total and leaves a HUGE number for total and count
	local tot = QuestItem_MakeIntFromHexString(total);
	local cnt = QuestItem_MakeIntFromHexString(count);
	if(tot > 200) then
		QuestItems[item].Total = 0;
	else
		QuestItems[item].Total = tot;
	end
	
	if(cnt > 200) then
		QuestItems[item][UnitName("player")].Count = 0;
	else
		QuestItems[item][UnitName("player")].Count = cnt;
	end
	QuestItems[item][UnitName("player")].QuestStatus 	= status;
end

function QuestItem_FindQuest(item)
	for y=1, GetNumQuestLogEntries(), 1 do
		local QuestName, level, questTag, isHeader, isCollapsed, complete = GetQuestLogTitle(y);
		-- Make sure the item is not a header --
		if(not isHeader) then
			SelectQuestLogEntry(y);
			local QDescription, QObjectives = GetQuestLogQuestText();
			-- Look for the item in the objectives
			if(QuestItem_SearchString(QObjectives, item)) then
				return QuestName;
			end
			-- Look for the item in quest leader boards
			if (GetNumQuestLeaderBoards() > 0) then 
				-- Look for the item in leader boards
				for i=1, GetNumQuestLeaderBoards(), 1 do --Objectives
					--local str = getglobal("QuestLogObjective"..i);
					local text, itemType, finished = GetQuestLogLeaderBoard(i);
					-- Check if type is an item, and if the item is what we are looking for
					if(itemType ~= nil and (itemType == "item" or itemType == "object") ) then
						if(QuestItem_SearchString(text, item)) then
							return QuestName;
						end
					end
				end
			end
		end
	end
	return nil;
end

function QuestItem_OnEvent(event)
	if(not arg1) then
		return;
	end
	
	local itemText = gsub(arg1,"(.*): %d+/%d+","%1",1);
	if(event == "UI_INFO_MESSAGE") then
		local itemCount = gsub(arg1,"(.*): (%d+)/(%d+)","%2");
		local itemTotal = gsub(arg1,"(.*): (%d+)/(%d+)","%3");
		
		QuestItem_LocateQuest(itemText, itemCount, itemTotal);
	elseif(event == "DELETE") then
		if(QuestItems[itemText]) then
			QuestItems[itemText] = nil;
			QuestItem_Debug("Deleted");
		end
	end
end

function QuestItem_LocateQuest(itemText, itemCount, itemTotal)
	local QuestName;
	-- Only look through the questlog if the item has not already been mapped to a quest
	if(not QuestItems[itemText] or QuestItems[itemText].QuestName == str_unidentified) then
		QuestName = QuestItem_FindQuest(itemText);
	else
		QuestName = QuestItems[itemText].QuestName;
	end
	
	-- Update the QuestItems array
	if(QuestName ~= nil) then
		QuestItem_Debug("Found quest for " .. itemText .. ": " .. QuestName);
		QuestItem_UpdateItem(itemText, QuestName, itemCount, itemTotal, 0);
	else
		QuestItem_Debug("No quest found for " .. itemText);
	end
end

function QuestItem_OnLoad()
	if ((not LOOTLINK_VERSION) or (LOOTLINK_VERSION < 310)) then
		if ( DEFAULT_CHAT_FRAME ) then 
			DEFAULT_CHAT_FRAME:AddMessage("QuestItem need LootLink >3.10", 0.8, 0.8, 0.2);
		end
		return;
	end
	
	LootLink_AddExtraTooltipInfo = QuestItem_AddTooltip;
	
	RegisterForSave("QuestItems");
	this:RegisterEvent("UI_INFO_MESSAGE");
	-- TODO: Add event and logic to determine if a quest is abandoned or is complete
	
	if ( DEFAULT_CHAT_FRAME ) then 
		DEFAULT_CHAT_FRAME:AddMessage("Shagot's QuestItem v"..QUESTLINK_VERSION.." loaded", 0.4, 0.5, 0.8);
		UIErrorsFrame:AddMessage("Loaded Shagoth's QuestItem", 0.4, 0.5, 0.8, 1.0, 10);
	end
end

function QuestItem_Debug(message)
	if(DEBUG) then
		if(not message) then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Message was nil", 0.9, 0.5, 0.3);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Debug: " ..message, 0.9, 0.5, 0.3);
		end
	end
end

-- Copied functions - don't want to depend on too many AddOns

-- From LootLink
function QuestItem_MakeIntFromHexString(str)
	if(not str) then
		return 0;
	end
	local remain = str;
	local amount = 0;
	while( remain ~= "" ) do
		amount = amount * 16;
		local byteVal = string.byte(strupper(strsub(remain, 1, 1)));
		if( byteVal >= string.byte("0") and byteVal <= string.byte("9") ) then
			amount = amount + (byteVal - string.byte("0"));
		elseif( byteVal >= string.byte("A") and byteVal <= string.byte("F") ) then
			amount = amount + 10 + (byteVal - string.byte("A"));
		end
		remain = strsub(remain, 2);
	end
	return amount;
end

-- From Sea
function QuestItem_ScanTooltip()
	local tooltipBase = "GameTooltip";
	local strings = {};
	for idx = 1, 10 do
		local textLeft = nil;
		local textRight = nil;
		ttext = getglobal(tooltipBase.."TextLeft"..idx);
		if(ttext and ttext:IsVisible() and ttext:GetText() ~= nil)
		then
			textLeft = ttext:GetText();
		end
		ttext = getglobal(tooltipBase.."TextRight"..idx);
		if(ttext and ttext:IsVisible() and ttext:GetText() ~= nil)
		then
			textRight = ttext:GetText();
		end
		if (textLeft or textRight)
		then
			strings[idx] = {};
			strings[idx].left = textLeft;
			strings[idx].right = textRight;
		end	
	end
	
	return strings;
end