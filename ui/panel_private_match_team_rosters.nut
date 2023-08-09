







global function _SetRosterHeaderToolTip
global function ConfirmKickPlayerDialogue


global const string PRIVATE_MATCH_TEAM_BUTTON_PANEL = "TeamPlayerRoster"
global const string PRIVATE_MATCH_TEAM_HEADER_PANEL = "TeamHeader"
global const string PRIVATE_MATCH_TEAM_FRAME_PANEL = "TeamFrame"

struct RosterButtonData
{
	entity player
	int    encodedEHandle
}

struct
{
	var                        spectatorsPanel
	var                        unassignedPlayersPanel
	var                        teamsPanel
	int                        teamSize
	int                        preloadingPlayers
	table< int, RosterStruct > teamRosters
	var 					   kickDragTarget
	var 					   kickPlayer

	var                            mouseDragIcon
	table< var, int >              mouseDragTargetTeamMap
	table< var, RosterButtonData > rosterButtonToPlayerMap
	RosterButtonData               dragEntData

} file













































































































































































void function _SetRosterHeaderToolTip( var panel, string toolTipText, string actionText1, string actionText2 = "", string actionText3 = "" )
{
	Hud_SetToolTipData( panel, CreateSimpleToolTip( "", toolTipText, actionText1, actionText2, actionText3 ) )
}

void function ConfirmKickPlayerDialogue( string playerName )
{
	if ( IsDialog( GetActiveMenu() ) )
		return

	ConfirmDialogData data
	data.headerText = "#TOURNAMENT_KICK_PLAYER"
	data.messageText = Localize( "#TOURNAMENT_KICK_PLAYER_CONFIRM", playerName )  
	data.resultCallback = void function( int dialogResult ) {
		if( dialogResult == eDialogResult.YES )
		{
			RunClientScript( "PrivateMatch_KickSelectedPlayer" ) 
		}
	}

	OpenConfirmDialogFromData( data )
}






















































































































































































































































































