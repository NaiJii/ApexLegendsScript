global function RTKMilestoneEventLandingPanel_OnInitialize
global function RTKMilestoneEventLandingPanel_OnDestroy

global struct RTKMilestoneEventLandingPanel_Properties
{
	rtk_panel buttonsPanel
}

global struct RTKMilestoneEventLandingPageModel
{
	string eventTitle
	asset titleImage
	int endTime
}

global struct RTKMilestoneEventLandingButtonsModel
{
	asset  image
	asset  backgroundImage
	string name
}

struct
{
	ItemFlavor ornull activeEvent
}file

void function RTKMilestoneEventLandingPanel_OnInitialize( rtk_behavior self )
{
	rtk_struct landingPanel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "landingPage", "RTKMilestoneEventLandingPageModel" )

	BuildMilestoneLandingPanelInfo( landingPanel )
	BuildLandingButtonsDataModel( landingPanel )

	SetUpLandingButtons( self )

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "landingPage", true ) )
}

void function RTKMilestoneEventLandingPanel_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "landingPage" )
}

void function BuildMilestoneLandingPanelInfo( rtk_struct landingPanelModel )
{
	file.activeEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
	if ( file.activeEvent != null )
	{
		ItemFlavor ornull event = file.activeEvent
		expect ItemFlavor(event)

		RTKMilestoneEventLandingPageModel generalModel
		generalModel.endTime = CalEvent_GetFinishUnixTime( event )
		generalModel.eventTitle = MilestoneEvent_GetEventName( event )
		generalModel.titleImage = MilestoneEvent_GetLandingPageImage( event )
		RTKStruct_SetValue( landingPanelModel, generalModel )
	}
}

void function BuildLandingButtonsDataModel( rtk_struct landingPanelModel )
{
	if ( file.activeEvent == null )
		return

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	array<RTKMilestoneEventLandingButtonsModel> buttonsDataModel
	array<MilestoneEventLandingPageButtonData> buttonsData = MilestoneEvent_GetLandingPageButtonData( event )
	asset buttonBackground = MilestoneEvent_GetLandingPageBGButtonImage( event )
	foreach ( buttonData in buttonsData )
	{
		RTKMilestoneEventLandingButtonsModel data
		data.name            = buttonData.name
		data.image           = buttonData.image
		data.backgroundImage = buttonBackground
		buttonsDataModel.append( data )
	}

	rtk_array landingButtonsData = RTKStruct_GetOrCreateScriptArrayOfStructs( landingPanelModel, "buttonData", "RTKMilestoneEventLandingButtonsModel" )
	RTKArray_SetValue( landingButtonsData, buttonsDataModel )
}

void function SetUpLandingButtons( rtk_behavior self )
{
	rtk_panel ornull buttonsPanel = self.PropGetPanel( "buttonsPanel" )
	if ( buttonsPanel != null )
	{
		expect rtk_panel( buttonsPanel )
		self.AutoSubscribe( buttonsPanel, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ) {
			array< rtk_behavior > buttonBehaviors = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in buttonBehaviors )
			{
				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex ) {
					if ( newChildIndex != 3 && newChildIndex != 4 ) 
						EventsPanel_GoToPage( newChildIndex + 1 )
					else if ( newChildIndex == 3 )
					{
						ItemFlavor ornull activeThemedShopEvent = GetActiveThemedShopEvent( GetUnixTimestamp() )
						if ( activeThemedShopEvent != null )
						{
							JumpToSeasonTab( "ThemedShopPanel" )
						}
					}
					else if( newChildIndex == 4 )
					{
						
						OpenGameModeSelectDialog()
					}
				} )
			}
		} )
	}
}
