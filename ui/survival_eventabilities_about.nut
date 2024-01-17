
global function EventAbilities_PopulateAboutText
global function EventAbilities_GetAboutHeader

string function GetPlaylist()
{
	if ( IsLobby() )
		return Lobby_GetSelectedPlaylist()
	else
		return GetCurrentPlaylistName()

	unreachable
}


string function EventAbilities_GetAboutHeader()
{
	return "#UPRISE_EVENT_ABOUT_HEADER"
}

array< featureTutorialTab > function EventAbilities_PopulateAboutText()
{
	array< featureTutorialTab > tabs
	string playlistUiRules = GetPlaylist_UIRules()

	if ( playlistUiRules != EVENT_ABILITIES )
		return tabs

	featureTutorialTab tab1

	array< featureTutorialData > tab1Rules

	
	tab1.tabName = "#GAMEMODE_RULES_OVERVIEW_TAB_NAME"
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#UPRISE_EVENT_ABOUT_OVERVIEW_1_HEADER", "#UPRISE_EVENT_ABOUT_OVERVIEW_1_BODY", $"rui/hud/gametype_icons/ltm/about_uprising_completechallenges" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#UPRISE_EVENT_ABOUT_OVERVIEW_2_HEADER", "#UPRISE_EVENT_ABOUT_OVERVIEW_2_BODY", $"rui/hud/gametype_icons/ltm/about_uprising_unlockabilities" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#UPRISE_EVENT_ABOUT_OVERVIEW_3_HEADER", "#UPRISE_EVENT_ABOUT_OVERVIEW_3_BODY", $"rui/hud/gametype_icons/ltm/about_uprising_rewardtracks" ) )

	tab1.rules = tab1Rules

	tabs.append( tab1 )

	return tabs
}



