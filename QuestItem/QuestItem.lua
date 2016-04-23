--[[ 
Description
If you have ever had a quest item you have no idea which quest it belongs to, and if it safe to destroy, this AddOn is for you.	

QuestItem stores an in-game database over quest items and tell you which quest they belong to. Useful to find out if you 
are still o	n the quest, and if it safe to destroy it. The AddOn will map items to quests when you pick them up, but also 
has a limited backward compatability. If you see tooltip for a questitem you have picked up before installing the addon, 
QuestItem will try to find the item in your questlog, and map it to a quest. In case unsuccessful, the item will be marked 
as unidentified.
]]--


DEBUG = false;

-- QuestItem array
QuestItems = {};
-- Settings
QuestItem_Settings = {};

----------------------------------------------------
-- Updates the database with item and quest mappings
----------------------------------------------------
----------------------------------------------------
function QuestItem_UpdateItem(item, quest, count, total, status)
	-- If item doesn't exist, add quest name and total item count to it
	if(not QuestItems[item]) then
		QuestItems[item] = {};
		QuestItems[item].QuestName = quest;
	end
	
	-- If old quest name was unidentified, save new name
	if(QuestItem_SearchString(QuestItems[item].QuestName, QUESTITEM_UNIDENTIFIED) and not QuestItem_SearchString(quest, QuestItems[item].QuestName) ) then
		QuestItems[item].QuestName = quest;
	end

	if(not QuestItems[item][UnitName("player")]) then
		QuestItems[item][UnitName("player")] = {};
	end

	-- Save total count
	if(QuestItem_CheckNumeric(total) ) then
		QuestItems[item].Total = QuestItem_MakeIntFromHexString(total);
	else
		QuestItems[item].Total = 0;
	end
	
	-- Save item count
	if(QuestItem_CheckNumeric(count) ) then
		QuestItems[item][UnitName("player")].Count = QuestItem_MakeIntFromHexString(count);
	else
		QuestItems[item][UnitName("player")].Count = 0;
	end

	QuestItems[item][UnitName("player")].QuestStatus 	= status;
end

----------------------------------------------------------------------
-- Find a quest based on item name
-- Returns:
-- 			QuestName  - the name of the Quest.
--			Total	   - Total number of items required to complete it
--			Count	   - The number of items you have
----------------------------------------------------------------------
----------------------------------------------------------------------
function QuestItem_FindQuest(item)
	local Total = 0;
	local Count = 0;
	
	-- Iterate the quest log entries
	for y=1, GetNumQuestLogEntries(), 1 do
		local QuestName, level, questTag, isHeader, isCollapsed, complete = GetQuestLogTitle(y);
		-- Don't check headers
		if(not isHeader) then
			SelectQuestLogEntry(y);
			local QDescription, QObjectives = GetQuestLogQuestText();
			
			-- Look for the item in the objectives - no count and total will be returned
			if(QuestItem_SearchString(QObjectives, item)) then
				return QuestName, Total, Count;
			end
			-- Look for the item in quest leader boards
			if (GetNumQuestLeaderBoards() > 0) then 
				-- Look for the item in leader boards
				for i=1, GetNumQuestLeaderBoards(), 1 do --Objectives
					--local str = getglobal("QuestLogObjective"..i);
					local text, itemType, finished = GetQuestLogLeaderBoard(i);
					-- Check if type is an item, and if the item is what we are looking for
					--QuestItem_Debug(itemType);
					if(itemType ~= nil and (itemType == "item" or itemType == "object") ) then
						if(QuestItem_SearchString(text, item)) then
							return QuestName, Total, Count;
						end
					end
				end
			end
		end
	end
	return nil, total, count;
end

--------------------------------------------------------------------------------
-- Check if there is a quest for the item. If it exists; update, if not, save it.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function QuestItem_LocateQuest(itemText, itemCount, itemTotal)
	local QuestName;
	-- Only look through the questlog if the item has not already been mapped to a quest
	if(not QuestItems[itemText] or QuestItems[itemText].QuestName == QUESTITEM_UNIDENTIFIED) then
		QuestName = QuestItem_FindQuest(itemText);
	else
		QuestName = QuestItems[itemText].QuestName;
	end
	
	-- Update the QuestItems array
	if(QuestName ~= nil) then
		QuestItem_Debug("Found quest for " .. itemText .. ": " .. QuestName);
		QuestItem_UpdateItem(itemText, QuestName, itemCount, itemTotal, 0);
	elseif(QuestItem_Settings["Alert"]) then
		QuestItem_PrintToScreen(QUESTITEM_CANTIDENTIFY .. itemText);
	end
end

---------------
-- OnLoad event
---------------
---------------
function QuestItem_OnLoad()
	QuestItem_OldTooltip = TT_AddTooltip;
	TT_AddTooltip = QuestItem_AddTooltip;
	
	RegisterForSave("QuestItems");
	RegisterForSave("QuestItem_Settings");
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("ITEM_PUSH");
	
	if(QuestItem_Settings["version"] and QuestItem_Settings["Enabled"] == true) then
		this:RegisterEvent("UI_INFO_MESSAGE");
	end
	
	
	-- Register slash commands
	SLASH_QUESTITEM1 = "/questitem";
	SLASH_QUESTITEM2 = "/qi";
	SlashCmdList["QUESTITEM"] = QuestItem_Config_OnCommand;
	
	if ( DEFAULT_CHAT_FRAME ) then 
		--DEFAULT_CHAT_FRAME:AddMessage(QUESTITEM_LOADED, 0.4, 0.5, 0.8);
		QuestItem_PrintToScreen(QUESTITEM_LOADED);
	end
end

-----------------
-- OnEvent method
-----------------
-----------------
function QuestItem_OnEvent(event)
	if(event == "VARIABLES_LOADED") then
		QuestItem_VariablesLoaded();
		this:UnregisterEvent("VARIABLES_LOADED");
		return;
	elseif(event == "ITEM_PUSH") then
		if(arg1) then
			QuestItem_Debug(arg1);
		end
		if(arg2) then
			QuestItem_Debug(arg2);
		end
		if(arg3) then
			QuestItem_Debug(arg3);
		end
	end
	
	if(not arg1) then
		return;
	end
	QuestItem_Debug(arg1);
	local itemText = gsub(arg1,"(.*): %d+/%d+","%1",1);
	if(event == "UI_INFO_MESSAGE") then
		local itemCount = gsub(arg1,"(.*): (%d+)/(%d+)","%2");
		local itemTotal = gsub(arg1,"(.*): (%d+)/(%d+)","%3");
		
		-- Ignore trade and duel events
		if(not strfind(itemText, QUESTITEM_TRADE) and not strfind(itemText, QUESTITEM_DUEL) and not strfind(itemText, QUESTITEM_DISCOVERED)) then
			QuestItem_LocateQuest(itemText, itemCount, itemTotal);
		end
	elseif(event == "DELETE") then
		if(QuestItems[itemText]) then
			QuestItems[itemText] = nil;
			QuestItem_Debug("Deleted");
		end
	end
end

------------------------------------
-- Initialize settings if not found. 
------------------------------------
------------------------------------
function QuestItem_VariablesLoaded()
	if ( QuestItem_Settings and QuestItem_Settings["version"] == QUESTITEM_VERSION ) then
		return;
	end
	
	if (not QuestItem_Settings) then
		QuestItem_Settings = { };	
	end
	
	-- No settings exist
	QuestItem_Settings["version"] = QUESTITEM_VERSION;
	
	QuestItem_Settings["Enabled"] = true;
	QuestItem_Settings["Alert"] = true;
	-- Check if AxuItemMenus is installed
	if(AxuItemMenus_AddTestHook) then
		QuestItem_Settings["DisplayRequest"] = false;
	else
		QuestItem_Settings["DisplayRequest"] = false;
	end
	QuestItem_Settings["ShiftOpen"] = false;
	QuestItem_Settings["AltOpen"] = false;
end