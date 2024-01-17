global function RTKEventsPanel_OnInitialize
global function RTKEventsPanel_OnDestroy
global function InitRTKEventsPanel
global function EventsPanel_SetOpenPageIndex
global function EventsPanel_GoToPage
global function EventsPanel_GetCurrentPageIndex

global const string FEATURE_EVENT_SHOP_TUTORIAL = "event_shop"

global struct RTKEventsPanel_Properties
{
	rtk_panel verticalContainerContext
	rtk_behavior paginationBehavior
	rtk_behavior paginationAnimBehavior
}

global struct RTKEventInfoModel
{
	string currentPageTitle
	string name
	string remainingDays
	int titleEndTimestamp
	string titleCounterLocalizationString
	vector titleCounterColor
	asset mainIcon
	asset leftCornerHeaderBg
	asset rightPanelBg
	asset gridItemsBg
	int currencyInWallet
	asset currencyIcon
	string currencyShortName
	string currencyLongName
	vector leftCornerTitleColor
	vector leftCornerEventNameColor
	vector leftCornerTimeRemainingColor
	float backgroundDarkening
	float rightPanelDarkening
	float leftPanelDarkening
	vector barsColor
	vector tooltipsColor
	string nextSection
	string prevSection
}

global enum eEventsPanelPage
{
	LANDING = 0
	MILESTONES = 1
	COLLECTION = 2
	EVENT_SHOP = 3
}

struct PrivateData
{
	string rootCommonPath = ""
}

struct
{
	ItemFlavor ornull activeEventShop
	ItemFlavor ornull milestoneEvent
	var panel
	bool registeredSweepstakesFooterCallback
	bool registeredSweepstakesKeyboardCallback
	bool didInitialize = false
	int currentPage = 0
	int previousPage = 0
	rtk_behavior ornull paginationBehavior
	InputDef& secondFooter
} file

void function RTKEventsPanel_OnInitialize( rtk_behavior self )
{
	if ( MilestoneEvent_IsEnabled() == false )
	{
		
		file.didInitialize = false
		return
	}

	file.didInitialize = true

	rtk_struct activeEvents = RTKDataModelType_CreateStruct( RTK_MODELTYPE_COMMON, "activeEvents" )
	EventShop_BuildCommonModel( self, activeEvents )

	InstantiateActiveEventsPanels( self )
	SetUpPaginationBehavior( self )

	UpdateVGUIFooterButtons( file.secondFooter )
	UpdatePaginationButtonText( self )
	RegisterButtonPressedCallback( KEY_H, OpenCurrentPanelAdditionalInfo )
}

void function RTKEventsPanel_OnDestroy( rtk_behavior self )
{
	if ( file.didInitialize == false )
	{
		
		return
	}

	file.didInitialize = false

	DeregisterButtonPressedCallback( KEY_H, OpenCurrentPanelAdditionalInfo )

	if ( file.registeredSweepstakesKeyboardCallback )
	{
		DeregisterButtonPressedCallback( KEY_E, OpenSweepstakesRules )
		file.registeredSweepstakesKeyboardCallback = false
	}
	rtk_behavior ornull pagination = self.PropGetBehavior( "paginationBehavior" )
	if ( pagination != null )
	{
		expect rtk_behavior( pagination )
		file.currentPage = RTKPagination_GetCurrentPage( pagination )
	}
	RunClientScript( "ClearBattlePassItem" )
}


void function InitRTKEventsPanel( var panel )
{
	AddCallback_UI_FeatureTutorialDialog_PopulateTabsForMode( EventShop_PopulateAboutText, FEATURE_EVENT_SHOP_TUTORIAL )
	AddCallback_UI_FeatureTutorialDialog_SetTitle( EventShop_PopulateAboutTitle, FEATURE_EVENT_SHOP_TUTORIAL )
	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )

#if PC_PROG_NX_UI
		file.secondFooter = AddPanelFooterOption( panel, LEFT, BUTTON_Y, true, "#EVENTS_EVENT_SHOP_GET_CURRENCY", "#EVENTS_EVENT_SHOP_GET_CURRENCY", OpenEventShopTutorial )
#else
		file.secondFooter = AddPanelFooterOption( panel, LEFT, BUTTON_X, true, "#EVENTS_EVENT_SHOP_GET_CURRENCY", "#EVENTS_EVENT_SHOP_GET_CURRENCY", OpenEventShopTutorial )
#endif

	file.panel = panel

		InitRTKMilestoneEventMainPanel( panel )

}

void function EventShop_BuildCommonModel( rtk_behavior self, rtk_struct activeEvents )
{
	PrivateData p
	self.Private( p )

	rtk_array eventsArray   = RTKStruct_AddArrayOfStructsProperty(activeEvents, "events", "RTKEventInfoModel")

	if ( RTKArray_GetCount( eventsArray ) > 0 )
		RTKArray_Clear( eventsArray )

	ItemFlavor ornull activeEventShop = EventShop_GetCurrentActiveEventShop()
	file.activeEventShop = activeEventShop

	if ( activeEventShop == null )
		return

	expect ItemFlavor( activeEventShop )

	
	
	array<ItemFlavor> eventSections = [ activeEventShop ]

	foreach (ItemFlavor ornull event in eventSections)
	{
		if (event != null)
		{
			expect ItemFlavor( event )

			rtk_struct eventArrayItem = RTKArray_PushNewStruct( eventsArray )

			DisplayTime dt = SecondsToDHMS( maxint( 0, CalEvent_GetFinishUnixTime( event ) - GetUnixTimestamp() ) )

			array<int> resetTimestamps = EventShop_GetWeeklyResetsTimestamps( activeEventShop )

			
			RTKEventInfoModel infoModel
			infoModel.currentPageTitle = Localize("#EVENTS_EVENT_SHOP")
			infoModel.name = ItemFlavor_GetShortName( event )
			infoModel.remainingDays = Localize( GetDaysHoursRemainingLoc( dt.days, dt.hours ), dt.days, dt.hours )
			infoModel.titleEndTimestamp = resetTimestamps.len() > 0 ? resetTimestamps[0] : 0
			infoModel.titleCounterLocalizationString =  resetTimestamps.len() > 1 ? "#NEW_ITEMS_IN" : "#TIME_REMAINING"
			infoModel.titleCounterColor = resetTimestamps.len() > 1 ? <0.88, 0.79, 0.49> : <0.62, 0.62, 0.62>
			infoModel.mainIcon = EventShop_GetEventMainIcon( event )
			infoModel.currencyInWallet = GRXCurrency_GetPlayerBalance( GetLocalClientPlayer(), EventShop_GetEventShopGRXCurrency() )
			infoModel.currencyIcon = ItemFlavor_GetIcon( EventShop_GetEventShopCurrency( event ) )
			infoModel.currencyShortName = ItemFlavor_GetShortName( EventShop_GetEventShopCurrency( event ) )
			infoModel.currencyLongName = ItemFlavor_GetLongName( EventShop_GetEventShopCurrency( event ) )

			infoModel.gridItemsBg = EventShop_GetShopPageItemsBackground( event )
			infoModel.rightPanelBg = EventShop_GetRightPanelBackground( event )
			infoModel.leftCornerHeaderBg = EventShop_GetLeftCornerHeaderBackground( event )
			infoModel.leftCornerTitleColor = EventShop_GetLeftPanelTitleColor( event )
			infoModel.leftCornerEventNameColor = EventShop_GetLeftPanelEventNameColor( event )
			infoModel.leftCornerTimeRemainingColor = EventShop_GetLeftPanelTimeRemainingColor( event )
			infoModel.backgroundDarkening = EventShop_GetBackgroundDarkeningOpacity( event )
			infoModel.rightPanelDarkening = EventShop_GetRightPanelOpacity( event )
			infoModel.leftPanelDarkening = EventShop_GetLeftPanelOpacity( event )
			infoModel.barsColor = EventShop_GetBarsColor( event )
			infoModel.tooltipsColor = EventShop_GeTooltipsColor( event )
			infoModel.nextSection = GetPaginationButtonText( false )
			infoModel.prevSection = GetPaginationButtonText( true )

			
			RTKStruct_SetValue( eventArrayItem, infoModel )
		}
	}

	if ( EventShop_HasSweepstakesOffers( activeEventShop ) )
	{
		if ( file.registeredSweepstakesFooterCallback == false )
		{
#if PC_PROG_NX_UI
				AddPanelFooterOption( file.panel, LEFT, BUTTON_X, true, "#EVENTS_EVENT_SHOP_SWEEPSTAKES_RULES", "#EVENTS_EVENT_SHOP_SWEEPSTAKES_RULES", OpenSweepstakesRules )
#else
				AddPanelFooterOption( file.panel, LEFT, BUTTON_Y, true, "#EVENTS_EVENT_SHOP_SWEEPSTAKES_RULES", "#EVENTS_EVENT_SHOP_SWEEPSTAKES_RULES", OpenSweepstakesRules )
#endif
			file.registeredSweepstakesFooterCallback = true
		}

		if ( file.registeredSweepstakesKeyboardCallback == false )
		{
			RegisterButtonPressedCallback( KEY_E, OpenSweepstakesRules )
			file.registeredSweepstakesKeyboardCallback = true
		}
	}

	p.rootCommonPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_COMMON, "events", true, ["activeEvents"] )
	self.GetPanel().SetBindingRootPath( p.rootCommonPath + "[0]")
}

array<featureTutorialTab> function EventShop_PopulateAboutText()
{
	array<featureTutorialTab> tabs
	featureTutorialTab tab1
	array<featureTutorialData> tab1Rules

	
	tab1.tabName = 	"#GAMEMODE_RULES_OVERVIEW_TAB_NAME"

	foreach ( EventShopTutorialData tutorial in EventShop_GetTutorials( expect ItemFlavor( EventShop_GetCurrentActiveEventShop() ) ) )
	{
		tab1Rules.append( UI_FeatureTutorialDialog_BuildDetailsData( tutorial.title, tutorial.desc, tutorial.icon ) )
	}

	tab1.rules = tab1Rules
	tabs.append( tab1 )

	return tabs
}

string function EventShop_PopulateAboutTitle()
{
	return "#EVENTS_EVENT_SHOP"
}

void function OpenEventShopTutorial( var button )
{
	if ( IsDialog( GetActiveMenu() ) )
		return

	UI_OpenFeatureTutorialDialog( FEATURE_EVENT_SHOP_TUTORIAL )
}

void function OpenSweepstakesRules( var button )
{
	if ( IsDialog( GetActiveMenu() ) )
		return

	UI_OpenEventShopSweepstakesRulesDialog()
}

void function EventsPanel_SetOpenPageIndex( int index )
{
	file.currentPage = index
}

int function EventsPanel_GetCurrentPageIndex()
{
	return file.currentPage
}

void function ClearItemPreviewOnStart_Thread()
{
	WaitFrame()
	UpdateDefaultItemPreviews()
}

void function InstantiateActiveEventsPanels( rtk_behavior self )
{
	rtk_panel ornull context = self.PropGetPanel( "verticalContainerContext" )

	if ( context != null )
	{
		expect rtk_panel( context )

			file.milestoneEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
			if ( file.milestoneEvent != null )
			{
				RTKPanel_Instantiate( $"ui_rtk/menus/events/milestone/milestone_event_landing.rpak", context, "Landing Page" )
				RTKPanel_Instantiate( $"ui_rtk/menus/events/milestone/milestone_event_main_panel.rpak", context, "Tracking Page" )
				RTKPanel_Instantiate( $"ui_rtk/menus/events/milestone/milestone_event_collection_panel.rpak", context, "Collection Page" )
				thread ClearItemPreviewOnStart_Thread()
			}

		if ( file.activeEventShop != null )
		{
			RTKPanel_Instantiate( $"ui_rtk/menus/events/events_event_shop.rpak", context, "Event Shop Page" )
		}
	}
}

void function SetUpPaginationBehavior( rtk_behavior self )
{
	rtk_behavior ornull pagination = self.PropGetBehavior( "paginationBehavior" )
	if ( pagination != null )
	{
		expect rtk_behavior( pagination )
		file.paginationBehavior = pagination
		pagination.PropSetInt( "startPageIndex", file.currentPage )
		rtk_behavior animator = self.PropGetBehavior( "paginationAnimBehavior" )
		self.AutoSubscribe( animator, "onAnimationStarted", function ( rtk_behavior animator, string animName ) : ( self, pagination ) {
			file.currentPage = RTKPagination_GetTargetPage( pagination )
			file.previousPage = RTKPagination_GetCurrentPage( pagination )

			UpdateDefaultItemPreviews()
			UpdateVGUIFooterButtons( file.secondFooter )
			UpdatePaginationButtonText( self )
		} )
	}
}

void function EventsPanel_GoToPage( int index )
{
	if ( file.paginationBehavior != null )
	{
		rtk_behavior ornull pagination =  file.paginationBehavior
		expect rtk_behavior( pagination )

		RTKPagination_GoToPage( pagination, index )
	}
}

void function UpdateVGUIFooterButtons( InputDef footer )
{
	switch ( file.currentPage )
	{
		case eEventsPanelPage.LANDING: 
		{
			UI_SetPresentationType( ePresentationType.BATTLE_PASS )
			
			footer.gamepadLabel = ""
			footer.mouseLabel = ""
			footer.activateFunc = null
			break
		}
		case eEventsPanelPage.MILESTONES: 
		{
			UI_SetPresentationType( ePresentationType.COLLECTION_EVENT )
			file.secondFooter.mouseLabel = "#MILESTONE_BUTTON_EVENT_INFO"
			file.secondFooter.gamepadLabel = "#MILESTONE_BUTTON_EVENT_INFO"
			file.secondFooter.activateFunc = OpenCollectionEventAboutPage
			break
		}
		case eEventsPanelPage.COLLECTION: 
		{
			UI_SetPresentationType( ePresentationType.COLLECTION_EVENT )
			
			footer.gamepadLabel = ""
			footer.mouseLabel = ""
			footer.activateFunc = null
			break
		}
		case eEventsPanelPage.EVENT_SHOP: 
		{
			UI_SetPresentationType( ePresentationType.COLLECTION_EVENT )
			file.secondFooter.mouseLabel = "#EVENTS_EVENT_SHOP_GET_CURRENCY"
			file.secondFooter.gamepadLabel = "#EVENTS_EVENT_SHOP_GET_CURRENCY"
			file.secondFooter.activateFunc = OpenEventShopTutorial
			break
		}
	}
	UpdateFooterOptions()
}

void function OpenCurrentPanelAdditionalInfo( var button )
{
	if ( file.currentPage == eEventsPanelPage.MILESTONES ) 
	{
		OpenCollectionEventAboutPage( button )
	}
	else if ( file.currentPage == eEventsPanelPage.EVENT_SHOP ) 
	{
		OpenEventShopTutorial( button )
	}
}

string function GetPaginationButtonText( bool isPrev )
{
	switch ( file.currentPage )
	{
		case eEventsPanelPage.LANDING: 
		{
			if ( GRX_IsOfferRestricted() )
			{
				return isPrev ? "" : "#S19ME01_LANDING_PAGE_BUTTON_PACKS_NAME_RESTRICTED"
			}
			else
			{
				return isPrev ? "" : "#S19ME01_LANDING_PAGE_BUTTON_PACKS_NAME"
			}
			break
		}
		case eEventsPanelPage.MILESTONES: 
		{
			return isPrev ? "#S19ME01_LANDING_PAGE_BUTTON_LANDING_NAME" : "#S19ME01_LANDING_PAGE_BUTTON_COLLECTION_NAME"
			break
		}
		case eEventsPanelPage.COLLECTION: 
		{
			if ( GRX_IsOfferRestricted() )
			{
				return isPrev ? "#S19ME01_LANDING_PAGE_BUTTON_PACKS_NAME_RESTRICTED" : "#S19ME01_LANDING_PAGE_BUTTON_SHOP_NAME"
			}
			else
			{
				return isPrev ? "#S19ME01_LANDING_PAGE_BUTTON_PACKS_NAME" : "#S19ME01_LANDING_PAGE_BUTTON_SHOP_NAME"
			}
			break
		}
		case eEventsPanelPage.EVENT_SHOP: 
		{
			return isPrev ? "#S19ME01_LANDING_PAGE_BUTTON_COLLECTION_NAME" : ""
			break
		}
	}
	return "#PLAYER_SEARCH_NOT_FOUND"
}

void function UpdatePaginationButtonText( rtk_behavior self )
{
	PrivateData p
	self.Private( p )
	rtk_struct eventsStruct = RTKDataModel_GetStruct( p.rootCommonPath + "[0]" )
	RTKStruct_SetString( eventsStruct, "nextSection", GetPaginationButtonText( false ) )
	RTKStruct_SetString( eventsStruct, "prevSection", GetPaginationButtonText( true ) )
}

void function UpdateDefaultItemPreviews()
{
	if ( file.currentPage == eEventsPanelPage.MILESTONES || file.currentPage == eEventsPanelPage.COLLECTION )
	{
		if ( file.previousPage != eEventsPanelPage.MILESTONES && file.previousPage != eEventsPanelPage.COLLECTION )
		{
			Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
			thread AutoAdvanceFeaturedItems_Tracking()
			thread AutoAdvanceFeaturedItems_Collection()
		}
	}
	else if ( file.currentPage == eEventsPanelPage.EVENT_SHOP )
	{
		Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
		EventShop_UpdatePreviewedOffer()
	}
	else
	{
		Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
		RunClientScript( "UIToClient_StopBattlePassScene" )
	}
}
