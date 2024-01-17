
global function Halloween_18_1_PopulateAboutText

string function GetPlaylist() 
{
	if ( IsLobby() )
		return Lobby_GetSelectedPlaylist()
	else
		return GetCurrentPlaylistName()

	unreachable
}

array< featureTutorialTab > function Halloween_18_1_PopulateAboutText()
{
	array< featureTutorialTab > tabs
	featureTutorialTab tab1
	array< featureTutorialData > tab1Rules

	
	tab1.tabName = 	"#HALLOWEEN_18_1_TAB_NAME"

	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#HALLOWEEN_18_1_HEADER_1", "#HALLOWEEN_18_1_BODY_1", $"rui/hud/gametype_icons/trick_n_treats/about_halloween_18_1_general" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#HALLOWEEN_18_1_HEADER_2", "#HALLOWEEN_18_1_BODY_2", $"rui/hud/gametype_icons/trick_n_treats/about_halloween_18_1_copycat_kit" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#HALLOWEEN_18_1_HEADER_3", "#HALLOWEEN_18_1_BODY_3", $"rui/hud/gametype_icons/trick_n_treats/about_halloween_18_1_candy" ) )

	tab1.rules = tab1Rules
	tabs.append( tab1 )

	return tabs
}



