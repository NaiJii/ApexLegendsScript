

global function EventShop_Init



global function GetActiveEventShop
global function EventShop_GetEventShopCurrency
global function EventShop_GetEventShopGRXCurrency
global function EventShop_GetGRXOfferLocation
global function EventShop_GetEventMainIcon
global function EventShop_GetLeftCornerHeaderBackground
global function EventShop_GetRightPanelBackground
global function EventShop_GetShopPageItemsBackground
global function EventShop_GetLobbyButtonImage
global function EventShop_GetEventShopData
global function EventShop_GetBadges
global function EventShop_GetRewards
global function EventShop_GetRadioPlays
global function EventShop_GetOffers
global function EventShop_GetMainChallenge
global function EventShop_GetTierRewards
global function EventShop_GetTierBadges
global function EventShop_GetTierRadioPlays
global function EventShop_GetTierUnlockValue
global function EventShop_GetTiersData
global function EventShop_GetBarsColor
global function EventShop_GetLinesColor
global function EventShop_GetLeftPanelTitleColor
global function EventShop_GetLeftPanelEventNameColor
global function EventShop_GetLeftPanelTimeRemainingColor
global function EventShop_GetBackgroundDarkeningOpacity
global function EventShop_GetRightPanelOpacity
global function EventShop_GetLeftPanelOpacity



global function EventShop_GetCoreItemFlav
global function EventShop_GetItemPrice
global function EventShop_GetCoreItemQuantity








global struct EventShopBadgeData
{
	ItemFlavor& badge
	int         x = 0
	int         y = 0
	int         size = 118
}

global struct EventShopRewardData
{
	ItemFlavor& reward
	int         x = 0
	int         y = 0
}

global struct EventShopRadioPlayData
{
	ItemFlavor& radioPlay
}

global struct EventShopOfferData
{
	ItemFlavor& offer
}

global struct EventShopTierData
{
	array<ItemFlavor> rewards
	array<ItemFlavor> badges
	array<ItemFlavor> radioPlays
	int unlockValue
}

global struct EventShopData
{
	ItemFlavor ornull mainChallengeFlav
	array<EventShopBadgeData> badges
	array<EventShopRewardData> rewards
	array<EventShopRadioPlayData> radioPlays
	array<EventShopOfferData> offers
}










struct FileStruct_LifetimeLevel
{
	table<ItemFlavor, EventShopData> eventShopDataMap
}







FileStruct_LifetimeLevel& fileLevel 

struct {
	
} fileVM 










void function EventShop_Init()
{

		FileStruct_LifetimeLevel newFileLevel
		fileLevel = newFileLevel


	AddCallback_OnItemFlavorRegistered( eItemType.calevent_event_shop, void function( ItemFlavor event ) {
		EventShopData eventShopData
		bool expired = false


			Assert( IsConnected(), "We're not connected to a server. This will result in excess challenges being loaded. This won't break anything, but it also shouldn't happen." )
			if ( IsConnected() )

			{
				expired = CalEvent_GetFinishUnixTime( event ) < GetUnixTimestamp()
			}

		eventShopData.mainChallengeFlav = RegisterItemFlavorFromSettingsAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "mainChallengeFlav" ) )
		if ( eventShopData.mainChallengeFlav != null )
			RegisterChallengeSource( expect ItemFlavor( eventShopData.mainChallengeFlav ), event, 0 )
		else
			Warning( "Event Shop '%s' refers to bad challenge asset: %s", string(ItemFlavor_GetAsset( event )), string( GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "mainChallengeFlav" ) ) )

		foreach ( int index, var badgeBlock in IterateSettingsAssetArray( ItemFlavor_GetAsset( event ), "badgeFlavs" ) )
		{
			ItemFlavor ornull badgeFlav = RegisterItemFlavorFromSettingsAsset( GetSettingsBlockAsset( badgeBlock, "badgeFlav" ) )

			if ( badgeFlav != null )
			{
				expect ItemFlavor( badgeFlav )

				EventShopBadgeData badge
				badge.badge = badgeFlav
				badge.x     = GetSettingsBlockInt( badgeBlock, "badgeX" )
				badge.y     = GetSettingsBlockInt( badgeBlock, "badgeY" )
				badge.size  = GetSettingsBlockInt( badgeBlock, "badgeSize" )

				eventShopData.badges.append( badge )
			}
		}

		foreach ( int index, var rewardBlock in IterateSettingsAssetArray( ItemFlavor_GetAsset( event ), "rewardFlavs" ) )
		{
			ItemFlavor ornull rewardFlav = RegisterItemFlavorFromSettingsAsset( GetSettingsBlockAsset( rewardBlock, "rewardFlav" ) )

			if ( rewardFlav != null )
			{
				expect ItemFlavor( rewardFlav )

				EventShopRewardData reward
				reward.reward = rewardFlav
				reward.x     = GetSettingsBlockInt( rewardBlock, "rewardX" )
				reward.y     = GetSettingsBlockInt( rewardBlock, "rewardY" )

				eventShopData.rewards.append( reward )
			}
		}

		foreach ( int index, var radioPlayBlock in IterateSettingsAssetArray( ItemFlavor_GetAsset( event ), "radioPlayFlavs" ) )
		{
			ItemFlavor ornull radioPlayFlav = RegisterItemFlavorFromSettingsAsset( GetSettingsBlockAsset( radioPlayBlock, "radioPlayFlav" ) )

			if ( radioPlayFlav != null )
			{
				expect ItemFlavor( radioPlayFlav )

				EventShopRadioPlayData radioPlay
				radioPlay.radioPlay = radioPlayFlav

				eventShopData.radioPlays.append( radioPlay )
			}
		}

		foreach ( int index, var offerBlock in IterateSettingsAssetArray( ItemFlavor_GetAsset( event ), "offerFlavs" ) )
		{
			ItemFlavor ornull offerFlav = RegisterItemFlavorFromSettingsAsset( GetSettingsBlockAsset( offerBlock, "offerFlav" ) )

			if ( offerFlav != null )
			{
				expect ItemFlavor( offerFlav )

				EventShopOfferData offer
				offer.offer = offerFlav

				eventShopData.offers.append( offer )
			}
		}

		fileLevel.eventShopDataMap[event] <- eventShopData
		
		
		
	} )

	
	
	
	
}










ItemFlavor ornull function GetActiveEventShop( int t )
{
	Assert( IsItemFlavorRegistrationFinished() )
	ItemFlavor ornull event = null
	foreach ( ItemFlavor ev in GetAllItemFlavorsOfType( eItemType.calevent_event_shop ) )
	{
		if ( !CalEvent_IsActive( ev, t ) )
			continue

		Assert( event == null, format( "Multiple event shops are active!! (%s, %s)", string(ItemFlavor_GetAsset( expect ItemFlavor(event) )), string(ItemFlavor_GetAsset( ev )) ) )
		event = ev
	}
	return event
}



ItemFlavor function EventShop_GetEventShopCurrency( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "eventShopCurrencyFlav" ) )
}



ItemFlavor function EventShop_GetEventShopGRXCurrency()
{
	return GRX_CURRENCIES[GRX_CURRENCY_SEASON02_EVENT01]
}



string function EventShop_GetGRXOfferLocation( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsString( ItemFlavor_GetAsset( event ), "eventShopGRXOfferLocation" )
}



asset function EventShop_GetEventMainIcon( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "eventMainIcon" )
}



asset function EventShop_GetLeftCornerHeaderBackground( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "leftCornerHeaderBg" )
}



asset function EventShop_GetRightPanelBackground( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "rightPanelBg" )
}



asset function EventShop_GetShopPageItemsBackground( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "eventShopPageItemsBg" )
}



asset function EventShop_GetLobbyButtonImage( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( event ), "eventShopLobbyButtonImage" )
}



EventShopData function EventShop_GetEventShopData( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event]
}



array<EventShopBadgeData> function EventShop_GetBadges( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event].badges
}



array<EventShopRewardData> function EventShop_GetRewards( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event].rewards
}



array<EventShopRadioPlayData> function EventShop_GetRadioPlays( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event].radioPlays
}



array<EventShopOfferData> function EventShop_GetOffers( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event].offers
}



ItemFlavor ornull function EventShop_GetMainChallenge( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return fileLevel.eventShopDataMap[event].mainChallengeFlav
}



array<ItemFlavor> function EventShop_GetTierRewards( ItemFlavor event, int tier )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )

	var tierBlock = Challenge_GetTierDataBlock( expect ItemFlavor(EventShop_GetMainChallenge( event )), tier )

	array<ItemFlavor> rewards = []
	var rewardsArray          = GetSettingsBlockArray( tierBlock, "rewards" )
	foreach ( var rewardBlock in IterateSettingsArray( rewardsArray ) )
	{
		asset rewardAsset = GetSettingsBlockAsset( rewardBlock, "flavor" )
		if ( IsValidItemFlavorSettingsAsset( rewardAsset ) )
		{
			ItemFlavor item = GetItemFlavorByAsset( rewardAsset )

			if ( ItemFlavor_GetType( item ) != eItemType.gladiator_card_badge && ItemFlavor_GetType( item ) != eItemType.radio_play  )
				rewards.append( item )
		}
	}

	return rewards
}



array<ItemFlavor> function EventShop_GetTierBadges( ItemFlavor event, int tier )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )

	var tierBlock = Challenge_GetTierDataBlock( expect ItemFlavor(EventShop_GetMainChallenge( event )), tier )

	array<ItemFlavor> badges = []
	var rewardsArray          = GetSettingsBlockArray( tierBlock, "rewards" )
	foreach ( var rewardBlock in IterateSettingsArray( rewardsArray ) )
	{
		asset rewardAsset = GetSettingsBlockAsset( rewardBlock, "flavor" )
		if ( IsValidItemFlavorSettingsAsset( rewardAsset ) )
		{
			ItemFlavor item = GetItemFlavorByAsset( rewardAsset )

			if ( ItemFlavor_GetType( item ) == eItemType.gladiator_card_badge )
				badges.append( item )
		}
	}

	return badges
}



array<ItemFlavor> function EventShop_GetTierRadioPlays( ItemFlavor event, int tier )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )

	var tierBlock = Challenge_GetTierDataBlock( expect ItemFlavor(EventShop_GetMainChallenge( event )), tier )

	array<ItemFlavor> radioPlays = []
	var rewardsArray          = GetSettingsBlockArray( tierBlock, "rewards" )
	foreach ( var rewardBlock in IterateSettingsArray( rewardsArray ) )
	{
		asset rewardAsset = GetSettingsBlockAsset( rewardBlock, "flavor" )
		if ( IsValidItemFlavorSettingsAsset( rewardAsset ) )
		{
			ItemFlavor item = GetItemFlavorByAsset( rewardAsset )

			if ( ItemFlavor_GetType( item ) == eItemType.radio_play )
				radioPlays.append( item )
		}
	}

	return radioPlays
}



int function EventShop_GetTierUnlockValue( ItemFlavor event, int tier )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )

	var tierBlock = Challenge_GetTierDataBlock( expect ItemFlavor(EventShop_GetMainChallenge( event )), tier )
	return GetSettingsBlockInt( tierBlock, "goalVal" )
}



array<EventShopTierData> function EventShop_GetTiersData( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )

	var settingsBlock = ItemFlavor_GetSettingsBlock( expect ItemFlavor(EventShop_GetMainChallenge( event )) )
	var tiersArray = GetSettingsBlockArray( settingsBlock, "tiers" )

	array<EventShopTierData> tiersData = []
	for ( int i = 0; i < GetSettingsArraySize( tiersArray ); i++ )
	{
		EventShopTierData tierData

		tierData.rewards = EventShop_GetTierRewards( event, i )
		tierData.badges = EventShop_GetTierBadges( event, i )
		tierData.radioPlays = EventShop_GetTierRadioPlays( event, i )
		tierData.unlockValue = EventShop_GetTierUnlockValue( event, i )

		tiersData.push(tierData)
	}

	return tiersData
}



vector function EventShop_GetBarsColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "eventShopBarsColor" )
}



vector function EventShop_GetLinesColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "eventShopLinesColor" )
}



vector function EventShop_GetLeftPanelTitleColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "eventShopLeftPanelTitleColor" )
}



vector function EventShop_GetLeftPanelEventNameColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "eventShopLeftPanelEventNameColor" )
}



vector function EventShop_GetLeftPanelTimeRemainingColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "eventShopLeftPanelTimeRemainingColor" )
}



float function EventShop_GetBackgroundDarkeningOpacity( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( event ), "backgroundDarkeningOpacity" )
}



float function EventShop_GetRightPanelOpacity( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( event ), "rightPanelOpacity" )
}



float function EventShop_GetLeftPanelOpacity( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_event_shop )
	return GetGlobalSettingsFloat( ItemFlavor_GetAsset( event ), "leftPanelOpacity" )
}



ItemFlavor ornull function EventShop_GetCoreItemFlav( GRXScriptOffer offer )
{
	
	for ( int offerIndex = 0; offerIndex < offer.items.len(); offerIndex++ )
	{
		if ( offer.offerType != GRX_OFFERTYPE_BUNDLE || offer.items[offerIndex].itemType == GRX_OFFERITEMTYPE_CORE )
		{
			ItemFlavor coreItemFlav = GetItemFlavorByGRXIndex( offer.items[offerIndex].itemIdx )

			if (ItemFlavor_GetGRXMode( coreItemFlav ) == eItemFlavorGRXMode.REGULAR)
				return coreItemFlav
		}
	}

	
	return GetItemFlavorByGRXIndex( offer.items[0].itemIdx )
}



int function EventShop_GetItemPrice( GRXScriptOffer offer )
{
	foreach ( ItemFlavorBag price in offer.prices )
	{
		Assert( price.flavors.len() == 1, "No price given for ItemFlavor bag in GRX offer." )
		if ( price.flavors[0] == EventShop_GetEventShopGRXCurrency() )
		{
			return price.quantities[0]
		}
	}
	return 0
}



int function EventShop_GetCoreItemQuantity( GRXScriptOffer offer )
{
	for ( int offerIndex = 0; offerIndex < offer.items.len(); offerIndex++ )
	{
		if ( offer.offerType != GRX_OFFERTYPE_BUNDLE || offer.items[offerIndex].itemType == GRX_OFFERITEMTYPE_CORE )
		{
			ItemFlavor coreItemFlav = GetItemFlavorByGRXIndex( offer.items[offerIndex].itemIdx )

			if (ItemFlavor_GetGRXMode( coreItemFlav ) == eItemFlavorGRXMode.REGULAR)
				return offer.items[offerIndex].itemQuantity
		}
	}

	
	return offer.items[0].itemQuantity
}


      
