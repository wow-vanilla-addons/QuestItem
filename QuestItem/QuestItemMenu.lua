function QuestItem_Menu_Request()
	QuestItem_Debug("Requesting quest mapping");
end

local QuestItem_Menu_Request_Info = {
	text = "Request quest mapping",
	func = QuestItem_Menu_Request,
	tooltipTitle = "Request mapping to quest",
	tooltipText = "TooltipText"
};

function QuestItem_Menu_Request_Test()
	if(QuestItems[AxuItemMenus_class.name] and QuestItems[AxuItemMenus_class.name].QuestName == QUESTITEM_CANTIDENTIFY and QuestItem_Settings["Enabled"] == true and QuestItem_Settings["DisplayRequest"] == true) then
		return true;
	end
	return false;
end

function QuestItem_Menu_OnLoad()
	-- Check if AxuItemMenus has been installed
    if (AxuItemMenus_AddTestHook) then
		AxuItemMenus_AddTestHook(QuestItem_Menu_Request_Test,
			QuestItem_Menu_Request_Info);
    end
end