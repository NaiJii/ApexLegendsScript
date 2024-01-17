global function CollectionEventAboutPage_Init
global function OpenCollectionEventAboutPage
struct {
	var menu
	var infoPanel
} file

void function CollectionEventAboutPage_Init( var menu )
{
	file.menu = menu
	
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, CollectionEventAboutPage_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, CollectionEventAboutPage_OnClose )

	file.infoPanel = Hud_GetChild( file.menu, "InfoPanel" )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function CollectionEventAboutPage_OnOpen()
{
	ItemFlavor ornull activeCollectionEvent = GetActiveCollectionEvent( GetUnixTimestamp() )
	ItemFlavor ornull milestoneEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )

	if ( activeCollectionEvent == null && milestoneEvent == null )
		return

	string eventName = ""
	asset bgPatternImage
	asset headerIcon
	vector specialTextCol
	array<string> aboutLines

	if( activeCollectionEvent != null )
	{
		expect ItemFlavor( activeCollectionEvent )
		eventName = ItemFlavor_GetLongName( activeCollectionEvent )
		bgPatternImage = CollectionEvent_GetBGPatternImage( activeCollectionEvent )
		headerIcon = CollectionEvent_GetHeaderIcon( activeCollectionEvent )
		specialTextCol = SrgbToLinear( CollectionEvent_GetAboutPageSpecialTextCol( activeCollectionEvent ) )
		aboutLines = CollectionEvent_GetAboutText( activeCollectionEvent, GRX_IsOfferRestricted() )
	}
	else if( milestoneEvent != null )
	{
		expect ItemFlavor( milestoneEvent )

		eventName = ItemFlavor_GetLongName( milestoneEvent )
		headerIcon = MilestoneEvent_GetLandingPageImage( milestoneEvent )
		specialTextCol = SrgbToLinear( MilestoneEvent_GetDisclaimerBoxColor( milestoneEvent ) )
		aboutLines = MilestoneEvent_GetAboutText( milestoneEvent, GRX_IsOfferRestricted() )
	}

	Assert( aboutLines.len() < 8, "Rui about_collection_event does not support more than 6 lines." )
	HudElem_SetRuiArg( file.infoPanel, "eventName", eventName )
	HudElem_SetRuiArg( file.infoPanel, "bgPatternImage", bgPatternImage )
	HudElem_SetRuiArg( file.infoPanel, "headerIcon", headerIcon )
	HudElem_SetRuiArg( file.infoPanel, "specialTextCol", specialTextCol )

	foreach ( int lineIdx, string line in aboutLines )
	{
		if ( line == "" )
			continue

		string aboutLine = "%@embedded_bullet_point%" + Localize( line )
		HudElem_SetRuiArg( file.infoPanel, "aboutLine" + lineIdx, aboutLine )
	}
}


void function CollectionEventAboutPage_OnClose()
{
	RunClientScript( "UIToClient_StopBattlePassScene" )
}

void function OpenCollectionEventAboutPage( var button )
{
	if ( IsDialog( GetActiveMenu() ) )
		return

	AdvanceMenu( GetMenu( "CollectionEventAboutPage" ) )
}

