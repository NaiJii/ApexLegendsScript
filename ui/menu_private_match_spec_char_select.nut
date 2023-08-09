global function InitPrivateMatchSpectCharSelectMenu


global function EnablePrivateMatchSpectCharSelectMenu
global function IsPrivateMatchSpectCharSelectMenuOpen
global function OpenPrivateMatchSpectCharSelectMenu
global function ClosePrivateMatchSpectCharSelectMenu
global function PrivateMatchSpectCharSelectMenu_HideScoreboard








struct TeamRosterStruct
{
	var 		  framePanel
	var           headerPanel
	var           listPanel
	int           teamIndex
	int			  teamPlacement
	int           teamDisplayNumber
}

struct
{
	var 		menu

	var 		decorationRui
	var 		menuHeaderRui
	var 		backgroundRui

	bool 		enableMenu = false
	bool 		disableNavigateBack = false

	var 		countdownRui
	var			whiteFlash
	array<var>  progressBarRuis

	int 		lockStepIndex = -2
	int			maxTeamSize = 0
	table< int, TeamRosterStruct > teamRosters

	bool 		isInitialized = false
	bool		isButtonMappped = false

	table< entity, var > buttonPlayerMap

} file

void function InitPrivateMatchSpectCharSelectMenu( var newMenuArg )
{
	file.menu = newMenuArg
	file.whiteFlash = Hud_GetChild( newMenuArg, "WhiteFlash" )


		file.menuHeaderRui = Hud_GetRui( Hud_GetChild( newMenuArg, "MenuHeader" ) )

		RuiSetString( file.menuHeaderRui, "menuName", "#TOURNAMENT_SPECTATOR_CHARACTER_SELECTION" )

		AddMenuEventHandler( newMenuArg, eUIEvent.MENU_OPEN, OnOpenPrivateMatchSpectCharSelectMenu )
		AddMenuEventHandler( newMenuArg, eUIEvent.MENU_SHOW, OnShowPrivateMatchSpectCharSelectMenu )
		AddMenuEventHandler( newMenuArg, eUIEvent.MENU_HIDE, OnHidePrivateMatchSpectCharSelectMenu )
		AddMenuEventHandler( newMenuArg, eUIEvent.MENU_CLOSE, OnClosePrivateMatchSpectCharSelectMenu )
		AddUICallback_OnLevelInit( void function() : ( newMenuArg )
		{
			Assert( CanRunClientScript() )
			RunClientScript( "InitPrivateMatchSpectCharSelectMenu", newMenuArg )
		} )










	file.isInitialized = true
}


void function OnOpenPrivateMatchSpectCharSelectMenu()
{
	if ( !IsFullyConnected() )
	{
		CloseActiveMenu()
		return
	}

	ShowPanel( Hud_GetChild( file.menu, "PrivateMatchScoreboardPanel" ) )
}



void function OnShowPrivateMatchSpectCharSelectMenu()
{
	UI_SetScoreboardAnimateIn( Hud_GetChild( file.menu, "PrivateMatchScoreboardPanel" ), 0.25 )

	var header = Hud_GetChild( file.menu, "MenuHeader" )
	var headerRui = Hud_GetRui( header )
	RuiSetWallTimeWithNow( headerRui, "animateStartTime" )
	RuiSetInt( headerRui, "animationDirection", 1 )

	SetMenuReceivesCommands( file.menu, PROTO_Survival_DoInventoryMenusUseCommands() && !IsControllerModeActive() )
}



void function OnHidePrivateMatchSpectCharSelectMenu()
{
	
}



void function OnClosePrivateMatchSpectCharSelectMenu()
{

}



void function PrivateMatchSpectCharSelectMenu_HideScoreboard()
{
	var header = Hud_GetChild( file.menu, "MenuHeader" )
	var headerRui = Hud_GetRui( header )
	RuiSetWallTimeWithNow( headerRui, "animateStartTime" )
	RuiSetInt( headerRui, "animationDirection", -1 )

	UI_SetScoreboardAnimateOut( Hud_GetChild( file.menu, "PrivateMatchScoreboardPanel" ), 0.25 )

	thread function() : ()
	{
		wait 0.25
		RunClientScript( "DisablePrivateMatchSpectCharSelectMenu" )
	}()

}



































































































































































































































































































































































































































































































































void function EnablePrivateMatchSpectCharSelectMenu( bool doEnable )
{
	file.enableMenu = doEnable
	if ( file.enableMenu == true )
	{
		AdvanceMenu( file.menu )
	}
}



bool function IsPrivateMatchSpectCharSelectMenuOpen()
{
	return GetActiveMenu() == file.menu
}



void function OpenPrivateMatchSpectCharSelectMenu( var button )
{
	if ( !IsPrivateMatch() )
		return

	if ( file.enableMenu == false )
		return

	CloseAllMenus()
	AdvanceMenu( file.menu )
}



void function ClosePrivateMatchSpectCharSelectMenu()
{
	if ( GetActiveMenu() == file.menu )
		thread CloseActiveMenu()
}



