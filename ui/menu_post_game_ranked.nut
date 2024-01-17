global function InitPostGameRankedMenu
global function InitPostGameRankedSummaryPanel
global function OpenRankedSummary
global function InitRankedScoreBarRuiForDoubleBadge

global function RankUpAnimation


const string POSTGAME_LINE_ITEM = "UI_Menu_MatchSummary_Ranked_XPBreakdown"
const string POSTGAME_XP_INCREASE = "UI_Menu_MatchSummary_Ranked_XPBar_Increase"
const asset RUI_PATH_RANKED_DIVISION_UP = $"ui/rank_division_up_anim.rpak"
const float PROGRESS_BAR_FILL_TIME = 5.0
const float PROGRESS_BAR_FILL_TIME_FAST = 2.0
const float LINE_DISPLAY_TIME = 0.4
const float RANK_UP_TIME = 3.6
const float DIALOGUE_DELAY = 1.6
const float ANIMATE_XP_BAR_DELAY = 0.25
const float ANIMATE_XP_BAR_PROGRESS_DELAY = 0.5
const float START_DELAY_OFFSET = -50.0
const float BAD_GAME_TIME_OFFSET = -9999.0
const int NUM_SCORE_LINES_DEFAULT = 4

struct
{
	var  menu
	var  continueButton
	var  menuHeaderRui
	bool showQuickVersion
	bool skippableWaitSkipped = false
	bool disableNavigateBack = false
	bool isFirstTime = false
	bool buttonsRegistered = false
	bool canUpdateXPBarEmblem = false
	var  barRuiToUpdate = null
} file

struct scoreLine
{
	string keyString = ""
	string valueString = ""
	vector color = <1,1,1>
	float  alpha = 1.0
	float rowHeight = 1.0
}

void function InitPostGameRankedMenu( var newMenuArg )
{
	var menu = GetMenu( "PostGameRankedMenu" )
	file.menu = menu

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, OnPostGameRankedMenu_Open )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, OnPostGameRankedMenu_Close )
	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, OnPostGameRankedMenu_Show )
	AddMenuEventHandler( menu, eUIEvent.MENU_HIDE, OnPostGameRankedMenu_Hide )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, OnNavigateBack )

	file.continueButton = Hud_GetChild( file.menu, "ContinueButton" )
	Hud_AddEventHandler( file.continueButton, UIE_CLICK, OnContinue_Activate )

	{
		TabDef tabDef = AddTab( file.menu, Hud_GetChild( file.menu, "MatchSummaryPanel" ), "#MENU_GENERAL" )
		SetTabBaseWidth( tabDef, 250 )
	}

	TabData tabData = GetTabDataForPanel( file.menu )

	tabData.centerTabs = true
	tabData.bannerHeader = ""
	tabData.bannerTitle = "#MATCH_SUMMARY"
	tabData.callToActionWidth = 700

	SetTabBackground( tabData, Hud_GetChild( file.menu, "TabsBackground" ), eTabBackground.STANDARD )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE", null, CanNavigateBack )
	AddMenuFooterOption( menu, LEFT, BUTTON_BACK, true, "", "", CloseRankedSummary, CanNavigateBack )

	RegisterSignal( "OnPostGameRankedMenu_Close" )

#if DEV
	AddMenuThinkFunc( file.menu, PostGameRankedMenuAutomationThink )
#endif
}

void function InitPostGameRankedSummaryPanel( var panel )
{
	
}

#if DEV
void function PostGameRankedMenuAutomationThink( var menu )
{
	if (AutomateUi())
	{
		printt("PostGameRankedMenuAutomationThink OnContinue_Activate()")
		OnContinue_Activate(null)
	}
}
#endif

void function OnPostGameRankedMenu_Open()
{
	AddCallbackAndCallNow_UserInfoUpdated( Ranked_OnUserInfoUpdatedInPostGame )
	Lobby_AdjustScreenFrameToMaxSize( Hud_GetChild( file.menu, "ScreenFrame" ), true )

	var matchRankRui = Hud_GetRui( Hud_GetChild( file.menu, "MatchRank" ) )
	PopulateMatchRank( matchRankRui )

	TabData tabData = GetTabDataForPanel( file.menu )
	TabDef tabDef = Tab_GetTabDefByBodyName( tabData, "MatchSummaryPanel" )
	tabDef.enabled = true
	tabDef.visible = true
	ActivateTab( tabData, 0 )
}

void function OnPostGameRankedMenu_Show()
{
	thread _Show()
}

void function _Show()
{
	Signal( uiGlobal.signalDummy, "OnPostGameRankedMenu_Close" )
	EndSignal( uiGlobal.signalDummy, "OnPostGameRankedMenu_Close" )

	if ( !IsFullyConnected() )
		return

	if ( !IsPersistenceAvailable() )
		return

	UI_SetPresentationType( ePresentationType.WEAPON_CATEGORY )

	float maxTimeToWaitForLoadScreen = UITime() + LOADSCREEN_FINISHED_MAX_WAIT_TIME
	while(  UITime() < maxTimeToWaitForLoadScreen && !IsLoadScreenFinished()  ) 
		WaitFrame()

	bool isFirstTime = GetPersistentVarAsInt( "showGameSummary" ) != 0

	string postMatchSurveyMatchId = string( GetPersistentVar( "postMatchSurveyMatchId" ) )
	float postMatchSurveySampleRateLowerBound = expect float( GetPersistentVar( "postMatchSurveySampleRateLowerBound" ) )
	if ( isFirstTime && TryOpenSurvey( eSurveyType.POSTGAME, postMatchSurveyMatchId, postMatchSurveySampleRateLowerBound ) )
	{
		while ( IsDialog( GetActiveMenu() ) )
			WaitFrame()
	}

	if ( !file.buttonsRegistered )
	{
		RegisterButtonPressedCallback( BUTTON_A, OnContinue_Activate )
		RegisterButtonPressedCallback( KEY_SPACE, OnContinue_Activate )
		file.buttonsRegistered = true
	}
}

void function RankUpAnimation( int numRanksEarned, int scoreStart, int ladderPosition, int finalScore, bool isProvisionalGraduation = false )
{
	PostGameGeneral_SetDisableNavigateBack( true )
	file.disableNavigateBack = true

	SharedRankedDivisionData rd_start = GetCurrentRankedDivisionFromScoreAndLadderPosition( scoreStart, ladderPosition )
	SharedRankedTierData startingTier = rd_start.tier
	SharedRankedDivisionData ornull nextDivision = GetNextRankedDivisionFromScore( scoreStart ) 

	if ( nextDivision != null ) 
	{
		expect SharedRankedDivisionData( nextDivision )
		StopUISoundByName( POSTGAME_XP_INCREASE )

		if ( numRanksEarned > 0 || isProvisionalGraduation )
		{
			Hud_Hide( Hud_GetChild( file.menu, "MovingBoxBG" ) )
			Hud_Hide( Hud_GetChild( file.menu, "RewardDisplay" ) )
			Hud_Hide( file.continueButton )

			wait 0.1

			Hud_Show( Hud_GetChild( file.menu, "MovingBoxBG" ) )
			Hud_Show( Hud_GetChild( file.menu, "RewardDisplay" ) )
			var rewardDisplayRui = Hud_GetRui( Hud_GetChild( file.menu, "RewardDisplay" ) )
			RuiDestroyNestedIfAlive( rewardDisplayRui, "levelUpAnimHandle" )

			if ( GetNextRankedDivisionFromScore( finalScore ) == null ) 
				ladderPosition = Ranked_GetLadderPosition( GetLocalClientPlayer() )

			SharedRankedDivisionData promotedDivisionData = GetCurrentRankedDivisionFromScoreAndLadderPosition( finalScore, ladderPosition )
			SharedRankedTierData promotedTierData         = promotedDivisionData.tier 
			SharedRankedDivisionData ornull nextPromotedDivision = GetNextRankedDivisionFromScore( finalScore )

			if ( isProvisionalGraduation || startingTier != promotedTierData )
			{
				asset levelupRuiAsset = isProvisionalGraduation ? RANKED_PLACEMENT_LEVEL_UP_BADGE : startingTier.levelUpRuiAsset
				if ( GetNextRankedDivisionFromScore( finalScore ) == null ) 
				{
					if ( !promotedDivisionData.isLadderOnlyDivision )
						levelupRuiAsset = promotedTierData.levelUpRuiAsset 
				}

				var nestedRuiHandle = RuiCreateNested( rewardDisplayRui, "levelUpAnimHandle", levelupRuiAsset )

				RuiSetGameTime( nestedRuiHandle, "startTime", ClientTime() )
				RuiSetImage( nestedRuiHandle, "newRank", promotedTierData.icon )

				
				if ( isProvisionalGraduation && nextPromotedDivision != null )
				{
					switch( promotedDivisionData.emblemDisplayMode )
					{
						case emblemDisplayMode.DISPLAY_DIVISION:
						{
							RuiSetString( nestedRuiHandle, "tierText", Localize( promotedDivisionData.emblemText ) )
							break
						}

						case emblemDisplayMode.DISPLAY_RP:
						{
							string rankScoreShortened = FormatAndLocalizeNumber( "1", float( finalScore ), IsTenThousandOrMore( finalScore ) )
							RuiSetString( nestedRuiHandle, "tierText", Localize( "#RANKED_POINTS_GENERIC", rankScoreShortened ) )
							break
						}

						case emblemDisplayMode.DISPLAY_LADDER_POSITION:
						{
							string ladderPosShortened
							if ( ladderPosition == SHARED_RANKED_INVALID_LADDER_POSITION )
								ladderPosShortened = ""
							else
								ladderPosShortened = Localize( "#RANKED_LADDER_POSITION_DISPLAY", FormatAndLocalizeNumber( "1", float( ladderPosition ), IsTenThousandOrMore( ladderPosition ) ) )

							RuiSetString( nestedRuiHandle, "tierText", ladderPosShortened )
							break
						}

						case emblemDisplayMode.NONE:
						default:
						{
							RuiSetString( nestedRuiHandle, "tierText", "" )
							break
						}
					}
				}
				else
				{
					RuiSetImage( nestedRuiHandle, "oldRank", startingTier.icon )
				}

				string sound = "UI_Menu_MatchSummary_Ranked_Promotion"
				if ( Ranked_GetNextTierData( promotedTierData ) == null )
					sound = "UI_Menu_MatchSummary_Ranked_PromotionApex" 

				if ( startingTier == promotedTierData )
					PlayLobbyCharacterDialogue( "glad_rankUp", DIALOGUE_DELAY  )
				else if ( promotedTierData.promotionAnnouncement != "" )
					PlayLobbyCharacterDialogue(  promotedTierData.promotionAnnouncement, DIALOGUE_DELAY  )

				EmitUISound( sound )
			}
			else
			{
				var nestedRuiHandle = RuiCreateNested( rewardDisplayRui, "levelUpAnimHandle", RUI_PATH_RANKED_DIVISION_UP )
				RuiSetGameTime( nestedRuiHandle, "startTime", ClientTime() )
				RuiSetString( nestedRuiHandle, "oldDivision", Localize( rd_start.emblemText ) )
				RuiSetString( nestedRuiHandle, "newDivision", Localize( promotedDivisionData.emblemText ) )
				RuiSetImage( nestedRuiHandle, "rankEmblemImg", startingTier.icon )
				EmitUISound( "UI_Menu_MatchSummary_Ranked_RankUp" )
				PlayLobbyCharacterDialogue( "glad_rankUp", DIALOGUE_DELAY  )
			}

			wait RANK_UP_TIME

			Hud_Hide( Hud_GetChild( file.menu, "MovingBoxBG" ) )
			Hud_Hide( Hud_GetChild( file.menu, "RewardDisplay" ) )
			Hud_Show( file.continueButton )
		}
	}

	file.disableNavigateBack = false
	PostGameGeneral_SetDisableNavigateBack( false )
}

void function ColorCorrectRui( var rui, SharedRankedTierData currentTier, int score )
{
	if ( currentTier.isLadderOnlyTier ) 
	{
		SharedRankedDivisionData scoreDivisionData = GetCurrentRankedDivisionFromScore( score )
		SharedRankedTierData scoreCurrentTier      = scoreDivisionData.tier
		RuiSetInt( rui, "currentTierColorOffset", scoreCurrentTier.index + 1 )
	}
	else
	{
		RuiSetInt( rui, "currentTierColorOffset", currentTier.index )
	}
}

void function InitRankedScoreBarRuiForDoubleBadge( var rui, int score, int ladderPosition )
{
	for ( int i=0; i<5; i++ )
		RuiDestroyNestedIfAlive( rui, "rankedBadgeHandle" + i )

	RuiSetBool( rui, "forceDoubleBadge", true )

	SharedRankedDivisionData currentRank = GetCurrentRankedDivisionFromScoreAndLadderPosition( score, ladderPosition )
	SharedRankedTierData currentTier     = currentRank.tier

	RuiSetGameTime( rui, "animStartTime", RUI_BADGAMETIME )
	ColorCorrectRui( rui, currentTier, score )

	
	RuiSetImage( rui, "icon0" , currentTier.icon )
	RuiSetString( rui, "emblemText0" , currentRank.emblemText )
	RuiSetInt( rui, "badgeScore0", score )
	SharedRanked_FillInRuiEmblemText( rui, currentRank, score, ladderPosition, "0"  )
	CreateNestedRankedRui( rui, currentRank.tier, "rankedBadgeHandle0", score, ladderPosition )
	bool shouldUpdateRuiWithCommunityUserInfo = Ranked_ShouldUpdateWithComnunityUserInfo( score, ladderPosition )
	if ( shouldUpdateRuiWithCommunityUserInfo )
		file.barRuiToUpdate = rui

	RuiSetImage( rui, "icon3" , currentTier.icon )
	RuiSetString( rui, "emblemText3" , currentRank.emblemText )
	RuiSetInt( rui, "badgeScore3", currentRank.scoreMin )
	SharedRanked_FillInRuiEmblemText( rui, currentRank, score, ladderPosition, "3"  )
	CreateNestedRankedRui( rui, currentRank.tier, "rankedBadgeHandle3", score, ladderPosition )

	SharedRankedDivisionData ornull nextRank = GetNextRankedDivisionFromScore( score )

	RuiSetInt( rui, "currentScore" , score )
	RuiSetInt( rui, "startScore" , currentRank.scoreMin )
	RuiSetBool( rui, "showSingleBadge", nextRank == null )


		RuiSetBool( rui, "inPromoTrials", RankedTrials_PlayerHasIncompleteTrial( GetLocalClientPlayer() ) && !RankedTrials_IsKillswitchEnabled() )
		RuiSetBool( rui, "showPromoPip", RankedTrials_NextRankHasTrial( currentRank, nextRank ) && !RankedTrials_IsKillswitchEnabled() )


	if ( nextRank != null )
	{		
		expect SharedRankedDivisionData( nextRank )
		SharedRankedTierData nextTier = nextRank.tier

		RuiSetBool( rui, "showSingleBadge", nextRank == currentRank )
		RuiSetInt( rui, "endScore" , nextRank.scoreMin )
		RuiSetString( rui, "emblemText4" , nextRank.emblemText  )
		RuiSetInt( rui, "badgeScore4", nextRank.scoreMin )
		RuiSetImage( rui, "icon4", nextTier.icon )
		RuiSetInt( rui, "nextTierColorOffset", nextTier.index )


			RuiSetAsset( rui, "promoCapImage", nextTier.promotionalMetallicImage )


		SharedRanked_FillInRuiEmblemText( rui, nextRank, nextRank.scoreMin, SHARED_RANKED_INVALID_LADDER_POSITION, "4"  )
		CreateNestedRankedRui( rui, nextRank.tier, "rankedBadgeHandle4", nextRank.scoreMin, SHARED_RANKED_INVALID_LADDER_POSITION ) 
	}
}

void function OnPostGameRankedMenu_Close()
{
	file.barRuiToUpdate = null
	RemoveCallback_UserInfoUpdated( Ranked_OnUserInfoUpdatedInPostGame )
}

void function OnContinue_Activate( var button )
{
	if ( !file.disableNavigateBack )
		CloseRankedSummary( null )
}

void function OnPostGameRankedMenu_Hide()
{
	Signal( uiGlobal.signalDummy, "OnPostGameRankedMenu_Close" )

	if ( file.buttonsRegistered )
	{
		DeregisterButtonPressedCallback( BUTTON_A, OnContinue_Activate )
		DeregisterButtonPressedCallback( KEY_SPACE, OnContinue_Activate )
		file.buttonsRegistered = false
	}
}

void function ResetSkippableWait()
{
	file.skippableWaitSkipped = false
}


bool function IsSkippableWaitSkipped()
{
	return file.skippableWaitSkipped || !file.disableNavigateBack
}


bool function SkippableWait( float waitTime, string uiSound = "" )
{
	if ( IsSkippableWaitSkipped() )
		return false

	if ( uiSound != "" )
		EmitUISound( uiSound )

	float startTime = UITime()
	while ( UITime() - startTime < waitTime )
	{
		if ( IsSkippableWaitSkipped() )
			return false

		WaitFrame()
	}

	return true
}


bool function CanNavigateBack()
{
	return file.disableNavigateBack != true
}


void function OnNavigateBack()
{
	if ( !CanNavigateBack() )
		return

	CloseRankedSummary( null )
}

void function CloseRankedSummary( var button )
{
	if ( GetActiveMenu() == file.menu )
		thread CloseActiveMenu()
}

void function OpenRankedSummary( bool firstTime )
{
	file.isFirstTime = firstTime
	AdvanceMenu( file.menu )
}

void function Ranked_OnUserInfoUpdatedInPostGame( string hardware, string id )
{
	if ( !IsConnected() )
		return

	if ( !IsLobby() )
		return

	if ( hardware == "" && id == "" )
		return

	CommunityUserInfo ornull cui = GetUserInfo( hardware, id )

	if ( cui == null )
		return

	if ( !file.canUpdateXPBarEmblem ) 
		return

	expect CommunityUserInfo( cui )

	entity uiPlayer    = GetLocalClientPlayer()
	bool inProvisional = !Ranked_HasCompletedProvisionalMatches(uiPlayer)

	if ( cui.hardware == GetUnspoofedPlayerHardware() && cui.uid == GetPlayerUID() ) 
	{
		if ( file.barRuiToUpdate != null  ) 
		{
			if ( !inProvisional && cui.rankedLadderPos > 0 ) 
				InitRankedScoreBarRuiForDoubleBadge( file.barRuiToUpdate, cui.rankScore, cui.rankedLadderPos )
		}
	}
}
