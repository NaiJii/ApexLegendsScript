
global function ShPassPanel_LevelInit















global function InitPassPanel
global function UpdateRewardPanel
global function InitAboutBattlePass1Dialog

global function InitPassPurchaseMenu

global function GetNumPages

global function TryDisplayBattlePassAwards

global function InitBattlePassRewardButtonRui

global function Battlepass_ShouldShowLow

global function BattlePass_PopulateRewardButton
global function BattlePass_SetRewardButtonIconSettings
global function BattlePass_SetUnlockedString

global function ServerCallback_GotBPFromPremier

global function GetBattlePassRewardHeaderText
global function GetBattlePassRewardItemName

global function BattlePass_PurchaseButton_OnActivate
global function ShouldDisplayTallButton
global function GetCharacterIconToDisplay



global function Season_GetLongName
global function Season_GetShortName
global function Season_GetTimeRemainingText
global function Season_GetSmallLogo
global function Season_GetSmallLogoBg
global function Season_GetLobbyBannerLeftImage
global function Season_GetLobbyBannerRightImage

global function Season_GetTitleTextColor
global function Season_GetHeaderTextColor
global function Season_GetTimeRemainingTextColor
global function Season_GetNewColor
global function Season_GetColor

global function Season_GetTabBarFocusedCol
global function Season_GetTabBarSelectedCol
global function Season_GetTabBGFocusedCol
global function Season_GetTabBGSelectedCol
global function Season_GetTabTextDefaultCol
global function Season_GetTabTextFocusedCol
global function Season_GetTabTextSelectedCol
global function Season_GetTabGlowFocusedCol

global function Season_GetSubTabBarFocusedCol
global function Season_GetSubTabBarSelectedCol
global function Season_GetSubTabBGFocusedCol
global function Season_GetSubTabBGSelectedCol
global function Season_GetSubTabTextDefaultCol
global function Season_GetSubTabTextFocusedCol
global function Season_GetSubTabTextSelectedCol
global function Season_GetSubTabGlowFocusedCol







struct BattlePassPageData
{
	int startLevel
	int endLevel
}





struct FileStruct_LifetimeLevel
{





















		int numCraftingMetalsInBattlePass = 0
		int numApexCoinsInBattlePass = 0

	table signalDummy
	int   videoChannel = -1

}
FileStruct_LifetimeLevel& fileLevel



const float CURSOR_DELAY_BASE = 0.3
const float CURSOR_DELAY_MED = 0.3
const float CURSOR_DELAY_FAST = 0.1

const int numBattlePassBulletPoints = 16

global struct RewardGroup
{
	int                     level
	array<BattlePassReward> rewards
}
struct RewardButtonData
{
	var               button
	var               footer
	int               rewardGroupSubIdx
	RewardGroup&      rewardGroup
	int               rewardSubIdx
	BattlePassReward& bpReward
}


struct
{

		int                                previousPage = -1
		int                                currentPage = -1
		array<RewardGroup>                 currentRewardGroups = []
		string ornull                      currentRewardButtonKey = null
		
		
		var                                rewardBarPanelHeader
		array<var>                         rewardButtonsFree
		array<var>                         rewardButtonsPremium
		table<var, RewardButtonData>       rewardButtonToDataMap
		table<string, RewardButtonData>    rewardKeyToRewardButtonDataMap
		array<var>                         rewardHeaders
		var                                rewardBarFooter
		bool                               rewardButtonFocusForced
		bool                               isShowingBattlePassProgress

		var nextPageButton
		var prevPageButton

		var invisiblePageLeftTriggerButton
		var invisiblePageRightTriggerButton

		var navRightOverriddenFree = null
		var navRightOverriddenPremium = null

		var statusBox
		var purchaseBG
		var purchaseButton
		var giftButton

		var levelReqButton
		var premiumReqButton

		var detailBox
		var loadscreenPreviewBox
		var loadscreenPreviewBoxOverlay

		int   lastStickState
		float stickRepeatAllowTime

		var focusedRewardButton
		int aboutVideoChannel
		var aboutPurchaseButton
		var aboutProgressButton

		table< ItemFlavor, table<int, BattlePassPageData> > pageDatas


} file


const int MAX_LEVELS_PER_PAGE = 8
const int REWARDS_PER_PAGE = 9








void function ShPassPanel_LevelInit()
{










		if ( IsLobby() ) 
		{
			ItemFlavor ornull activeBattlePass = GetActiveBattlePass()

			if ( activeBattlePass != null )
				BuildPageDatas( expect ItemFlavor( activeBattlePass ) )
		}

}




void function InitPassPanel( var panel )
{
	RegisterSignal( "TryChangePageThread" )

	SetPanelTabTitle( panel, "#PASS" )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, OnPanelShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, OnPanelHide )

	file.purchaseBG = Hud_GetChild( panel, "PurchaseBG" )

	file.purchaseButton = Hud_GetChild( panel, "PurchaseButton" )
	file.giftButton = Hud_GetChild( panel, "GiftButton" )
	Hud_AddEventHandler( file.purchaseButton, UIE_CLICK, BattlePass_PurchaseButton_OnActivate )
	Hud_AddEventHandler( file.giftButton, UIE_CLICK, GiftButton_OnClick )

	file.rewardBarPanelHeader = Hud_GetChild( panel, "RewardBarPanelHeader" )
	file.rewardHeaders = GetPanelElementsByClassname( file.rewardBarPanelHeader, "RewardFooter" )

	file.rewardButtonsFree = GetPanelElementsByClassname( file.rewardBarPanelHeader, "RewardButtonFree" )
	foreach ( int rewardButtonIdx, var rewardButton in file.rewardButtonsFree )
	{
		Hud_SetNavUp( rewardButton, file.purchaseButton )
		Hud_AddEventHandler( rewardButton, UIE_GET_FOCUS, BattlePass_RewardButtonFree_OnGetFocus )
		Hud_AddEventHandler( rewardButton, UIE_LOSE_FOCUS, BattlePass_RewardButtonFree_OnLoseFocus )
		Hud_AddEventHandler( rewardButton, UIE_CLICK, BattlePass_RewardButtonFree_OnActivate )
		Hud_AddEventHandler( rewardButton, UIE_CLICKRIGHT, BattlePass_RewardButtonFree_OnAltActivate )
	}

	file.rewardButtonsPremium = GetPanelElementsByClassname( file.rewardBarPanelHeader, "RewardButtonPremium" )
	foreach ( int rewardButtonIdx, var rewardButton in file.rewardButtonsPremium )
	{
		Hud_SetNavUp( rewardButton, file.rewardButtonsFree[ rewardButtonIdx ] )
		Hud_SetNavDown( file.rewardButtonsFree[ rewardButtonIdx ], rewardButton )
		Hud_AddEventHandler( rewardButton, UIE_GET_FOCUS, BattlePass_RewardButtonPremium_OnGetFocus )
		Hud_AddEventHandler( rewardButton, UIE_LOSE_FOCUS, BattlePass_RewardButtonPremium_OnLoseFocus )
		Hud_AddEventHandler( rewardButton, UIE_CLICK, BattlePass_RewardButtonPremium_OnActivate )
		Hud_AddEventHandler( rewardButton, UIE_CLICKRIGHT, BattlePass_RewardButtonPremium_OnAltActivate )
	}

	file.rewardBarFooter = Hud_GetChild( panel, "RewardBarFooter" )

	file.nextPageButton = Hud_GetChild( panel, "RewardBarNextButton" )
	file.prevPageButton = Hud_GetChild( panel, "RewardBarPrevButton" )
	var prevPageRui = Hud_GetRui( file.prevPageButton )
	RuiSetBool( prevPageRui, "flipHorizontal", true )

	Hud_AddEventHandler( file.nextPageButton, UIE_CLICK, BattlePass_PageForward )
	Hud_AddEventHandler( file.prevPageButton, UIE_CLICK, BattlePass_PageBackward )
	file.statusBox = Hud_GetChild( panel, "StatusBox" )

	Hud_AddEventHandler( Hud_GetChild( panel, "StatusBox" ), UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "BattlePassAboutPage1" ) ) )

	file.levelReqButton = Hud_GetChild( panel, "LevelReqButton" )
	file.premiumReqButton = Hud_GetChild( panel, "PremiumReqButton" )

	file.detailBox = Hud_GetChild( panel, "DetailsBox" )
	file.loadscreenPreviewBox = Hud_GetChild( panel, "LoadscreenPreviewBox" )
	file.loadscreenPreviewBoxOverlay = Hud_GetChild( panel, "LoadscreenPreviewBoxOverlay" )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddPanelFooterOption( panel, LEFT, BUTTON_A, false, "#A_BUTTON_INSPECT", "#A_BUTTON_INSPECT", null, BattlePass_IsFocusedItemInspectable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", null, BattlePass_IsFocusedItemEquippable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_BUY_UP_TO", "#X_BUTTON_BUY_UP_TO", null, BattlePass_CanBuyUpToFocusedItem )
	AddPanelFooterOption( panel, LEFT, BUTTON_Y, true, "#Y_GIFT_INFO_TITLE", "#GIFT_INFO_TITLE", OpenGiftInfoPopUp )

	file.invisiblePageLeftTriggerButton = Hud_GetChild( file.rewardBarPanelHeader, "InvisiblePageLeftTriggerButton" )
	Hud_AddEventHandler( file.invisiblePageLeftTriggerButton, UIE_GET_FOCUS, void function( var button ) {
		BattlePass_PageBackward( button )
	} )
	file.invisiblePageRightTriggerButton = Hud_GetChild( file.rewardBarPanelHeader, "InvisiblePageRightTriggerButton" )
	Hud_AddEventHandler( file.invisiblePageRightTriggerButton, UIE_GET_FOCUS, void function( var button ) {
		BattlePass_PageForward( button )
	} )
}


string function GetRewardButtonKey( int levelNum, int rewardSubIdx )
{
	return format( "level%d:reward%d", levelNum, rewardSubIdx )
}

void function UpdateRewardPanel( array<RewardGroup> rewardGroups )
{
	int panelMaxWidth = Hud_GetBaseWidth( file.rewardBarPanelHeader )

	const int MAX_REWARD_BUTTONS = 15
	const int MAX_REWARD_FOOTERS = 15

	int thinDividers
	int thickDividers
	int numButtons = 0
	foreach ( rewardIdx, rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		thinDividers += (rewardGroup.rewards.len() - 1)
		if ( rewardIdx < (rewardGroups.len() - 1) )
			thickDividers++

		numButtons += GetRewardsBoxSizeForGroup( rewardGroup )
	}

	Assert( file.rewardHeaders.len() == MAX_REWARD_FOOTERS )
	Assert( file.rewardButtonsFree.len() == MAX_REWARD_BUTTONS )
	Assert( file.rewardButtonsPremium.len() == MAX_REWARD_BUTTONS )

	file.rewardButtonsFree.sort( SortByScriptId )
	file.rewardButtonsPremium.sort( SortByScriptId )

	int buttonWidth = Hud_GetWidth( file.rewardButtonsFree[0] )

	foreach ( headerBox in file.rewardHeaders )
	{
		Hud_Hide( headerBox )
		Hud_SetEnabled( headerBox, false )
	}

	foreach ( rewardButton in file.rewardButtonsFree )
	{
		Hud_Hide( rewardButton )
		Hud_SetEnabled( rewardButton, false )
		Hud_SetSelected( rewardButton, false )
	}

	foreach ( rewardButton in file.rewardButtonsPremium )
	{
		Hud_Hide( rewardButton )
		Hud_SetEnabled( rewardButton, false )
		Hud_SetSelected( rewardButton, false )
	}

	file.rewardButtonToDataMap.clear()
	file.rewardKeyToRewardButtonDataMap.clear()

	

	int thinPadding  = ContentScaledXAsInt( 4 )
	int thickPadding = ContentScaledXAsInt( 50 )

	if ( file.currentPage == 0 )
	{
		thickPadding = ContentScaledXAsInt( 56 )
	}

	int contentWidth       = (buttonWidth * numButtons) + (thinPadding * thinDividers) + (thickPadding * thickDividers)
	int minContentWidth    = (buttonWidth * 5) + (thinPadding * thinDividers) + (thickPadding * 4)
	
	bool hasPremiumPass    = false
	int battlePassLevelIdx = 0

	
	
	

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null && GRX_IsInventoryReady()
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
		battlePassLevelIdx = GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false )
	}

	array<RewardButtonData> rewardButtonDataList = []

	int offset    = 0
	int buttonIdx = 0
	int footerIdx = 0

	int numLevels
	foreach ( int rewardGroupSubIdx, RewardGroup rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		numLevels++
	}

	for (int rewardGroupSubIdx = 0 ; rewardGroupSubIdx < rewardGroups.len() ; rewardGroupSubIdx++)
	{
		RewardGroup rewardGroup = rewardGroups[IsRTL() ? rewardGroups.len() - 1 - rewardGroupSubIdx : rewardGroupSubIdx]

		if ( rewardGroup.rewards.len() == 0 )
			continue

		var rewardFooter = file.rewardHeaders[footerIdx]
		Hud_SetX( rewardFooter, offset )
		var footerRui = Hud_GetRui( rewardFooter )
		RuiSetString( footerRui, "levelText", GetBattlePassDisplayLevel( rewardGroup.level ) )
		RuiSetInt( footerRui, "level", rewardGroup.level )
		Hud_Show( rewardFooter )
		Hud_SetEnabled( rewardFooter, true )

		array<RewardButtonData> rbd_freeArray
		array<RewardButtonData> rbd_premiumArray

		foreach ( int rewardSubIdx, BattlePassReward bpReward in rewardGroup.rewards )
		{
			RewardButtonData rbd
			rbd.footer = rewardFooter
			rbd.rewardGroupSubIdx = rewardGroupSubIdx
			rbd.rewardGroup = rewardGroup
			rbd.rewardSubIdx = rewardSubIdx
			rbd.bpReward = bpReward

			if ( bpReward.isPremium )
				rbd_premiumArray.append( rbd )
			else
				rbd_freeArray.append( rbd )
		}

		int footerWidth           = 0
		int numButtonsInThisLevel = maxint( rbd_freeArray.len(), rbd_premiumArray.len() )

		for ( int i = 0; i < numButtonsInThisLevel; i++ )
		{
			RewardButtonData rbd_free
			RewardButtonData rbd_premium
			BattlePassReward bpReward

			Hud_Hide( file.rewardButtonsFree[buttonIdx] )
			Hud_Hide( file.rewardButtonsPremium[buttonIdx] )

			if ( (rbd_freeArray.len() > i && !IsRTL()) || (IsRTL() && rbd_freeArray.len() > numButtonsInThisLevel - 1 - i ) )
			{
				rbd_free = rbd_freeArray[ IsRTL() ? numButtonsInThisLevel - 1 - i : i ]
				PopulateBattlePassButton( rbd_free, file.rewardButtonsFree[buttonIdx], rewardButtonDataList, hasActiveBattlePass, hasPremiumPass, battlePassLevelIdx, offset )
				bpReward = rbd_free.bpReward
			}

			if ( (rbd_premiumArray.len() > i && !IsRTL()) || (IsRTL() && rbd_premiumArray.len() > numButtonsInThisLevel - 1 - i))
			{
				rbd_premium = rbd_premiumArray[ IsRTL() ? numButtonsInThisLevel - 1 - i : i ]
				PopulateBattlePassButton( rbd_premium, file.rewardButtonsPremium[buttonIdx], rewardButtonDataList, hasActiveBattlePass, hasPremiumPass, battlePassLevelIdx, offset )
				bpReward = rbd_premium.bpReward
			}

			bool isOwned = bpReward.level <= battlePassLevelIdx
			RuiSetBool( footerRui, "isOwned", isOwned )
			RuiSetInt( footerRui, "ownedLevel", battlePassLevelIdx )

			offset += buttonWidth
			footerWidth += buttonWidth

			if ( i < numButtonsInThisLevel - 1 )
			{
				offset += thinPadding
				footerWidth += thinPadding
			}
			else
			{
				offset += thickPadding
			}

			buttonIdx++
		}

		int margin = thickPadding
		Hud_SetWidth( rewardFooter, footerWidth + margin )
		Hud_SetX( rewardFooter, Hud_GetX( rewardFooter ) - int( margin * 0.5 ) )
		RuiSetBool( footerRui, "isLast", footerIdx >= numLevels - 1 )
		RuiSetBool( footerRui, "isFirst", footerIdx == 0 )
		footerIdx++
	}

	ResetBattlePassButtonNav( file.navRightOverriddenFree, "RewardButton" ) 

	Hud_SetNavRight( file.rewardButtonsFree[buttonIdx - 1], file.invisiblePageRightTriggerButton )
	file.navRightOverriddenFree = file.rewardButtonsFree[buttonIdx - 1]

	ResetBattlePassButtonNav( file.navRightOverriddenPremium, "RewardButtonPremium" ) 

	Hud_SetNavRight( file.rewardButtonsPremium[buttonIdx - 1], file.invisiblePageRightTriggerButton )
	file.navRightOverriddenPremium = file.rewardButtonsPremium[buttonIdx - 1]

	var buttonToFocus

	if ( GetFocus() == file.invisiblePageLeftTriggerButton || GetFocus() == file.prevPageButton )
		buttonToFocus = file.rewardButtonsPremium[buttonIdx - 1]
	else if ( GetFocus() == file.invisiblePageRightTriggerButton || GetFocus() == file.nextPageButton )
		buttonToFocus = file.rewardButtonsPremium[0]

	if ( buttonToFocus != null )
	{
		if ( buttonToFocus != file.focusedRewardButton )
		{
			Hud_SetFocused( buttonToFocus )
		}
		else
		{
			BattlePass_RewardButton_OnLoseFocus( buttonToFocus )
			BattlePass_RewardButton_OnGetFocus( buttonToFocus )
		}
	}

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}

void function ResetBattlePassButtonNav ( var button, string buttonType )
{
	if ( button == null )
		return

	string buttonName =  Hud_GetHudName( button )
	string buttonNumber = buttonName.slice( buttonType.len() )
	int navRightNum = buttonNumber.tointeger() + 1

	string navRightButtonName = buttonType + navRightNum.tostring()

	if ( Hud_HasChild( Hud_GetParent( button ), navRightButtonName ) )
	{
		var navRightButton = Hud_GetChild( Hud_GetParent( button ), navRightButtonName )
		Hud_SetNavRight( button, navRightButton )
	}
}

void function PopulateBattlePassButton( RewardButtonData rbd, var rewardButton, array<RewardButtonData> rewardButtonDataList, bool hasActiveBattlePass, bool hasPremiumPass, int battlePassLevelIdx, int offset )
{
	rbd.button = rewardButton

	file.rewardButtonToDataMap[rewardButton] <- rbd
	file.rewardKeyToRewardButtonDataMap[GetRewardButtonKey( rbd.rewardGroup.level, rbd.rewardSubIdx )] <- rbd

	rewardButtonDataList.append( rbd )

	Hud_SetX( rewardButton, offset )
	Hud_SetEnabled( rewardButton, hasActiveBattlePass )

	BattlePassReward bpReward = rbd.bpReward

	bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level <= battlePassLevelIdx

	BattlePass_PopulateRewardButton( bpReward, rewardButton, isOwned, bpReward.isPremium )

	var btnRui = Hud_GetRui( rewardButton )
	RuiSetBool( btnRui, "isPassPanel", true )
}

void function BattlePass_PopulateRewardButton( BattlePassReward bpReward, var rewardButton, bool isOwned, bool canUseTallButton, var ruiOverride = null )
{
	var btnRui
	if ( rewardButton != null )
		btnRui = Hud_GetRui( rewardButton )
	if ( ruiOverride != null )
		btnRui = ruiOverride

	Assert( btnRui != null )

	RuiSetBool( btnRui, "isOwned", isOwned )
	RuiSetBool( btnRui, "isPremium", bpReward.isPremium )

	int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
	RuiSetInt( btnRui, "rarity", rarity )

	asset rewardImage = CustomizeMenu_GetRewardButtonImage( bpReward.flav )
	RuiSetImage( btnRui, "buttonImage", rewardImage )
	
	RuiSetImage( btnRui, "buttonImageSecondLayer", $"" )
	RuiSetFloat2( btnRui, "buttonImageSecondLayerOffset", <0.0, 0.0, 0.0> )

	int itemType = ItemFlavor_GetType( bpReward.flav )

	if ( itemType == eItemType.account_pack )
		RuiSetBool( btnRui, "isLootBox", true )
	else
		RuiSetBool( btnRui, "isLootBox", false )

	RuiSetString( btnRui, "itemCountString", "" )
	if ( itemType == eItemType.account_currency )
	{
		RuiSetString( btnRui, "itemCountString", FormatAndLocalizeNumber( "1", float( bpReward.quantity ), true ) )
	}
	else if ( itemType == eItemType.account_pack )
	{
		if( float( bpReward.quantity ) > 1.0 )
			RuiSetString( btnRui, "itemCountString", FormatAndLocalizeNumber( "1", float( bpReward.quantity ), true ) )
	}

	RuiSetInt( btnRui, "bpLevel", bpReward.level )
	RuiSetBool( btnRui, "isRewardBar", false )
	RuiSetBool( btnRui, "showCharacterIcon", false )

	if ( GRX_IsInventoryReady() )
	{
		ItemFlavor ornull activeBattlePass = GetActiveBattlePass()
		expect ItemFlavor( activeBattlePass )
		bool hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
		RuiSetBool( btnRui, "isPremiumBPOwned", hasPremiumPass )
	}

	BattlePass_SetRewardButtonIconSettings( bpReward.flav, btnRui, rewardButton, canUseTallButton )

	RuiSetBool( btnRui, "forceShowRarityBG", ShouldForceShowRarityBG( bpReward.flav ) )

	if ( rewardButton != null )
		Hud_Show( rewardButton )
}

void function BattlePass_ForceFullIconForWeaponSkin( ItemFlavor flav, var btnRui, bool useTallButton, asset rewardImage )
{
	asset weaponIcon = WeaponItemFlavor_GetHudIcon( WeaponSkin_GetWeaponFlavor( flav ) )
	RuiSetBool( btnRui, "showCharacterIcon", weaponIcon != $"" )
	RuiSetImage( btnRui, "characterIcon", weaponIcon )

	RuiSetBool( btnRui, "forceFullIcon", true )
	RuiSetFloat2( btnRui, "characterIconSize", <60, 30, 0> )

	if ( !useTallButton )
	{
		
		
		RuiSetImage( btnRui, "buttonImage", $"white" )
		RuiSetImage( btnRui, "buttonImageSecondLayer", rewardImage )
		RuiSetFloat2( btnRui, "buttonImageSecondLayerOffset", <0.0, 0.16, 0.0> )
	}
}

void function BattlePass_SetRewardButtonIconSettings( ItemFlavor flav, var btnRui, var rewardButton, bool canUseTallButton )
{
	asset rewardImage = CustomizeMenu_GetRewardButtonImage( flav )

	if ( rewardButton != null )
		Hud_SetHeight( rewardButton, Hud_GetBaseHeight( rewardButton ) )

	RuiSetBool( btnRui, "forceFullIcon", false )
	if ( ShouldDisplayTallButton( flav ) )
	{
		if ( canUseTallButton )
		{
			if ( rewardButton != null )
				Hud_SetHeight( rewardButton, Hud_GetBaseHeight( rewardButton ) * 1.5 )
		}

		if ( ItemFlavor_GetType( flav ) != eItemType.character_skin )
		{
			asset icon = GetCharacterIconToDisplay( flav )
			RuiSetBool( btnRui, "showCharacterIcon", icon != $"" )
			RuiSetImage( btnRui, "characterIcon", icon )
			RuiSetFloat2( btnRui, "characterIconSize", <35, 35, 0> )

			if ( ItemFlavor_GetType( flav ) == eItemType.weapon_skin )
			{
				if ( icon != $"" && icon != rewardImage )
					BattlePass_ForceFullIconForWeaponSkin( flav, btnRui, canUseTallButton, rewardImage )
			}
		}
		else
		{
			RuiSetBool( btnRui, "forceFullIcon", true )
		}

		return
	}

	if ( ItemFlavor_GetType( flav ) == eItemType.weapon_skin && GetGlobalSettingsBool( ItemFlavor_GetAsset( flav ), "forceFullWeaponIcon" ) )
	{
		BattlePass_ForceFullIconForWeaponSkin( flav, btnRui, false, rewardImage ) 
		return
	}
}

bool function ShouldForceShowRarityBG( ItemFlavor flav )
{
	int itemType = ItemFlavor_GetType( flav )
	switch ( itemType )
	{
		case eItemType.weapon_skin:
		case eItemType.weapon_charm:
		case eItemType.character_skin:
		case eItemType.gladiator_card_frame:
		case eItemType.gladiator_card_stance:
		case eItemType.gladiator_card_intro_quip:
		case eItemType.gladiator_card_kill_quip:
		case eItemType.gladiator_card_stat_tracker:
		case eItemType.loadscreen:
		case eItemType.account_pack:
		case eItemType.voucher:
			return true
	}

	return false
}

asset function GetCharacterIconToDisplay( ItemFlavor flav )
{
	ItemFlavor ornull char = GetItemFlavorAssociatedCharacterOrWeapon( flav )

	if ( char != null )
	{
		expect ItemFlavor( char )
		asset icon = ItemFlavor_GetIcon( char )
		if ( icon != ItemFlavor_GetIcon( flav ) )
			return icon
	}

	return $""
}

bool function ShouldDisplayTallButton( ItemFlavor flav )
{
	int itemType = ItemFlavor_GetType( flav )

	switch ( itemType )
	{
		case eItemType.character_skin:
			
			
			return ItemFlavor_GetIcon( flav ) != $""

		case eItemType.character_execution:
		case eItemType.gladiator_card_frame:
		case eItemType.gladiator_card_stance:
		case eItemType.character_emote:
		case eItemType.skydive_emote:
		case eItemType.emote_icon:
			return true

		case eItemType.weapon_skin:
			
			
			return ItemFlavor_GetQuality( flav ) >= eRarityTier.EPIC && ItemFlavor_GetIcon( flav ) != $""
	}

	return false
}

void function BattlePass_PageForward( var button )
{
	if ( GetActiveMenu() != GetMenu( "LobbyMenu" ) )
		return

	int oldPage = file.currentPage
	BattlePass_SetPage( file.currentPage + 1 )

	if ( oldPage != file.currentPage )
	{
		var focus = GetFocus()
		if ( focus != file.nextPageButton
				&& focus != file.prevPageButton
				&& focus != file.invisiblePageLeftTriggerButton
				&& focus != file.invisiblePageRightTriggerButton )
		{
			file.focusedRewardButton = null
			ForceVGUIFocusUpdate()
		}
		EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	}
}


void function BattlePass_PageBackward( var button )
{
	if ( GetActiveMenu() != GetMenu( "LobbyMenu" ) )
		return

	int oldPage = file.currentPage
	BattlePass_SetPage( file.currentPage - 1 )

	if ( oldPage != file.currentPage )
	{
		var focus = GetFocus()
		if ( focus != file.nextPageButton
				&& focus != file.prevPageButton
				&& focus != file.invisiblePageLeftTriggerButton
				&& focus != file.invisiblePageRightTriggerButton )
		{
			file.focusedRewardButton = null
			ForceVGUIFocusUpdate()
		}
		EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	}
}

bool function ContainsOwnedBPPresaleVoucher( GRXScriptOffer offer )
{
	foreach( GRXStoreOfferItem item in offer.items )
	{
		if ( ItemFlavor_GetType(GetItemFlavorByGRXIndex( item.itemIdx )) == eItemType.battlepass_presale_voucher &&
			 GRX_IsItemOwnedByPlayer( GetItemFlavorByGRXIndex( item.itemIdx )))
		{
			return true
		}
	}
	return false
}

void function BattlePass_PurchaseButton_OnActivate( var button )
{
	BattlePass_Purchase( button, 1 )
}


void function BattlePass_Purchase( var button, int startQuantity )
{
	entity player = GetLocalClientPlayer()
	EHI playerEHI = ToEHI( player )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( playerEHI )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		return
	}
	expect ItemFlavor( activeBattlePass )

	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )

	if ( !hasPremiumPass )
	{
		AdvanceMenu( GetMenu( "PassPurchaseMenu" ) )
	}
	else if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetLocalClientPlayer() ), activeBattlePass ) > 0 )
	{
		if ( ItemFlavor_IsItemDisabledForGRX( BattlePass_GetXPPurchaseFlav( activeBattlePass ) ) )
		{
			EmitUISound( "menu_deny" )
			return
		}

		RewardPurchaseDialogConfig rpdcfg

		rpdcfg.secondaryButtonIsEnabled = CanPlayerPurchaseBattlePassLevelsWithLegendTokens( player, activeBattlePass )

		rpdcfg.purchaseButtonTextCallback = string function( int purchaseQuantity ) : ( activeBattlePass ) {
			ItemFlavor xpPurchaseFlav              = BattlePass_GetXPPurchaseFlav( activeBattlePass )
			array<GRXScriptOffer> xpPurchaseOffers = GRX_GetItemDedicatedStoreOffers( xpPurchaseFlav, "battlepass" )
			Assert( xpPurchaseOffers.len() == 1 )
			if ( xpPurchaseOffers.len() < 1 )
			{
				Warning( "No offer for xp purchase for '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )
				return ""
			}
			GRXScriptOffer xpPurchaseOffer = xpPurchaseOffers[0]
			Assert( xpPurchaseOffer.prices.len() == 1 )
			if ( xpPurchaseOffer.prices.len() < 1 )
				return ""

			return GRX_GetFormattedPrice( xpPurchaseOffer.prices[0], purchaseQuantity )
		}

		rpdcfg.secondaryPurchaseButtonTextCallback = string function ( int purchaseQuantity ) : ( activeBattlePass ) {
			ItemFlavor xpPurchaseLegendTokenFlav              = BattlePass_GetXPPurchaseLegendTokenFlav( activeBattlePass )
			array<GRXScriptOffer> xpPurchaseLegendTokenOffers = GRX_GetItemDedicatedStoreOffers( xpPurchaseLegendTokenFlav, "battlepass" )
			Assert( xpPurchaseLegendTokenOffers.len() == 1 )
			if ( xpPurchaseLegendTokenOffers.len() < 1 )
			{
				Warning( "No offer for xp purchase legend token for '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )
				return ""
			}
			GRXScriptOffer xpPurchaseLegendTokenOffer = xpPurchaseLegendTokenOffers[0]
			Assert( xpPurchaseLegendTokenOffer.prices.len() == 1 )
			if ( xpPurchaseLegendTokenOffer.prices.len() < 1 )
				return ""

			return GRX_GetFormattedPrice( xpPurchaseLegendTokenOffer.prices[0], purchaseQuantity )
		}

		rpdcfg.maxPurchasableLevelsCallback = int function() : ( activeBattlePass ) {
			return GetPlayerBattlePassPurchasableLevels( ToEHI( GetLocalClientPlayer() ), activeBattlePass )
		}

		rpdcfg.startingPurchaseLevelIdxCallback = int function() : ( activeBattlePass ) {
			return GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false )
		}

		rpdcfg.secondaryButtonAvailabilityCallback = bool function( int purchaseQuantity ) : ( activeBattlePass ) {
			if ( !CanPlayerPurchaseBattlePassLevelsWithLegendTokens( GetLocalClientPlayer(), activeBattlePass ) )
				return false
			bool hasEnoughLevels = GetPlayerBattlePassPurchasableLevelsWithLegendTokens( ToEHI( GetLocalClientPlayer() ), activeBattlePass ) >= purchaseQuantity
			return hasEnoughLevels
		}

		rpdcfg.secondaryPurchaseButtonDescTextCallback = string function ( int purchaseQuantity ) : ( activeBattlePass ) {
			int levelsLeft = 0
			int levelsMax = 0

			if ( CanPlayerPurchaseBattlePassLevelsWithLegendTokens( GetLocalClientPlayer(), activeBattlePass ) )
			{
				levelsLeft = GetPlayerBattlePassUnpurchasedLevelsWithLegendTokens( ToEHI( GetLocalClientPlayer() ), activeBattlePass )
				levelsMax = GetMaxBattlePassLevelsWithLegendTokens()
			}

			return Localize( "#BATTLE_PASS_MAX_N_PURCHASE_LEVEL_WITH_LEGEND_TOKEN", levelsLeft, levelsMax )
		}

		rpdcfg.rewardsCallback = array<BattlePassReward> function( int purchaseQuantity, int startingPurchaseLevelIdx ) : ( activeBattlePass ) {
			array<BattlePassReward> rewards
			for ( int index = 1; index <= purchaseQuantity; index++ )
				rewards.extend( GetBattlePassLevelRewards( activeBattlePass, startingPurchaseLevelIdx + index ) )
			return rewards
		}

		rpdcfg.getPurchaseFlavCallback = ItemFlavor function() : ( activeBattlePass ) {
			return BattlePass_GetXPPurchaseFlav( activeBattlePass )
		}

		rpdcfg.getSecondaryPurchaseFlavCallback = ItemFlavor function() : ( activeBattlePass ) {
			return BattlePass_GetXPPurchaseLegendTokenFlav( activeBattlePass )
		}


		rpdcfg.toolTipDataMaxPurchase.titleText     = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
		rpdcfg.toolTipDataMaxPurchase.descText      = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
		rpdcfg.toolTipDataSecondaryButton.titleText = "#BATTLE_PASS_PURCHASE_LEVEL_LEGEND_TOKEN_OVER_LIMIT"
		rpdcfg.toolTipDataSecondaryButton.descText  = Localize( "#BATTLE_PASS_PURCHASE_LEVEL_LEGEND_TOKEN_OVER_LIMIT_DESC", GetMaxBattlePassLevelsWithLegendTokens() )

		asset lockIcon = $"rui/menu/buttons/lock"

		rpdcfg.levelIndexStart                = 1
		rpdcfg.headerText                     = "#BATTLE_PASS_YOU_WILL_RECEIVE"
		rpdcfg.quantityText                   = "#BATTLE_PASS_PLUS_N_LEVEL"
		rpdcfg.titleText                      = "#BATTLE_PASS_PURCHASE_LEVEL"
		rpdcfg.descText                       = "#BATTLE_PASS_PURCHASE_LEVEL_DESC"
		rpdcfg.buttonLinkerText               = "#BATTLE_PASS_PURCHASE_LEVEL_BUTTON_LINKER"
		rpdcfg.quantityTextPlural             = "#BATTLE_PASS_PLUS_N_LEVELS"
		rpdcfg.titleTextPlural                = "#BATTLE_PASS_PURCHASE_LEVELS"
		rpdcfg.descTextPlural                 = "#BATTLE_PASS_PURCHASE_LEVELS_DESC"
		rpdcfg.secondaryButtonUnavailableText = "%$" + lockIcon + "% " + Localize( "#BATTLE_PASS_PURCHASE_LEVEL_LEGEND_TOKEN_UNAVAILABLE" )
		rpdcfg.startQuantity                  = startQuantity

		RewardPurchaseDialog( rpdcfg )
	}
	
	else
	{
		bpPresaleOfferData presaleOfferData = GetBPPresaleOfferData()
		if ( presaleOfferData.basicOffer == null || presaleOfferData.bundleOffer == null )
		{
			Assert( presaleOfferData.basicOffer == null && presaleOfferData.bundleOffer == null,
			"Error: One of the BP Presale Offers is null while the other is valid. While Presale is live, both offers must be valid.")
			return
		}
		
		
		GRXScriptOffer offer = expect GRXScriptOffer( presaleOfferData.basicOffer )
		if ( ContainsOwnedBPPresaleVoucher( offer ) )
		{
			return
		}
		OpenBPPresaleDialog( presaleOfferData )
	}
}

void function BattlePass_RewardButtonFree_OnGetFocus( var button )
{
	BattlePass_RewardButton_OnGetFocus( button )
}

void function BattlePass_RewardButtonFree_OnLoseFocus( var button )
{
	BattlePass_RewardButton_OnLoseFocus( button )
}

void function BattlePass_RewardButtonFree_OnActivate( var button )
{
	BattlePass_RewardButton_OnActivate( button )
}

void function BattlePass_RewardButtonFree_OnAltActivate( var button )
{
	BattlePass_RewardButton_OnAltActivate( button )
}

void function BattlePass_RewardButtonPremium_OnGetFocus( var button )
{
	BattlePass_RewardButton_OnGetFocus( button )
}

void function BattlePass_RewardButtonPremium_OnLoseFocus( var button )
{
	BattlePass_RewardButton_OnLoseFocus( button )
}

void function BattlePass_RewardButtonPremium_OnActivate( var button )
{
	BattlePass_RewardButton_OnActivate( button )
}

void function BattlePass_RewardButtonPremium_OnAltActivate( var button )
{
	BattlePass_RewardButton_OnAltActivate( button )
}

void function BattlePass_RewardButton_OnGetFocus( var button )
{
	Hud_SetNavDown( file.purchaseButton, button )
	Hud_SetNavDown( file.giftButton, button )

	if ( !(button in file.rewardButtonToDataMap) )
		return

	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]

	file.currentRewardButtonKey = GetRewardButtonKey( rbd.rewardGroup.level, rbd.rewardSubIdx )
	bool wasFocusForced = file.rewardButtonFocusForced
	file.rewardButtonFocusForced = false

	Hud_SetNavDown( file.purchaseButton, rbd.button )
	Hud_SetNavDown( file.giftButton, rbd.button )

	foreach ( var otherButton in file.rewardButtonsFree )
		Hud_SetSelected( otherButton, false )
	foreach ( var otherButton in file.rewardButtonsPremium )
		Hud_SetSelected( otherButton, false )

	Hud_SetSelected( button, true )

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	file.focusedRewardButton = button
	Hud_Show( file.detailBox )

	int battlePassLevel = GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )

	string itemName = GetBattlePassRewardItemName( reward )
	int rarity      = ItemFlavor_HasQuality( reward.flav ) ? ItemFlavor_GetQuality( reward.flav ) : 0

	string itemDesc   = GetBattlePassRewardItemDesc( reward )
	string headerText = GetBattlePassRewardHeaderText( reward )

	HudElem_SetRuiArg( file.detailBox, "headerText", headerText )
	HudElem_SetRuiArg( file.detailBox, "titleText", itemName )
	HudElem_SetRuiArg( file.detailBox, "descText", itemDesc )
	HudElem_SetRuiArg( file.detailBox, "rarity", rarity )

	HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText3", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText3", "" )

	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_pack )
	{
		if ( rarity == 1 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#APEX_PACK_PROBABILITIES_RARE" ) )
		}
		else if ( rarity == 2 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#APEX_PACK_PROBABILITIES_EPIC" ) )
		}
		else if ( rarity == 3 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#APEX_PACK_PROBABILITIES_LEGENDARY" ) )
		}
	}

	HudElem_SetRuiArg( file.levelReqButton, "buttonText", Localize( "#BATTLE_PASS_LEVEL_REQUIRED", reward.level + 2 ) )
	HudElem_SetRuiArg( file.levelReqButton, "meetsRequirement", battlePassLevel >= reward.level + 1 )
	HudElem_SetRuiArg( file.levelReqButton, "isPremium", false )

	if ( reward.isPremium && hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}
	else if ( reward.isPremium && !hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REQUIRED" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", false )
	}
	else
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_FREE_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}

	HudElem_SetRuiArg( file.premiumReqButton, "isPremium", reward.isPremium )

	bool isLoadScreen = (ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen)
	Hud_SetVisible( file.loadscreenPreviewBox, isLoadScreen )
	Hud_SetVisible( file.loadscreenPreviewBoxOverlay, isLoadScreen )

	float scale = 1.0
	bool shouldPlayAudioPreview = !wasFocusForced
	RunClientScript( "UIToClient_ItemPresentation", ItemFlavor_GetGUID( reward.flav ), reward.level, scale, Battlepass_ShouldShowLow( reward.flav ), file.loadscreenPreviewBox, shouldPlayAudioPreview, "battlepass_right_ref" )

	UpdateBattlePassProgress( wasFocusForced, wasFocusForced )

	UpdateFooterOptions() 
}


void function UpdateBattlePassProgress( bool show, bool instant = false )
{
	if ( file.isShowingBattlePassProgress && show )
		return
	file.isShowingBattlePassProgress = show

	entity player = GetLocalClientPlayer()
	int playerEHI = ToEHI( player )
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( playerEHI )
	if ( activeBattlePass == null )
		return
	expect ItemFlavor( activeBattlePass )
	int currentBattlePassXP  = GetPlayerBattlePassXPProgress( playerEHI, activeBattlePass, false )
	int battlePassLevel      = GetBattlePassLevelForXP( activeBattlePass, currentBattlePassXP ) + 1
	bool battlePassCompleted = battlePassLevel >= (GetBattlePassMaxLevelIndex( activeBattlePass ) + 1)

	var rui = Hud_GetRui( file.detailBox )
	RuiSetBool( rui, "battlePassCompleted", battlePassCompleted )
	RuiSetGameTime( rui, "showBPProgressStartTime", instant ? -100.0 : ClientTime() )
	UpdateChallengeBoxHeaderBPProgress( player, rui )
	RuiSetBool( rui, "showBPProgress", show )

	SetSeasonColors( rui )
}


bool function Battlepass_ShouldShowLow( ItemFlavor flav )
{
	switch ( ItemFlavor_GetType( flav ) )
	{
		case eItemType.character_skin:
		case eItemType.gladiator_card_frame:
		case eItemType.emote_icon:
			return true
	}
	return false
}

void function BattlePass_RewardButton_OnLoseFocus( var button )
{
	if ( GetActiveMenu() == GetMenu( "LobbyMenu" ) )
		file.currentRewardButtonKey = null

	UpdateBattlePassProgress( true )
	UpdateFooterOptions() 
}

void function BattlePass_FocusRewardButton( RewardButtonData rbd )
{
	

	file.currentRewardButtonKey = null
	BattlePass_RewardButton_OnGetFocus( rbd.button )

	HudElem_SetRuiArg( rbd.button, "forceFocusShineMarker", RandomInt( INT_MAX ) )

	
	
	
	
	
}

void function BattlePass_RewardButton_OnActivate( var button )
{
	if ( GetActiveBattlePass() == null )
		return

	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]
	if ( ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen )
	{
		LoadscreenPreviewMenu_SetLoadscreenToPreview( reward.flav )
		AdvanceMenu( GetMenu( "LoadscreenPreviewMenu" ) )
	}
	else if ( InspectItemTypePresentationSupported( reward.flav ) )
	{
		RunClientScript( "ClearBattlePassItem" )
		SetBattlePassItemPresentationModeActive( reward )
	}
}


void function BattlePass_RewardButton_OnAltActivate( var button )
{
	if ( GetActiveBattlePass() == null )
		return

	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]

	if ( BattlePass_CanEquipReward( reward ) )
	{
		ItemFlavor item           = reward.flav
		array<LoadoutEntry> entry = GetAppropriateLoadoutSlotsForItemFlavor( item )

		if ( entry.len() == 0 )
			return

		if ( entry.len() == 1 )
		{
			EmitUISound( "UI_Menu_Equip_Generic" )
			RequestSetItemFlavorLoadoutSlot( ToEHI( GetLocalClientPlayer() ), entry[ 0 ], item )
		}
		else
		{
			
			OpenSelectSlotDialog( entry, item, GetItemFlavorAssociatedCharacterOrWeapon( item ),
				(void function( int index ) : ( entry, item )
				{
					EmitUISound( "UI_Menu_Equip_Generic" )
					RequestSetItemFlavorLoadoutSlot_WithDuplicatePrevention( ToEHI( GetLocalClientPlayer() ), entry, item, index )
				})
			)
		}
		return
	}

	entity player = GetLocalClientPlayer()
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( player ) )
	if ( activeBattlePass == null )
		return
	expect ItemFlavor( activeBattlePass )

	if ( BattlePass_CanBuyUpTo( player, activeBattlePass, rbd ) )
	{
		
		int currentLevel = GetPlayerBattlePassLevel( player, activeBattlePass, false )
		int maxPurchasable = GetPlayerBattlePassPurchasableLevels( ToEHI( player ), activeBattlePass )
		int purchaseLevels = rbd.rewardGroup.level - currentLevel
		Assert( purchaseLevels <= maxPurchasable )
		BattlePass_Purchase( null, purchaseLevels )
	}
}


bool function BattlePass_IsFocusedItemInspectable()
{
	var focusedPanel = GetFocus()
	if ( focusedPanel in file.rewardButtonToDataMap )
	{
		RewardButtonData rbd    = file.rewardButtonToDataMap[focusedPanel]
		BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]
		return (ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen || InspectItemTypePresentationSupported( reward.flav ))
	}
	return false
}


bool function BattlePass_CanBuyUpToFocusedItem()
{
	entity player = GetLocalClientPlayer()
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( player ) )
	if ( activeBattlePass == null )
		return false
	expect ItemFlavor( activeBattlePass )

	var focusedPanel = GetFocus()
	if ( focusedPanel in file.rewardButtonToDataMap )
	{
		RewardButtonData rbd = file.rewardButtonToDataMap[focusedPanel]
		return BattlePass_CanBuyUpTo( player, activeBattlePass, rbd )
	}

	return false
}


bool function BattlePass_CanBuyUpTo( entity player, ItemFlavor activeBattlePass, RewardButtonData rbd )
{
	if ( !GRX_IsInventoryReady( player ) )
		return false

	if ( !DoesPlayerOwnBattlePass( player, activeBattlePass ) )
		return false

	int level = rbd.rewardGroup.level
	int levelXP = GetBattlePassXPForLevel( activeBattlePass, level - 1 )
	int passXP = GetPlayerBattlePassXPProgress( ToEHI( player ), activeBattlePass )
	int maxPurchaseLevels = GetBattlePassMaxPurchaseLevels( activeBattlePass )

	if ( level > maxPurchaseLevels )
		return false

	return passXP < levelXP
}


bool function BattlePass_IsFocusedItemEquippable()
{
	var focusedPanel = GetFocus()
	if ( focusedPanel in file.rewardButtonToDataMap )
	{
		RewardButtonData rbd = file.rewardButtonToDataMap[focusedPanel]
		return BattlePass_CanEquipReward( rbd.rewardGroup.rewards[rbd.rewardSubIdx] )
	}
	return false
}


bool function BattlePass_CanEquipReward( BattlePassReward reward )
{
	ItemFlavor item                  = reward.flav
	int itemType                     = ItemFlavor_GetType( item )
	array<LoadoutEntry> loadoutSlots = GetAppropriateLoadoutSlotsForItemFlavor( item )

	if ( loadoutSlots.len() == 0 )
		return false

	foreach ( loadoutSlot in loadoutSlots)
	{
		bool isEquipped = (LoadoutSlot_GetItemFlavor( LocalClientEHI(), loadoutSlot ) == item)
		if ( isEquipped )
			return false
	}

	return GRX_IsItemOwnedByPlayer_AllowOutOfDateData( item )
}


string function GetBattlePassRewardHeaderText( BattlePassReward reward )
{
	string headerText = ItemFlavor_GetRewardShortDescription( reward.flav )
	if ( ItemFlavor_HasQuality( reward.flav ) )
	{
		string rarityName = ItemFlavor_GetQualityName( reward.flav )
		if ( headerText == "" )
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER", Localize( rarityName ) )
		else
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER_DESC", Localize( rarityName ), headerText )
	}

	return headerText
}


string function GetBattlePassRewardItemName( BattlePassReward reward )
{
	return ItemFlavor_GetLongName( reward.flav )
}


string function GetBattlePassRewardItemDesc( BattlePassReward reward )
{
	string itemDesc = ItemFlavor_GetLongDescription( reward.flav )
	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_currency )
	{
		if ( reward.flav == GetItemFlavorByAsset( $"settings/itemflav/grx_currency/crafting.rpak" ) )
			itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_CRAFTING )
		else
			itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_PREMIUM )
	}
	else if ( ItemFlavor_GetType( reward.flav ) == eItemType.voucher )
	{
		itemDesc = Localize( itemDesc, int( BATTLEPASS_XP_BOOST_AMOUNT * 100 ) )
	}

	return itemDesc
}


array<RewardGroup> function GetRewardGroupsForPage( int pageNumber )
{
	array<RewardGroup> rewardGroups

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null )
		return rewardGroups
	expect ItemFlavor( activeBattlePass )

	int levelOffset    = GetLevelOffsetForPage( activeBattlePass, pageNumber )
	int endLevelOffset = GetLevelEndForPage( activeBattlePass, pageNumber )

	for ( int levelIdx = levelOffset; levelIdx < endLevelOffset; levelIdx++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIdx
		rewardGroup.rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}

int function GetRewardsBoxSizeForGroup( RewardGroup rewardGroup )
{
	int numFree
	int numPremium

	foreach ( reward in rewardGroup.rewards )
	{
		if ( reward.isPremium )
			numPremium++
		else
			numFree++
	}

	return maxint( numPremium, numFree ) 
}

int function GetRewardsCountForLevel( ItemFlavor activeBattlePass, int level )
{
	int numFree
	int numPremium

	array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, level )

	foreach ( reward in rewards )
	{
		if ( reward.isPremium )
			numPremium++
		else
			numFree++
	}

	return maxint( numPremium, numFree ) 
}

int function GetLevelOffsetForPage( ItemFlavor activeBattlePass, int pageIdx )
{
	if ( activeBattlePass in file.pageDatas )
	{
		return file.pageDatas[ activeBattlePass ][ pageIdx ].startLevel
	}

	array<int> pageToLevelIdx = [0]
	int levelsInCurrentPage   = 0
	int rewardCount           = 0
	int maxLevel              = GetBattlePassMaxLevelIndex( activeBattlePass )
	for ( int levelIdx = 0; levelIdx < maxLevel; levelIdx++ )
	{
		int rewardsLen = GetRewardsCountForLevel( activeBattlePass, levelIdx )

		if ( rewardsLen > 0 )
			levelsInCurrentPage++

		if ( rewardCount + rewardsLen <= REWARDS_PER_PAGE && levelsInCurrentPage < MAX_LEVELS_PER_PAGE )
		{
			rewardCount += rewardsLen
		}
		else
		{
			pageToLevelIdx.append( levelIdx )
			rewardCount = rewardsLen
			levelsInCurrentPage = 0
		}
	}

	return pageToLevelIdx[pageIdx]
}


int function GetNumPages( ItemFlavor activeBattlePass )
{
	if ( activeBattlePass in file.pageDatas )
		return file.pageDatas[ activeBattlePass ].len()

	array<int> pageToLevelIdx = [0]
	int levelsInCurrentPage   = 0
	int rewardCount           = 0
	int maxLevel              = GetBattlePassMaxLevelIndex( activeBattlePass )
	for ( int levelIdx = 0; levelIdx < maxLevel; levelIdx++ )
	{
		int rewardsLen = GetRewardsCountForLevel( activeBattlePass, levelIdx )

		if ( rewardsLen > 0 )
			levelsInCurrentPage++

		if ( rewardCount + rewardsLen <= REWARDS_PER_PAGE && levelsInCurrentPage < MAX_LEVELS_PER_PAGE )
		{
			rewardCount += rewardsLen
		}
		else
		{
			pageToLevelIdx.append( levelIdx )
			rewardCount = rewardsLen
			levelsInCurrentPage = 0
		}
	}

	return pageToLevelIdx.len()
}


int function GetLevelEndForPage( ItemFlavor activeBattlePass, int pageIdx )
{
	if ( activeBattlePass in file.pageDatas )
	{
		return file.pageDatas[ activeBattlePass ][ pageIdx ].endLevel
	}

	int rewardCount = 0
	int levelIdx    = GetLevelOffsetForPage( activeBattlePass, pageIdx )
	for ( int i = 0 ; i < MAX_LEVELS_PER_PAGE && levelIdx <= GetBattlePassMaxLevelIndex( activeBattlePass ) && rewardCount < REWARDS_PER_PAGE; levelIdx++ )
	{
		int rewardsLen = GetRewardsCountForLevel( activeBattlePass, levelIdx )
		rewardCount += rewardsLen

		if ( rewardCount > REWARDS_PER_PAGE )
			return levelIdx

		if ( rewardsLen > 0 )
			i++
	}

	return levelIdx
}


array<RewardGroup> function GetEmptyRewardGroups()
{
	array<RewardGroup> rewardGroups
	BattlePassReward emptyReward

	for ( int levelIdx = 0; levelIdx < 10; levelIdx++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIdx
		rewardGroup.rewards.append( emptyReward )
		if ( levelIdx % 2 != 0 )
		{
			rewardGroup.rewards.append( emptyReward )
		}
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}

void function BattlePass_UpdatePageOnOpen()
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		BattlePass_SetPage( 0 )
		return
	}
	expect ItemFlavor( activeBattlePass )
	int currentLevel    = GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false ) + 1
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )

	int desiredPageNum                 = -1
	string desiredFocusRewardButtonKey = ""

	if ( SeasonPanel_GetLastMenuNavDirectionTopLevel() == MENU_NAV_BACK && file.currentPage != -1 && file.currentRewardButtonKey != null && (expect string(file.currentRewardButtonKey) in file.rewardKeyToRewardButtonDataMap) )
	{
		desiredPageNum = file.currentPage
		desiredFocusRewardButtonKey = expect string(file.currentRewardButtonKey)
	}
	else
	{
		desiredPageNum = BattlePass_GetPageForLevel( activeBattlePass, currentLevel )
	}

	BattlePass_SetPage( desiredPageNum )
	if ( desiredFocusRewardButtonKey != "" )
	{
		BattlePass_FocusRewardButton( file.rewardKeyToRewardButtonDataMap[desiredFocusRewardButtonKey] )
	}
	else
	{
		BattlePass_RewardButton_OnGetFocus( file.rewardButtonsPremium[0] )
	}

	file.rewardButtonFocusForced = true
}

void function BuildPageDatas( ItemFlavor activeBattlePass )
{
	if ( activeBattlePass in file.pageDatas )
		delete file.pageDatas[ activeBattlePass ]

	int numPages = GetNumPages( activeBattlePass )

	table<int, BattlePassPageData> datas

	for ( int pageNum = 0 ; pageNum < numPages ; pageNum++ )
	{
		int startLevel = GetLevelOffsetForPage( activeBattlePass, IsRTL() ? numPages -1 - pageNum : pageNum )
		int endLevel   = GetLevelEndForPage( activeBattlePass, IsRTL() ? numPages -1 - pageNum : pageNum )
		BattlePassPageData pData
		pData.startLevel = startLevel
		pData.endLevel = endLevel
		datas[ pageNum ] <- pData
	}

	file.pageDatas[ activeBattlePass ] <- datas
}


void function CalculateBattlePassRewardCurrencies()
{
	
	if ( fileLevel.numApexCoinsInBattlePass != 0 && fileLevel.numCraftingMetalsInBattlePass != 0 )
		return

	ItemFlavor ornull activeBattlePass = GetActiveBattlePass()
	if ( activeBattlePass == null )
		return

	expect ItemFlavor( activeBattlePass )

	
	fileLevel.numApexCoinsInBattlePass = 0
	fileLevel.numCraftingMetalsInBattlePass = 0

	int maxLevel = GetBattlePassMaxLevelIndex( activeBattlePass ) + 1

	for ( int levelIndex = 0; levelIndex < maxLevel; levelIndex++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIndex )
		foreach ( BattlePassReward reward in rewards )
		{
			switch ( reward.flav )
			{
				case GRX_CURRENCIES[ GRX_CURRENCY_PREMIUM ]:
					fileLevel.numApexCoinsInBattlePass += reward.quantity
					break

				case GRX_CURRENCIES[ GRX_CURRENCY_CRAFTING ]:
					fileLevel.numCraftingMetalsInBattlePass += reward.quantity
					break

				default:
					break
			}
		}
	}
}


int function BattlePass_GetPageForLevel( ItemFlavor activeBattlePass, int level )
{
	int numPages = GetNumPages( activeBattlePass )
	for ( int pageNum = 0 ; pageNum < numPages ; pageNum++ )
	{
		int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNum )
		int endLevel   = GetLevelEndForPage( activeBattlePass, pageNum )
		if ( level >= startLevel && level <= endLevel )
			return pageNum
	}

	return numPages
}


int function BattlePass_GetNextLevelWithReward( ItemFlavor activeBattlePass, int currentLevelIdx )
{
	int maxLevelIdx = GetBattlePassMaxLevelIndex( activeBattlePass )
	maxLevelIdx += 1 
	for ( int levelIdx = currentLevelIdx; levelIdx <= maxLevelIdx; levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx, GetLocalClientPlayer() )
		if ( rewards.len() > 0 )
			return levelIdx
	}

	return minint( currentLevelIdx, maxLevelIdx )
}


void function BattlePass_SetPage( int pageNumber )
{
	ItemFlavor ornull activeBattlePass = GetActiveBattlePass()
	if ( activeBattlePass == null )
	{
		file.currentPage = 0
		return
	}

	expect ItemFlavor( activeBattlePass )

	int numPages = GetNumPages( activeBattlePass )
	pageNumber = ClampInt( pageNumber, 0, numPages - 1 )

	if ( file.currentPage == pageNumber )
	{
#if PC_PROG_NX_UI
		UpdateRewardPanel( file.currentRewardGroups )
#endif
		return
	}

	file.previousPage = file.currentPage
	file.currentPage = pageNumber

	file.currentRewardGroups = GetRewardGroupsForPage( pageNumber )

	UpdateRewardPanel( file.currentRewardGroups )
	bool prevPageAvailable = (pageNumber > 0)
	bool nextPageButton    = (pageNumber < numPages - 1)
	Hud_SetVisible( file.prevPageButton, prevPageAvailable )
	Hud_SetEnabled( file.invisiblePageLeftTriggerButton, prevPageAvailable )
	Hud_SetVisible( file.nextPageButton, nextPageButton )
	Hud_SetEnabled( file.invisiblePageRightTriggerButton, nextPageButton )

	int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNumber )
	int endLevel   = GetLevelEndForPage( activeBattlePass, pageNumber )

	HudElem_SetRuiArg( file.rewardBarFooter, "currentPage", pageNumber )
	HudElem_SetRuiArg( file.rewardBarFooter, "levelRangeText", Localize( "#BATTLE_PASS_LEVEL_RANGE", startLevel + 1, endLevel ) )
	HudElem_SetRuiArg( file.rewardBarFooter, "numPages", GetNumPages( activeBattlePass ) )

	foreach ( button in file.rewardButtonsPremium )
	{
		HudElem_SetRuiArg( button, "forceFocusShineMarker", RandomInt( INT_MAX ) )
	}

	foreach ( button in file.rewardButtonsFree )
	{
		HudElem_SetRuiArg( button, "forceFocusShineMarker", RandomInt( INT_MAX ) )
	}
}




void function OnPanelShow( var panel )
{
	RegisterStickMovedCallback( ANALOG_RIGHT_X, TryChangePageFromRS )

	UI_SetPresentationType( ePresentationType.BATTLE_PASS_3 )
	

	RegisterButtonPressedCallback( IsRTL() ? MOUSE_WHEEL_UP : MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	RegisterButtonPressedCallback(  IsRTL() ? MOUSE_WHEEL_DOWN : MOUSE_WHEEL_UP, BattlePass_PageBackward )
	
	

	file.isShowingBattlePassProgress = false
	UpdateBattlePassProgress( true, true )

	BattlePass_UpdatePageOnOpen()
	BattlePass_UpdateStatus()
	BattlePass_UpdatePurchaseButton( file.purchaseButton )
	BattlePass_UpdateGiftButton()
	CalculateBattlePassRewardCurrencies()

	AddCallbackAndCallNow_OnGRXOffersRefreshed( OnGRXStateChanged )
	AddCallbackAndCallNow_OnGRXInventoryStateChanged( OnGRXStateChanged )

	HudElem_SetRuiArg( file.detailBox, "useSmallFont", ShouldUseSmallFont() )
	HudElem_SetRuiArg( file.statusBox, "timeRemainingOffsetY", GetTimeRemainingOffsetY() )
	
}

bool function ShouldUseSmallFont()
{
	switch ( GetLanguage() )
	{
		case "german":
			return true
	}

	return false
}

float function GetTimeRemainingOffsetY()
{
	switch ( GetLanguage() )
	{
		case "japanese":
			return 8.0
	}

	return 2.0
}

void function OnPanelHide( var panel )
{
	Signal( uiGlobal.signalDummy, "TryChangePageThread" )
	DeregisterStickMovedCallback( ANALOG_RIGHT_X, TryChangePageFromRS )

	

	DeregisterButtonPressedCallback( IsRTL() ? MOUSE_WHEEL_UP : MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	DeregisterButtonPressedCallback( IsRTL() ? MOUSE_WHEEL_DOWN : MOUSE_WHEEL_UP, BattlePass_PageBackward )
	
	

	RemoveCallback_OnGRXOffersRefreshed( OnGRXStateChanged )
	RemoveCallback_OnGRXInventoryStateChanged( OnGRXStateChanged )

	RunClientScript( "ClearBattlePassItem" )
}

void function TryChangePageFromRS( ... )
{
	float stickDeflection = expect float( vargv[1] )
	

	int stickState = eStickState.NEUTRAL
	if ( stickDeflection > 0.25 )
		stickState = eStickState.RIGHT
	else if ( stickDeflection < -0.25 )
		stickState = eStickState.LEFT

	if ( stickState != file.lastStickState )
	{
		file.stickRepeatAllowTime = UITime()
		file.lastStickState = stickState
		thread TryChangePageThread( stickState )
	}
	else
	{
		file.lastStickState = stickState
	}
}

void function TryChangePageThread( int stickState )
{
	Signal( uiGlobal.signalDummy, "TryChangePageThread" )
	EndSignal( uiGlobal.signalDummy, "TryChangePageThread" )

	if ( stickState == eStickState.NEUTRAL )
		return

	int times = 0

	while ( stickState == file.lastStickState )
	{
		if ( file.stickRepeatAllowTime <= UITime() )
		{
			if ( stickState == eStickState.RIGHT )
			{
				
				BattlePass_PageForward( null )
			}
			else if ( stickState == eStickState.LEFT )
			{
				
				BattlePass_PageBackward( null )
			}

			file.stickRepeatAllowTime = UITime() + GetPageDelay( times )
			times++
		}

		WaitFrame()
	}
}

float function GetPageDelay( int repeatCount )
{
	if ( repeatCount > 2 )
		return CURSOR_DELAY_FAST
	if ( repeatCount > 0 )
		return CURSOR_DELAY_MED

	return CURSOR_DELAY_BASE
}

void function OnGRXStateChanged()
{
	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()

	if ( !ready )
		return

	thread TryDisplayBattlePassAwards( true )
}


void function BattlePass_UpdatePurchaseButton( var button, bool showUpsell = true )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		Hud_SetEnabled( button, false )
		Hud_SetVisible( button, false )
		HudElem_SetRuiArg( button, "buttonText", "#COMING_SOON" )
		return
	}

	expect ItemFlavor( activeBattlePass )

	Hud_SetEnabled( button, true )
	Hud_SetVisible( button, true )
	Hud_SetLocked( button, false )
	Hud_ClearToolTipData( button )

	HudElem_SetRuiArg( button, "showUnlockedString", false )

	if ( GRX_IsItemOwnedByPlayer( activeBattlePass ) )
	{
		if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetLocalClientPlayer() ), activeBattlePass ) > 0 )
		{
			HudElem_SetRuiArg( button, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE_XP" )
			return
		}
		else
		{
			 
			 
			 
			bpPresaleOfferData bpPresaleOffers = GetBPPresaleOfferData()
			if ( bpPresaleOffers.basicOffer == null || bpPresaleOffers.bundleOffer == null )
			{
				Assert( bpPresaleOffers.basicOffer == null && bpPresaleOffers.bundleOffer == null,
					"Error: One of the BP Presale Offers is null while the other is valid. While Presale is live, both offers must be valid.")
				Hud_SetLocked( button, true )
				ToolTipData toolTipData
				toolTipData.titleText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
				toolTipData.descText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
				Hud_SetToolTipData( button, toolTipData )
				return
			}
			GRXScriptOffer basicOffer = expect GRXScriptOffer( bpPresaleOffers.basicOffer )
			if ( ContainsOwnedBPPresaleVoucher( basicOffer ) )
			{
				Hud_SetLocked( button, true )
				HudElem_SetRuiArg( button, "buttonText", "#BUTTON_BATTLE_PASS_PRESALE_PURCHASED" )
				return
			}
			HudElem_SetRuiArg( button, "buttonText", "#BUTTON_BATTLE_PASS_GOTO_PRESALE" )
			Hud_SetLocked( button, false )
			ToolTipData toolTipData
			toolTipData.titleText = "#BUTTON_BATTLE_PASS_GOTO_PRESALE"
			toolTipData.descText = "#BUTTON_BATTLE_PASS_GOTO_PRESALE_DESC"
			Hud_SetToolTipData( button, toolTipData )
			return
		}
	}
	else
	{
		HudElem_SetRuiArg( button, "buttonText", "#PURCHASE" )

		int level = GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false )

		if ( level > 0 )
		{
			ToolTipData toolTipData
			toolTipData.titleText = "#BATTLE_PASS_BUTTON_PURCHASE"
			toolTipData.descText = "#BUTTON_BATTLE_PASS_PURCHASE_DESC"
			Hud_SetToolTipData( button, toolTipData )
		}

		if ( showUpsell )
		{
			if ( level > 10 )
			{
				HudElem_SetRuiArg( button, "showUnlockedString", true )
				string unlockString = BattlePass_SetUnlockedString( button, level )

#if PC_PROG_NX_UI
				
				if ( IsNxHandheldMode() )
				{
					HudElem_SetRuiArg( button, "showUnlockedString", false )
					ToolTipData toolTipData
					toolTipData.titleText = "#BATTLE_PASS_BUTTON_PURCHASE"

					toolTipData.descText = Localize("#BUTTON_BATTLE_PASS_PURCHASE_DESC") + "\n\n" + Localize("#BATTLEPASS_UNLOCKS") + "\n" + unlockString
					Hud_SetToolTipData( button, toolTipData )
					return
				}
#endif
				Hud_SetY( button, -1 * int(Hud_GetHeight( file.purchaseBG ) * 0.15) )
			}
			else
			{
#if PC_PROG_NX_UI
				
				if ( IsNxHandheldMode() )
				{
					return
				}
#endif
				Hud_SetY( button, 0 )
			}
		}
	}
}

void function BattlePass_UpdateGiftButton()
{
	UpdatePackGiftButton( file.giftButton )
}

void function GiftButton_OnClick( var button )
{
	if ( Hud_IsLocked( button ) )
		return

	if ( !IsTwoFactorAuthenticationEnabled() )
	{
		OpenTwoFactorInfoDialog( button )
		return
	}

	SetCurrentTabForPIN( "PassPanel" )
	AdvanceMenu( GetMenu( "PassPurchaseMenu" ) )
}

string function BattlePass_SetUnlockedString( var button, int level )
{
	int numRares       = GetNumPremiumRewardsOfTypeUpToLevel( level, eRarityTier.RARE, [ eItemType.account_currency, eItemType.account_currency_bundle ] )
	int numEpics       = GetNumPremiumRewardsOfTypeUpToLevel( level, eRarityTier.EPIC, [ eItemType.account_currency, eItemType.account_currency_bundle ] )
	int numLegendaries = GetNumPremiumRewardsOfTypeUpToLevel( level, eRarityTier.LEGENDARY, [ eItemType.account_currency, eItemType.account_currency_bundle ] )

	ItemFlavor apexCoins        = GRX_CURRENCIES[ GRX_CURRENCY_PREMIUM ]
	ItemFlavor craftingCurrency = GRX_CURRENCIES[ GRX_CURRENCY_CRAFTING ]

	int numCoins    = GetNumPremiumRewardsOfTypeUpToLevel( level, -1, [], [ apexCoins ] )
	int numCrafting = GetNumPremiumRewardsOfTypeUpToLevel( level, -1, [], [ craftingCurrency ] )

	printt( "numRares " + numRares )
	printt( "numEpics " + numEpics )
	printt( "numLegendaries " + numLegendaries )
	printt( "numCoins " + numCoins )
	printt( "numCrafting " + numCrafting )

	const int MAX_UNLOCK_THINGS = 5
	const int MAX_COLOR_TIERS = 3

	array<string> unlockedStrings
	int colorTiersUsed
	if ( colorTiersUsed < MAX_COLOR_TIERS && unlockedStrings.len() < MAX_UNLOCK_THINGS && numLegendaries > 0 )
	{
		int quality = eRarityTier.LEGENDARY
		int count   = numLegendaries
		unlockedStrings.append( Localize( "#BATTLEPASS_DISPLAY_QUANTITY_QUALITY", count, Localize( ItemQuality_GetQualityName( quality ) ), (colorTiersUsed + 1) ) )
		HudElem_SetRuiArg( button, "unlockedStringColorTier" + (colorTiersUsed + 1), quality )
		HudElem_SetRuiArg( button, "altStyle" + (colorTiersUsed + 1) + "Color", SrgbToLinear( GetKeyColor( COLORID_MENU_TEXT_LOOT_TIER0, quality + 1 ) / 255.0 ) )
		colorTiersUsed++
	}

	if ( colorTiersUsed < MAX_COLOR_TIERS && unlockedStrings.len() < MAX_UNLOCK_THINGS && numEpics > 0 )
	{
		int quality = eRarityTier.EPIC
		int count   = numEpics
		unlockedStrings.append( Localize( "#BATTLEPASS_DISPLAY_QUANTITY_QUALITY", count, Localize( ItemQuality_GetQualityName( quality ) ), (colorTiersUsed + 1) ) )
		HudElem_SetRuiArg( button, "unlockedStringColorTier" + (colorTiersUsed + 1), quality )
		HudElem_SetRuiArg( button, "altStyle" + (colorTiersUsed + 1) + "Color", SrgbToLinear( GetKeyColor( COLORID_MENU_TEXT_LOOT_TIER0, quality + 1 ) / 255.0 ) )
		colorTiersUsed++
	}

	if ( colorTiersUsed < MAX_COLOR_TIERS && unlockedStrings.len() < MAX_UNLOCK_THINGS && numRares > 0 )
	{
		int quality = eRarityTier.RARE
		int count   = numRares
		unlockedStrings.append( Localize( "#BATTLEPASS_DISPLAY_QUANTITY_QUALITY", count, Localize( ItemQuality_GetQualityName( quality ) ), (colorTiersUsed + 1) ) )
		HudElem_SetRuiArg( button, "unlockedStringColorTier" + (colorTiersUsed + 1), quality )
		HudElem_SetRuiArg( button, "altStyle" + (colorTiersUsed + 1) + "Color", SrgbToLinear( GetKeyColor( COLORID_MENU_TEXT_LOOT_TIER0, quality + 1 ) / 255.0 ) )
		colorTiersUsed++
	}

	if ( unlockedStrings.len() < MAX_UNLOCK_THINGS && numCoins > 0 )
	{
		int count          = numCoins
		string imageString = ItemFlavor_GetIcon( apexCoins )
		unlockedStrings.append( Localize( "#BATTLEPASS_DISPLAY_QUANTITY_CURRENCY", "%$" + imageString + "%", count, 0 ) )
	}

	if ( unlockedStrings.len() < MAX_UNLOCK_THINGS && numCrafting > 0 )
	{
		int count          = numCrafting
		string imageString = ItemFlavor_GetIcon( craftingCurrency )
		unlockedStrings.append( Localize( "#BATTLEPASS_DISPLAY_QUANTITY_CURRENCY", "%$" + imageString + "%", count, 0 ) )
	}

	int stringCount = unlockedStrings.len()
	while ( unlockedStrings.len() < MAX_UNLOCK_THINGS )
		unlockedStrings.append( "" )

	string unlockedString = Localize( "#BATTLEPASS_REWARDS_DISPLAY_" + stringCount, unlockedStrings[0], unlockedStrings[1], unlockedStrings[2], unlockedStrings[3], unlockedStrings[4] )

	HudElem_SetRuiArg( button, "unlockedString", unlockedString )

	return unlockedString
}

int function GetNumPremiumRewardsOfTypeUpToLevel( int endLevel, int tier, array<int> excludeItemTypes = [], array<ItemFlavor> onlyMatchItemFlavs = [] )
{
	ItemFlavor ornull activeBattlePass = GetActiveBattlePass()

	if ( activeBattlePass == null )
		return 0

	expect ItemFlavor( activeBattlePass )

	int count

	for ( int levelIdx = 0; levelIdx <= endLevel; levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		foreach ( reward in rewards )
		{
			if ( reward.isPremium )
			{
				if ( (tier == -1 || ItemFlavor_GetQuality( reward.flav ) == tier)
				&& (
				(onlyMatchItemFlavs.len() == 0 && !excludeItemTypes.contains( ItemFlavor_GetType( reward.flav ) ))
				|| (onlyMatchItemFlavs.len() > 0 && onlyMatchItemFlavs.contains( reward.flav ))
				)
				)
				{
					printt( string(ItemFlavor_GetAsset( reward.flav )) )
					count += reward.quantity
				}
			}
		}
	}

	return count
}

void function BattlePass_UpdateStatus()
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null

	if ( !hasActiveBattlePass )
		return

	expect ItemFlavor(activeBattlePass)

	int currentBattlePassXP = GetPlayerBattlePassXPProgress( ToEHI( GetLocalClientPlayer() ), activeBattlePass, false )

	int ending_passLevel = GetBattlePassLevelForXP( activeBattlePass, currentBattlePassXP )
	int ending_passXP    = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel - 1 )

	int ending_nextPassLevelXP
	if ( ending_passLevel > GetBattlePassMaxLevelIndex( activeBattlePass ) )
		ending_nextPassLevelXP = ending_passXP
	else
		ending_nextPassLevelXP = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel )

	int xpToCompleteLevel = ending_nextPassLevelXP - ending_passXP
	int xpForLevel        = currentBattlePassXP - ending_passXP

	Assert( currentBattlePassXP >= ending_passXP )
	Assert( currentBattlePassXP <= ending_nextPassLevelXP )
	float ending_passLevelFrac = GraphCapped( currentBattlePassXP, ending_passXP, ending_nextPassLevelXP, 0.0, 1.0 )

	
	
	
	
	

	ItemFlavor currentSeason = GetLatestSeason( GetUnixTimestamp() )
	int seasonEndUnixTime    = CalEvent_GetFinishUnixTime( currentSeason )
	int remainingSeasonTime  = seasonEndUnixTime - GetUnixTimestamp()

	if ( remainingSeasonTime > 0 )
	{
		DisplayTime dt = SecondsToDHMS( remainingSeasonTime )
		HudElem_SetRuiArg( file.statusBox, "timeRemainingText", Localize( GetDaysHoursRemainingLoc( dt.days, dt.hours ), dt.days, dt.hours ) )
	}
	else
	{
		HudElem_SetRuiArg( file.statusBox, "timeRemainingText", Localize( "#BATTLE_PASS_SEASON_ENDED" ) )
	}

	HudElem_SetRuiArg( file.statusBox, "seasonNameText", ItemFlavor_GetLongName( activeBattlePass ) )
	HudElem_SetRuiArg( file.statusBox, "seasonNumberText", Localize( ItemFlavor_GetShortName( activeBattlePass ) ) )
	HudElem_SetRuiArg( file.statusBox, "smallLogo", GetGlobalSettingsAsset( ItemFlavor_GetAsset( activeBattlePass ), "smallLogo" ), eRuiArgType.IMAGE )
	HudElem_SetRuiArg( file.statusBox, "bannerImage", GetGlobalSettingsAsset( ItemFlavor_GetAsset( activeBattlePass ), "bannerImage" ), eRuiArgType.IMAGE )

	ItemFlavor dummy
	ItemFlavor bpLevelBadge = GetBattlePassProgressBadge( activeBattlePass )

	RuiDestroyNestedIfAlive( Hud_GetRui( file.purchaseBG ), "currentBadgeHandle" )
	CreateNestedGladiatorCardBadge( Hud_GetRui( file.purchaseBG ), "currentBadgeHandle", ToEHI( GetLocalClientPlayer() ), bpLevelBadge, 0, dummy, ending_passLevel + 1 )
}




struct
{
	var menu
	var rewardPanel
	var header
	var background

	var purchaseButton
	var inc1Button
	var inc5Button
	var dec1Button
	var dec5Button

	table<var, BattlePassReward> buttonToItem

	int purchaseQuantity = 1

	bool closeOnGetTopLevel = false

} s_passPurchaseXPDialog




void function InitBattlePassRewardButtonRui( var rui, BattlePassReward bpReward )
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null && GRX_IsInventoryReady()
	bool hasPremiumPass                = false
	int battlePassLevel                = 0
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
		battlePassLevel = GetPlayerBattlePassLevel( GetLocalClientPlayer(), activeBattlePass, false )
		RuiSetBool( rui, "isPremiumBPOwned", hasPremiumPass )
	}

	bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level < battlePassLevel
	RuiSetBool( rui, "isOwned", isOwned )
	RuiSetBool( rui, "isPremium", bpReward.isPremium )

	int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
	RuiSetInt( rui, "rarity", rarity )
	RuiSetImage( rui, "buttonImage", CustomizeMenu_GetRewardButtonImage( bpReward.flav ) )
	RuiSetImage( rui, "buttonImageSecondLayer", $"" )
	RuiSetFloat2( rui, "buttonImageSecondLayerOffset", <0.0, 0.0, 0.0> )

	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
		RuiSetBool( rui, "isLootBox", true )
	else
		RuiSetBool( rui, "isLootBox", false )

	RuiSetString( rui, "itemCountString", "" )
	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
		RuiSetString( rui, "itemCountString", FormatAndLocalizeNumber( "1", float( bpReward.quantity ), true ) )
}




void function InitAboutBattlePass1Dialog( var newMenuArg )

{
	var menu = newMenuArg
	SetDialog( menu, true )
	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, AboutBattlePass1Dialog_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_HIDE, AboutBattlePass1Dialog_OnClose )
	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )

	file.aboutProgressButton = Hud_GetChild( menu, "CurrentProgress" )
	AddButtonEventHandler( file.aboutProgressButton, UIE_CLICK, AboutProgressButton_OnClick )

	file.aboutPurchaseButton = Hud_GetChild( menu, "PurchaseButton" )
	AddButtonEventHandler( file.aboutPurchaseButton, UIE_CLICK, AboutPurchaseButton_OnClick )
}

void function AboutPurchaseButton_OnClick( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() || Hud_IsLocked( button ) )
		return
	expect ItemFlavor( activeBattlePass )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )

	CloseActiveMenu()
	SetCurrentTabForPIN( "PassPanel" ) 
	AdvanceMenu( GetMenu( "PassPurchaseMenu" ) )
}

void function AboutProgressButton_OnClick( var button )
{
	JumpToSeasonTab( "PassPanel" )
}

void function AboutBattlePass1Dialog_OnOpen()
{
	var menu                = GetMenu( "BattlePassAboutPage1" )
	var rui                 = Hud_GetRui( Hud_GetChild( menu, "InfoPanel" ) )

	RegisterButtonPressedCallback( KEY_SPACE, AboutProgressButton_OnClick )

	ItemFlavor ornull activeBattlePass = GetActiveBattlePass()
	if ( activeBattlePass == null )
	{
		activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
		if ( activeBattlePass == null )
			return
	}
	expect ItemFlavor( activeBattlePass )
	var infoPanel = Hud_GetChild( menu, "InfoPanel" )
	asset battlePassAsset = ItemFlavor_GetAsset( activeBattlePass )
	RuiSetImage( rui, "logo", GetGlobalSettingsAsset( battlePassAsset , "largeLogo" ) )
	RuiSetString( rui, "battlePassName", GetGlobalSettingsStringAsAsset( battlePassAsset, "aboutPurchaseTitle" ) )
	RuiSetColorAlpha( rui, "headerColor", GetGlobalSettingsVector( battlePassAsset, "headerColor" ), 1)

	bool isPassOwned = GRX_IsItemOwnedByPlayer( activeBattlePass )
	if ( isPassOwned )
		HudElem_SetRuiArg( file.aboutPurchaseButton, "buttonText", Localize( "#BUY_GIFT" ) )
	else
		HudElem_SetRuiArg( file.aboutPurchaseButton, "buttonText", Localize( "#UPGRADE_OR_GIFT" ) )

	bool showPurchaseButton = true
	if ( !IsPlayerLeveledForGifting() )
		showPurchaseButton = !isPassOwned


	int buttonWidth = Hud_GetWidth( file.aboutProgressButton )
	float scaleFactor = buttonWidth/425.0
	Hud_SetX( file.aboutProgressButton, !showPurchaseButton ? -172*scaleFactor : 75*scaleFactor )
	Hud_SetX( file.aboutPurchaseButton, 250*scaleFactor )
	Hud_SetVisible( file.aboutPurchaseButton, showPurchaseButton )
}

void function AboutBattlePass1Dialog_OnClose()
{
	DeregisterButtonPressedCallback( KEY_SPACE, AboutProgressButton_OnClick )
	SocialEventUpdate()
}





void function ShowRewardTable( var button )
{
	
}




















































































































struct
{
	var menu
	var rewardPanel
	var passPurchaseButton
	var passGiftButton
	var bundlePurchaseButton
	var passGetCoinsButton
	var	passBasicInfo
	var passBundleInfo
	var backgroundsPanel
	var passBanner
	var overlayPanel
	var seasonLogoBox
	var offersBorders

	bool closeOnGetTopLevel = false
} s_passPurchaseMenu

void function InitPassPurchaseMenu( var newMenuArg )

{
	var menu = GetMenu( "PassPurchaseMenu" )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassPurchaseMenu_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, PassPurchaseMenu_OnClose )

	AddMenuEventHandler( menu, eUIEvent.MENU_GET_TOP_LEVEL, PassPurchaseMenu_OnGetTopLevel )

	s_passPurchaseMenu.menu = menu
	s_passPurchaseMenu.passPurchaseButton = Hud_GetChild( menu, "PassPurchaseButton" )
	s_passPurchaseMenu.passGiftButton = Hud_GetChild( menu, "PassGiftButton" )
	s_passPurchaseMenu.passGetCoinsButton = Hud_GetChild( menu, "PassGetCoinsButton" )
	s_passPurchaseMenu.bundlePurchaseButton = Hud_GetChild( menu, "BundlePurchaseButton" )
	s_passPurchaseMenu.passBasicInfo = Hud_GetChild( menu, "PassPriceInfo" )
	s_passPurchaseMenu.passBundleInfo = Hud_GetChild( menu, "BundlePriceInfo" )

	s_passPurchaseMenu.backgroundsPanel = Hud_GetChild( menu, "Backgrounds" )
	s_passPurchaseMenu.passBanner = Hud_GetChild( menu, "HeaderBanner" )
	Hud_AddEventHandler( s_passPurchaseMenu.passPurchaseButton, UIE_GET_FOCUS, PassPurchaseButton_OnFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.passPurchaseButton, UIE_LOSE_FOCUS, PassPurchaseButton_OnLoseFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.passGiftButton, UIE_GET_FOCUS, PassPurchaseButton_OnFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.passGiftButton, UIE_LOSE_FOCUS, PassPurchaseButton_OnLoseFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.passGetCoinsButton, UIE_GET_FOCUS, PassPurchaseButton_OnFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.passGetCoinsButton, UIE_LOSE_FOCUS, PassPurchaseButton_OnLoseFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.bundlePurchaseButton, UIE_GET_FOCUS, BundlePurchaseButton_OnFocus )
	Hud_AddEventHandler( s_passPurchaseMenu.bundlePurchaseButton, UIE_LOSE_FOCUS, BundlePurchaseButton_OnLoseFocus )

	Hud_AddEventHandler( s_passPurchaseMenu.passPurchaseButton, UIE_CLICK, PassPurchaseButton_OnActivate )
	Hud_AddEventHandler( s_passPurchaseMenu.passGiftButton, UIE_CLICK, PassGiftButton_OnActivate )
	Hud_AddEventHandler( s_passPurchaseMenu.bundlePurchaseButton, UIE_CLICK, BundlePurchaseButton_OnActivate )
	Hud_AddEventHandler( s_passPurchaseMenu.passGetCoinsButton, UIE_CLICK, GetCoinsButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddMenuFooterOption( newMenuArg, LEFT, BUTTON_X, true, "#X_GIFT_INFO_TITLE", "#GIFT_INFO_TITLE", OpenGiftInfoPopUp )
}
void function PassPurchaseButton_OnFocus( var button )
{
	HudElem_SetRuiArg( s_passPurchaseMenu.backgroundsPanel, "isPremiumFocused", true )
	Hud_SetLocked( s_passPurchaseMenu.bundlePurchaseButton, true )
}

void function PassPurchaseButton_OnLoseFocus( var button )
{
	HudElem_SetRuiArg( s_passPurchaseMenu.backgroundsPanel, "isPremiumFocused", false )
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	bool hasPremiumPass  = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
	Hud_SetLocked( s_passPurchaseMenu.bundlePurchaseButton, hasPremiumPass )
}

void function PassPurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetLocalClientPlayer(), activeBattlePass ) )
		return

	ItemFlavor basicPurchaseFlav = BattlePass_GetBasicPurchasePack( activeBattlePass )
	if ( !GRX_GetItemPurchasabilityInfo( basicPurchaseFlav ).isPurchasableAtAll )
		return

	GRXScriptOffer basicPurchaseOffer = GRX_GetItemDedicatedStoreOffers( basicPurchaseFlav, "battlepass" )[0]

	PurchaseDialogConfig pdc
	pdc.offer = basicPurchaseOffer
	pdc.quantity = 1
	pdc.onPurchaseResultCallback = OnBattlePassPurchaseResults
	pdc.purchaseSoundOverride = "UI_Menu_BattlePass_Purchase"
	PurchaseDialog( pdc )
}

void function PassGiftButton_OnActivate( var button )
{
	if ( Hud_IsLocked( button ) )
		return

	if ( !IsTwoFactorAuthenticationEnabled() )
	{
		OpenTwoFactorInfoDialog( button )
		return
	}

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )
	if ( !GRX_GetItemPurchasabilityInfo( BattlePass_GetBasicPurchasePack( activeBattlePass ) ).isPurchasableAtAll )
		return

	ItemFlavor basicPurchaseFlav = BattlePass_GetBasicPurchasePack( activeBattlePass )
	GRXScriptOffer basicPurchaseOffer = GRX_GetItemDedicatedStoreOffers( basicPurchaseFlav, "battlepass" )[0]

	if ( !GRX_CanAfford( basicPurchaseOffer.prices[0], 1 ) )
	{
		OpenVCPopUp( null )
		return
	}
	OpenGiftingDialog( basicPurchaseOffer )
}

void function BundlePurchaseButton_OnFocus( var button )
{
	HudElem_SetRuiArg( s_passPurchaseMenu.backgroundsPanel, "isBundleFocused", true )
	Hud_SetLocked( s_passPurchaseMenu.passPurchaseButton, true )
	Hud_SetLocked( s_passPurchaseMenu.passGiftButton, true )
	Hud_SetLocked( s_passPurchaseMenu.passGetCoinsButton, true )
}

void function BundlePurchaseButton_OnLoseFocus( var button )
{
	HudElem_SetRuiArg( s_passPurchaseMenu.backgroundsPanel, "isBundleFocused", false )
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	bool hasPremiumPass  = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
	Hud_SetLocked( s_passPurchaseMenu.passPurchaseButton, hasPremiumPass )
	UpdatePackGiftButton( s_passPurchaseMenu.passGiftButton )
	Hud_SetLocked( s_passPurchaseMenu.passGetCoinsButton, hasPremiumPass )
}

void function BundlePurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetLocalClientPlayer(), activeBattlePass ) )
		return

	if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetLocalClientPlayer() ), activeBattlePass ) < 25 )
		return

	ItemFlavor purchasePack = BattlePass_GetBundlePurchasePack( activeBattlePass )
	if ( !GRX_GetItemPurchasabilityInfo( purchasePack ).isPurchasableAtAll )
		return

	GRXScriptOffer bundlePurchaseOffer = GRX_GetItemDedicatedStoreOffers( purchasePack, "battlepass" )[0]

	if ( !GRX_CanAfford( bundlePurchaseOffer.prices[0], 1 ) )
	{
		OpenVCPopUp( null )
		return
	}

	PurchaseDialogConfig pdc
	pdc.flav = purchasePack
	pdc.quantity = 1
	pdc.onPurchaseResultCallback = OnBattlePassPurchaseResults
	pdc.purchaseSoundOverride = "UI_Menu_BattlePass_Purchase"
	PurchaseDialog( pdc )
}

void function GetCoinsButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )
	ItemFlavor basicPurchaseFlav = BattlePass_GetBasicPurchasePack( activeBattlePass )
	GRXScriptOffer basicPurchaseOffer = GRX_GetItemDedicatedStoreOffers( basicPurchaseFlav, "battlepass" )[0]

	if ( !GRX_CanAfford( basicPurchaseOffer.prices[0], 1 ) )
		OpenVCPopUp( null )
}

void function PassPurchaseMenu_OnOpen()
{
	SetCurrentTabForPIN( "PassPanel" ) 

	RunClientScript( "ClearBattlePassItem" )
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )
	asset battlePassAsset = ItemFlavor_GetAsset( activeBattlePass )
	bool offerRestricted  = GRX_IsOfferRestricted( GetLocalClientPlayer() )

	var rui = Hud_GetRui( s_passPurchaseMenu.passBanner )
	RuiSetString( rui, "seasonName", GetGlobalSettingsStringAsAsset( battlePassAsset, "aboutPurchaseTitle" ) )
	RuiSetColorAlpha( rui, "headerColor", GetGlobalSettingsVector( battlePassAsset, "headerColor" ), 1 )
	AddCallbackAndCallNow_OnGRXInventoryStateChanged( UpdatePassPurchaseButtons )
	Lobby_AdjustScreenFrameToMaxSize( Hud_GetChild( GetMenu( "PassPurchaseMenu" ), "DarkBackground" ), true )
	HudElem_SetRuiArg( s_passPurchaseMenu.passBundleInfo, "priceTextString", Localize( "#OFFER_BUNDLE_NAME" ) )
	HudElem_SetRuiArg( s_passPurchaseMenu.passBasicInfo, "priceTextString", Localize( "#OFFER_BASIC_NAME" ) )
	HudElem_SetRuiArg( s_passPurchaseMenu.passGetCoinsButton, "buttonText", Localize( "#CONFIRM_GET_PREMIUM" ) )
}


void function PassPurchaseMenu_OnClose()
{
	RemoveCallback_OnGRXInventoryStateChanged( UpdatePassPurchaseButtons )
}

void function PassPurchaseMenu_OnGetTopLevel()
{
	if ( s_passPurchaseMenu.closeOnGetTopLevel )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = false
		CloseActiveMenu()
	}
	UpdatePackGiftButton( s_passPurchaseMenu.passGiftButton )
}

void function UpdatePassPurchaseButtons()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	bool hasPremiumPass  = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )

	
	ItemFlavor basicPurchaseFlav = BattlePass_GetBasicPurchasePack( activeBattlePass )
	HudElem_SetRuiArg( s_passPurchaseMenu.passPurchaseButton, "buttonText", hasPremiumPass ? "#OWNED" : "#UPGRADE" )
	HudElem_SetRuiArg( s_passPurchaseMenu.passPurchaseButton, "buttonDescText", hasPremiumPass ? "#BUNDLE_BONUS_LOCKED" : "" )

	array<GRXScriptOffer> basicPurchaseOffers = GRX_GetItemDedicatedStoreOffers( basicPurchaseFlav, "battlepass" )
	
	if ( basicPurchaseOffers.len() == 1 )
	{
		GRXScriptOffer basicPurchaseOffer = basicPurchaseOffers[0]
		Assert( basicPurchaseOffer.prices.len() == 1 )
		if ( basicPurchaseOffer.prices.len() == 1 )
		{
			bool canAfford =  GRX_CanAfford( basicPurchaseOffer.prices[0], 1 )
			HudElem_SetRuiArg( s_passPurchaseMenu.passBasicInfo, "price",  GRX_GetFormattedPrice( basicPurchaseOffer.prices[0] ) )
			HudElem_SetRuiArg( s_passPurchaseMenu.passBasicInfo, "canAfford", canAfford )
			Hud_SetVisible( s_passPurchaseMenu.passGetCoinsButton, !canAfford )
			UpdatePadNavigationPurchaseButtons( canAfford )
		}
		else Warning( "Expected 1 price for basic pack offer of '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )
	}
	else
	{
		Warning( "Expected 1 offer for basic pack of '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )

		foreach ( offer in basicPurchaseOffers )
			printt("UpdatePassPurchaseButtons - offer in basic battle pass is" + offer.offerAlias)
	}


	
	ItemFlavor bundlePurchaseFlav = BattlePass_GetBundlePurchasePack( activeBattlePass )
	HudElem_SetRuiArg( s_passPurchaseMenu.bundlePurchaseButton, "buttonText", hasPremiumPass ? "#OWNED" : "#UPGRADE" )
	HudElem_SetRuiArg( s_passPurchaseMenu.bundlePurchaseButton, "buttonDescText", hasPremiumPass ? "#BUNDLE_BONUS_LOCKED" : "" )

	array<GRXScriptOffer> bundlePurchaseOffers = GRX_GetItemDedicatedStoreOffers( bundlePurchaseFlav, "battlepass" )
	
	if ( bundlePurchaseOffers.len() == 1 )
	{
		GRXScriptOffer bundlePurchaseOffer = bundlePurchaseOffers[0]
		Assert( bundlePurchaseOffer.prices.len() == 1 )
		if ( bundlePurchaseOffer.prices.len() == 1 )
		{
			bool canAfford =  GRX_CanAfford( bundlePurchaseOffer.prices[0], 1 )
			HudElem_SetRuiArg( s_passPurchaseMenu.passBundleInfo, "price",  GRX_GetFormattedPrice( bundlePurchaseOffer.prices[0] ) )
			HudElem_SetRuiArg( s_passPurchaseMenu.passBundleInfo, "canAfford", canAfford )
			HudElem_SetRuiArg( s_passPurchaseMenu.bundlePurchaseButton, "buttonText", canAfford ? "#UPGRADE" : "#CONFIRM_GET_PREMIUM" )
		}
		else Warning( "Expected 1 price for bundle pack offer of '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )
	}
	else Warning( "Expected 1 offer for bundle pack of '%s'", string(ItemFlavor_GetAsset( activeBattlePass )) )

	bool canPurchaseBundle = GetPlayerBattlePassPurchasableLevels( ToEHI( GetLocalClientPlayer() ), activeBattlePass ) >= 25

	Hud_SetLocked( s_passPurchaseMenu.bundlePurchaseButton, !canPurchaseBundle || hasPremiumPass )
	Hud_SetLocked( s_passPurchaseMenu.passPurchaseButton, hasPremiumPass )
	if ( !canPurchaseBundle )
	{
		ToolTipData toolTipData
		toolTipData.titleText = "#BATTLE_PASS_BUNDLE_PROTECT"
		toolTipData.descText = "#BATTLE_PASS_BUNDLE_PROTECT_DESC"
		Hud_SetToolTipData( s_passPurchaseMenu.bundlePurchaseButton, toolTipData )
	}
	else
	{
		Hud_ClearToolTipData( s_passPurchaseMenu.bundlePurchaseButton )
	}
}

void function UpdatePadNavigationPurchaseButtons( bool canAfford )
{
	if ( canAfford )
	{
		Hud_SetNavRight( s_passPurchaseMenu.passGiftButton, s_passPurchaseMenu.passPurchaseButton )
		Hud_SetNavRight( s_passPurchaseMenu.passPurchaseButton, s_passPurchaseMenu.bundlePurchaseButton )
		Hud_SetNavLeft( s_passPurchaseMenu.bundlePurchaseButton, s_passPurchaseMenu.passPurchaseButton )
		Hud_SetNavLeft( s_passPurchaseMenu.passPurchaseButton, s_passPurchaseMenu.passGiftButton )
	}
	else
	{
		Hud_SetNavRight( s_passPurchaseMenu.passGetCoinsButton, s_passPurchaseMenu.bundlePurchaseButton )
		Hud_SetNavLeft( s_passPurchaseMenu.bundlePurchaseButton, s_passPurchaseMenu.passGetCoinsButton )
	}
}

void function OnBattlePassPurchaseResults( bool wasSuccessful )
{
	if ( wasSuccessful )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = true
	}
}



bool function TryDisplayBattlePassAwards( bool playSound = false )
{
	WaitEndFrame()

	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()
	if ( !ready )
		return false

	EHI playerEHI                      = ToEHI( GetLocalClientPlayer() )
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetLocalClientPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return false

	expect ItemFlavor( activeBattlePass )

	int currentXP          = GetPlayerBattlePassXPProgress( playerEHI, activeBattlePass )
	int lastSeenXP         = GetPlayerBattlePassLastSeenXP( playerEHI, activeBattlePass )
	bool hasPremiumPass    = DoesPlayerOwnBattlePass( GetLocalClientPlayer(), activeBattlePass )
	bool hadPremiumPass    = GetPlayerBattlePassLastSeenPremium( playerEHI, activeBattlePass )

	if ( currentXP == lastSeenXP && hasPremiumPass == hadPremiumPass )
		return false

	if ( IsDialog( GetActiveMenu() ) )
		return false

	int lastLevel    = GetBattlePassLevelForXP( activeBattlePass, lastSeenXP ) + 1
	int currentLevel = GetBattlePassLevelForXP( activeBattlePass, currentXP )

	if ( currentXP == 0 && lastSeenXP == 0 )
		lastLevel = 0 

	array<BattlePassReward> allAwards
	array<BattlePassReward> freeAwards

	for ( int levelIdx = lastLevel; levelIdx <= currentLevel; levelIdx++ )
	{
		array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		foreach ( award in awardsForLevel )
		{
			if ( award.isPremium )
				continue

			freeAwards.append( award )
		}
	}

	allAwards.extend( freeAwards )

	if ( hasPremiumPass != hadPremiumPass )
		lastLevel = 0 

	if ( hasPremiumPass )
	{
		array<BattlePassReward> premiumAwards

		for ( int levelIdx = lastLevel; levelIdx <= currentLevel; levelIdx++ )
		{
			array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
			foreach ( award in awardsForLevel )
			{
				if ( !award.isPremium )
					continue

				premiumAwards.append( award )
			}
		}

		allAwards.extend( premiumAwards )
	}

	if ( allAwards.len() == 0 )
		return false

	allAwards.sort( SortByAwardLevel )

	file.currentPage = -1 

	ShowRewardCeremonyDialog(
		"",
		Localize( "#BATTLE_PASS_REACHED_LEVEL", GetBattlePassDisplayLevel( currentLevel ) ),
		"",
		allAwards,
		true,
		false,
		false,
		playSound )

	return true
}


int function SortByAwardLevel( BattlePassReward a, BattlePassReward b )
{
	if ( a.level > b.level )
		return 1
	else if ( a.level < b.level )
		return -1

	if ( a.isPremium && !b.isPremium )
		return 1
	else if ( b.isPremium && !a.isPremium )
		return -1

	return 0
}
































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































void function ServerCallback_GotBPFromPremier()
{
	thread _GotBPFromPremier()
}

void function _GotBPFromPremier()
{
	DialogData dialogData
	dialogData.header = "#BATTLEPASS_EA_ACCESS_PREMIUM_HEADER"
	dialogData.message = "#BATTLEPASS_EA_ACCESS_PREMIUM_BODY"
	dialogData.darkenBackground = true
	dialogData.noChoiceWithNavigateBack = true

	AddDialogButton( dialogData, "#CLOSE" )

	while ( IsDialog( GetActiveMenu() ) )
		WaitFrame()

	OpenDialog( dialogData )
}





string function Season_GetLongName( ItemFlavor season )
{
	return ItemFlavor_GetLongName( season )
}


string function Season_GetShortName( ItemFlavor season )
{
	return Localize( ItemFlavor_GetShortName( season ) )
}


string function Season_GetTimeRemainingText( ItemFlavor season )
{
	int seasonEndUnixTime   = CalEvent_GetFinishUnixTime( season )
	int remainingSeasonTime = seasonEndUnixTime - GetUnixTimestamp()

	if ( remainingSeasonTime <= 0 )
		return Localize( "#BATTLE_PASS_SEASON_ENDED" )

	DisplayTime dt = SecondsToDHMS( remainingSeasonTime )

	return Localize( "#SEASON_ENDS_IN_DAYS", string( dt.days ) )
}


asset function Season_GetSmallLogo( ItemFlavor season )
{
	ItemFlavor pass = Season_GetBattlePass( season )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( pass ), "smallLogo" )
}


asset function Season_GetLobbyBannerLeftImage( ItemFlavor season )
{
	ItemFlavor pass = Season_GetBattlePass( season )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( season ), "lobbyButtonImage" )
}

asset function Season_GetLobbyBannerRightImage( ItemFlavor season )
{
	ItemFlavor pass = Season_GetBattlePass( season )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( season ), "lobbyBgRightImage" )
}

asset function Season_GetSmallLogoBg( ItemFlavor season )
{
	ItemFlavor pass = Season_GetBattlePass( season )
	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( season ), "lobbyDiamondImage" )
}


vector function Season_GetTitleTextColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "seasonTitleColor" )
}


vector function Season_GetHeaderTextColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "seasonHeaderColor" )
}


vector function Season_GetTimeRemainingTextColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "seasonTimeRemainingColor" )
}

vector function Season_GetNewColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "seasonNewColor" )
}

vector function Season_GetColor( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "seasonCol" )
}


vector function Season_GetTabBGFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabBGFocusedCol" )
}

vector function Season_GetTabBarFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabBarFocusedCol" )
}

vector function Season_GetTabBGSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabBGSelectedCol" )
}

vector function Season_GetTabBarSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabBarSelectedCol" )
}

vector function Season_GetTabTextDefaultCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabTextDefaultCol" )
}

vector function Season_GetTabTextFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabTextFocusedCol" )
}

vector function Season_GetTabTextSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabTextSelectedCol" )
}

vector function Season_GetTabGlowFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "tabGlowFocusedCol" )
}


vector function Season_GetSubTabBGFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabBGFocusedCol" )
}

vector function Season_GetSubTabBarFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabBarFocusedCol" )
}

vector function Season_GetSubTabBGSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabBGSelectedCol" )
}

vector function Season_GetSubTabBarSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabBarSelectedCol" )
}

vector function Season_GetSubTabTextDefaultCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabTextDefaultCol" )
}

vector function Season_GetSubTabTextFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabTextFocusedCol" )
}

vector function Season_GetSubTabTextSelectedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabTextSelectedCol" )
}

vector function Season_GetSubTabGlowFocusedCol( ItemFlavor event )
{
	Assert( ItemFlavor_GetType( event ) == eItemType.calevent_season )
	return GetGlobalSettingsVector( ItemFlavor_GetAsset( event ), "subtabGlowFocusedCol" )
}


