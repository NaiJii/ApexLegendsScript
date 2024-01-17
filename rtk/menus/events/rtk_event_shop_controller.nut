global function RTKEventShopPanel_OnInitialize
global function RTKEventShopPanel_OnDestroy
global function RTKMutator_AlphaFromShopItemState
global function RTKMutator_TierXPosition
global function RTKMutator_TierYPosition
global function GetActiveTierBindingPath
global function GetSweepstakesOffer
global function IsOfferPartOfEventShop
global function EventShop_UpdatePreviewedOffer

global struct RTKEventShopPanel_Properties
{
	rtk_panel offersGrid
	rtk_panel tierList
	rtk_behavior challengesGridButton
}

global struct RTKEventShopOfferItemModel
{
	string title
	string description
	int price
	int quantity
	asset icon
	bool isSweepstakes
	bool isGenericIcon
	int quality
	int state
	bool isRecurring
	bool isAvailable
	bool isOwned
	bool canAfford
}

global struct RTKTierModalInfo
{
	asset icon
	string text
	bool isCustomSize
}

global struct RTKEventShopTierModel
{
	asset badgeIcon
	asset loadscreenIcon
	int accumulatedCurrency
	int unlockValue
	float progress
	string progressText
	bool isLocked
	string radioPlayGUID
	int tier
	array<RTKTierModalInfo> modalData
}

global struct RTKEventShopTooltipInfoModel
{
	string titleText
	string subtitleText
	string bodyText
	string additionalText
	string actionText
	vector titleColor
	vector bodyTextAltColor
	vector additionalTextAltColor
	asset icon
	bool isTitleVisible
	bool isSubtitleVisible
	bool isActionTextVisible
	bool isAdditionalTextVisible
	bool isIconVisible
}

global struct RTKEventShopModel
{
	string gridTitle
	string rewardsTitle
	array<RTKEventShopOfferItemModel> offers
	array<RTKEventShopTierModel> tiers
	RTKEventShopTooltipInfoModel& tooltipInfo
}


global enum eShopCurrencyProgression
{
	GAMEPLAY,
	CHALLENGES
}

global enum eShopItemState
{
	UNAVAILABLE = -1,
	AVAILABLE = 0,
	OWNED = 1,
	LOCKED = 2,
	UNAFFORDABLE = 3,
	_COUNT,
}

struct PrivateData
{
	string rootCommonPath = ""
}

struct
{
	array<GRXScriptOffer> offers = []
	array<EventShopTierData> tiers = []
	bool isRecurringRewardAvailable = false
	int accumulatedCurrency = 0
	int ownedOffers = 0
	ItemFlavor ornull activeEventShop = null
	string activeTierBindingPath = ""
	string currencyShortName = ""
	string currencyLongName = ""
	GRXScriptOffer& sweepstakesOffer
} file

void function RTKEventShopPanel_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	if ( !GRX_IsInventoryReady() || !GRX_AreOffersReady() )
		return
	
	entity player = GetLocalClientPlayer()

	file.accumulatedCurrency = GoldenHorse_GetEventCurrencyLifetimeTotal( player )


	rtk_struct eventShop = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "eventShop", "RTKEventShopModel" )
	rtk_array offersArray = RTKDataModel_GetArray( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "offers", true, ["eventShop"] ) )
	rtk_array tiersArray = RTKDataModel_GetArray( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "tiers", true, ["eventShop"] ) )
	rtk_struct tooltipInfo = RTKDataModel_GetStruct( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "tooltipInfo", true, ["eventShop"] ) )

	file.activeEventShop = EventShop_GetCurrentActiveEventShop()

	file.currencyShortName = ItemFlavor_GetShortName( EventShop_GetEventShopCurrency( expect ItemFlavor( file.activeEventShop ) ) )
	file.currencyLongName = ItemFlavor_GetLongName( EventShop_GetEventShopCurrency( expect ItemFlavor( file.activeEventShop ) ) )

	RTKEventShopModel eventShopModel
	eventShopModel.gridTitle =  Localize( EventShop_GetGridTitle( expect ItemFlavor( file.activeEventShop ) ), Localize( file.currencyLongName ) )
	eventShopModel.rewardsTitle = Localize( EventShop_GetRewardsTitle( expect ItemFlavor( file.activeEventShop ) ), Localize( file.currencyShortName ) )
	RTKStruct_SetValue( eventShop, eventShopModel )

	
	string offerLocation = EventShop_GetGRXOfferLocation( expect ItemFlavor( file.activeEventShop ) )
	Assert( GRX_IsLocationActive( offerLocation ), "Location not active, please make sure that the currency you're using is registered in the MTX_CurrencyName[] inside the microtransactions.h file" )
	file.offers = GRX_GetLocationOffers( offerLocation )

	file.offers.sort( int function( GRXScriptOffer a, GRXScriptOffer b ) {
		int aSlot = ( "slot" in a.attributes ? int( a.attributes["slot"] ) : 99999 )
		int bSlot = ( "slot" in b.attributes ? int( b.attributes["slot"] ) : 99999 )
		if ( aSlot != bSlot )
			return aSlot - bSlot

		return 0
	} )

	foreach (int index, GRXScriptOffer offer in file.offers)
	{
		
		rtk_struct offerStruct = RTKArray_PushNewStruct( offersArray )

		
		
		ItemFlavor ornull coreItemFlav = EventShop_GetCoreItemFlav( offer )
		expect ItemFlavor( coreItemFlav )

		
		EventShopOfferData offerData = EventShop_GetOfferByCoreItem( expect ItemFlavor( file.activeEventShop ), coreItemFlav )

		

		
		RTKEventShopOfferItemModel offerModel
		offerModel.title = offer.titleText
		offerModel.description = offer.descText
		offerModel.price = EventShop_GetItemPrice(offer)
		offerModel.quantity = EventShop_GetCoreItemQuantity(offer)
		offerModel.icon = offerData.gridIcon != $"" ? offerData.gridIcon : ItemFlavor_GetIcon( coreItemFlav )
		offerModel.isSweepstakes = offerData.isSweepstakesOffer
		offerModel.isGenericIcon = false
		offerModel.quality = ItemFlavor_GetQuality( coreItemFlav, 0 ) + 1
		offerModel.isRecurring = offerData.isLockedOffer
		offerModel.isOwned = GRXOffer_IsFullyClaimed( offer ) || ( offer.purchaseLimit > 1 && offer.purchaseCount >= offer.purchaseLimit )
		offerModel.isAvailable = offer.isAvailable
		offerModel.canAfford = GRX_CanAfford( offer.prices[0], 1 )
		offerModel.state = ItemShopState( offer, false )

		if ( offerData.isLockedOffer )
		{
			offerModel.isAvailable = IsRecurringOfferAvailableToPurchase()
			offerModel.state = ItemShopState( offer, true )
		}

		file.ownedOffers += GRXOffer_IsFullyClaimed( offer ) ? 1 : 0

		
		RTKStruct_SetValue( offerStruct, offerModel )
	}

	file.tiers = EventShop_GetTiersData( expect ItemFlavor( file.activeEventShop ) )
	for ( int i = 0; i < file.tiers.len(); i++ )
	{
		rtk_struct tierStruct = RTKArray_PushNewStruct( tiersArray )

		
		RTKEventShopTierModel tierModel

		
		tierModel.unlockValue = file.tiers[i].unlockValue
		tierModel.accumulatedCurrency = file.accumulatedCurrency
		tierModel.progress = TierProgress( file.accumulatedCurrency, file.tiers[i].unlockValue)

		string formattedUnlockValue = FormatAndLocalizeNumber( "1", float( file.tiers[i].unlockValue ), true )
		string formattedAccumulatedCurrency = FormatAndLocalizeNumber( "1", float( file.accumulatedCurrency ), true )
		tierModel.progressText = Localize( "#VAL_SLASH_VAL", file.accumulatedCurrency > file.tiers[i].unlockValue ? formattedUnlockValue : formattedAccumulatedCurrency, formattedUnlockValue )

		tierModel.isLocked = TierProgress( file.accumulatedCurrency, file.tiers[i].unlockValue) < 1.0
		tierModel.tier = i + 1

		if ( file.tiers[i].badges.len() > 0 )
		{
			tierModel.badgeIcon = ItemFlavor_GetIcon( file.tiers[i].badges[0] )
			RTKTierModalInfo tierData
			tierData.icon = tierModel.badgeIcon
			tierData.text = ItemFlavor_GetLongName( file.tiers[i].badges[0] )
			tierModel.modalData.push(tierData)
		}

		if ( file.tiers[i].rewards.len() > 0 )
		{
			tierModel.loadscreenIcon = ItemFlavor_GetIcon( file.tiers[i].rewards[0] )
			RTKTierModalInfo tierData
			tierData.icon = tierModel.loadscreenIcon
			tierData.text = ItemFlavor_GetLongName( file.tiers[i].rewards[0] )
			tierData.isCustomSize = true
			tierModel.modalData.push(tierData)
		}

		if( file.tiers[i].radioPlays.len() > 0 )
			tierModel.radioPlayGUID = ItemFlavor_GetGUIDString( file.tiers[i].radioPlays[0] )
		
		RTKStruct_SetValue( tierStruct, tierModel )
	}

	EventShop_UpdatePreviewedOffer()

	
	rtk_panel ornull offersGrid = self.PropGetPanel( "offersGrid" )
	if ( offersGrid != null )
	{
		expect rtk_panel( offersGrid )
		self.AutoSubscribe( offersGrid, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ) {
			array< rtk_behavior > gridItems = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in gridItems )
			{
				self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, newChildIndex ) {
					UpdateItemPresentation( file.offers[newChildIndex] )
					UpdateGridTooltipInfo( newChildIndex )
				} )

				ItemFlavor ornull coreItemFlav = EventShop_GetCoreItemFlav( file.offers[newChildIndex] )
				expect ItemFlavor( coreItemFlav )

				if ( ItemFlavor_GetTypeName(coreItemFlav ) == "#itemtype_battlepass_purchased_xp_NAME" && !file.isRecurringRewardAvailable)
					continue

				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex ) {
					EventShopOfferData offerData = EventShop_GetOfferData( expect ItemFlavor( file.activeEventShop ), newChildIndex )

					if ( offerData.isSweepstakesOffer )
					{
						file.sweepstakesOffer = file.offers[newChildIndex]
						UI_OpenEventShopSweepstakesFlowDialog()
					}
					else
					{
						StoreInspectMenu_AttemptOpenWithOffer( file.offers[newChildIndex], true )
					}
				} )
			}
		} )
	}

	
	rtk_panel ornull tierList = self.PropGetPanel( "tierList" )
	if ( tierList != null )
	{
		expect rtk_panel( tierList )
		self.AutoSubscribe( tierList, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ) {
			rtk_behavior ornull button = newChild.FindBehaviorByTypeName( "Button" )

			if ( button != null )
			{
				expect rtk_behavior( button )
				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChild, newChildIndex ) {
					rtk_struct rtkModel = RTKDataModel_GetStruct( newChild.GetBindingRootPath() )
					bool isLocked  = RTKStruct_GetBool( rtkModel, "isLocked" )
					array<ItemFlavor> radioPlayFlavs = EventShop_GetTierRadioPlays( expect ItemFlavor( file.activeEventShop ), newChildIndex )

					if ( !isLocked && radioPlayFlavs.len() > 0 )
					{
						RadioPlay_SetGUID( ItemFlavor_GetGUIDString( radioPlayFlavs[0] ) )
					}
					file.activeTierBindingPath = newChild.GetBindingRootPath()
					UI_OpenEventShopTierDialog()
				} )

				self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, newChildIndex ) {
					UpdateTierTooltipInfo( newChildIndex )
				} )
			}
		} )
	}

	rtk_behavior ornull challengesGridButton = self.PropGetBehavior( "challengesGridButton" )
	if ( challengesGridButton != null )
	{
		expect rtk_behavior( challengesGridButton )
		self.AutoSubscribe( challengesGridButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			JumpToChallenges( "challengeseventshop" )
		} )
	}

	p.rootCommonPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_COMMON, "events", true, ["activeEvents"] )
	self.GetPanel().SetBindingRootPath( p.rootCommonPath + "[0]")
}

string function GetActiveTierBindingPath()
{
	return file.activeTierBindingPath
}

GRXScriptOffer function GetSweepstakesOffer()
{
	return file.sweepstakesOffer
}

int function ItemShopState( GRXScriptOffer offer, bool isLocked )
{
	
	
	bool offerAvailableToPurchase = isLocked ? IsRecurringOfferAvailableToPurchase() : offer.isAvailable

	if ( offerAvailableToPurchase )
	{
		
		if ( GRXOffer_IsFullyClaimed( offer ) || ( offer.purchaseLimit > 1 && offer.purchaseCount >= offer.purchaseLimit ) )
			return eShopItemState.OWNED

		
		if ( !GRX_CanAfford( offer.prices[0], 1 ) )
			return eShopItemState.UNAFFORDABLE

		
		return eShopItemState.AVAILABLE
	}
	else
	{
		
		
		return eShopItemState.LOCKED
	}

	return eShopItemState.UNAVAILABLE
}

float function TierProgress( int currentValue, int totalValue )
{
	if (totalValue <= 0)
		return 0.0

	return clamp( float( currentValue ) / float( totalValue ), 0.0, 1.0 )
}

void function UpdateGridTooltipInfo( int index = 0 )
{
	rtk_struct tooltipInfo = RTKDataModel_GetStruct( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "tooltipInfo", true, ["eventShop"] ) )

	string titleText = Localize( file.offers[ index ].titleText )
	int purchaseLimit = file.offers[ index ].purchaseLimit
	int purchaseCount = file.offers[ index ].purchaseCount
	int quantity = EventShop_GetCoreItemQuantity(file.offers[ index ] )

	RTKEventShopTooltipInfoModel tooltipInfoModel

	
	tooltipInfoModel.titleText = titleText
	tooltipInfoModel.bodyText = Localize( "#EVENTS_EVENT_SHOP_GRID_BODY", titleText )
	tooltipInfoModel.additionalText = Localize( "#EVENTS_EVENT_SHOP_GRID_COUNTER_AVAILABLE", (purchaseLimit - purchaseCount), purchaseLimit )
	tooltipInfoModel.isIconVisible = purchaseLimit > 1 || GRXOffer_IsFullyClaimed( file.offers[ index ] )
	tooltipInfoModel.isAdditionalTextVisible = purchaseLimit > 1
	tooltipInfoModel.icon = GRXOffer_IsFullyClaimed( file.offers[ index ] ) ? $"ui_image/rui/menu/buttons/checked.rpak" : ( purchaseLimit > 1 ? $"ui_image/rui/menu/events/event_shop/repeatable.rpak" : $"" )

	
	if ( purchaseLimit > 1 && quantity > 1 )
	{
		tooltipInfoModel.bodyText = Localize( "#EVENTS_EVENT_SHOP_GRID_BODY_SETS", purchaseLimit, titleText )
	}

	
	EventShopOfferData offerData = EventShop_GetOfferData( expect ItemFlavor( file.activeEventShop ), index )
	if ( offerData.isSweepstakesOffer )
	{
		tooltipInfoModel.subtitleText = Localize( "#EVENTS_EVENT_SHOP_GRID_SUBTITLE_DAILY_LIMIT" )
		tooltipInfoModel.bodyText = Localize( "#EVENTS_EVENT_SHOP_GRID_BODY_SWEEPSTAKES", purchaseLimit )
		tooltipInfoModel.additionalText = Localize( "#EVENTS_EVENT_SHOP_GRID_COUNTER_DAILY_LIMIT", (purchaseLimit - purchaseCount), purchaseLimit )
	}

	
	if ( !GRX_CanAfford( file.offers[ index ].prices[0], 1 ) && !GRXOffer_IsFullyClaimed( file.offers[ index ] ) )
	{
		tooltipInfoModel.bodyText = Localize( "#EVENTS_EVENT_SHOP_GRID_BODY_INSUFFICIENT", Localize ( file.currencyLongName ), titleText )
	}

	RTKStruct_SetValue( tooltipInfo, tooltipInfoModel )
}

void function UpdateTierTooltipInfo( int index = 0 )
{
	rtk_struct tooltipInfo = RTKDataModel_GetStruct( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "tooltipInfo", true, ["eventShop"] ) )

	RTKEventShopTooltipInfoModel tooltipInfoModel

	tooltipInfoModel.titleText = ItemFlavor_GetLongName( file.tiers[ index ].badges[0] )
	tooltipInfoModel.bodyText = Localize( "#EVENTS_EVENT_SHOP_MILESTONE_BODY_2", Localize( file.currencyLongName ) )

	RTKStruct_SetValue( tooltipInfo, tooltipInfoModel )
}

void function UpdateItemPresentation( GRXScriptOffer offer )
{
	ItemFlavor ornull offerCoreItem = EventShop_GetCoreItemFlav( offer )
	if ( offerCoreItem != null )
	{
		expect ItemFlavor( offerCoreItem )
		RunClientScript( "UIToClient_ItemPresentation", ItemFlavor_GetGUID( offerCoreItem ), -1, 1.19, false, null, false, "collection_event_ref", false, false, false, false )
	}
}

void function EventShop_UpdatePreviewedOffer()
{
	if (file.offers.len() > 0)
	{
		foreach ( int index, GRXScriptOffer offer in file.offers )
		{
			EventShopOfferData offerData = EventShop_GetOfferData( expect ItemFlavor( file.activeEventShop ), index )
			if ( offerData.isFeaturedOffer )
			{
				UpdateItemPresentation( file.offers[index] )
				return
			}
		}

		UpdateItemPresentation( file.offers[file.offers.len() - 1] )
	}
}

bool function IsRecurringOfferAvailableToPurchase()
{
	foreach (GRXScriptOffer offer in file.offers)
	{
		if (ItemFlavor_GetTypeName( expect ItemFlavor( EventShop_GetCoreItemFlav(offer ) ) ) == "#itemtype_battlepass_purchased_xp_NAME")
			continue

		if (!GRXOffer_IsFullyClaimed( offer ) )
		{
			file.isRecurringRewardAvailable = false
			return false
		}
	}

	if ( (GetPlayerBattlePassLevel( GetLocalClientPlayer(), expect ItemFlavor( GetActiveBattlePass() ), false ) + 1) >= 100 )
	{
		file.isRecurringRewardAvailable = false
		return false
	}

	file.isRecurringRewardAvailable = true
	return true
}

bool function IsOfferPartOfEventShop( GRXScriptOffer offer )
{
	
	
	if ( EventShop_GetCurrentActiveEventShop() == null || offer.isCraftingOffer )
		return false

	
	ItemFlavor offerCoreItem = expect ItemFlavor( EventShop_GetCoreItemFlav( offer ) )
	array<EventShopOfferData> eventOffers = EventShop_GetOffers( expect ItemFlavor( EventShop_GetCurrentActiveEventShop() ) )

	bool matchesEventShopItem = false

	foreach ( EventShopOfferData eventOffer in eventOffers )
	{
		if ( ItemFlavor_GetGUID( offerCoreItem ) == ItemFlavor_GetGUID( eventOffer.offer ) )
		{
			matchesEventShopItem = true
			break
		}
	}

	if ( !matchesEventShopItem )
	{
		return false
	}

	
	foreach ( ItemFlavorBag bag in offer.prices )
	{
		foreach ( ItemFlavor& flavor in bag.flavors )
		{
			if ( flavor == GRX_CURRENCIES[GRX_CURRENCY_EVENT] )
			{
				return true
			}
		}
	}

	return false
}

void function RTKEventShopPanel_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "eventShop" )
	file.ownedOffers = 0
}


float function RTKMutator_AlphaFromShopItemState( int input, float minAlpha, float maxAlpha )
{
	switch (input)
	{
		case eShopItemState.UNAVAILABLE:
		case eShopItemState.OWNED:
		case eShopItemState.LOCKED:
			return minAlpha
		case eShopItemState.UNAFFORDABLE:
		case eShopItemState.AVAILABLE:
			return maxAlpha
	}

	return maxAlpha
}

int function RTKMutator_TierXPosition( int input, int xOffset )
{
	return input % 2 == 0 ? 0 : xOffset
}

int function RTKMutator_TierYPosition( int input, int yOffset )
{
	return input * yOffset
}

