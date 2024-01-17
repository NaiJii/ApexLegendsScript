
global function Survival_Strikeout_PopulateAboutText

string function GetPlaylist()
{
	if ( IsLobby() )
		return Lobby_GetSelectedPlaylist()
	else
		return GetCurrentPlaylistName()

	unreachable
}

array< featureTutorialTab > function Survival_Strikeout_PopulateAboutText()
{
	array< featureTutorialTab > tabs
	featureTutorialTab tab1
	array< featureTutorialData > tab1Rules

	
	tab1.tabName = 	"#SURVIVAL_STRIKEOUT_TAB_NAME"

	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#SURVIVAL_STRIKEOUT_1_HEADER", "#SURVIVAL_STRIKEOUT_1_BODY", $"rui/hud/gametype_icons/ltm/about_strikeout_respawn" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#SURVIVAL_STRIKEOUT_2_HEADER", "#SURVIVAL_STRIKEOUT_2_BODY", $"rui/hud/gametype_icons/ltm/about_strikeout_fullammo" ) )
	tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( "#SURVIVAL_STRIKEOUT_3_HEADER", "#SURVIVAL_STRIKEOUT_3_BODY", $"rui/hud/gametype_icons/ltm/about_strikeout_bleeding" ) )

	tab1.rules = tab1Rules
	tabs.append( tab1 )

	return tabs
}



