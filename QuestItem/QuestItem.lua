--[[ 
Description
	If you have ever had a quest item you have no idea which quest it belongs to, and if it safe to destroy, this AddOn is for you.	

	QuestItem stores an in-game database over quest items and tell you which quest they belong to. Useful to find out if you 
	are still o	n the quest, and if it safe to destroy it. The AddOn will map items to quests when you pick them up, but also 
	has a limited backward compatability. If you see tooltip for a questitem you have picked up before installing the addon, 
	QuestItem will try to find the item in your questlog, and map it to a quest. In case unsuccessful, the item will be marked 
	as unidentified.

	Currently, there are some quest items QuestItem will not be able to identify as the name of the item is not found in 
	the questlog. These items are usually pre-requisites for some quest, and will be identified as soon as you complete the first 
	step. For example: Take a sample of the water in some river. The item will be "Empty sampeling tube", and will not be 
	mapped to a quest as it is not mentioned in the questlog. When filling the tube, it will have a new name which will be identified,
	however, the "Empty sampeling tube" will still be unidentified.

This is my first AddOn, so I hope you'll be gentle with me ;o)
I will try to get rid of dependencies to LootLink in the near future.

Feature summary:
- Identify quest items when picked up.
- Show quest name and status in tooltip for quest items.
- Will try to identify items picked up before the AddOn was installed.
- Identified items are available for all your characters, and status is unique for your character.
- Displays how many items are needed to complete quest, and how many you currently have.

If you like this addon (or even if you don't), donations are always welcome to my character Shagoth on the Stormreaver server ;D
	
History:
	New in version 0.3:
	- Using Enchanted Tooltip instead of LootLink to display item tooltip.
	New in version 0.2:
	- Quest items that are not labeled "Quest Item" are now displayed with status in the tooltip.
	- Item count is now displayed next to the quest name in tooltip.
]]--
QUESTITEM_VERSION = "0.3";
DEBUG = false;
str_unidentified = "Unidentified quest";

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
	QuestItem_OldTooltip = TT_AddTooltip;
	TT_AddTooltip = QuestItem_AddTooltip;
	
	RegisterForSave("QuestItems");
	this:RegisterEvent("UI_INFO_MESSAGE");
	
	if ( DEFAULT_CHAT_FRAME ) then 
		DEFAULT_CHAT_FRAME:AddMessage("Shagot's QuestItem v" ..QUESTITEM_VERSION.. " loaded", 0.4, 0.5, 0.8);
		UIErrorsFrame:AddMessage("Loaded Shagoth's QuestItem", 0.4, 0.5, 0.8, 1.0, 8);
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