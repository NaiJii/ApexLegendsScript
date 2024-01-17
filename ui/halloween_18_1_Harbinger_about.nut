
global function Halloween_18_1_Harbinger_PopulateAboutText

string function GetPlaylist() 
{
	if ( IsLobby() )
		return Lobby_GetSelectedPlaylist()
	else
		return GetCurrentPlaylistName()

	unreachable
}

array< featureTutorialTab > function Halloween_18_1_Harbinger_PopulateAboutText()
{
	array< featureTutorialTab > tabs
	featureTutorialTab tab1
	array< featureTutorialData > tab1Rules

	
	tab1.tabName = 	"#HALLOWEEN_18_1_TAB_NAME"

	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#HALLOWEEN_18_1_Harbinger_HEADER_1", "#HALLOWEEN_18_1_Harbinger_BODY_1", $"rui/hud/gametype_icons/harbringer/about_harbinger_18_1_spooky" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#HALLOWEEN_18_1_Harbinger_HEADER_2", "#HALLOWEEN_18_1_Harbinger_BODY_2", $"rui/hud/gametype_icons/harbringer/about_harbinger_18_1_shell" ) )

	tab1.rules = tab1Rules
	tabs.append( tab1 )

	return tabs
}



