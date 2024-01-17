global function RTKMilestoneEventCollectionPanel_OnInitialize
global function RTKMilestoneEventCollectionPanel_OnDestroy
global function AutoAdvanceFeaturedItems_Collection

global struct RTKMilestoneEventCollectionPanel_Properties
{
	rtk_panel offersGrid
	rtk_behavior chaseButton
	rtk_behavior gridPagination
	rtk_behavior contentArea
}

global struct RTKMilestoneEventCollectionPanelModel
{
	vector color
	vector titleBgColor
	int totalItems
	int collectedItems
}
global struct RTKMilestoneCollectedCategoryInfo
{
	int quality
	int quantity
	int maxQuantity
}

global struct RTKMilestoneCollectedItemInfoTooltip
{
	string titleText
}

global struct RTKMilestoneCollectedItemInfo
{
	int quality
	int state
	bool isOwned
	bool isPurchasable
	asset icon
	int price
	RTKMilestoneCollectedItemInfoTooltip& tooltipInfo
}

global struct RTKMilestoneChaseItemInfo
{
	int quality
	int state
	bool isOwned
	asset icon
	string name
	string description
	RTKMilestoneCollectedItemInfoTooltip& tooltipInfo
}

struct PrivateData
{
	string rootCommonPath = ""
	int currentCarouselItemIndex = 0
}

struct
{
	ItemFlavor ornull activeEvent = null
	array<ItemFlavor> items
	array<ItemFlavor> chaseItems
	array<ItemFlavor> featuredItems
	bool isRestricted = false

	int        currentCarouselItemIndex = 0
	float      offerChangeStartTime = 0
	float      lastOfferChangeTimeUpdate = -1
	float      nextOfferChangeTime = 0
	rtk_struct collectionModel
	int 	   currentGridPage = 0
} file

void function RTKMilestoneEventCollectionPanel_OnInitialize( rtk_behavior self )
{
	rtk_struct milestoneEvent = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "milestoneEvent", "RTKMilestoneEventCollectionPanelModel" )
	file.collectionModel = milestoneEvent

	BuildMilestoneGeneralPanelInfo( self, milestoneEvent )

	BuildMilestoneCollectedCategoryInfo( self, milestoneEvent ) 
	BuildMilestoneCollectedItemsInfo( self, milestoneEvent )
	BuildMilestoneChaseItemInfo( self, milestoneEvent )
	BuildMilestoneCarouselInfo( milestoneEvent, file.featuredItems[file.currentCarouselItemIndex] )

	SetUpGridButtons( self, milestoneEvent )
	SetUpChaseButton( self, milestoneEvent )
	ResetCarouselVars()
	thread AutoAdvanceFeaturedItems_Collection()
	SetInitialGridPaginationPage( self )

	rtk_behavior ornull contentArea = self.PropGetBehavior( "contentArea" )
	if ( contentArea != null )
	{
		expect rtk_behavior( contentArea )
		RTKCursorInteract_AutoSubscribeOnHoverLeaveListener( self, contentArea,
			void function() : ( self, contentArea )
			{
				if ( EventsPanel_GetCurrentPageIndex() != eEventsPanelPage.EVENT_SHOP )
				{
					thread AutoAdvanceFeaturedItems_Collection()
					thread AutoAdvanceFeaturedItems_Tracking()
				}
			}
		)
	}

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "milestoneEvent", true ) )
}

void function RTKMilestoneEventCollectionPanel_OnDestroy( rtk_behavior self )
{
	Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "milestoneEvent" )

	rtk_behavior ornull gridPagination = self.PropGetBehavior( "gridPagination" )
	if ( gridPagination != null )
	{
		expect rtk_behavior( gridPagination )
		file.currentGridPage = RTKPagination_GetCurrentPage( gridPagination )
	}
}

void function BuildMilestoneGeneralPanelInfo( rtk_behavior self, rtk_struct milestoneEventModel )
{
	file.isRestricted = GRX_IsOfferRestricted()
	file.activeEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
	if ( file.activeEvent != null )
	{
		RTKMilestoneEventCollectionPanelModel generalModel
		ItemFlavor ornull event = file.activeEvent
		expect ItemFlavor(event)

		generalModel.color = MilestoneEvent_GetTitleCol( event )
		generalModel.titleBgColor = MilestoneEvent_GetTitleBGColor( event )
		file.items = MilestoneEvent_GetEventItems( event, file.isRestricted )
		file.chaseItems = MilestoneEvent_GetMythicEventItems( event, file.isRestricted )
		file.featuredItems = MilestoneEvent_GetFeaturedItems( event )
		generalModel.totalItems = file.isRestricted ? file.items.len() : file.items.len() + file.chaseItems.len()
		generalModel.collectedItems = GRX_GetNumberOfOwnedItemsByPlayer( file.items ) + GRX_GetNumberOfOwnedItemsByPlayer( file.chaseItems )
		RTKStruct_SetValue( milestoneEventModel, generalModel )
	}
}

void function BuildMilestoneCollectedCategoryInfo( rtk_behavior self, rtk_struct milestoneEventModel )
{
	array<RTKMilestoneCollectedCategoryInfo> collectedInfoModel = []

	if ( file.activeEvent == null )
	{
		return
	}
	if ( !GRX_IsInventoryReady() )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	array<CollectionEventRewardGroup> rewardGroups = MilestoneEvent_GetRewardGroups( event, file.isRestricted )
	foreach ( rewardGroup in rewardGroups )
	{
		RTKMilestoneCollectedCategoryInfo tierData
		tierData.quantity = GetNumberOfOwnedRewardsPerCategory( rewardGroup )
		tierData.maxQuantity = rewardGroup.rewards.len()
		tierData.quality = rewardGroup.quality
		collectedInfoModel.append( tierData )
	}

	
	collectedInfoModel.reverse()

	rtk_array collectedInfo = RTKStruct_GetOrCreateScriptArrayOfStructs( milestoneEventModel, "collectedInfo", "RTKMilestoneCollectedCategoryInfo" )
	RTKArray_SetValue( collectedInfo, collectedInfoModel )
}

void function BuildMilestoneCollectedItemsInfo( rtk_behavior self, rtk_struct milestoneEventModel )
{
	array<RTKMilestoneCollectedItemInfo> collectedItemsModel = []

	if ( file.activeEvent == null )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	file.items.reverse() 
	foreach ( item in file.items )
	{
		asset customImage = MilestoneEvent_GetCustomIconForItemIdx( event, item.grxIndex, file.isRestricted )
		RTKMilestoneCollectedItemInfo infoData
		infoData.quality = ItemFlavor_GetQuality( item )
		infoData.icon = customImage != "" ? customImage : CustomizeMenu_GetRewardButtonImage( item )
		infoData.isOwned = GRX_IsItemOwnedByPlayer( item )
		infoData.state = infoData.isOwned ? eShopItemState.OWNED : eShopItemState.AVAILABLE
		array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( item, MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )
		infoData.isPurchasable = offers.len() > 0
		infoData.price = infoData.isPurchasable ? GRXOffer_GetPremiumPriceQuantity( offers[0] ) : -1
		infoData.tooltipInfo.titleText = ItemFlavor_GetLongName( item ) 
		collectedItemsModel.append( infoData )
	}
	rtk_array collectedInfo = RTKStruct_GetOrCreateScriptArrayOfStructs( milestoneEventModel, "collectedItemsModel", "RTKMilestoneCollectedItemInfo" )
	RTKArray_SetValue( collectedInfo, collectedItemsModel )
}

void function BuildMilestoneChaseItemInfo( rtk_behavior self, rtk_struct milestoneEventModel )
{
	if ( file.activeEvent == null )
	{
		return
	}
	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	if ( file.chaseItems.len() < 1 )
		return

	ItemFlavor chaseItem = file.chaseItems[0]

	RTKMilestoneChaseItemInfo infoData
	infoData.quality = ItemFlavor_GetQuality( chaseItem )
	infoData.icon = MilestoneEvent_GetChaseItemIcon( event )
	infoData.isOwned = GRX_IsItemOwnedByPlayer( chaseItem )
	infoData.state = infoData.isOwned ? eShopItemState.OWNED : eShopItemState.AVAILABLE
	infoData.name = Localize( ItemFlavor_GetLongName( chaseItem ) )
	int totalItems = file.isRestricted ? file.items.len() : file.items.len() + file.chaseItems.len()
	infoData.description = Localize( MilestoneEvent_GetChaseItemUnlockDescription( event ), totalItems, infoData.name )
	infoData.tooltipInfo.titleText = ItemFlavor_GetLongName( chaseItem ) 

	rtk_struct chaseInfo = RTKStruct_GetOrCreateScriptStruct( milestoneEventModel, "chaseItemModel", "RTKMilestoneChaseItemInfo" )
	RTKStruct_SetValue( chaseInfo, infoData )
}

void function SetUpGridButtons( rtk_behavior self, rtk_struct milestoneEventModel )
{
	if ( file.activeEvent == null )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	rtk_panel ornull offersGrid = self.PropGetPanel( "offersGrid" )
	if ( offersGrid != null )
	{
		expect rtk_panel( offersGrid )

		self.AutoSubscribe( offersGrid, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self, event, milestoneEventModel ) {
			array< rtk_behavior > gridItems = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in gridItems )
			{
				array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( file.items[newChildIndex], MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )

				self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, newChildIndex, milestoneEventModel ) {
					if ( EventsPanel_GetCurrentPageIndex() != eEventsPanelPage.EVENT_SHOP )
					{
						Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
						BuildMilestoneCarouselInfo( milestoneEventModel, file.items[newChildIndex] )
					}
				} )


				if( offers.len() > 0 )
				{
					GRXScriptOffer offer = offers[0]
					self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex, offer ) {
						StoreInspectMenu_AttemptOpenWithOffer( offer )
					} )
				}
				else
				{
					self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex, event ) {
						string title = file.isRestricted ? "#MILESTONE_EVENT_LOCKED_PRESENTATION_BUTTON_TITLE" : "#MILESTONE_EVENT_PURCHASE_PRESENTATION_BUTTON_TITLE"
						SetGenericItemPresentationModeActiveWithNavBack( file.items[newChildIndex], title, "#MILESTONE_EVENT_PURCHASE_PRESENTATION_BUTTON_DESC", void function() : ()
						{
						} )
					} )
				}
			}
		} )
	}
}

void function SetUpChaseButton( rtk_behavior self, rtk_struct milestoneEventModel )
{
	if ( file.activeEvent == null )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	rtk_behavior ornull button = self.PropGetBehavior( "chaseButton" )
	if ( button != null )
	{
		expect rtk_behavior( button )

		array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( file.chaseItems[0], MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )

		self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, milestoneEventModel ) {
			if ( EventsPanel_GetCurrentPageIndex() != eEventsPanelPage.EVENT_SHOP )
			{
				Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
				BuildMilestoneCarouselInfo( milestoneEventModel, file.chaseItems[0] )
			}
		} )


		if( offers.len() > 0 )
		{
			GRXScriptOffer offer = offers[0]
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self , offer ) {
				StoreInspectMenu_AttemptOpenWithOffer( offer )
			} )
		}
		else
		{
			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, event ) {
				string description = file.isRestricted ? "#MILESTONE_EVENT_LOCKED_PRESENTATION_BUTTON_DESC" : "#MILESTONE_EVENT_PURCHASE_PRESENTATION_BUTTON_DESC"
				string title = file.isRestricted ? "#MILESTONE_EVENT_LOCKED_PRESENTATION_BUTTON_TITLE" : "#MILESTONE_EVENT_PURCHASE_PRESENTATION_BUTTON_TITLE"
				SetGenericItemPresentationModeActiveWithNavBack( file.chaseItems[0], title, description, void function() : ()
				{
				} )
			} )
		}
	}
}

void function AutoAdvanceFeaturedItems_Collection()
{
	EndSignal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )

	BuildMilestoneCarouselInfo( file.collectionModel, file.featuredItems[file.currentCarouselItemIndex] )
	const float OFFER_DELAY = 3.0
	while ( true )
	{
		if ( !RTKDataModel_HasDataModel( "&menus.milestoneEvent.carouselInfo.progress" ) )
			return

		if ( file.nextOfferChangeTime != file.lastOfferChangeTimeUpdate )
		{
			file.nextOfferChangeTime = ClientTime() + OFFER_DELAY
			file.offerChangeStartTime = ClientTime()
			file.lastOfferChangeTimeUpdate = file.nextOfferChangeTime
		}

		float remainingTime = file.nextOfferChangeTime - ClientTime()
		float totalTime = file.nextOfferChangeTime - file.offerChangeStartTime
		float progress = remainingTime/totalTime
		rtk_array arr = RTKDataModel_GetArray( "&menus.milestoneEvent.carouselInfo.progress" )
		RTKArray_SetFloat( arr, file.currentCarouselItemIndex, progress )

		if ( progress < 0.0 )
		{
			file.currentCarouselItemIndex++
			if ( file.currentCarouselItemIndex > file.featuredItems.len() - 1 )
				file.currentCarouselItemIndex = 0

			if ( GRX_IsInventoryReady() )
				BuildMilestoneCarouselInfo( file.collectionModel, file.featuredItems[file.currentCarouselItemIndex] )

			file.nextOfferChangeTime = ClientTime() + OFFER_DELAY
		}
		WaitFrame()
	}
}

void function SetInitialGridPaginationPage( rtk_behavior self )
{
	rtk_behavior ornull gridPagination = self.PropGetBehavior( "gridPagination" )
	if ( gridPagination != null )
	{
		expect rtk_behavior( gridPagination )
		gridPagination.PropSetInt( "startPageIndex", file.currentGridPage )

		
		
		
		
		
		
		
		
		
	}
}

int function GetNumberOfOwnedRewardsPerCategory( CollectionEventRewardGroup rewardGroup )
{
	int counter = 0
	foreach	( flav in rewardGroup.rewards )
	{
		if ( GRX_IsItemOwnedByPlayer( flav ) )
		{
			counter++
		}
	}
	return counter
}

void function ResetCarouselVars()
{
	file.lastOfferChangeTimeUpdate = -1
	file.nextOfferChangeTime = 0
	file.offerChangeStartTime = 0
}

