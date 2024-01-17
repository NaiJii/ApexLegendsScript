global function RTKPostGameXpBreakdown_OnInitialize
global function RTKPostGameXpBreakdown_OnDestroy
global function InitRTKPostGameSummary

global struct RTKPostGameXpBreakdown_Properties
{
	array<rtk_behavior> tweenStaggers
	rtk_behavior progressBarAnimator
	rtk_panel breakdownContainer
	rtk_panel levelUpPopUp
	rtk_panel gladiatorCard
	rtk_panel badgePanel
}

global struct RTKPostGameXpBreakdownModel
{
	string title
	int boostPercentage
	int xpValue

	vector textColor
	vector backgroundColor

	string tooltipTitle
	array<string> tooltipDescription
}

global struct RTKPostGameXpRewardsModel
{
	asset icon
	string value
}

global struct RTKAccountProgressBarsModel
{
	float progressFracStart
	float boostFracStart
	float progressFracEnd
	float boostFracEnd
	float animDuration

	int startXP
	int	endXP
	int	maxLevelXP
	RTKBadgeModel& currentBadge
	RTKBadgeModel& nextBadge
}

global struct RTKPostGameTotalXpModel
{
	int baseXP
	int totalXP
	int boostsApplied
}

global struct RTKLevelUpPopUpModel
{
	RTKBadgeModel& badge
	array<RTKPostGameXpRewardsModel> rewards
}

global struct RTKBadgeDisplayModel
{
	RTKBadgeModel& badge
	string badgeTitle
	string badgeDescription
	string badgeType
}

struct AccountXPData
{
	int   accountXP
	int   startLevelXP
	int   nextLevelXP
	int   level
	int   nextLevel
	float levelFrac
}

struct
{
	int levelUps
	int levelUpsBoosted
	int endLevel
	int bonusXP = 0
	int badgeUnlocks
}file

const float AUTOSKIPOPUP_DELAY = 1.5
const float AUTOFADEBADGE_DELAY = 1.0

#if DEV
	global function DEV_SetPostMatchFakeBonusXP
	int DEV_BonusXP = 0
#endif
void function RTKPostGameXpBreakdown_OnInitialize( rtk_behavior self )
{
	bool isFirstTime = GetPersistentVarAsInt( "showGameSummary" ) != 0
	rtk_struct postGameXpModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "xp_breakdown", "", [ "postGame" ] )
	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "xp_breakdown", true, [ "postGame" ] ) )
	EmitUISound( "UI_Menu_MatchSummary_Appear" )

	AccountXPData previousAccountData       = GetAccountXPDataFromPersistanceVar( "previousXP", true )
	AccountXPData currentAccountData        = GetAccountXPDataFromPersistanceVar( "xp" )
	AccountXPData currentBoostedAccountData = GetAccountXPDataFromPersistanceVar( "xp", true )
	int accountLevel = isFirstTime ? previousAccountData.level : currentBoostedAccountData.level
	entity player = GetLocalClientPlayer()
	file.bonusXP = GetBonusTotalAccountXP( player )
	BuildPostGameXpBreakdownModel( postGameXpModel )
	BuildPostGameTotalXpBreakdownModel( postGameXpModel )
	BuildPostGameXpRewardsModel( postGameXpModel, accountLevel )
	BuildPostGameProgressBarModel( postGameXpModel, isFirstTime )
	BuildLevelUpPopUpModel( postGameXpModel )
	SetUpLevelUpPopUpButton( self )
	SetUpContinueButton( self )

	rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )

	if ( barAnimator != null )
	{
		expect rtk_behavior( barAnimator )
		self.AutoSubscribe( barAnimator, "onAnimationFinished", function ( rtk_behavior animator, string animName ) : ( self, postGameXpModel, barAnimator, isFirstTime ) {
			StopUISoundByName( "UI_Menu_MatchSummary_XPBar" )
			if ( DidPlayerLeveUp( postGameXpModel ) ) 
			{
				EmitUISound( "ui_menu_matchsummary_levelup" )
				ConfigureXPBarLevelUpData( postGameXpModel )
				RTKAnimator_PlayAnimation( animator, "AnimateBar" )
				if ( file.levelUpsBoosted == 0 && isFirstTime )
				{
					barAnimator.SetActive( false )
					ShowLevelUpPopUp( self, true )
					StopUISoundByName( "UI_Menu_MatchSummary_XPBar" )
				}
			}
		} )
		self.AutoSubscribe( barAnimator, "onAnimationStarted", function ( rtk_behavior animator, string animName ) : ( ) {
			EmitUISound( "UI_Menu_MatchSummary_XPBar" )
		} )

		ItemFlavor ornull character = GetLastMatchCharacter()
		array<BadgeDisplayData> unlockedBadges = GetPostMatchUnlockedBadges( player )
		file.badgeUnlocks =  unlockedBadges.len()

		if ( isFirstTime && file.badgeUnlocks == 0 )
		{
			StartFirstTimePostGameBreakdown( self, currentAccountData, currentBoostedAccountData, postGameXpModel )
		}
		else if ( isFirstTime && file.badgeUnlocks > 0 )
		{
			if ( character != null )
			{
				expect ItemFlavor( character )
				DisplayBadgeUnlock( self, postGameXpModel, player, character, unlockedBadges )
				ShowBadgeUnlockDisplay( self, true )
			}
		}
	}
	
	
	PostGame_ToggleVisibilityContinueButton( false )
	if ( PostGame_IsContinueButtonRegistered() )
	{
		DeregisterButtonPressedCallback( BUTTON_A, PostGameGeneral_OnContinue_Activate )
		DeregisterButtonPressedCallback( KEY_SPACE, PostGameGeneral_OnContinue_Activate )
		PostGame_SetContinueButtonRegistered( false )
	}
}
void function InitRTKPostGameSummary( var panel )
{
	RegisterSignal( "EndPostMatchAutoPlayThreads" )
}

void function SetUpContinueButton( rtk_behavior self )
{
	rtk_behavior ornull button = self.PropGetPanel( "breakdownContainer" ).FindChildByName( "ContinueButton" ).FindBehaviorByTypeName( "Button" )
	if ( button != null )
	{
		expect rtk_behavior( button )
		self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : () {
			CloseActiveMenu()
		})
	}
}

void function StartFirstTimePostGameBreakdown( rtk_behavior self, AccountXPData currentAccountData, AccountXPData currentBoostedAccountData, rtk_struct postGameXpModel )
{
	rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )
	if ( barAnimator == null )
		return

	expect rtk_behavior( barAnimator )

	rtk_struct accountProgressModel = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "accountProgress", "RTKAccountProgressBarsModel" )
	array <rtk_behavior> tweenStaggersBehaviors
	rtk_array tweenStaggers = self.PropGetArray( "tweenStaggers" )

	for( int i = 0; i < RTKArray_GetCount( tweenStaggers ); i++ )
		tweenStaggersBehaviors.append( RTKArray_GetBehavior( tweenStaggers, i ) )

	foreach( rtk_behavior behavior in tweenStaggersBehaviors )
	{
		behavior.SetActive( true )
		self.AutoSubscribe( behavior, "onFinish", function () : ( barAnimator, currentAccountData, currentBoostedAccountData, accountProgressModel ) {
			if ( !RTKAnimator_IsPlaying( barAnimator ) )
			{
				RTKAnimator_PlayAnimation( barAnimator, "AnimateBar" )
				RTKStruct_SetFloat( accountProgressModel, "boostFracEnd", file.levelUpsBoosted > 0 ? 1.0 : currentBoostedAccountData.levelFrac )
				RTKStruct_SetFloat( accountProgressModel, "progressFracEnd", file.levelUps > 0 ? 1.0 : currentAccountData.levelFrac )
				if ( file.levelUpsBoosted == 0 )
					RTKStruct_SetInt( accountProgressModel, "endXP", currentBoostedAccountData.accountXP - currentBoostedAccountData.startLevelXP )
			}
		} )
	}
}

void function RTKPostGameXpBreakdown_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "xp_breakdown" )
	StopUISoundByName( "UI_Menu_MatchSummary_XPBar" )
	Signal( uiGlobal.signalDummy, "EndPostMatchAutoPlayThreads" )

	
	
	PostGame_ToggleVisibilityContinueButton( true )
	if ( !PostGame_IsContinueButtonRegistered() && GetActiveMenu() == GetMenu( "PostGameMenu" ) )
	{
		RegisterButtonPressedCallback( BUTTON_A, PostGameGeneral_OnContinue_Activate )
		RegisterButtonPressedCallback( KEY_SPACE, PostGameGeneral_OnContinue_Activate )
		PostGame_SetContinueButtonRegistered( true )
	}
}

void function BuildPostGameXpBreakdownModel( rtk_struct postGameXpModel )
{
	const vector COLOR_MATCH = <255, 255, 255> / 255.0
	const vector COLOR_BONUS = <142, 250, 255> / 255.0
	const int LIST_QUANTITY = 2
	UpdateXPEvents()
	entity player = GetLocalClientPlayer()
	string lastGameMode = expect string( GetPersistentVar( "lastGameMode" ) )
	if (!( lastGameMode in xpDisplayGroups ))
		lastGameMode = SURVIVAL

	array< array<RTKPostGameXpBreakdownModel> > xpLists
	for ( int listIndex = 0; listIndex < LIST_QUANTITY; listIndex++ )
	{
		array<RTKPostGameXpBreakdownModel> listModel

		int index = 0
		foreach ( xpType in xpDisplayGroups[ lastGameMode ][listIndex] )
		{
			int eventValue = GetXPEventValue( player, xpType )
			if ( XpEventTypeData_DisplayEmpty( xpType ) || eventValue > 0 )
			{

				array<string> tooltipDescription
				array<Boost> boosts = Boost_GetBoostsAffectingXPType( player, xpType )
				int boostPercentage = 0
				foreach( Boost boost in boosts )
				{
					boostPercentage += int( boost.uiModifierSummaryAmount )
					tooltipDescription.append( boost.boostDescriptionShort )
				}

				vector displayColor = (listIndex % 2 == 0) ? COLOR_MATCH : COLOR_BONUS
				RTKPostGameXpBreakdownModel item
				item.title = GetXPEventNameDisplay( player, xpType )
				item.boostPercentage = boostPercentage
				if ( boosts.len() > 0 )
					item.tooltipTitle = boosts.len() == 1 ? boosts[0].boostNameShort : "#PROGRESSION_MODIFIERS_MULTI_BOOST"
				item.tooltipDescription = tooltipDescription
				item.xpValue = eventValue
				item.textColor = displayColor
				item.backgroundColor = (index % 2 == 0) ? displayColor : <0,0,0>

				listModel.append( item )
				index++
			}
		}
		xpLists.append( listModel )
	}

	for ( int i = 0; i < LIST_QUANTITY; i++ )
	{
		rtk_array xpBreakdownModel = RTKStruct_GetOrCreateScriptArrayOfStructs( postGameXpModel, "xpList"+string(i+1), "RTKPostGameXpBreakdownModel" )
		RTKArray_SetValue( xpBreakdownModel, xpLists[i] )
}
}

void function BuildPostGameProgressBarModel( rtk_struct postGameXpModel, bool isFirstTime )
{
	AccountXPData previousAccountData       = GetAccountXPDataFromPersistanceVar( "previousXP", true )
	AccountXPData currentAccountData        = GetAccountXPDataFromPersistanceVar( "xp" )
	AccountXPData currentBoostedAccountData = GetAccountXPDataFromPersistanceVar( "xp", true )

	file.levelUps = currentAccountData.level - previousAccountData.level
	file.levelUpsBoosted = currentBoostedAccountData.level - previousAccountData.level
	file.endLevel = currentBoostedAccountData.level
	int maxXPForCurrentLevel    = previousAccountData.nextLevelXP - previousAccountData.startLevelXP

	RTKAccountProgressBarsModel accountProgress
	accountProgress.progressFracStart = previousAccountData.levelFrac
	accountProgress.boostFracStart = previousAccountData.levelFrac

	if ( isFirstTime )
	{
		accountProgress.startXP = previousAccountData.accountXP - previousAccountData.startLevelXP
		accountProgress.endXP = maxXPForCurrentLevel
		accountProgress.maxLevelXP = accountProgress.endXP
		accountProgress.currentBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( previousAccountData.level )
		accountProgress.currentBadge.tier = previousAccountData.level
		accountProgress.nextBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( previousAccountData.nextLevel )
		accountProgress.nextBadge.tier = previousAccountData.nextLevel
		accountProgress.boostFracEnd = previousAccountData.levelFrac
		accountProgress.progressFracEnd = previousAccountData.levelFrac
	}
	else
	{
		accountProgress.startXP = currentBoostedAccountData.accountXP - currentBoostedAccountData.startLevelXP
		accountProgress.maxLevelXP = currentBoostedAccountData.nextLevelXP - currentBoostedAccountData.startLevelXP
		accountProgress.currentBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( currentBoostedAccountData.level )
		accountProgress.currentBadge.tier = currentBoostedAccountData.level
		accountProgress.nextBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( currentBoostedAccountData.nextLevel )
		accountProgress.nextBadge.tier = currentBoostedAccountData.nextLevel
		accountProgress.boostFracEnd = currentBoostedAccountData.levelFrac
		accountProgress.progressFracEnd = file.levelUpsBoosted > file.levelUps ? 0.0 : currentAccountData.levelFrac
	}
	accountProgress.animDuration = 1.0 + min((-0.1 * file.levelUpsBoosted), 0.0) 

	rtk_struct accountProgressModel = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "accountProgress", "RTKAccountProgressBarsModel" )
	RTKStruct_SetValue( accountProgressModel, accountProgress )
}

void function SetFullLevelUpAccountProgressData()
{
	int currentLevel = (file.endLevel - file.levelUpsBoosted) + 1
	AccountXPData currentAccountData     = GetAccountXPDataFromPersistanceVar( "xp" )
	int earnedXPForCurrentLevel = GetTotalXPToCompleteAccountLevel( currentLevel - 1 ) - GetTotalXPToCompleteAccountLevel( currentLevel )
	int xpForLevel   = GetTotalXPToCompleteAccountLevel( currentLevel ) - GetTotalXPToCompleteAccountLevel( currentLevel - 1 )

	RTKAccountProgressBarsModel accountProgress
	accountProgress.currentBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( currentLevel )
	accountProgress.currentBadge.tier = currentLevel
	accountProgress.nextBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( currentLevel + 1 )
	accountProgress.nextBadge.tier = currentLevel + 1
	accountProgress.startXP = 0
	accountProgress.endXP = GetTotalXPToCompleteAccountLevel( currentLevel )
	accountProgress.maxLevelXP = accountProgress.endXP
	accountProgress.progressFracStart = 0
	accountProgress.boostFracStart = 0
	accountProgress.boostFracEnd = 1
	accountProgress.progressFracEnd = (file.levelUps > 0 ) ? currentAccountData.levelFrac : 0.0
	accountProgress.animDuration = 1.0 + min((-0.1 * file.levelUpsBoosted), 0.0) 

	rtk_struct postGameXpModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "xp_breakdown", true, [ "postGame" ] ) )
	rtk_struct accountProgressModel = RTKStruct_GetStruct( postGameXpModel, "accountProgress" )
	RTKStruct_SetValue( accountProgressModel, accountProgress )
}

void function SetFinalLevelUpAccountProgressData()
{
	AccountXPData currentAccountData        = GetAccountXPDataFromPersistanceVar( "xp" )
	AccountXPData currentBoostedAccountData        = GetAccountXPDataFromPersistanceVar( "xp", true )

	RTKAccountProgressBarsModel accountProgress
	accountProgress.currentBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( currentBoostedAccountData.level )
	accountProgress.currentBadge.tier = currentBoostedAccountData.level
	accountProgress.nextBadge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset(  currentBoostedAccountData.nextLevel )
	accountProgress.nextBadge.tier = currentBoostedAccountData.nextLevel

	accountProgress.startXP = 0
	accountProgress.endXP = currentBoostedAccountData.accountXP - currentBoostedAccountData.startLevelXP
	accountProgress.maxLevelXP = GetTotalXPToCompleteAccountLevel( currentBoostedAccountData.level )

	accountProgress.progressFracStart = 0
	accountProgress.boostFracStart = 0

	accountProgress.boostFracEnd = currentBoostedAccountData.levelFrac
	accountProgress.progressFracEnd = (file.endLevel > currentAccountData.level ) ? 0.0 : currentAccountData.levelFrac
	accountProgress.animDuration = 1.0

	rtk_struct postGameXpModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "xp_breakdown", true, [ "postGame" ] ) )
	rtk_struct accountProgressModel = RTKStruct_GetStruct( postGameXpModel, "accountProgress" )
	RTKStruct_SetValue( accountProgressModel, accountProgress )
}

void function BuildPostGameTotalXpBreakdownModel( rtk_struct postGameXpModel )
{
	int previousAccountXP = GetPersistentVarAsInt( "previousXP" )
	int currentAccountXP  = GetPersistentVarAsInt( "xp" )
	int baseXP = (currentAccountXP - file.bonusXP) - previousAccountXP
	int totalXP = currentAccountXP - previousAccountXP
#if DEV
		totalXP = (currentAccountXP + DEV_BonusXP) - previousAccountXP
#endif

	int activeBoosts = Boost_GetBoostEventQuantityFromCategory( eBoostCategory.ACCOUNT_XP, Boost_GetPreviousAppliedBoosts( GetLocalClientPlayer() ) )
	activeBoosts += Boost_GetActiveLegacyBoostEventQuantity()

	RTKPostGameTotalXpModel totalXpBreakdown
	totalXpBreakdown.baseXP = baseXP
	totalXpBreakdown.boostsApplied = activeBoosts
	totalXpBreakdown.totalXP = totalXP
	rtk_struct xpTotalModel = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "totalXPModel", "RTKPostGameTotalXpModel" )
	RTKStruct_SetValue( xpTotalModel, totalXpBreakdown )
}

void function BuildPostGameXpRewardsModel( rtk_struct postGameXpModel, int accountLevel )
{
	array<RewardData> accountRewardArray = GetRewardsForAccountLevel( accountLevel )

	array<RTKPostGameXpRewardsModel> rewards = []
	for ( int i = 0; i < accountRewardArray.len(); i++ )
	{
		RTKPostGameXpRewardsModel reward
		reward.icon = GetImageForReward( accountRewardArray[i] )
		reward.value = GetStringForReward( accountRewardArray[i] )
		if ( reward.icon != "" )
			rewards.append( reward )
	}
	rtk_array xpTotalModel = RTKStruct_GetOrCreateScriptArrayOfStructs( postGameXpModel, "xpRewards", "RTKPostGameXpRewardsModel" )
	RTKArray_SetValue( xpTotalModel, rewards )
}

bool function DidPlayerLeveUp( rtk_struct postGameXpModel )
{
	rtk_struct accountProgressStruct = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "accountProgress", "RTKAccountProgressBarsModel" )

	RTKAccountProgressBarsModel accountProgressModel
	RTKStruct_GetValue( accountProgressStruct, accountProgressModel )
	return accountProgressModel.endXP == accountProgressModel.maxLevelXP
}
void function ConfigureXPBarLevelUpData( rtk_struct postGameXpModel )
{
	rtk_struct accountProgress = RTKStruct_GetStruct( postGameXpModel, "accountProgress" )
	BuildPostGameXpRewardsModel( postGameXpModel, file.endLevel - file.levelUpsBoosted )

	if ( file.levelUpsBoosted > 1 )
		SetFullLevelUpAccountProgressData()
	else
		SetFinalLevelUpAccountProgressData()

	file.levelUps--
	file.levelUpsBoosted--
}

AccountXPData function GetAccountXPDataFromPersistanceVar( string persitanceVar, bool isBoosted = false )
{
	AccountXPData accountData
	accountData.accountXP = GetPersistentVarAsInt( persitanceVar )
	if ( !isBoosted )
		accountData.accountXP -= file.bonusXP
#if DEV
	if ( persitanceVar == "xp" && isBoosted )
		accountData.accountXP += DEV_BonusXP
#endif
	accountData.level        = GetAccountLevelForXP( accountData.accountXP )
	accountData.startLevelXP = GetTotalXPToCompleteAccountLevel( accountData.level  - 1 )
	accountData.nextLevelXP  = GetTotalXPToCompleteAccountLevel( accountData.level )
	accountData.nextLevel    = accountData.level + 1
	accountData.levelFrac    = GraphCapped( accountData.accountXP, accountData.startLevelXP, accountData.nextLevelXP, 0.0, 1.0 )
	return accountData
}

void function BuildLevelUpPopUpModel( rtk_struct postGameXpModel )
{
	array<RTKPostGameXpRewardsModel> rewards = []
	table<ItemFlavor, int> rewardToQuantity = GetRewardToQuantityTable()

	foreach ( ItemFlavor flav, int qty in rewardToQuantity )
	{
		RTKPostGameXpRewardsModel reward
		reward.icon  = GetImageForRewardItemFlavor( flav )
		reward.value = GetStringRewardForItemFlavor( flav, qty )
		if ( reward.icon != "" )
			rewards.append( reward )
	}

	RTKLevelUpPopUpModel levelModel
	levelModel.badge.badgeRuiAsset = GetAccountBadgeRuiAssetAsAsset( file.endLevel )
	levelModel.badge.tier = file.endLevel
	levelModel.rewards = rewards

	rtk_struct levelUpModel = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "levelUpModel", "RTKLevelUpPopUpModel" )
	RTKStruct_SetValue( levelUpModel, levelModel )
}

string function GetStringRewardForItemFlavor( ItemFlavor flav, int qty )
{
	if ( ItemFlavor_GetGRXMode( flav ) == eItemFlavorGRXMode.PACK )
		return qty > 1 ? string( qty ) + " " + Localize( "#PACKS" ) :  Localize( "#PACK" )
	else
		return FormatAndLocalizeNumber( "1", float( qty ), ItemFlavor_IsCurrency( flav ) || IsTenThousandOrMore( qty ) )
	unreachable
}

table<ItemFlavor, int> function GetRewardToQuantityTable()
{
	table<ItemFlavor, int> rewardToQuantity
	for ( int i = file.levelUpsBoosted - 1; i >= 0; i-- )
	{
		array<RewardData> accountRewardArray = GetRewardsForAccountLevel( file.endLevel - i )
		for ( int j = 0; j < accountRewardArray.len(); j++ )
		{
			if ( !(accountRewardArray[j].item in rewardToQuantity) )
				rewardToQuantity[accountRewardArray[j].item] <- accountRewardArray[j].quantity
			else
				rewardToQuantity[accountRewardArray[j].item] += accountRewardArray[j].quantity
		}
	}
	return rewardToQuantity
}

int function GetBonusTotalAccountXP( entity player )
{
	string lastGameMode = expect string( GetPersistentVar( "lastGameMode" ) )
	if (!( lastGameMode in xpDisplayGroups ))
		lastGameMode = SURVIVAL

	array<int> xpTypes = clone xpDisplayGroups[lastGameMode][0]
	xpTypes.extend( clone xpDisplayGroups[lastGameMode][1] )

	return Boost_GetBonusPostGameTotalAccountXP( player, xpTypes )
}

void function ShowLevelUpPopUp( rtk_behavior self, bool isVisible )
{
	rtk_panel popUp = self.PropGetPanel( "levelUpPopUp" )
	rtk_panel breakdown = self.PropGetPanel( "breakdownContainer" )
	popUp.SetVisible( isVisible )
	popUp.SetActive( isVisible )
	breakdown.FindBehaviorByTypeName( "GlobalInput" ).SetActive( !isVisible )
	breakdown.SetVisible( !isVisible )
	thread LevelUpPopUpAutoSkip_Thread( self )
}

void function LevelUpPopUpButton_onPress( rtk_behavior self, rtk_behavior barAnimator )
{
	if ( barAnimator.IsActiveSelf() )
		return

	ShowLevelUpPopUp( self, false )
	barAnimator.SetActive( true )
	EmitUISound( "UI_Menu_MatchSummary_XPBar" )
}

void function LevelUpPopUpAutoSkip_Thread( rtk_behavior self )
{
	EndSignal( uiGlobal.signalDummy, "EndPostMatchAutoPlayThreads" )
	rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )
	if ( barAnimator == null )
		return
	expect rtk_behavior( barAnimator )

	wait AUTOSKIPOPUP_DELAY
	if ( barAnimator.IsActiveSelf() )
		return
	ShowLevelUpPopUp( self, false )
	barAnimator.SetActive( true )
	EmitUISound( "UI_Menu_MatchSummary_XPBar" )
}

void function SetUpLevelUpPopUpButton( rtk_behavior self )
{
	rtk_panel popUp = self.PropGetPanel( "levelUpPopUp" )
	rtk_behavior ornull button = popUp.FindChildByName( "ContinueButton" ).FindBehaviorByTypeName( "Button" )
	rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )
	if ( button != null && barAnimator != null )
	{
		expect rtk_behavior( button )
		expect rtk_behavior( barAnimator )
		self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, popUp, barAnimator ) {
			LevelUpPopUpButton_onPress( self, barAnimator )
		})
	}
}

void function ShowBadgeUnlockDisplay( rtk_behavior self, bool isVisible )
{
	rtk_panel badgePanel = self.PropGetPanel( "badgePanel" )
	rtk_panel breakdown = self.PropGetPanel( "breakdownContainer" )
	badgePanel.SetVisible( isVisible )
	badgePanel.FindBehaviorByTypeName( "CursorInteract" ).SetActive( isVisible )
	breakdown.SetVisible( !isVisible )
	breakdown.FindBehaviorByTypeName( "GlobalInput" ).SetActive( !isVisible )
}

void function PlayBadgeFadeOutWait_Thread( rtk_behavior animator, rtk_behavior self )
{
	EndSignal( uiGlobal.signalDummy, "EndPostMatchAutoPlayThreads" )
	wait AUTOFADEBADGE_DELAY
	if ( file.badgeUnlocks < 0 || RTKAnimator_IsPlayingAnimation( animator, "FadeIn" ) || RTKAnimator_IsPlayingAnimation( animator, "FadeOut" ) )
		return

	RTKAnimator_PlayAnimation( animator, "FadeOut" )
}
void function DisplayBadgeUnlock( rtk_behavior self, rtk_struct postGameXpModel, entity player, ItemFlavor character, array<BadgeDisplayData> badgeData )
{
	rtk_panel badgePanel = self.PropGetPanel( "badgePanel" )
	rtk_behavior ornull cursorArea = badgePanel.FindBehaviorByTypeName( "CursorInteract" )
	rtk_behavior ornull button = badgePanel.FindBehaviorByTypeName( "Button" )
	rtk_behavior ornull animator = badgePanel.FindBehaviorByTypeName( "Animator" )

	if ( animator != null )
	{
		badgePanel.SetActive( true )
		expect rtk_behavior( animator )

		EmitUISound( "UI_Menu_Badge_Earned" )
		file.badgeUnlocks--
		RTKAnimator_PlayAnimation( animator, "FadeIn" )
		BuildBadgeDisplayModel( postGameXpModel, player, character, badgeData[file.badgeUnlocks] )
		self.AutoSubscribe( animator, "onAnimationFinished", function ( rtk_behavior animator, string animName ) : ( self, postGameXpModel, player, character, badgeData, badgePanel ) {

			if ( animName == "FadeIn" )
			{
				thread PlayBadgeFadeOutWait_Thread( animator, self )
			}

			if ( animName == "FadeOut" && file.badgeUnlocks > 0 )
			{
				StopUISound( "UI_Menu_Badge_Earned" )
				file.badgeUnlocks--
				BuildBadgeDisplayModel( postGameXpModel, player, character, badgeData[file.badgeUnlocks] )
				RTKAnimator_PlayAnimation( animator, "FadeIn" )
				EmitUISound( "UI_Menu_Badge_Earned" )
			}
			else if ( animName == "FadeOut" )
			{
				ShowBadgeUnlockDisplay( self, false )
				AccountXPData currentAccountData        = GetAccountXPDataFromPersistanceVar( "xp" )
				AccountXPData currentBoostedAccountData = GetAccountXPDataFromPersistanceVar( "xp", true )
				StartFirstTimePostGameBreakdown( self, currentAccountData, currentBoostedAccountData, postGameXpModel )
			}
		})

		if ( cursorArea != null )
		{
			expect rtk_behavior( cursorArea )
			RTKCursorInteract_AutoSubscribeOnKeyCodePressedListener( self, cursorArea,
				void function( int code ) : ( self, animator, postGameXpModel, player, character, badgeData, badgePanel )
				{
					if ( code == KEY_SPACE || code == BUTTON_A )
					{
						if ( file.badgeUnlocks > 0 )
						{
							StopUISound( "UI_Menu_Badge_Earned" )
							file.badgeUnlocks--
							BuildBadgeDisplayModel( postGameXpModel, player, character, badgeData[file.badgeUnlocks] )
							RTKAnimator_PlayAnimation( animator, "FadeIn" )
							EmitUISound( "UI_Menu_Badge_Earned" )
						}
						else
						{
							ShowBadgeUnlockDisplay( self, false )
							AccountXPData currentAccountData        = GetAccountXPDataFromPersistanceVar( "xp" )
							AccountXPData currentBoostedAccountData = GetAccountXPDataFromPersistanceVar( "xp", true )
							StartFirstTimePostGameBreakdown( self, currentAccountData, currentBoostedAccountData, postGameXpModel )
						}
					}
				}
			)
		}
	}
}

void function BuildBadgeDisplayModel( rtk_struct postGameXpModel, entity player, ItemFlavor character, BadgeDisplayData badgeData )
{
	ItemFlavor badge = badgeData.badge
	GladCardBadgeDisplayData gcbdd = GetBadgeData( ToEHI( player ), character, 0, badge, null )
	array<GladCardBadgeTierData> tierDataList = GladiatorCardBadge_GetTierDataList( badge )
	RTKBadgeDisplayModel badgeDisplayModel
	badgeDisplayModel.badgeTitle = ItemFlavor_GetLongName( badge )
	string categoryName = GetBadgeCategoryName( badge )

	badgeDisplayModel.badgeType = GladiatorCardBadge_IsCharacterBadge( badge ) ? Localize( "#CHARACTER_BADGE", Localize( ItemFlavor_GetLongName( character ) ) ) : Localize( "#ACCOUNT_BADGE", categoryName )

	float unlockRequirement = badgeData.tierData.unlocksAt
	if ( tierDataList.len() > 1 )
	{
		badgeDisplayModel.badgeDescription = Localize( ItemFlavor_GetShortDescription( badge ), format( "`2%s`0", string(unlockRequirement) ) )
	}
	else
	{
		badgeDisplayModel.badgeDescription = ItemFlavor_GetShortDescription( badge )
	}
	badgeDisplayModel.badge.badgeRuiAsset = gcbdd.ruiAsset
	badgeDisplayModel.badge.imageAsset = gcbdd.imageAsset
	badgeDisplayModel.badge.tier = gcbdd.dataInteger

	rtk_struct badgeDisplayModelStruct = RTKStruct_GetOrCreateScriptStruct( postGameXpModel, "badgeUnlocked", "RTKBadgeDisplayModel" )
	RTKStruct_SetValue( badgeDisplayModelStruct, badgeDisplayModel )
}

ItemFlavor ornull function GetLastMatchCharacter()
{
	int characterGUID = GetPersistentVarAsInt( "lastGameCharacter" )
	ItemFlavor ornull character = null
	if ( IsValidItemFlavorGUID( characterGUID ) )
	{
		character = GetItemFlavorByGUID( characterGUID )
	}
	else
	{
		Warning( "Cannot display post-game summary banner because character \"" + string(characterGUID) + "\" is not registered right now." )
	}
	return character
}

array<BadgeDisplayData> function GetPostMatchUnlockedBadges( entity player )
{
	array<BadgeDisplayData> unlockedBadgesData

	table<int, int> grxPostGameRewardGUIDToPersistenceIdx = GRX_GetPostGameRewards()
	foreach ( int guid, int _ in grxPostGameRewardGUIDToPersistenceIdx )
	{
		if ( !IsValidItemFlavorGUID( guid ) )
			continue

		ItemFlavor item = GetItemFlavorByGUID( guid )
		if ( ItemFlavor_GetType( item ) != eItemType.gladiator_card_badge )
			continue

		BadgeDisplayData unlockedBadgeData
		unlockedBadgeData.badge = item
		unlockedBadgeData.tierData = GladiatorCardBadge_GetTierDataList( item )[0]
		unlockedBadgesData.append( unlockedBadgeData )
		GRX_MarkRewardAcknowledged( guid, grxPostGameRewardGUIDToPersistenceIdx[ guid ] )
	}

	unlockedBadgesData.extend( GladiatorCardBadge_GetPostGameStatUnlockBadgesDisplayData() )

	return unlockedBadgesData
}

#if DEV
void function DEV_SetPostMatchFakeBonusXP( int xp )
{
	DEV_BonusXP = xp
}
#endif

