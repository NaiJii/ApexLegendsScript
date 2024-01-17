global function RTKMilestoneEventMainPanel_OnInitialize
global function RTKMilestoneEventMainPanel_OnDestroy
global function InitRTKMilestoneEventMainPanel
global function AutoAdvanceFeaturedItems_Tracking
global function BuildMilestoneCarouselInfo
global function SetIsAutoOpeningMilestonePacks
global function MilestoneEvent_LootBoxMenuOnClose

global struct RTKMilestoneEventMainPanel_Properties
{
	rtk_behavior singlePurchaseButton
	rtk_behavior multiplePurchaseButton
	array<rtk_behavior> viewAllItemsButtons = []
	rtk_behavior informationButton
	array<rtk_behavior> rewardButtons = []
}

global struct RTKMilestonePackButtonModel
{
	int discount
	string originalPrice
	int quantity
	string price
	bool isPaidPack = true
}

global struct RTKMilestoneEventPanelModel
{
	vector titleColor
	vector titleBgColor
	vector subtitleColor
	vector disclaimerBoxColor
	string nextMilestoneText
	int totalItems
	int currentCollectedItems
	int endtime
	bool isRestricted
}

global struct RTKMilestoneCarouselPanelInfo
{
	string name
	string itemTypeDescription
	int quality
	bool isOwned
	bool isRestricted
	asset packIcon
	asset coinIcon
	string packName
	int price

	array<float> progress
}


struct PrivateData
{
	string rootCommonPath = ""
}

struct
{
	bool isRestricted
	string baseStructName = "milestoneEvent"
	ItemFlavor ornull activeEvent = null
	array<ItemFlavor> featuredItems

	int currentCarouselItemIndex = 0
	float offerChangeStartTime = 0
	float lastOfferChangeTimeUpdate = -1
	float nextOfferChangeTime = 0
	array<MilestoneEventGrantReward> milestones
	rtk_struct trackingModel
	
	bool isAutoOpeningMilestonePacks = false
} file

const int SINGLE_BUTTON_PACK_QUANTITY = 1
const int MULTIPLE_BUTTON_PACK_QUANTITY = 4

void function InitRTKMilestoneEventMainPanel( var panel )
{
	RegisterSignal( "EndAutoAdvanceFeaturedItems" )
}

void function RTKMilestoneEventMainPanel_OnInitialize( rtk_behavior self )
{
	rtk_struct trackingPanel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "trackingPage", "RTKMilestoneEventPanelModel" )
	file.trackingModel = trackingPanel
	BuildMilestoneGeneralPanelInfo( trackingPanel )
	BuildMilestoneRewardsItemsInfo( trackingPanel )

	SetUpPurchaseButtons( self, trackingPanel )
	SetUpButtons( self )
	SetUpRewardButtons( self, trackingPanel )
	ResetCarouselVars()

	thread AutoAdvanceFeaturedItems_Tracking()
	if ( file.activeEvent == null )
		return

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)
	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "trackingPage", true ) )

	thread TryOpenMilestoneRewardPack()
}

void function RTKMilestoneEventMainPanel_OnDestroy( rtk_behavior self )
{
	Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "trackingPage" )
}

void function BuildMilestoneGeneralPanelInfo( rtk_struct trackingPanelModel )
{
	file.activeEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
	file.isRestricted = GRX_IsOfferRestricted()

	if ( file.activeEvent != null )
	{
		RTKMilestoneEventPanelModel generalModel
		ItemFlavor ornull event = file.activeEvent
		expect ItemFlavor(event)
		file.featuredItems = MilestoneEvent_GetFeaturedItems( event )
		array<ItemFlavor> items = MilestoneEvent_GetEventItems( event, file.isRestricted )
		array<ItemFlavor> chaseItems = MilestoneEvent_GetMythicEventItems( event, file.isRestricted )

		generalModel.titleColor = MilestoneEvent_GetTitleCol( event )
		generalModel.titleBgColor = MilestoneEvent_GetTitleBGColor( event )
		generalModel.subtitleColor = MilestoneEvent_GetMilestoneBoxTitleColor( event )
		generalModel.disclaimerBoxColor = MilestoneEvent_GetDisclaimerBoxColor( event )
		generalModel.endtime =  CalEvent_GetFinishUnixTime( event )
		int remainingItemsForMile =  MilestoneEvent_GetRemainingCompletionItemsForCurrentMilestone( event )
		if ( remainingItemsForMile == 0  )
		{
			generalModel.nextMilestoneText = Localize( "#MILESTONE_EVENT_TRACKING_BOX_COMPLETED_MILES" )
		}
		else
		{
			generalModel.nextMilestoneText = Localize( "#MILESTONE_EVENT_TRACKING_BOX_NEXT_MILE", remainingItemsForMile )
		}
		generalModel.totalItems = file.isRestricted ? items.len() : items.len() + chaseItems.len()
		generalModel.currentCollectedItems = file.isRestricted ? GRX_GetNumberOfOwnedItemsByPlayer( items ) : GRX_GetNumberOfOwnedItemsByPlayer( items ) + GRX_GetNumberOfOwnedItemsByPlayer( chaseItems )
		generalModel.isRestricted = file.isRestricted
		RTKStruct_SetValue( trackingPanelModel, generalModel )
	}
}

void function SetUpButtons( rtk_behavior self )
{
	rtk_array viewAllItemsButtons = self.PropGetArray( "viewAllItemsButtons" )
	rtk_behavior ornull informationButton = self.PropGetBehavior( "informationButton" )

	if ( informationButton != null )
	{
		expect rtk_behavior( informationButton )
	}

	if ( file.activeEvent == null )
		return

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	for ( int i = 0; i < RTKArray_GetCount( viewAllItemsButtons ); i++ )
	{
		rtk_behavior button = RTKArray_GetBehavior( viewAllItemsButtons, i )
		self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, event ) {
			EventsPanel_GoToPage( 2 ) 
		} )
	}

	self.AutoSubscribe( informationButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, event ) {
		OpenMilestonePackInfoDialog( null )
	} )
}

void function SetUpPurchaseButtons( rtk_behavior self, rtk_struct trackingPanelModel )
{
	if ( file.activeEvent == null )
		return

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	rtk_behavior ornull singlePurchaseButton = self.PropGetBehavior( "singlePurchaseButton" )
	rtk_behavior ornull multiplePurchaseButton = self.PropGetBehavior( "multiplePurchaseButton" )

	array<GRXScriptOffer> singlePurchaseOffers = GRX_GetItemDedicatedStoreOffers( MilestoneEvent_GetMainPackFlav( event ), MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )
	array<GRXScriptOffer> multiplePurchaseOffers = GRX_GetItemDedicatedStoreOffers( MilestoneEvent_GetGuaranteedPackFlav( event ), MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )

	if ( singlePurchaseButton != null && multiplePurchaseButton != null )
	{
		expect rtk_behavior( singlePurchaseButton )
		expect rtk_behavior( multiplePurchaseButton )
		singlePurchaseButton.PropSetBool( "interactive", singlePurchaseOffers.len() > 0 )
		multiplePurchaseButton.PropSetBool( "interactive", multiplePurchaseOffers.len() > 0 )
		singlePurchaseButton.GetPanel().SetVisible( singlePurchaseOffers.len() > 0 )
		multiplePurchaseButton.GetPanel().SetVisible( multiplePurchaseOffers.len() > 0 )
	}

	self.AutoSubscribe( singlePurchaseButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( event, singlePurchaseOffers ) {
		if ( singlePurchaseOffers.len() == 0 )
		{
			return
		}
		PurchaseDialogConfig pdc
		pdc.quantity = 1
		pdc.offer = singlePurchaseOffers[0]
		PurchaseDialog( pdc )
	} )

	self.AutoSubscribe( multiplePurchaseButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( event, multiplePurchaseOffers ) {
		if ( multiplePurchaseOffers.len() == 0 )
		{
			return
		}
		PurchaseDialogConfig pdc
		pdc.quantity = 1
		pdc.offer = multiplePurchaseOffers[0]
		PurchaseDialog( pdc )
	} )

	BuildPurchaseButtonDataModel( trackingPanelModel )
}

void function SetUpRewardButtons( rtk_behavior self, rtk_struct trackingPanelModel )
{
	if ( file.activeEvent == null )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	rtk_array rewardButtons = self.PropGetArray( "rewardButtons" )

	if ( file.milestones.len() > 0 )
	{
		int index = 0
		for ( int i = 0; i < RTKArray_GetCount( rewardButtons ); i++ )
		{
			rtk_behavior button =  RTKArray_GetBehavior(rewardButtons , i)
			self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, index, trackingPanelModel ) {
				Signal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
				BuildMilestoneCarouselInfo( trackingPanelModel, file.milestones[index].rewardFlav )
			} )

			self.AutoSubscribe( button, "onIdle", function( rtk_behavior button, int prevState ) : ( self, index, trackingPanelModel ) {
				thread AutoAdvanceFeaturedItems_Tracking()
				thread AutoAdvanceFeaturedItems_Collection()
			} )

			self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, index, event ) {
				SetGenericItemPresentationModeActiveWithNavBack( file.milestones[index].rewardFlav, "#MILESTONE_EVENT_LOCKED_PRESENTATION_BUTTON_TITLE", "#MILESTONE_EVENT_LOCKED_PRESENTATION_BUTTON_DESC", void function() : ()
				{
				} )
			} )

			index++
		}
	}
}

void function BuildPurchaseButtonDataModel( rtk_struct trackingPanelModel )
{
	if ( file.activeEvent == null )
		return

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)
	array<GRXScriptOffer> singlePurchaseOffers = MilestoneEvent_GetSinglePackOffers( event )
	array<GRXScriptOffer> multiplePurchaseOffers = MilestoneEvent_GetGuaranteedMultiPackOffers( event )

	array<RTKMilestonePackButtonModel> buttonsDataModel
	RTKMilestonePackButtonModel singlePurchaseDataModel = GetMilestonePackButtonDataModelFromOffers( singlePurchaseOffers, SINGLE_BUTTON_PACK_QUANTITY )
	RTKMilestonePackButtonModel multiplePurchaseDataModel = GetMilestonePackButtonDataModelFromOffers( multiplePurchaseOffers, MULTIPLE_BUTTON_PACK_QUANTITY )

	buttonsDataModel.append( singlePurchaseDataModel )
	buttonsDataModel.append( multiplePurchaseDataModel )

	rtk_array purchaseButtonData = RTKStruct_GetOrCreateScriptArrayOfStructs( trackingPanelModel, "purchaseButtonData", "RTKMilestonePackButtonModel" )
	RTKArray_SetValue( purchaseButtonData, buttonsDataModel )
}

RTKMilestonePackButtonModel function GetMilestonePackButtonDataModelFromOffers( array<GRXScriptOffer> offers, int defaultQuantity )
{
	RTKMilestonePackButtonModel offerModel
	if ( offers.len() > 0 )
	{
		GRXScriptOffer offer = offers[0]
		if ( offer.prices.len() == 2 )
		{
			string firstPrice = "%$" + ItemFlavor_GetIcon( GRX_CURRENCIES[GRX_CURRENCY_PREMIUM] ) + "% " + FormatAndLocalizeNumber( "1", float( GRXOffer_GetPremiumPriceQuantity( offer ) ), true )
			string secondPrice = "%$" + ItemFlavor_GetIcon( GRX_CURRENCIES[GRX_CURRENCY_CRAFTING] ) + "% " + FormatAndLocalizeNumber( "1", float( GRXOffer_GetCraftingPriceQuantity( offer ) ), true )
			offerModel.price = Localize( "#STORE_PRICE_N_N", firstPrice, secondPrice )
		}
		else
		{
			offerModel.price = GRX_GetFormattedPrice( offer.prices[0], 1 )
		}
		offerModel.isPaidPack = GRXOffer_GetPremiumPriceQuantity( offer ) > 1 
		int originalPrice = GRXOffer_GetOriginalPremiumPriceQuantity( offer )
		int price = GRXOffer_GetPremiumPriceQuantity( offer )
		if ( originalPrice > 0 )
		{
			offerModel.discount = int( (float((originalPrice - price )) / float(originalPrice)) * 100 )
			offerModel.originalPrice = "%$" + ItemFlavor_GetIcon( GRX_CURRENCIES[GRX_CURRENCY_PREMIUM] ) + "% " + FormatAndLocalizeNumber( "1", float(originalPrice), true )
		}
	}
	else
	{
		offerModel.price = ""
		offerModel.discount = 0
		offerModel.originalPrice = ""
	}
	offerModel.quantity = defaultQuantity
	return offerModel
}

void function BuildMilestoneRewardsItemsInfo( rtk_struct trackingPanelModel )
{
	array<RTKMilestoneCollectedItemInfo> rewardsItemsModel = []

	if ( file.activeEvent == null )
	{
		return
	}

	ItemFlavor ornull event = file.activeEvent
	expect ItemFlavor(event)

	array<MilestoneEventGrantReward> milestones = MilestoneEvent_GetMilestoneGrantRewards( event, file.isRestricted )
	file.milestones = milestones

	foreach ( milestone in milestones )
	{
		RTKMilestoneCollectedItemInfo infoData
		ItemFlavor item = milestone.rewardFlav
		infoData.quality = ItemFlavor_GetQuality( item )
		infoData.icon = milestone.customImage == "" ? CustomizeMenu_GetRewardButtonImage( item ) : milestone.customImage
		infoData.isOwned = GRX_IsItemOwnedByPlayer( item )
		infoData.state = infoData.isOwned ? eShopItemState.OWNED : eShopItemState.AVAILABLE
		infoData.isPurchasable = false
		infoData.price = -1
		infoData.tooltipInfo.titleText = milestone.customName == "" ? ItemFlavor_GetLongName( item ) : milestone.customName
		rewardsItemsModel.append( infoData )
	}

	rtk_array rewardsInfo = RTKStruct_GetOrCreateScriptArrayOfStructs( trackingPanelModel, "rewardsItemsModel", "RTKMilestoneCollectedItemInfo" )
	RTKArray_SetValue( rewardsInfo, rewardsItemsModel )
}


void function AutoAdvanceFeaturedItems_Tracking()
{
	EndSignal( uiGlobal.signalDummy, "EndAutoAdvanceFeaturedItems" )
	if ( !GRX_IsInventoryReady() || !GRX_AreOffersReady() )
		return

	BuildMilestoneCarouselInfo( file.trackingModel, file.featuredItems[file.currentCarouselItemIndex] )
	const float OFFER_DELAY = 3.0
	while ( true )
	{
		if ( !RTKDataModel_HasDataModel( "&menus.trackingPage.carouselInfo.progress" ) )
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
		rtk_array arr = RTKDataModel_GetArray( "&menus.trackingPage.carouselInfo.progress" )
		RTKArray_SetFloat( arr, file.currentCarouselItemIndex, progress )

		if ( progress < 0.0 )
		{
			file.currentCarouselItemIndex++
			if ( file.currentCarouselItemIndex > file.featuredItems.len() - 1 )
				file.currentCarouselItemIndex = 0

			if ( GRX_IsInventoryReady() )
				BuildMilestoneCarouselInfo( file.trackingModel, file.featuredItems[file.currentCarouselItemIndex] )
			file.nextOfferChangeTime = ClientTime() + OFFER_DELAY
		}
		WaitFrame()
	}
}

void function BuildMilestoneCarouselInfo( rtk_struct milestoneEventModel, ItemFlavor item )
{
	if ( file.activeEvent != null )
	{
		ItemFlavor ornull event = file.activeEvent
		expect ItemFlavor( event )

		RTKMilestoneCarouselPanelInfo itemInfo
		itemInfo.isOwned = IsItemFlavorRewardItem( item ) ? true : GRX_IsItemOwnedByPlayer( item )
		itemInfo.quality = ItemFlavor_GetQuality( item )
		itemInfo.name = ItemFlavor_GetLongName( item )
		itemInfo.itemTypeDescription = MilestoneEvent_GetCarouselItemDescriptionText(item )
		itemInfo.packIcon = MilestoneEvent_GetMainPackImage( event )
		itemInfo.packName = Localize( MilestoneEvent_GetMainPackShortPluralName( event ) )
		ItemFlavor currencyFlav = GRX_CURRENCIES[GRX_CURRENCY_PREMIUM]
		itemInfo.coinIcon = ItemFlavor_GetIcon( currencyFlav )
		itemInfo.isRestricted = file.isRestricted
		array<GRXScriptOffer> offers = GRX_GetItemDedicatedStoreOffers( item, MilestoneEvent_GetFrontPageGRXOfferLocation( event, file.isRestricted ) )
		if ( !file.isRestricted )
		{
			ItemFlavor ornull activeThemedShopEvent = GetActiveThemedShopEvent( GetUnixTimestamp() )
			if ( activeThemedShopEvent != null )
			{
				expect ItemFlavor( activeThemedShopEvent )
				offers.extend( GRX_GetItemDedicatedStoreOffers( item, ThemedShopEvent_GetGRXOfferLocation( activeThemedShopEvent ) ) )
			}
		}
		itemInfo.price = offers.len() > 0 ? GRXOffer_GetPremiumPriceQuantity( offers[0] ) : -1

		foreach ( featuredItem in file.featuredItems )
		{
			itemInfo.progress.append( 0 )
		}

		rtk_struct carouselInfo = RTKStruct_GetOrCreateScriptStruct( milestoneEventModel, "carouselInfo", "RTKMilestoneCarouselPanelInfo" )
		RTKStruct_SetValue( carouselInfo, itemInfo )
		if ( IsValidItemFlavorGUID( ItemFlavor_GetGUID( item ) ) )
		{
			RunClientScript( "UIToClient_ItemPresentation",ItemFlavor_GetGUID( item ) , -1, 1.19, false, null, true, "collection_event_ref", false, true, false, false )
		}
	}
}

string function MilestoneEvent_GetBaseModelDataPath()
{
	return RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, file.baseStructName, true )
}

bool function IsItemFlavorRewardItem( ItemFlavor item )
{
	foreach ( milestone in file.milestones )
	{
		if ( milestone.rewardFlav.guid == item.guid )
			return true
	}
	return false
}

void function SetIsAutoOpeningMilestonePacks( bool isAutoOpeningPacks )
{
	file.isAutoOpeningMilestonePacks = isAutoOpeningPacks
}




void function MilestoneEvent_LootBoxMenuOnClose()
{
	SetIsAutoOpeningMilestonePacks( true )
	Remote_ServerCallFunction( "UICallback_AutoOpenMilestonePacks" )
}

void function TryOpenMilestoneRewardPack()
{
	
	
	
	wait 1.6
	if ( !GRX_IsInventoryReady() || !GRX_AreOffersReady() )
	{
		return
	}
	if ( file.isAutoOpeningMilestonePacks )
	{
		return
	}
	if ( file.activeEvent == null )
	{
		return
	}
	ItemFlavor ornull activeEvent = file.activeEvent
	if ( activeEvent == null )
	{
		return
	}
	expect ItemFlavor( activeEvent )

	ItemFlavor mainPackFlav = MilestoneEvent_GetMainPackFlav( activeEvent )
	int mainPackFlavCount =  GRX_GetPackCount( ItemFlavor_GetGRXIndex( mainPackFlav ) )
	ItemFlavor guaranteedPackFlav = MilestoneEvent_GetGuaranteedPackFlav( activeEvent )
	int guaranteedPackFlavCount =  GRX_GetPackCount( ItemFlavor_GetGRXIndex( guaranteedPackFlav ) )

	if ( mainPackFlavCount == 0 && guaranteedPackFlavCount == 0 )
	{
		return
	}
	
	ItemFlavor milestonePackFlav = mainPackFlavCount > 0 ? mainPackFlav : guaranteedPackFlav
	OnLobbyOpenLootBoxMenu_ButtonPress( milestonePackFlav )
}

void function ResetCarouselVars()
{
	file.lastOfferChangeTimeUpdate = -1
	file.nextOfferChangeTime = 0
	file.offerChangeStartTime = 0
}
