global function InitMainMenu
global function LaunchMP
global function AttemptLaunch
global function GetUserSignInState
global function UpdateSignedInState
global function SetLaunchingState
global function GetLaunchingState
global function CanAutoRetryConnect
global function EnableAutoRetryConnect

#if DEV
global function Dev_ResetFirstTimeUserState
#endif

struct
{
	var menu
	var titleArt
	var versionDisplay
	var signedInDisplay
	bool canAutoRetryConnect = true






	int launching = eLaunching.FALSE
} file

#if DEV
void function Dev_ResetFirstTimeUserState()
{
	SetFirstTimePlayerState( eNewPlayerState.NEVER_PLAYED )
}
#endif

void function InitMainMenu( var newMenuArg ) 
{
	var menu = GetMenu( "MainMenu" )
	file.menu = menu

	SetGamepadCursorEnabled( menu, false )

	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnMainMenu_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnMainMenu_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnMainMenu_NavigateBack )

	file.titleArt = Hud_GetChild( file.menu, "TitleArt" )
	var titleArtRui = Hud_GetRui( file.titleArt )
	RuiSetImage( titleArtRui, "basicImage", $"ui/menu/title_screen/title_art" )

	var subtitleRui = Hud_GetRui( Hud_GetChild( file.menu, "Subtitle" ) )
	RuiSetString( subtitleRui, "subtitleText", Localize( "#BP_S19_NAME").toupper() )
	if ( GetLanguage() == "polish" )
		RuiSetBool( subtitleRui, "useAltFont", true )

	file.versionDisplay = Hud_GetChild( menu, "VersionDisplay" )
	file.signedInDisplay = Hud_GetChild( menu, "SignInDisplay" )





	file.canAutoRetryConnect = true
}


void function OnMainMenu_Show()
{
	
	
	float aspectRatio = 2.4 
	int width = int( Hud_GetHeight( file.titleArt ) * aspectRatio )
	Hud_SetWidth( file.titleArt, width )

	Hud_SetText( file.versionDisplay, GetPublicGameVersion() )
	Hud_Show( file.versionDisplay )

	ActivatePanel( GetPanel( "MainMenuPanel" ) )

	Chroma_MainMenu()











	SetMenuNavigationDisabled( true )
}


void function OnMainMenu_Close()
{
	HidePanel( GetPanel( "MainMenuPanel" ) )
	SetMenuNavigationDisabled( false )
}


void function ActivatePanel( var panel )
{
	Assert( panel != null )

	array<var> elems = GetElementsByClassname( file.menu, "MainMenuPanelClass" )
	foreach ( elem in elems )
	{
		if ( elem != panel && Hud_IsVisible( elem ) )
			HidePanel( elem )
	}

	ShowPanel( panel )
}


void function OnMainMenu_NavigateBack()
{
	if ( IsSearchingForPartyServer() )
	{
		StopSearchForPartyServer( "", Localize( "#MAINMENU_CONTINUE" ) )
		return
	}


		OpenConfirmExitToDesktopDialog()

}


int function GetUserSignInState()
{

















	return userSignInState.SIGNED_IN
}


void function UpdateSignedInState()
{	







	Hud_SetText( file.signedInDisplay, "" )
}


void function SetLaunchingState( int val )
{
	file.launching = val
}


int function GetLaunchingState()
{
	return file.launching
}


void function LaunchMP()
{
	SetLaunchingState( eLaunching.MULTIPLAYER )
	AttemptLaunch()
}

void function UpdateMessageSuppressionFlags()
{

	if ( !GetConVarBool( "ftue_flow_enabled" ) )
	{
		SetFeatureSuppressed( eFeatureSuppressionFlags.ALL, false ) 
		return
	}

	string playerHardware = GetPlayerHardware()
	string userID = GetConVarString( "platform_user_id" )
	int retrieveAttempts = 0
	CommunityUserInfo ornull userInfo = GetUserInfo( playerHardware, userID )
	while (userInfo == null)
	{
		retrieveAttempts++
		if( retrieveAttempts > 999 )
		{
			Warning( "Timed out when attempting to retrieve User Info for first time player detection" )
			return
		}

		WaitFrame()
		userInfo = GetUserInfo( playerHardware, userID )
	}

	expect CommunityUserInfo( userInfo )
	if ( userInfo.matches <= 0 )
	{
		SetFeatureSuppressed( eFeatureSuppressionFlags.ALL, true )
	}
	else if( GetFirstTimePlayerState() < eNewPlayerState.FIRST_MATCH_PLAYED )
	{
		SetFeatureSuppressed( eFeatureSuppressionFlags.ALL, false ) 
		SetFirstTimePlayerState( eNewPlayerState.FIRST_MATCH_PLAYED )
	}

}

bool function TryPlayIntroVideo()
{
	if ( GetActiveMenu() == GetMenu( "PlayVideoMenu" ) )
		return false

	const int CURRENT_INTRO_VIDEO_VERSION = 17

	VideoPlaySettings settings
	settings.videoCompleteFunc = PrelaunchValidateAndLaunch
	settings.forceSubtitles = true
	settings.skipRule = eVideoSkipRule.HOLD

	if( ShouldShowFirstPlayIntro() )
	{
		if ( GetLanguage() == "english" )
			settings.video = WELCOME_VIDEO
		else
			settings.video = WELCOME_INT_VIDEO

		settings.milesAudio = WELCOME_AUDIO_EVENT

		SetFirstTimePlayerState( eNewPlayerState.SEEN_INTRO )
	}
	else if ( ShouldShowIntro( CURRENT_INTRO_VIDEO_VERSION ) )
	{
		settings.video = INTRO_VIDEO
		settings.milesAudio = INTRO_AUDIO_EVENT

		SetIntroViewedVersion( CURRENT_INTRO_VIDEO_VERSION )
	}
	else
	{
		return false
	}

	Assert(settings.video.len() > 0)

	if ( IsDialog( GetActiveMenu() ) )
		CloseActiveMenu()

	PlayVideoMenu( true, settings )
	return true
}

void function AttemptLaunch()
{
	int launching = GetLaunchingState()
	if ( launching == eLaunching.FALSE )
		return

	UpdateMessageSuppressionFlags()

	Assert( launching == eLaunching.MULTIPLAYER || launching == eLaunching.MULTIPLAYER_INVITE )































	if( TryPlayIntroVideo() )
		return

	if ( TryLoadSpectateParameters() || ( CanAutoRetryConnect() && TryLoadReconnectFromLocalStorage() ) )
	{
		DisableAutoRetryConnect()
		thread DelayedReconnect()
	}
	else
	{
		StartSearchForPartyServer()
	}

	SetLaunchingState( eLaunching.FALSE )




}

void function EnableAutoRetryConnect()
{
	file.canAutoRetryConnect = true
}

void function DisableAutoRetryConnect()
{
	file.canAutoRetryConnect = false
}

bool function CanAutoRetryConnect()
{
	return file.canAutoRetryConnect
}

void function DelayedReconnect()
{
	float delay = GetReconnectDelay()
	printt( FUNC_NAME(), delay )

	Wait( delay )

	if ( Reconnect_IsLiveSpectateLoaded() )
		EmitUISound( "diag_mp_crypto_bc_droneviewstart_calm_1p" )

	if( StartReconnectFromParameters() )
		EnableAutoRetryConnect()
}

bool function ShouldShowFirstPlayIntro()
{
	if ( !GetConVarBool( "ftue_flow_enabled" ) )
		return false

	if ( GetConVarBool( "autoConnect" ) )
		return false

#if DEV
	if ( GetConVarBool( "skipIntroVideos" ) )
		return false
#endif


	return GetFirstTimePlayerState() < eNewPlayerState.SEEN_INTRO




}

bool function ShouldShowIntro( int introVersion )
{
	if ( GetConVarBool( "autoConnect" ) )
		return false

#if DEV
	if ( GetConVarBool( "skipIntroVideos" ) )
		return false
#endif


	if ( GetConVarBool( "ftue_flow_enabled" ) && GetFirstTimePlayerState() < eNewPlayerState.FIRST_MATCH_PLAYED )
		return false


	if ( GetIntroViewedVersion() < introVersion )
		return true
	if ( InputIsButtonDown( KEY_LSHIFT ) && InputIsButtonDown( KEY_LCONTROL ) )
		return true
	if ( InputIsButtonDown( BUTTON_TRIGGER_LEFT_FULL ) && InputIsButtonDown( BUTTON_TRIGGER_RIGHT_FULL ) )
		return true

	return false
}













