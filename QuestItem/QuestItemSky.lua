QUESTITEM_MAILBOX_CHECK_INTERVAL 	= 5;
QUESTITEM_INBOX_DATA 				= "QuestItemData";
QUESTITEM_INBOX_REQUEST 			= "QuestItemRequest";
QUESTITEM_CHECKCOUNT 				= 1;

--------------------------------------------
-- [[ Initialize and register with Sky ]] --
--------------------------------------------
function QuestItem_Sky_OnLoad()
	-- TODO: Check for sky
	--[[
	if(not Sky.isChannelActive(QI_CHANNEL_NAME)) then
		SkyChannelManager.joinChannel(QI_CHANNEL_NAME);
	end
	
	QuestItem_Sky_Register();
	QuestItem_Sky_MailCheck();
	]]--
end

------------------------------
-- [[ Register mailboxes ]] --
------------------------------
function QuestItem_Sky_Register()
	-- Register a test program
	Sky.registerMailbox(
		{
			id = QUESTITEM_INBOX_DATA;
			events = { QI_CHANNEL_NAME};
			acceptTest = QuestItem_Sky_AcceptData;
			weight = 5;
		}
	);
end

----------------------------------------
-- [[ Accept item mapping requests ]] --
----------------------------------------
function QuestItem_Sky_AcceptRequest(envelope)
	return true;
end

------------------------------------
-- [[ Accept item mapping data ]] --
------------------------------------
function QuestItem_Sky_AcceptData(envelope)
	return true;
end

-----------------------------------------------
-- [[ Check the mailbox every few seconds ]] --
-----------------------------------------------
function QuestItem_Sky_MailCheck()
	QuestItem_Sky_ReadMail();
	Chronos.scheduleByName("QuestItemMailCheck", QUESTITEM_MAILBOX_CHECK_INTERVAL, QuestItem_Sky_MailCheck ); 
end

--[[ Scan the mailbox ]]--
function QuestItem_Sky_ReadMail()
	if(QUESTITEM_CHECKCOUNT < 5) then
		QuestItem_Debug("Reading mail");
		QUESTITEM_CHECKCOUNT = QUESTITEM_CHECKCOUNT + 1;
	end
	
	local recordCount = 0;
	local requestMail = Sky.getAllMessages(QUESTITEM_INBOX_DATA); 
	if(Sky.getNextMessage(QUESTITEM_INBOX_DATA)) then
		QuestItem_Debug("fant data");
	else
		QuestItem_Debug("Tom mailbox");
	end

	for k, envelope in requestMail do 
		local data = envelope.msg;
		local username = envelope.sender;
		if ( type(data) == "table" ) then 
			QuestItem_Debug("Recieved request from: " .. username .. " from " .. data.message);
		end
	end
end

-- /script QuestItem_Sky_SendTestData();
function QuestItem_Sky_SendTestData()
	QuestItem_Debug("Trying to send data to sky");
	local testData = { message = "Hei";};
	Sky.sendTable(testData, QI_CHANNEL_NAME, QUESTITEM_INBOX_DATA);
	
end