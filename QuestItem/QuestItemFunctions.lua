------------------------------------------------
-- Print debug message to the default chatframe.
-- Only works if the DEBUG variable in the 
-- beginning of QuestItem.lua is set to true.
------------------------------------------------
------------------------------------------------
function QuestItem_Debug(message)
	if(DEBUG) then
		if(not message) then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Message was nil", 0.9, 0.5, 0.3);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Debug: " ..message, 0.9, 0.5, 0.3);
		end
	end
end

function QuestItem_PrintToScreen(message)
	UIErrorsFrame:AddMessage(message, 0.4, 0.5, 0.8, 1.0, 8);
end

---------------------------------------------------
-- Find out if an item is a quest item by searching 
-- the text in the tooltip.
---------------------------------------------------
---------------------------------------------------
function QuestItem_IsQuestItem(tooltip)
	if(tooltip) then
		local tooltip = getglobal(tooltip:GetName() .. "TextLeft"..2);
		if(tooltip and tooltip:GetText()) then
			if(QuestItem_SearchString(tooltip:GetText(), QUESTITEM_QUESTITEM)) then
				return true;
			end
		end
	end
	return false;
end

---------------------------------------
-- Look for the item in the text string
---------------------------------------
---------------------------------------
function QuestItem_SearchString(text, item)
	if(string.find(string.lower(text), string.lower(item)) ) then
		return true;
	end
	return false;
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
		amount = amount * 10;
		local byteVal = string.byte(strupper(strsub(remain, 1, 1)));
		if( byteVal >= string.byte("0") and byteVal <= string.byte("9") ) then
			amount = amount + (byteVal - string.byte("0"));
		end
		remain = strsub(remain, 2);
	end
	return amount;
end

function QuestItem_CheckNumeric(string)
	local remain = string;
	local hasNumber;
	local hasPeriod;
	local char;
	
	while( remain ~= "" and remain ~= nil) do
	--while( remain ~= "") do
		char = strsub(remain, 1, 1);
		if( char >= "0" and char <= "9" ) then
			hasNumber = 1;
		elseif( char == "." and not hasPeriod ) then
			hasPeriod = 1;
		else
			return nil;
		end
		remain = strsub(remain, 2);
	end
	
	return hasNumber;
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