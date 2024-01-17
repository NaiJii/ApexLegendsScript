
global function InitMainMenuPanel
global function StartSearchForPartyServer
global function StopSearchForPartyServer
global function IsSearchingForPartyServer
global function SetLaunchState
global function PrelaunchValidateAndLaunch

global function IsCrossProgressing
global function UICodeCallback_XProgCheckRolloutRequestFinished
global function UICodeCallback_XProgMigrateRequestFinished
global function UICodeCallback_XProgMigrateStatusRequestFinished
global function UICodeCallback_XProgMigrateFlowFailed
global function UICodeCallback_XProgMigrateNotificationRequestFinished
global function UI_CrossProgression_DoMigrateFlow

global function UICodeCallback_GetOnPartyServer













#if DEV
global function DEV_ToggleRuiIssuesDemo
#endif

const bool SPINNER_DEBUG_INFO = PC_PROG

const int MIGRATE_DEFAULT_RETRY_MINUTES = 180
const float REAUTH_REQUEST_TIMEOUT = 10.0

struct
{
	var                menu
	var                panel
	var                status
	var                launchButton
	void functionref() launchButtonActivateFunc = null
	var                statusDetails
	bool               statusDetailsVisiblity = false
	
	bool               working = false
	bool               searching = false
	bool               crossProgressing = false
	bool			   hasReconnectFile = false
	bool               isNucleusProcessActive = false
	var				   serverSearchMessage
	var				   serverSearchError
	bool				needsEAAccountRegistration = false


		bool xProgCheckRolloutRequestFinished = false
		bool xProgCheckNotificationRequestFinished = false
		bool xProgRequestMigrateFinished = false
		bool xProgMigrateDoneWithMTXData = false
		bool xProgMigrateFailed = false






	float startTime = 0
} file

#if SPINNER_DEBUG_INFO
void function SetSpinnerDebugInfo( string message )
{
	if ( GetConVarBool( "spinner_debug_info" ) )
	{
		Assert( file.working )
		SetLaunchState( eLaunchState.WORKING, message )
	}
}
#endif

void function InitMainMenuPanel( var panel )
{
	RegisterSignal( "EndPrelaunchValidation" )
	RegisterSignal( "EndSearchForPartyServerTimeout" )
	RegisterSignal( "EndSetMainProfileForCrossProgressionTimeout" )
	RegisterSignal( "EndMigrateFlow" )
	RegisterSignal( "SetLaunchState" )
	RegisterSignal( "MainMenu_Think" )

	file.panel = GetPanel( "MainMenuPanel" )
	file.menu = GetParentMenu( file.panel )

#if DEV
	AddMenuThinkFunc( file.menu, MainMenuPanelAutomationThink )
#endif

	AddPanelEventHandler( file.panel, eUIEvent.PANEL_SHOW, OnMainMenuPanel_Show )
	AddPanelEventHandler( file.panel, eUIEvent.PANEL_HIDE, OnMainMenuPanel_Hide )

	file.launchButton = Hud_GetChild( panel, "LaunchButton" )
	Hud_AddEventHandler( file.launchButton, UIE_CLICK, LaunchButton_OnActivate )

	file.status = Hud_GetRui( Hud_GetChild( panel, "Status" ) )
	file.statusDetails = Hud_GetRui( Hud_GetChild( file.panel, "StatusDetails" ) )
	file.serverSearchMessage = Hud_GetChild( file.panel, "ServerSearchMessage" )
	file.serverSearchError = Hud_GetChild( file.panel, "ServerSearchError" )







	

#if DEV
		if ( GetBugReproNum() == 233677 )
		{
			AddPanelFooterOption( panel, LEFT, BUTTON_Y, true, "", "" )
			var footerButtons = Hud_GetChild( file.menu, "FooterButtons" )
			var leftRuiFooterButton0 = Hud_GetChild( footerButtons, "LeftRuiFooterButton0" )
			thread DEV_TestFooterTextWidths( leftRuiFooterButton0 )
		}
#endif


		AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_EXIT_TO_DESKTOP", "#B_BUTTON_EXIT_TO_DESKTOP", null, IsExitToDesktopFooterValid )
		AddPanelFooterOption( panel, LEFT, KEY_TAB, false, "", "#DATACENTER_DOWNLOADING", OpenDataCenterDialog, IsDataCenterFooterVisible, UpdateDataCenterFooter )

	AddPanelFooterOption( panel, LEFT, BUTTON_STICK_RIGHT, false, "#DATACENTER_DOWNLOADING", "", OpenDataCenterDialog, IsDataCenterFooterVisible, UpdateDataCenterFooter )

	file.hasReconnectFile = TryLoadReconnectFromLocalStorage()

		AddPanelFooterOption( panel, LEFT, KEY_Q, true, "", "#BUTTON_RETRY_CONNECT", RetryConnect_OnActivate, IsRetryConnectFooterValid )

	AddPanelFooterOption( panel, LEFT, BUTTON_X, true, "#BUTTON_RETRY_CONNECT", "", RetryConnect_OnActivate, IsRetryConnectFooterValid )

	AddPanelFooterOption( panel, LEFT, BUTTON_START, true, "#START_BUTTON_ACCESSIBLITY", "#BUTTON_ACCESSIBLITY", Accessibility_OnActivate, IsAccessibilityFooterValid )





}

#if DEV
void function MainMenuPanelAutomationThink( var menu )
{
	if (AutomateUi())
	{
		printt("MainMenuPanelAutomationThink LaunchButton_OnActivate()")
		LaunchButton_OnActivate(null)
	}
}
#endif

void function RetryConnect_OnActivate( var button )
{
	if ( IsRetryConnectFooterValid() )
	{
		EnableAutoRetryConnect()
		LaunchButton_OnActivate(null)
	}
}

bool function IsRetryConnectFooterValid()
{
	return !IsWorking() && !IsSearchingForPartyServer() && !IsCrossProgressing() && file.hasReconnectFile && !CanAutoRetryConnect()
}


bool function IsExitToDesktopFooterValid()
{
	return !IsWorking() && !IsSearchingForPartyServer() && !IsCrossProgressing()
}



bool function IsAccessibilityFooterValid()
{
	if ( !IsAccessibilityAvailable() )
		return false




		return !IsWorking() && !IsSearchingForPartyServer() && !IsCrossProgressing()

}

bool function IsDataCenterFooterVisible()
{
	return !IsWorking() && !IsSearchingForPartyServer() && !IsCrossProgressing()
}


bool function IsDataCenterFooterClickable()
{
#if DEV
	bool hideDurationElapsed = true
#else
	bool hideDurationElapsed = UITime() - file.startTime > 10.0
#endif




		return !IsWorking() && !IsSearchingForPartyServer() && !IsCrossProgressing() && hideDurationElapsed

}

void function UpdateDataCenterFooter( InputDef footerData )
{
	string label = "#DATACENTER_DOWNLOADING"
	if ( !IsDatacenterMatchmakingOk() )
	{
		if ( IsSendingDatacenterPings() )
			label = Localize( "#DATACENTER_CALCULATING" )
		else
			label = Localize( label, GetDatacenterDownloadStatusCode() )
	}
	else
	{
		label = Localize( "#DATACENTER_INFO", GetDatacenterName(), GetDatacenterMinPing(), GetDatacenterPing(), GetDatacenterPacketLoss(), GetDatacenterSelectedReasonSymbol() )
		if ( IsDataCenterFooterClickable() )
			footerData.clickable = true
	}

	var elem = footerData.vguiElem
	Hud_SetText( elem, label )
	Hud_Show( elem )
}

void function OnDataCenterDialog_Close()
{
	SetMenuNavigationDisabled( true )
}

void function OnMainMenuPanel_Show( var panel )
{
	DataDialog_AddCallback_OnClose( OnDataCenterDialog_Close )

	file.startTime = UITime()

	AccessibilityHintReset()
	EnterLobbySurveyReset()

	thread MainMenu_Think()

	thread PrelaunchValidation( GetConVarBool( "autoConnect" ) )

	ExecCurrentGamepadButtonConfig()
	ExecCurrentGamepadStickConfig()
}

void function MainMenu_Think()
{
	Signal( uiGlobal.signalDummy, "MainMenu_Think" )
	EndSignal( uiGlobal.signalDummy, "MainMenu_Think" )

	while ( true )
	{
		
#if DEV
		    if ( GetBugReproNum() != 233677 )
#endif
		UpdateFooterOptions()

		WaitFrame()
	}
}


void function PrelaunchValidateAndLaunch()
{
	printt( "*** PrelaunchValidateAndLaunch");
	thread PrelaunchValidation( true )
}


void function PrelaunchValidation( bool autoContinue = false )
{
	printt( "*** PrelaunchValidation");
	EndSignal( uiGlobal.signalDummy, "EndPrelaunchValidation" )

	SetLaunchState( eLaunchState.WORKING )

#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "PrelaunchValidation" )
#endif


		bool isPCPlatEnabled = PCPlat_IsEnabled()
		string platToken = PCPlat_IsSteam() ? "STEAM" : "ORIGIN"
		PrintLaunchDebugVal( "isPCPlatEnabled", isPCPlatEnabled )
		if ( !isPCPlatEnabled )
		{
#if DEV
				if ( autoContinue )
					LaunchMP()
				else
					SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )

				return
#endif

			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#"+platToken+"_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isOriginConnected = isPCPlatEnabled ? PCPlat_IsOnline() : true
		PrintLaunchDebugVal( "isPCPlatConnected", isPCPlatEnabled )
		if ( !isOriginConnected )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#"+platToken+"_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isPCPlatLatest = PCPlat_IsUpToDate()
		PrintLaunchDebugVal( "isOriginLatest", isPCPlatLatest )
		if ( !isPCPlatLatest )
		{
			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#TITLE_UPDATE_AVAILABLE" ) )
			return
		}

























	bool hasLatestPatch = HasLatestPatch()
	PrintLaunchDebugVal( "hasLatestPatch", hasLatestPatch )
	if ( !hasLatestPatch )
	{
		SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#TITLE_UPDATE_AVAILABLE" ) )
		return
	}


		bool isPCPlatAccountAvailable = true 
		PrintLaunchDebugVal( "isPCPlatAccountAvailable", isPCPlatAccountAvailable )
		if ( !isPCPlatAccountAvailable )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#"+platToken+"_ACCOUNT_IN_USE" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isPCPlatLoggedIn = true 
		PrintLaunchDebugVal( "isPCPlatLoggedIn", isPCPlatLoggedIn )
		if ( !isPCPlatLoggedIn )
		{
			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#"+platToken+"_NOT_LOGGED_IN" ), Localize( "#MAINMENU_RETRY" ) )
			return
		}

		bool isPCPlatAgeApproved = MeetsAgeRequirements()
		PrintLaunchDebugVal( "isPCPlatAgeApproved", isPCPlatAgeApproved )
		if ( !isPCPlatAgeApproved )
		{
			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#MULTIPLAYER_AGE_RESTRICTED" ) )
			return
		}

		if ( PCPlat_IsSteam() )
		{
			if ( file.needsEAAccountRegistration )
			{
				file.needsEAAccountRegistration = false
				PCPlat_RegisterEAAccount()
			}

			while( !PCPlat_IsReady() )
			{
				if ( !PCPlat_IsOnline() )
				{
					SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#"+platToken+"_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )
					return
				}

				if ( PCPlat_IsWaitingForEARegistration() )
				{
					file.needsEAAccountRegistration = true

					SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#STEAM_EA_ACCOUNT_REQUIRED"), Localize( "#STEAM_REGISTER_BUTTON" ) )
					return
				}

				int errorLevel = PCPlat_GetEALinkErrorLevel()
				if ( errorLevel != 0 )
				{
					SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#STEAM_EA_ACCOUNT_ERROR" ) + "\nError: " + errorLevel )
					return
				}

				WaitFrame()
			}
		}

#if SPINNER_DEBUG_INFO
		SetSpinnerDebugInfo( "isPCPlatReady" )
#endif
		while ( true )
		{
			bool isPCPlatReady = PCPlat_IsReady()
			PrintLaunchDebugVal( "isPCPlatReady", isPCPlatReady )
			if ( isPCPlatReady )
				break

			WaitFrame()
		}



































































































































	bool hasPermission = HasPermission()
	PrintLaunchDebugVal( "hasPermission", hasPermission )
	if ( !hasPermission )
	{
















			SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#MULTIPLAYER_NOT_AVAILABLE" ) )

		return
	}
















































#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "isAuthenticatedByStryder" )
#endif
	float startTime = UITime()
	while ( true )
	{
		bool isAuthenticatedByStryder = IsStryderAuthenticated()
		PrintLaunchDebugVal( "isAuthenticatedByStryder", isAuthenticatedByStryder )

		if ( isAuthenticatedByStryder )
			break
		if ( UITime() - startTime > 10.0 )
		{



				SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#ORIGIN_IS_OFFLINE" ), Localize( "#MAINMENU_RETRY" ) )

			return
		}

		WaitFrame()
	}

	bool isMPAllowedByStryder = IsStryderAllowingMP()
	PrintLaunchDebugVal( "isMPAllowedByStryder", isMPAllowedByStryder )
	if ( !isMPAllowedByStryder )
	{
		string unavailableString = "#MULTIPLAYER_NOT_AVAILABLE"
		if ( IsPlayerLoggedInToMultipleMachines() )
			unavailableString = "#MULTIPLAYER_NOT_AVAILABLE_MULTIPLE_LOGIN"

		SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( unavailableString ), Localize( "#MAINMENU_RETRY" ) )
		return
	}


















	if ( !file.xProgMigrateFailed && GetConVarBool( "CrossProgression_CheckRollout" ) )
	{
		if ( !CrossProgression_IsMigrated() )
		{
			
			if ( !file.xProgCheckRolloutRequestFinished )
			{
#if SPINNER_DEBUG_INFO
					SetSpinnerDebugInfo( "CheckRolloutForCrossProgression" )
#endif

				const float CHECK_ROLLOUT_TIMEOUT = 10.0
				float startTimeCheckRollout = UITime()

				CrossProgression_RequestCheckRollout()

				while ( true )
				{
					PrintLaunchDebugVal( "[CrossProgression] xProgCheckRolloutRequestFinished", file.xProgCheckRolloutRequestFinished )

					if ( file.xProgCheckRolloutRequestFinished )
						break

					if ( UITime() - startTimeCheckRollout > CHECK_ROLLOUT_TIMEOUT )
					{
						
						file.xProgMigrateFailed = true
						printt( "[CrossProgression] CheckRollout Timeout" )
						break
					}

					WaitFrame()
				}
			}
			else
			{
				
				UICodeCallback_XProgCheckRolloutRequestFinished()
			}

			SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )
			return
		}

#if SPINNER_DEBUG_INFO
			SetSpinnerDebugInfo( "ReAuthenticatedByStryder" )
#endif
		float startTimeReAuth = UITime()
		while ( true )
		{
			bool isReAuthenticatedByStryder = IsStryderAuthenticated()
			PrintLaunchDebugVal( "[CrossProgression] isReAuthenticatedByStryder", isReAuthenticatedByStryder )

			if ( isReAuthenticatedByStryder )
				break

			if ( UITime() - startTimeReAuth > REAUTH_REQUEST_TIMEOUT )
			{
				SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, Localize( "#CROSS_PROGRESSION_REAUTH_NOT_AVAILABLE" ), Localize( "#MAINMENU_RETRY" ) )
				return
			}

			WaitFrame()
		}
	}
	else if ( CrossProgression_IsOfflineMigration() && !file.xProgCheckNotificationRequestFinished )
	{
#if SPINNER_DEBUG_INFO
			SetSpinnerDebugInfo( "CheckNotificationForCrossProgression" )
#endif

		const float CHECK_NOTIFICATION_TIMEOUT = 10.0
		float startTimeCheckNotification = UITime()

		CrossProgression_RequestMigrateNotification();

		while ( true )
		{
			PrintLaunchDebugVal( "[CrossProgression] xProgCheckNotificationRequestFinished", file.xProgCheckNotificationRequestFinished )

			if ( file.xProgCheckNotificationRequestFinished )
				break

			if ( UITime() - startTimeCheckNotification > CHECK_NOTIFICATION_TIMEOUT )
			{
				file.xProgCheckNotificationRequestFinished = true
				printt( "[CrossProgression] CheckNotification Timeout" )
				break
			}

			WaitFrame()
		}
	}

	if ( GetConVarBool("CrossProgression_ForceMigrate" ) && !CrossProgression_IsMigrated() )
	{
		SetLaunchState( eLaunchState.CANT_CONTINUE, Localize( "#CROSS_PROGRESSION_FORCE_MIGRATE" ) )
		return;
	}
























	if ( autoContinue )
		LaunchMP()
	else
		SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )
}


void function OnMainMenuPanel_Hide( var panel )
{
	Signal( uiGlobal.signalDummy, "MainMenu_Think" )
	Signal( uiGlobal.signalDummy, "EndPrelaunchValidation" )
	file.working = false
	file.searching = false
	file.crossProgressing = false



}


void function SetLaunchState( int launchState, string details = "", string prompt = "" )
{
	printt( "*** SetLaunchState *** launchState: " + GetEnumString( "eLaunchState", launchState ) + " details: \"" + details + "\" prompt: \"" + prompt + "\"" )

	if ( launchState == eLaunchState.WAIT_TO_CONTINUE )
	{
		printt( "*** Setting LaunchButton_OnActivate ***  PrelaunchValidateAndLaunch")
		file.launchButtonActivateFunc = PrelaunchValidateAndLaunch
		AccessibilityHint( eAccessibilityHint.LAUNCH_TO_LOBBY )
	}
	else
	{
		printt( "*** Setting LaunchButton_OnActivate ***  NULL")
		file.launchButtonActivateFunc = null
	}

	Hud_SetVisible( file.launchButton, launchState == eLaunchState.WAIT_TO_CONTINUE )

	RuiSetString( file.status, "prompt", prompt )
	RuiSetBool( file.status, "showPrompt", prompt != "" )

	file.working = launchState == eLaunchState.WORKING
	RuiSetBool( file.status, "showSpinner", file.working )

	thread ShowStatusMessagesAfterDelay()

	if ( details == "" )
		details = GetConVarString( "rspn_motd" )

	if ( details != "" )
		RuiSetString( file.statusDetails, "details", details )

	bool lastStatusDetailsVisiblity = file.statusDetailsVisiblity
	file.statusDetailsVisiblity = details != ""

	if ( file.statusDetailsVisiblity == true || ( file.statusDetailsVisiblity == false && lastStatusDetailsVisiblity != false ) )
	{
		RuiSetBool( file.statusDetails, "ruiVisible", file.statusDetailsVisiblity )
		RuiSetGameTime( file.statusDetails, "initTime", ClientTime() )
	}

	UpdateSignedInState()
	UpdateFooterOptions()
}


void function ShowStatusMessagesAfterDelay()
{
	Signal( uiGlobal.signalDummy, "SetLaunchState" )
	EndSignal( uiGlobal.signalDummy, "SetLaunchState" )

	if ( !IsWorking() )
		return

	wait 5.0

	if ( !IsWorking() )
		return

	OnThreadEnd(
		function() : (  )
		{
			Hud_SetVisible( file.serverSearchMessage, false )
			Hud_SetVisible( file.serverSearchError, false )
		}
	)

	Hud_SetVisible( file.serverSearchMessage, true )
	Hud_SetVisible( file.serverSearchError, true )

	WaitForever()
}


bool function IsWorking()
{
	return file.working
}



void function DoMigrateFlow()
{
	EndSignal( uiGlobal.signalDummy, "EndMigrateFlow" )

	file.crossProgressing = true
	SetLaunchState( eLaunchState.WORKING )

	CrossProgression_RequestMigrate()

	const float MIGRATE_FLOW_TIMEOUT = 180.0
	float startTimeMigrate = UITime()

	const float QUERY_STATUS_INTERVAL = 10.0
	float nextTimeRequestStatus       = 0.0

	while ( true )
	{
		float currentTime = UITime()
		if ( currentTime - startTimeMigrate > MIGRATE_FLOW_TIMEOUT )
		{
			file.xProgMigrateFailed = true
			printt( "[CrossProgression] DoMigrateFlow Timeout" )

			UI_CloseCrossProgressionDialog()
			ConfirmDialogData data
			data.headerText = Localize( "#CROSS_PROGRESSION_MIGRATE_COOLINGDOWN_TITLE" )
			data.messageText = Localize( "#CROSS_PROGRESSION_MIGRATE_COOLINGDOWN_DESC", string( MIGRATE_DEFAULT_RETRY_MINUTES ) )
			OpenOKDialogFromData( data )

			break
		}

		if ( file.xProgMigrateFailed )
			break

		if ( CrossProgression_IsMigrated() )
		{
			XProgMigrateData migrateData = CrossProgressionGetMigrateData()
			if ( !file.xProgMigrateDoneWithMTXData && migrateData.hasMultipleProfiles )
				CrossProgression_RequestMigrateStatus()

			break
		}

		if ( file.xProgRequestMigrateFinished && currentTime > nextTimeRequestStatus )
		{
			if ( nextTimeRequestStatus > QUERY_STATUS_INTERVAL )
				CrossProgression_RequestMigrateStatus()

			nextTimeRequestStatus = currentTime + QUERY_STATUS_INTERVAL
		}

		WaitFrame()
	}

	file.crossProgressing = false
	SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, "", Localize( "#MAINMENU_CONTINUE" ) )
}

bool function IsCrossProgressionMigrateFlowEnabled()
{
	if ( !GetConVarBool( "CrossProgression_Ready" ) )
		return false

	if ( file.xProgMigrateFailed )
		return false

	return true
}


void function UI_CrossProgression_DoMigrateFlow()
{

		thread DoMigrateFlow()

}

void function UICodeCallback_XProgCheckRolloutRequestFinished()
{

		printt( "[CrossProgression] UICodeCallback_XProgCheckRolloutRequestFinished")

		file.xProgCheckRolloutRequestFinished = true

		if ( IsCrossProgressionMigrateFlowEnabled() && !CrossProgression_IsMigrated() )
		{
			RTKCrossProgressionPanel_SetDialogHeight()
			UI_OpenCrossProgressionDialog()
		}

}

void function UICodeCallback_XProgMigrateRequestFinished()
{

		printt( "[CrossProgression] UICodeCallback_XProgMigrateRequestFinished" )
		file.xProgRequestMigrateFinished = true

		if ( CrossProgression_IsMigrated() )
		{
			XProgMigrateData migrateData = CrossProgressionGetMigrateData()

			if ( migrateData.hasMultipleProfiles )
			{
				RTKCrossProgressionPanel_SetHeader()
				RTKCrossProgressionPanel_SetDialogHeight()
				RTKCrossProgressionPanel_UpdateDataModel()
				UI_OpenCrossProgressionDialog()
			}
			else
			{
				UI_CloseCrossProgressionDialog()
			}
		}

}


void function UICodeCallback_XProgMigrateStatusRequestFinished()
{

		printt( "[CrossProgression] UICodeCallback_XProgMigrateStatusRequestFinished")

		XProgMigrateData migrateData = CrossProgressionGetMigrateData()
		printt( "[CrossProgression] XProgStatus process state: ", migrateData.processStatus )

		if ( CrossProgression_IsMigrated() )
		{
			file.xProgMigrateDoneWithMTXData = true

			UICodeCallback_XProgMigrateRequestFinished()

			printt( "[CrossProgression] EA ID: ", migrateData.eaId )
			printt( "[CrossProgression] Nickname: ", migrateData.nickname )
			printt( "[CrossProgression] Level: ", migrateData.level )
			printt( "[CrossProgression] Herirlooms: ", migrateData.heirloom )
			printt( "[CrossProgression] Herirloom Shards ", migrateData.heirloomShards )
			printt( "[CrossProgression] Apex Packs ", migrateData.apexPacks )
			printt( "[CrossProgression] Total (Cosmetics)", migrateData.cosmetics )
			printt( "[CrossProgression] Legend Tokens", migrateData.credits )
			printt( "[CrossProgression] Crafting Metals", migrateData.crafting )
			printt( "[CrossProgression] Nintendo AC", migrateData.premiumNx )
			printt( "[CrossProgression] All other AC", migrateData.premium )
		}

}

void function UICodeCallback_XProgMigrateNotificationRequestFinished()
{

		printt( "[CrossProgression] UICodeCallback_XProgMigrateNotificationRequestFinished")
		file.xProgCheckNotificationRequestFinished = true;
		UI_OpenCrossProgressionDialog();

}

void function UICodeCallback_XProgMigrateFlowFailed()
{

		printt( "[CrossProgression] UICodeCallback_XProgMigrateFlowFailed")

		file.xProgMigrateFailed = true

		XProgMigrateData migrateData = CrossProgressionGetMigrateData()
		UI_CloseCrossProgressionDialog()
		ConfirmDialogData data
		data.headerText = Localize( "#CROSS_PROGRESSION_MIGRATE_COOLINGDOWN_TITLE" )
		data.messageText = Localize( "#CROSS_PROGRESSION_MIGRATE_COOLINGDOWN_DESC" )
		OpenOKDialogFromData( data )

}

bool function IsCrossProgressing()
{

	return IsCrossProgressionMigrateFlowEnabled() && file.crossProgressing


	return false
}


void function StartSearchForPartyServer()
{







	SearchForPartyServer()
	SetLaunchState( eLaunchState.WORKING )
	file.searching = true

#if SPINNER_DEBUG_INFO
	SetSpinnerDebugInfo( "SearchForPartyServer" )
#endif

	UpdateSignedInState()
	UpdateFooterOptions()

	thread SearchForPartyServerTimeout()
}


void function SearchForPartyServerTimeout()
{
	EndSignal( uiGlobal.signalDummy, "EndSearchForPartyServerTimeout" )

	Hud_SetAutoText( file.serverSearchMessage, "", HATT_MATCHMAKING_EMPTY_SERVER_SEARCH_STATE, 0 )
	Hud_SetAutoText( file.serverSearchError, "", HATT_MATCHMAKING_EMPTY_SERVER_SEARCH_ERROR, 0 )

	string noServers              = Localize( "#MATCHMAKING_NOSERVERS" )
	string serverError            = Localize( "#MATCHMAKING_SERVERERROR" )
	string localError             = Localize( "#MATCHMAKING_LOCALERROR" )
	string lastValidSearchMessage = ""
	string lastValidSearchError   = ""
	float startTime               = UITime()

	while ( UITime() - startTime < 30.0 )
	{
		string searchMessage = Hud_GetUTF8Text( file.serverSearchMessage )
		string searchError = Hud_GetUTF8Text( file.serverSearchError )
		

		
		if ( ClientIsPreCaching() )
		{
			startTime = UITime()
		}

		if ( searchMessage == noServers || searchMessage == serverError || searchMessage == localError )
		{
			lastValidSearchMessage = searchMessage
			lastValidSearchError = searchError
		}

		WaitFrame()
	}
	

	string details
	if ( (lastValidSearchMessage == serverError || lastValidSearchMessage == localError) && lastValidSearchError != "" )
		details = Localize( "#UNABLE_TO_CONNECT_ERRORCODE", lastValidSearchError )
	else
		details = Localize( "#UNABLE_TO_CONNECT" )

	thread StopSearchForPartyServer( details, Localize( "#MAINMENU_RETRY" ) )
}


void function StopSearchForPartyServer( string details, string prompt )
{
	Signal( uiGlobal.signalDummy, "EndSearchForPartyServerTimeout" )

	MatchmakingCancel()
	Party_LeaveParty()
	SetLaunchState( eLaunchState.WAIT_TO_CONTINUE, details, prompt )
	file.searching = false

	UpdateSignedInState()
	UpdateFooterOptions()
}


bool function IsSearchingForPartyServer()
{
	return file.searching
}

























































































































































void function LaunchButton_OnActivate( var button )
{
	if ( file.launchButtonActivateFunc == null )
	{
		printt( "*** LaunchButton_OnActivate ***  Null")
		return
	}

	printt( "*** LaunchButton_OnActivate ***", string( file.launchButtonActivateFunc ) )
	thread file.launchButtonActivateFunc()
}


void function UICodeCallback_GetOnPartyServer()
{
	SetLaunchingState( eLaunching.MULTIPLAYER_INVITE )
	PrelaunchValidateAndLaunch()
}


bool function IsStryderAuthenticated()
{
	return GetConVarInt( "mp_allowed" ) != -1
}


bool function IsStryderAllowingMP()
{
	return GetConVarInt( "mp_allowed" ) == 1
}



bool function HasLatestPatch()
{





	return true
}


bool function HasPermission()
{




	return true
}


void function Accessibility_OnActivate( var button )
{





	if ( IsDialog( GetActiveMenu() ) )
		return

	if ( !IsAccessibilityAvailable() )
		return

	AdvanceMenu( GetMenu( "AccessibilityDialog" ) )
}


void function OnConfirmDialogResult( int result )
{
	printt( result )
}


void function PrintLaunchDebugVal( string name, bool val )
{
#if DEV
		printt( "*** PrelaunchValidation *** " + name + ": " + val )
#endif
}







































































void function SwitchProfile_OnActivate( var button )
{













}


bool function IsSwitchProfileFooterValid()
{



		return false

}


#if DEV
void function DEV_TestFooterTextWidths( var elem )
{
	while ( true )
	{
		Hud_SetText( elem, "testing" )
		wait 3
		Hud_SetText( elem, "testing longer" )
		wait 3
		Hud_SetText( elem, "testing even longer" )
		wait 3
		Hud_SetText( elem, "testing even more longer" )
		wait 3
		Hud_SetText( elem, "testing even more more more longer" )
		wait 3
		Hud_SetText( elem, "testing even more more more more more more longer" )
		wait 3
	}
}

void function DEV_ToggleRuiIssuesDemo( string elemName )
{
	var targetElem = Hud_GetChild( file.panel, elemName )

	array<var> elems
	elems.append( Hud_GetChild( file.panel, "RuiIssuesTransparency" ) )
	elems.append( Hud_GetChild( file.panel, "RuiIssuesSamplingBlur" ) )
	elems.append( Hud_GetChild( file.panel, "RuiIssues9SliceScaling" ) )

	foreach ( elem in elems )
	{
		if ( elem == targetElem )
			Hud_SetVisible( elem, !Hud_IsVisible( elem ) )
		else
			Hud_SetVisible( elem, false )
	}
}
#endif

