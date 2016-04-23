--[[ 
Description
	QuestItem stores an in-game database over quest items and tell you which quest they belong to. 
	Useful to find out if you are still on the quest, and if it safe to destroy it. 
	
History:
	New in version 0.2:
	- Quest items that are not labeled "Quest Item" are now displayed with status in the tooltip.
	- Item count is now displayed next to the quest name in tooltip.
]]--


QUESTITEM_VERSION = "0.2";
DEBUG = false;
str_unidentified = "Unidentified quest";


local lOriginal_ContainerFrameItemButton_OnEnter;
-- QuestItem array
QuestItems = {};

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
	if(QuestItem_SearchString(QuestItems[item].QuestName, str_unidentified) and not QuestItem_SearchString(quest, QuestItems[item].QuestName) ) then
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

---------------
-- OnLoad event
---------------
---------------
function QuestItem_OnLoad()
	if ((not LOOTLINK_VERSION) or (LOOTLINK_VERSION < 310)) then
		if ( DEFAULT_CHAT_FRAME ) then 
			DEFAULT_CHAT_FRAME:AddMessage("QuestItem need LootLink >3.10", 0.8, 0.8, 0.2);
		end
		return;
	end
	
	LootLink_AddExtraTooltipInfo = QuestItem_AddTooltip;
	--lOriginal_ContainerFrameItemButton_OnEnter = ContainerFrameItemButton_OnEnter;
	--ContainerFrameItemButton_OnEnter = QuestItem_ContainerFrameItemButton_OnEnter;
	
	RegisterForSave("QuestItems");
	this:RegisterEvent("UI_INFO_MESSAGE");
	
	if ( DEFAULT_CHAT_FRAME ) then 
		DEFAULT_CHAT_FRAME:AddMessage("Shagot's QuestItem v"..QUESTITEM_VERSION.." loaded", 0.4, 0.5, 0.8);
		UIErrorsFrame:AddMessage("Loaded Shagoth's QuestItem", 0.4, 0.5, 0.8, 1.0, 10);
	end
end

-----------------
-- OnEvent method
-----------------
-----------------
function QuestItem_OnEvent(event)
	if(not arg1) then
		return;
	end
	QuestItem_Debug(arg1);
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