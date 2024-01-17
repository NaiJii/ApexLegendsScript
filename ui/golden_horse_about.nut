

global function GoldenHorse_PopulateAboutText

string function GetPlaylist() 
{
	if ( IsLobby() )
		return Lobby_GetSelectedPlaylist()
	else
		return GetCurrentPlaylistName()

	unreachable
}

array< featureTutorialTab > function GoldenHorse_PopulateAboutText()
{
	array< featureTutorialTab > tabs
	featureTutorialTab tab1
	array< featureTutorialData > tab1Rules

	
	tab1.tabName = 	"#GOLDEN_HORSE_TAB_NAME"

	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#GOLDEN_HORSE_HEADER_1", "#GOLDEN_HORSE_BODY_1", $"rui/hud/gametype_icons/ltm/about_gh_1" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#GOLDEN_HORSE_HEADER_2", "#GOLDEN_HORSE_BODY_2", $"rui/hud/gametype_icons/ltm/about_gh_2" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#GOLDEN_HORSE_HEADER_3", "#GOLDEN_HORSE_BODY_3", $"rui/hud/gametype_icons/ltm/about_gh_3" ) )

	tab1.rules = tab1Rules
	tabs.append( tab1 )

	return tabs
}



      
