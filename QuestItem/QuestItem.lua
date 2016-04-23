--[[ 
Description
If you have ever had a quest item you have no idea which quest it belongs to, and if it safe to destroy, this AddOn is for you.	

QuestItem stores an in-game database over quest items and tell you which quest they belong to. Useful to find out if you 
are still o	n the quest, and if it safe to destroy it. The AddOn will map items to quests when you pick them up, but also 
has a limited backward compatability. If you see tooltip for a questitem you have picked up before installing the addon, 
QuestItem will try to find the item in your questlog, and map it to a quest. In case unsuccessful, the item will be marked 
as unidentified.

QuestItem now has a configuration screen you can access by typing /questitem or /qi at the chat prompt. Here you can configure
some of the functionallity as well as do manual mapping of unidentified items.

Feature summary:
- Identify quest items when picked up.
- Show quest name and status in tooltip for quest items.
- Will try to identify items picked up before the AddOn was installed.
- Identified items are available for all your characters, and status is unique for your character.
- Displays how many items are needed to complete quest, and how many you currently have.
- Manual mapping for unidentified items.
- Configuration

+ If you like this addon (or even if you don't), donations are always welcome to my character Shagoth on the Stormreaver server ;D
+ If you can translate the interface to german, edit the appropriate localization.lua file, and mail it to me at shagoth@gmail.com
+ Bug reports can be made adding a comment, or sending me a PM or email at shagoth@gmail.com

	
History:
	New in version 1.4
	- Added support for Menus on quest items using AxuMenuItems mod.
	- Request to sky channel for identification of items if not found in the questlog.
	
	New in version 1.3.1:
	- Bugfix for the error 'Interface\AddOns\QuestItem\QuestItemFunctions.lua:78 :bad argument #1 to 'strsub' (string expected, got nil)'
	
	New in version 1.3:
	- EnhTooltip dependency removed!
	- Manually mapped items should now display correct status if the mapped quest is in the questlog.
	
	New in version 1.2:
	- German translation (thanks to Thernel)
	- Minor fix when trying to identify quests. Should make german version work better.
	
	New in version 1.1.1:
	- Fixed a problem which caused item count to be incorrect in tooltip.
	
	New in version 1.1:
	- When an item is identified from tooltip, the count of required items are returned.
	- FR client is now supported
	- French translation
	
	New in version 1.0.1:
	- Updated toc file
	
	New in version 1.0:
	- Removed message to the chat window on load. Just annoying with too many addons adding loaded message there.
	- Configuration.
	- Manual mapping of items.
	- Alert when QuestItem is unable to map item to quest.
	
	New in version 0.3:
	- Using Enhanced Tooltip instead of LootLink to display item tooltip.
	Known issues in version 0.3:
	
	New in version 0.2:
	- Quest items that are not labeled "Quest Item" are now displayed with status in the tooltip.
	- Item count is now displayed next to the quest name in tooltip.
	
	New in version 0.1:
	- First release
]]--

-- /script arg1="Dentrium-Kraftstein: 1/1"; QuestItem_OnEvent("DELETE"); arg1="Roon's Kodo Horn: 1/1"; QuestItem_OnEvent("UI_INFO_MESSAGE");
-- /script arg1="Dentrium Power Stone: 5/8"; QuestItem_OnEvent("UI_INFO_MESSAGE"); QuestItem_OnEvent("DELETE");
-- /script arg1="An' Alleum-Kraftstein"; QuestItem_OnEvent("DELETE"); QuestItem_OnEvent("DELETE");

DEBUG = false;
QI_CHANNEL_NAME = "QuestItem";

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
	if(total ~= nil and QuestItem_CheckNumeric(total) ) then
		QuestItems[item].Total = QuestItem_MakeIntFromHexString(total);
	else
		QuestItems[item].Total = 0;
	end
	
	-- Save item count
	if(count ~= nil and QuestItem_CheckNumeric(count) ) then
		QuestItems[item][UnitName("player")].Count = QuestItem_MakeIntFromHexString(count);
	else
		QuestItems[item][UnitName("player")].Count = 0;
	end

	QuestItems[item][UnitName("player")].QuestStatus 	= status;
end

----------------------------------------------------------------------
-- Find a quest based on item name
-- Returns:
-- 			QuestName  	- the name of the Quest.
--			Total	   	- Total number of items required to complete it
--			Count	   	- The number of items you have
--			Texture		- Texture of the item
----------------------------------------------------------------------
----------------------------------------------------------------------
function QuestItem_FindQuest(item)
	local total = 1;
	local count = 0;
	local texture = nil;
	local itemName;
	
	-- Iterate the quest log entries
	for y=1, GetNumQuestLogEntries(), 1 do
		local QuestName, level, questTag, isHeader, isCollapsed, complete = GetQuestLogTitle(y);
		-- Don't check headers
		if(not isHeader) then
			SelectQuestLogEntry(y);
			local QDescription, QObjectives = GetQuestLogQuestText();
			
			-- Find out if this item has already been mapped to a quest. 
			-- This is to to prevent any reset of the status for manually mapped items.
			if(QuestItems[item] and (QuestItems[item].QuestName and QuestItems[item].QuestName == QuestName) ) then
				QuestItem_UpdateItem(item, QuestName, count, total, 0)
				return QuestName, total, count, texture;
			end

			-- Look for the item in quest leader boards
			if (GetNumQuestLeaderBoards() > 0) then 
				-- Look for the item in leader boards
				for i=1, GetNumQuestLeaderBoards(), 1 do --Objectives
					--local str = getglobal("QuestLogObjective"..i);
					local text, itemType, finished = GetQuestLogLeaderBoard(i);
					-- Check if type is an item, and if the item is what we are looking for
					--QuestItem_Debug("Item type: " ..itemType);
					if(itemType ~= nil and (itemType == "item" or itemType == "object") ) then
						if(QuestItem_SearchString(text, item)) then
							local count = gsub(text,"(.*): (%d+)/(%d+)","%2");
							local total = gsub(text,"(.*): (%d+)/(%d+)","%3");
							QuestItem_Debug("Count: " ..count);
							return QuestName, total, count, texture;
						end
					end
				end
			end
			-- Look for the item in the objectives - no count and total will be returned
			if(QuestItem_SearchString(QObjectives, item)) then
				return QuestName, total, count, texture;
			end
		end
	end
	return nil, total, count, texture;
end

--------------------------------------------------------------------------------
-- Check if there is a quest for the item. If it exists; update, if not, save it.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function QuestItem_LocateQuest(itemText, itemCount, itemTotal)
	local QuestName, texture;
	
	-- Only look through the questlog if the item has not already been mapped to a quest
	if(not QuestItems[itemText] or QuestItems[itemText].QuestName == QUESTITEM_UNIDENTIFIED) then
		QuestName, itemTotal, itemCount, texture = QuestItem_FindQuest(itemText);
	else
		QuestName = QuestItems[itemText].QuestName;
	end
	
	-- Update the QuestItems array
	if(QuestName ~= nil) then
		QuestItem_Debug("Found quest for " .. itemText .. ": " .. QuestName);
		QuestItem_UpdateItem(itemText, QuestName, itemCount, itemTotal, 0);
	--elseif(QuestItem_Settings["Alert"]) then
--		QuestItem_PrintToScreen(QUESTITEM_CANTIDENTIFY .. itemText);
	end
end

---------------
-- OnLoad event
---------------
---------------
function QuestItem_OnLoad()
	RegisterForSave("QuestItems");
	RegisterForSave("QuestItem_Settings");
	
	this:RegisterEvent("VARIABLES_LOADED");

	-- Register slash commands
	SLASH_QUESTITEM1 = "/questitem";
	SLASH_QUESTITEM2 = "/qi";
	SlashCmdList["QUESTITEM"] = QuestItem_Config_OnCommand;
	
	QuestItem_PrintToScreen(QUESTITEM_LOADED);
	
	--QuestItem_Sky_OnLoad();
	QuestItem_HookTooltip();
end


-----------------
-- OnEvent method
-----------------
-----------------
function QuestItem_OnEvent(event)
	if(event == "VARIABLES_LOADED") then
		QuestItem_VariablesLoaded();
		this:UnregisterEvent("VARIABLES_LOADED");
		
		if(QuestItem_Settings["version"] and QuestItem_Settings["Enabled"] == true) then
			this:RegisterEvent("UI_INFO_MESSAGE");		
		end
		return;
	end
	
	if(not arg1) then
		return;
	end

	local itemText = gsub(arg1,"(.*): %d+/%d+","%1",1);
	if(event == "UI_INFO_MESSAGE") then
		local itemCount = gsub(arg1,"(.*): (%d+)/(%d+)","%2");
		local itemTotal = gsub(arg1,"(.*): (%d+)/(%d+)","%3");
		if(arg2 ~= nil) then
			QuestItem_Debug("arg2: " .. arg2);
		end
		-- Ignore trade and duel events
		if(not strfind(itemText, QUESTITEM_TRADE) and not strfind(itemText, QUESTITEM_DUEL) and not strfind(itemText, QUESTITEM_DISCOVERED)) then
			QuestItem_Debug("Looking for quest item "..itemText);
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