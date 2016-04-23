QUESTITEM_MAILBOX_CHECK_INTERVAL 	= 5;
QUESTITEM_INBOX_ID 					= "QuestItem" .. GetLocale();
QUESTITEM_REQUEST_MSG 				= "QuestItemRequest";
QUESTITEM_REQUEST_REPLY				= "QuestItemReply";
QUESTITEM_CHECKCOUNT 				= 1;

--[[
envelope.msg structure:
	message - message type
	data - data table
]]--

--------------------------------------------
-- [[ Initialize and register with Sky ]] --
--------------------------------------------
function QuestItem_Sky_OnLoad()
	if(Sky ~= nil) then
		if(not Sky.isChannelActive(QUESTITEM_INBOX_ID)) then
			SkyChannelManager.joinChannel(QUESTITEM_INBOX_ID);
		end
		
		QuestItem_Sky_Register();
	end
end

------------------------------
-- [[ Register mailboxes ]] --
------------------------------
function QuestItem_Sky_Register()
	-- Register a test program
	Sky.registerMailbox(
		{
			id = QUESTITEM_INBOX_ID,
			events = { QUESTITEM_INBOX_ID, SKY_PLAYER},
			acceptTest = QuestItem_Sky_AcceptData,
		}
	);
end

------------------------------------
-- [[ Accept item mapping data ]] --
------------------------------------
function QuestItem_Sky_AcceptData(envelope)
	if(envelope.target == QUESTITEM_INBOX_ID) then
		if(type(envelope.msg) == "table") then
			local packet = envelope.msg;
			if(packet.message == QUESTITEM_REQUEST_MSG) then
				QuestItem_Sky_SendItemData(packet.item, envelope.sender);
			elseif(packet.message == QUESTITEM_REQUEST_REPLY) then
				QuestItem_Sky_AssignData(packet);
			end
		end
	else
		QuestItem_Debug("Rejected data from Sky user " .. envelope.sender);
	end
end

function QuestItem_Sky_AssignData(data)
	if( (QuestItems[data.ItemName] )) then --and QuestItems[data.ItemName].QuestName == QUESTITEM_UNIDENTIFIED) or not QuestItems[data.ItemName) then
		if(not QuestItems[data.ItemName]) then
			QuestItems[data.ItemName] = {};
		end
		QuestItems[data.ItemName].QuestName = data.QuestName;
		QuestItems[data.ItemName].Total = data.Total;
		QuestItem_Debug("Recieved mapping for " .. data.ItemName);
	end
end
---------------------------------------------------------
-- [[ Send item data to a player requesting mapping ]] --
---------------------------------------------------------
function QuestItem_Sky_SendItemData(itemName, targetName)
	QuestItem_Debug(targetName .. " is requesting mapping for " ..itemName);
	if(QuestItems[itemName]) then
		QuestItem_Debug("Sending mapping for " .. itemName .. " to " .. targetName);
		local itemData = {
			message = QUESTITEM_REQUEST_REPLY,
			ItemName = itemName, 
			QuestName = QuestItems[itemName].QuestName, 
			Total = QuestItems[itemName].Total,
		};
		Sky.sendTable(itemData, SKY_PLAYER, QUESTITEM_INBOX_ID, targetName);
	else
		QuestItem_Debug("Don't have " .. itemName .. ", cant send to " .. targetName);
	end
end

-- /script QuestItem_Sky_SendTestData("Nenja");
function QuestItem_Sky_SendTestData(target)
	if(target == nil) then
		QuestItem_Debug("Trying to send data to sky");
	else
		QuestItem_Debug("Trying to send data to " .. target);
	end
	
	local testData = { message = QUESTITEM_REQUEST_MSG; item = "SomeQuestItem";};
	Sky.sendTable(testData, SKY_PLAYER, QUESTITEM_INBOX_ID, target);
end

------------------------------------------------
-- [[ Request mapping for an item from Sky ]] --
------------------------------------------------
-- /script QuestItem_Sky_RequestMapping("Tough Wolf Meat");
function QuestItem_Sky_RequestMapping(itemName)
	local target = "Nenja";
	QuestItem_Debug("Requesting mapping for " .. itemName);
	
	local requestMessage = { message = QUESTITEM_REQUEST_MSG; item = itemName;};
	Sky.sendTable(requestMessage, SKY_PLAYER, QUESTITEM_INBOX_ID, target);
	--Sky.sendTable(requestMessage, "CHANNEL", QUESTITEM_INBOX_ID, QUESTITEM_INBOX_ID);
end