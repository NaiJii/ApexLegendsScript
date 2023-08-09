global function InitPrivateMatchGameStatusMenu


global function EnablePrivateMatchGameStatusMenu
global function IsPrivateMatchGameStatusMenuOpen
global function TogglePrivateMatchGameStatusMenu
global function OpenPrivateMatchGameStatusMenu
global function ClosePrivateMatchGameStatusMenu
global function SetChatModeButtonText
global function SetSpecatorChatModeState
global function SetChatTargetText
global function InitPrivateMatchSummaryPanel
global function InitPrivateMatchOverviewPanel
global function InitPrivateMatchAdminPanel
global function OnPrivateMatchStateChange














const int TEAM_COUNT_PANEL_ONE 		= 2
const int TEAM_COUNT_PANEL_TWO 		= 7
const int TEAM_COUNT_PANEL_THREE 	= 11

const int MAX_TEAM_SIZE = 3
const int ROSTER_LIST_SIZE = 20 

enum ePlayerHealthStatus
{
	PM_PLAYERSTATE_ALIVE,
	PM_PLAYERSTATE_BLEEDOUT,
	PM_PLAYERSTATE_DEAD,
	PM_PLAYERSTATE_REVIVING,
	PM_PLAYERSTATE_ELIMINATED,

	_count
}

enum eGameStatusPanel
{
	PM_GAMEPANEL_ROSTER,
	PM_GAMEPANEL_INGAME_SUMMARY,
	PM_GAMEPANEL_POSTGAME_SUMMARY,
	PM_GAMEPANEL_ADMIN,

	__count
}

struct TeamRosterStruct
{
	var           framePanel
	var           headerPanel
	var           listPanel
	table< var, int > connectionMap
	table< var, entity > buttonPlayerMap
}

struct TeamDetailsData
{
	int teamIndex
	int teamValue
	int teamKills
	int teamPlacement
	int playerAlive
	string teamName
}

struct PlayerData
{
	entity playerEntity
	asset characterPortrait 	= $"white"
	string playerName 			= ""
	int killCount 				= 0
}

struct TeamData
{
	array<PlayerData> players
	int placement = 0
}

struct AdminConfigData
{
	int chatMode
	bool spectatorChat
}

struct
{
	var menu

	var postGameSummaryPanel
	var inGameSummaryPanel
	var adminPanel

	var textChat
	var chatInputLine
	var chatButtonIcon

	var endMatchButton
	var chatModeButton
	var chatSpectCheckBox
	var chatTargetText

	bool enableMenu = false
	bool disableNavigateBack = false

	array< TeamRosterStruct > teamRosters
	array< int > teamIndices
	int lastPlayerCount = 0
	array< var > teamOverviewPanels

	int displayDirtyBit = 0
	table< int, TeamData > teamData
	table< string, PlayerData > playerData

	bool isInitialized = false
	bool tabsInitialized = false
	bool updateConnections = false

	bool inputsRegistered = false

	int maxTeamSize = MAX_TEAM_SIZE
	int overviewSizeTotal = 0
	AdminConfigData adminConfig
} file

void function InitPrivateMatchGameStatusMenu( var menu )
{
	file.menu = menu
	file.inGameSummaryPanel = Hud_GetChild( menu, "PrivateMatchOverviewPanel" )
	file.postGameSummaryPanel = Hud_GetChild( menu, "PrivateMatchSummaryPanel" )
	file.adminPanel = Hud_GetChild( menu, "PrivateMatchAdminPanel" )


		AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnOpenPrivateMatchGameStatusMenu )
		AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnShowPrivateMatchGameStatusMenu )
		AddMenuEventHandler( menu, eUIEvent.MENU_HIDE, OnHidePrivateMatchGameStatusMenu )
		AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnClosePrivateMatchGameStatusMenu )
		AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavigateBack )


		AddCommandForMenuToPassThrough( menu, "toggle_inventory" )

		AddUICallback_OnLevelInit( void function() : ( menu )
		{
			Assert( CanRunClientScript() )
			RunClientScript( "InitPrivateMatchGameStatusMenu", menu )
		} )

		SetTabRightSound( menu, "UI_InGame_InventoryTab_Select" )
		SetTabLeftSound( menu, "UI_InGame_InventoryTab_Select" )

		file.isInitialized = true

















































}


void function RegisterInputs()
{
	if( file.inputsRegistered )
		return


	RegisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT_FULL, FocusChat_OnActivate )




	file.inputsRegistered = true
}

void function DeRegisterInputs()
{
	if ( !file.inputsRegistered )
		return


		DeregisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT_FULL, FocusChat_OnActivate )




	file.inputsRegistered = false
}

void function FocusChat_OnActivate( var button )
{
	Hud_SetFocused( file.chatInputLine )
}

void function EnterText_OnActivate( var button )
{
	if ( !HudChat_HasAnyMessageModeStoppedRecently() && Hud_IsVisible( file.textChat ) )
		Hud_StartMessageMode( file.textChat )
}

void function EndMatchButton_OnActivate( var button )
{
	if ( IsDialog( GetActiveMenu() ) )
		return

	ConfirmDialogData data
	data.headerText = "#TOURNAMENT_END_MATCH_DIALOG_HEADER"
	data.messageText = "#TOURNAMENT_END_MATCH_DIALOG_MSG" 
	data.resultCallback = void function( int dialogResult ) 
	{
		if ( dialogResult == eDialogResult.YES )
		{
			ClosePrivateMatchGameStatusMenu( null )
			if ( HasMatchAdminRole() )
			{
				Remote_ServerCallFunction( "ClientCallback_PrivateMatchEndMatchEarly" )
			}
		}
	}

	OpenConfirmDialogFromData( data )
}

void function InitPrivateMatchSummaryPanel( var panel )
{
	AddPanelFooterOption( panel ,LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK")

	var teamOneHeaderRui = Hud_GetRui( Hud_GetChild( panel, "TeamOverviewHeader01" ) )
	RuiSetString( teamOneHeaderRui, "kills", Localize( "#TOURNAMENT_SPECTATOR_TEAM_KILLS" ) )
	RuiSetString( teamOneHeaderRui, "teamName", Localize( "#TOURNAMENT_SPECTATOR_TEAM_NAME" ) )
	RuiSetString( teamOneHeaderRui, "playersAlive", Localize( "#TOURNAMENT_SPECTATOR_PLAYERS_ALIVE" ) )
}

void function InitHeaderTitle( var panel, string headerName, string headerTitle, vector headerColor )
{
	var headerRui = Hud_GetRui( Hud_GetChild( panel, headerName ) )
	RuiSetString( headerRui, "title", Localize( headerTitle ) )
	RuiSetColorAlpha( headerRui, "backgroundColor", SrgbToLinear( headerColor ), 1.0 )
}

void function InitPrivateMatchOverviewPanel( var panel )
{
	AddPanelFooterOption( panel ,LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK")

	InitHeaderTitle( panel, "AliveSquadsHeader", Localize( "#TOURNAMENT_SPECTATOR_ALIVE_TEAMS_HEADER" ), <36, 36, 36> / 255.0 )
	InitHeaderTitle( panel, "EliminatedSquadsHeader", Localize( "#TOURNAMENT_SPECTATOR_DEAD_TEAMS_HEADER" ), <121, 25, 26 > / 255.0 )

	var overviewGrid = Hud_GetChild( panel, "TeamOverview" )
	Hud_InitGridButtons( overviewGrid, 22 )

	
	var scrollPanel = Hud_GetChild( overviewGrid, "ScrollPanel" )
	Hud_Hide( Hud_GetChild( scrollPanel, "GridButton0" ) )
}

void function InitPrivateMatchAdminPanel( var panel )
{
	AddPanelFooterOption( panel ,LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK")

	AddUICallback_InputModeChanged( ControllerIconVisibilty )

	file.endMatchButton = Hud_GetChild( panel, "EndMatchButton" )
	HudElem_SetRuiArg( file.endMatchButton, "buttonText", Localize( "#TOURNAMENT_END_MATCH" ) )
	Hud_AddEventHandler( file.endMatchButton, UIE_CLICK, EndMatchButton_OnActivate )

	file.textChat = Hud_GetChild( panel, "AdminChatWindow" )
	file.chatInputLine = Hud_GetChild( file.textChat, "ChatInputLine" )

	file.chatButtonIcon = Hud_GetChild( panel, "AdminChatBoxIcon")

	file.chatModeButton = Hud_GetChild( panel, "AdminChatModeButton" )
	Hud_AddEventHandler( file.chatModeButton, UIE_CLICK, ChatModeButton_OnActivate )

	file.chatSpectCheckBox = Hud_GetChild( panel, "SpectatorChatCheckBox" )
	Hud_AddEventHandler( file.chatSpectCheckBox, UIE_CLICK, ChatSpectatorCheckBox_OnActivate )

	file.chatTargetText = Hud_GetChild( panel, "AdminChatTarget" )
}

void function SetChatModeButtonText( string newText )
{
	ToolTipData adminChatModeTooltip
	adminChatModeTooltip.descText = newText
	HudElem_SetRuiArg( file.chatModeButton, "buttonText", newText )
}


void function SetSpecatorChatModeState( bool isActive, bool isSelected )
{
	HudElem_SetRuiArg( file.chatSpectCheckBox, "isActive", isActive )
	HudElem_SetRuiArg( file.chatSpectCheckBox, "isSelected", isSelected )
}

void function SetChatTargetText( string target )
{
	if ( target != "" )
	{
		HudElem_SetRuiArg( file.chatTargetText, "targetText", Localize("#TOURNAMENT_SPECTATOR_CHAT_TARGET" ) + target )
	}
	else
	{
		HudElem_SetRuiArg( file.chatTargetText, "targetText", "" )
	}
}

void function ControllerIconVisibilty( bool controllerModeActive )
{
	Hud_SetEnabled( file.chatButtonIcon, controllerModeActive )
	Hud_SetVisible( file.chatButtonIcon, controllerModeActive )
}


























































































































































































































































































































































































































































































































































































































































































void function TryInitializeGameStatusMenu()
{
	if ( !file.tabsInitialized )
	{
		TabData tabData = GetTabDataForPanel( file.menu )
		tabData.centerTabs = true
		{
			TabDef tabdef = AddTab( file.menu, Hud_GetChild( file.menu, "PrivateMatchScoreboardPanel" ), "#TOURNAMENT_TEAM_STATUS" )		
			SetTabBaseWidth( tabdef, 240 )
		}

		{
			TabDef tabdef = AddTab( file.menu, Hud_GetChild( file.menu, "PrivateMatchOverviewPanel" ), "#TOURNAMENT_MATCH_STATS" )		
			SetTabBaseWidth( tabdef, 240 )
		}

		{
			TabDef tabdef = AddTab( file.menu, Hud_GetChild( file.menu, "PrivateMatchSummaryPanel" ), "#TOURNAMENT_MATCH_STATS" )		
			SetTabBaseWidth( tabdef, 240 )
		}

		{
			TabDef tabdef = AddTab( file.menu, Hud_GetChild( file.menu, "PrivateMatchAdminPanel" ), "#TOURNAMENT_ADMIN_CONTROLS" )
			SetTabBaseWidth( tabdef, 300 )

			tabdef.visible = false
			tabdef.enabled = false
		}    

		SetTabDefsToSeasonal(tabData)
		SetTabBackground( tabData, Hud_GetChild( file.menu, "TabsBackground" ), eTabBackground.STANDARD )

		file.tabsInitialized = true
	}
}


void function OnOpenPrivateMatchGameStatusMenu()
{
	if ( !IsFullyConnected() )
	{
		CloseActiveMenu()
		return
	}

	TryInitializeGameStatusMenu()

	bool isAdmin = HasMatchAdminRole()
	TabData tabData       = GetTabDataForPanel( file.menu )
	TabDef adminTab       = Tab_GetTabDefByBodyName( tabData, "PrivateMatchAdminPanel" )
	adminTab.visible 	  = isAdmin
	adminTab.enabled  	  = isAdmin

	UpdateMenuTabs()

	ActivateTab( tabData, eGameStatusPanel.PM_GAMEPANEL_ROSTER )

	SetTabNavigationEnabled( file.menu, true )

	RunClientScript( "PrivateMatch_PopulateGameStatusMenu", file.menu )

}

void function OnShowPrivateMatchGameStatusMenu()
{
	SetMenuReceivesCommands( file.menu, PROTO_Survival_DoInventoryMenusUseCommands() && !IsControllerModeActive() )
	if ( !HasMatchAdminRole() )
		return

	RegisterInputs()

	ControllerIconVisibilty( IsControllerModeActive() )

	RunClientScript( "PrivateMatch_ToggleUpdatePlayerConnections", true )
}

void function OnHidePrivateMatchGameStatusMenu()
{
	
	if ( !HasMatchAdminRole() )
		return

	DeRegisterInputs()

	RunClientScript( "PrivateMatch_ToggleUpdatePlayerConnections", false )
}

void function OnPrivateMatchStateChange( int gameState )
{
	TryInitializeGameStatusMenu()

	TabData tabData        	= GetTabDataForPanel( file.menu )
	TabDef inGameSummary 	= Tab_GetTabDefByBodyName( tabData, "PrivateMatchOverviewPanel" )
	TabDef postGameSummary 	= Tab_GetTabDefByBodyName( tabData, "PrivateMatchSummaryPanel" )

	bool summaryActive 		= tabData.activeTabIdx == eGameStatusPanel.PM_GAMEPANEL_INGAME_SUMMARY

	bool midGame = gameState < eGameState.WinnerDetermined
	bool isBattleRoyale = ( GetCurrentPlaylistVarString( "stats_match_type", "survival" ) == "survival" )
	bool isStandardBR = ( GetCurrentPlaylistVarInt( "max_teams", 20 ) <= 20 )
	SetTabDefVisible( inGameSummary, midGame && isBattleRoyale && isStandardBR)
	SetTabDefVisible( postGameSummary, isBattleRoyale && !midGame && isStandardBR )

	if ( !midGame && summaryActive )
		ActivateTab( tabData, eGameStatusPanel.PM_GAMEPANEL_POSTGAME_SUMMARY )
}


void function OnClosePrivateMatchGameStatusMenu()
{
	if ( !HasMatchAdminRole() )
		return

	DeRegisterInputs()

	file.updateConnections = false
}


bool function CanNavigateBack()
{
	return file.disableNavigateBack != true
}


void function OnNavigateBack()
{
	ClosePrivateMatchGameStatusMenu( null )
}


void function EnablePrivateMatchGameStatusMenu( bool doEnable )
{
	file.enableMenu = doEnable
}


bool function IsPrivateMatchGameStatusMenuOpen()
{
	return GetActiveMenu() == file.menu
}

void function TogglePrivateMatchGameStatusMenu( var button )
{
	if ( !IsPrivateMatch() )
		return

	if ( GetActiveMenu() == file.menu )
		thread CloseActiveMenu()

	if ( file.enableMenu == true )
		AdvanceMenu( file.menu )
}


void function OpenPrivateMatchGameStatusMenu( var button )
{
	if ( !IsPrivateMatch() )
		return

	if ( file.enableMenu == false )
		return

	CloseAllMenus()
	AdvanceMenu( file.menu )
}

void function ChatModeButton_OnActivate( var button )
{
	if ( HasMatchAdminRole() )
	{
		RunClientScript( "PrivateMatch_CycleAdminChatMode" )
	}
}

void function ChatSpectatorCheckBox_OnActivate( var button )
{
	if ( HasMatchAdminRole() )
	{
		RunClientScript( "PrivateMatch_ToggleAdminSpectatorChat" )
	}
}

void function ClosePrivateMatchGameStatusMenu( var button )
{
	if ( GetActiveMenu() == file.menu )
		thread CloseActiveMenu()
}



