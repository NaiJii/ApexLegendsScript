global function RTKRankedMatchSummary_InitMetaData
global function RTKRankedMatchSummary_OnInitialize
global function RTKRankedMatchSummary_OnDestroy
global function BuildRankedMatchSummaryDataModel
global function BuildRankedBadgeDataModel
global function AnimateRankedProgressBar
global function StartRankUpAnimation
global function SetContinueButtonRegistration
global function RTKRankedMatchSummary_UpdateTweenDataModel

global struct RTKRankedMatchSummary_Properties
{
	rtk_behavior progressBarAnimator
	rtk_behavior tweenStagger
}

global struct BonusBreakdownInfo
{
	string bonusName 	 = ""
	int bonusValue 		 = 0
	bool crossOut		 = false

	string tooltipTitle	 = ""
	string tooltipBody   = ""
}

global struct ConditionalElement
{
	int 	alternatingBGOffset = 0
	string 	stringL = ""
	int 	stringR = 0
	vector 	colorL = <1.0, 1.0, 1.0>
	vector 	colorR = <1.0, 1.0, 1.0>
	vector	bgColor = <0.16, 0.16, 0.16>

	string tooltipTitle	 = ""
	string tooltipBody   = ""
}

global struct RankedPromoTrial
{
	bool active
	string description
	int statGoal
	int statCurrent
	vector progressBarColor
}

global struct RankedProgressBarTweenData
{
	int minRankScore
	int maxRankScore
	int startScore
	int endScore

	float progressFracStart
	float progressFracEnd

	bool isDoubleBadge = false
	bool hasPromoTrialAtEnd = false
	asset promoTrialCapImage

	RTKRankedBadgeModel& badge1
	RTKRankedBadgeModel& badge2

	
	int adjustedMinRankScore
	int adjustedMaxRankScore
	int adjustedStartScore
	int adjustedEndScore
}

global struct RankedProgressBarData
{
	int startScore
	int endScore
	int totalRanks

	int currentTweenIndex = 0
	RankedProgressBarTweenData& currentTween
	array< RankedProgressBarTweenData > tweens = []
}

global struct PromoTrialsData
{
	bool hasTrial = false

	int trialsAttempts = 0
	int maxTrialsAttempts = 1
	int trialsCount = 0
	array< RankedPromoTrial > trials = []
	string trialsInfoString = ""

	vector trialsStatusColor = <1, 1, 1>
	vector trialsStatusBannerColor = <1, 1, 1>
	float trialsStatusBannerAlpha = 0.0
	string trialsStatusMessage = ""
}

global struct RankedMatchSummaryExtraInfo
{
	int entryCost = 0
	int totalBonus = 0
	array< BonusBreakdownInfo > breakdownBonuses = []
	array< ConditionalElement > conditionals = []
	array< BonusBreakdownInfo > stats = []

	RankedProgressBarData& progressData

	string lastPlayedTime = "0m"
	string lastGameMode = ""

	PromoTrialsData& trialsData
}

global struct RankedMatchSummaryScreenData
{
	bool isProgressPanelVisible = true
	bool isRankUpAnimationInProgress = false

	vector themeColor = <1, 1, 1>
	vector titleTextColor = <1, 1, 1>
}

struct PrivateData
{
	rtk_struct rankedMatchSummaryModel
	rtk_struct rankedMatchSummaryScreenDataModel
	rtk_struct summaryBreakdownModel
	rtk_struct summaryExtraInfoModel
	rtk_struct progressModel

	bool isFirstTime = false
	int numRanksEarned = 0
	int scoreStart = 0
	int scoreEnd = 0
	int ladderPosition
	bool hasLPBarAnimationStarted = false
	bool callbacksRegistered = false
}

const string POSTGAME_XP_INCREASE = "UI_Menu_MatchSummary_Ranked_XPBar_Increase"
const string POSTGAME_RANKED_MENU_NAME = "PostGameRankedMenu"

void function RTKRankedMatchSummary_InitMetaData( string behaviorType, string structType )
{
	RTKMetaData_SetAllowedBehaviorTypes( structType, "progressBarAnimator", [ "Animator" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "tweenStagger", [ "TweenStagger" ] )
}

void function RTKRankedMatchSummary_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	SetContinueButtonRegistration( self, true )

	p.isFirstTime = GetPersistentVarAsInt( "showGameSummary" ) != 0

	BuildRankedMatchSummaryDataModel( self )
	BuildRankedBadgeDataModel( self )

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "ranked", true, [ "postGame" ] ) )

	
	if ( p.isFirstTime )
	{
		rtk_behavior ornull tweenStagger = self.PropGetBehavior( "tweenStagger" )
		if ( tweenStagger != null )
		{
			expect rtk_behavior( tweenStagger )
			tweenStagger.SetActive( true )
			self.AutoSubscribe( tweenStagger, "onFinish", function () : ( self ) {
				rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )
				if ( barAnimator != null )
				{
					expect rtk_behavior( barAnimator )
					if ( !RTKAnimator_IsPlaying( barAnimator ) )
					{
						AnimateRankedProgressBar( self )
					}
				}
			} )
		}
	}
	else 
	{
		AnimateRankedProgressBar( self )
	}
}

void function RTKRankedMatchSummary_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "ranked", ["postGame"] )
	SetContinueButtonRegistration( self, false )
}

void function BuildRankedMatchSummaryDataModel( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	p.rankedMatchSummaryModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "ranked", "", [ "postGame" ] )

	entity player = GetLocalClientPlayer()

	RankLadderPointsBreakdown scoreBreakdown
	LoadLPBreakdownFromPersistance ( scoreBreakdown, player )

	RankedMatchSummaryExtraInfo extraInfo

	extraInfo.entryCost = ( GetConVarBool( "ranked_disable_point_gain" ) ) ? 0 : -1 * Ranked_GetCostForEntry()
	extraInfo.totalBonus = 0

	int elapsedTime = GetUnixTimestamp() - GetPersistentVarAsInt( "lastGameTime" )
	extraInfo.lastPlayedTime = GetFormattedIntByType( elapsedTime, eNumericDisplayType.TIME_MINUTES_LONG )

	string lastGameMode = expect string( GetPersistentVar( "lastGameMode" ) )
	extraInfo.lastGameMode = lastGameMode

	
	scoreBreakdown.placementScore = scoreBreakdown.placementScore + extraInfo.entryCost

	
	
	if (scoreBreakdown.highEndAdjustment < 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_HIGHEND_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.highEndAdjustment
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_HIGHEND_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_HIGHEND_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= false 
		extraInfo.totalBonus				+= scoreBreakdown.highEndAdjustment
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	if (scoreBreakdown.killBonus > 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_ELIMINATION_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.killBonus
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_ELIMINATION_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_ELIMINATION_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= scoreBreakdown.wasAbandoned
		extraInfo.totalBonus				+= scoreBreakdown.killBonus
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	if (scoreBreakdown.convergenceBonus > 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_RATING_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.convergenceBonus
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_RATING_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_RATING_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= scoreBreakdown.wasAbandoned
		extraInfo.totalBonus				+= scoreBreakdown.convergenceBonus
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	if (scoreBreakdown.skillDiffBonus > 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_SKILL_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.skillDiffBonus
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_SKILL_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_SKILL_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= scoreBreakdown.wasAbandoned
		extraInfo.totalBonus				+= scoreBreakdown.skillDiffBonus
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	if (scoreBreakdown.provisionalMatchBonus > 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_PROVISIONAL_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.provisionalMatchBonus
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_PROVISIONAL_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_PROVISIONAL_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= scoreBreakdown.wasAbandoned
		extraInfo.totalBonus				+= scoreBreakdown.provisionalMatchBonus
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	if (scoreBreakdown.promotionBonus > 0)
	{
		BonusBreakdownInfo tempBonusBreakdownInfo
		tempBonusBreakdownInfo.bonusName	= "#RANKED_TIER_PROMOTION_BONUS"
		tempBonusBreakdownInfo.bonusValue	= scoreBreakdown.promotionBonus
		tempBonusBreakdownInfo.tooltipTitle = "#RANKED_TIER_PROMOTION_BONUS"
		tempBonusBreakdownInfo.tooltipBody  = "#RANKED_TIER_PROMOTION_BONUS_DESC"
		tempBonusBreakdownInfo.crossOut		= scoreBreakdown.wasAbandoned
		extraInfo.totalBonus				+= scoreBreakdown.promotionBonus
		extraInfo.breakdownBonuses.push(tempBonusBreakdownInfo)
	}

	
	int altBgOffset = IsOdd( extraInfo.breakdownBonuses.len() ) ? 1 : 0

	
	if (scoreBreakdown.penaltyPointsForAbandoning > 0)
	{
		ConditionalElement tempCondEle
		tempCondEle.stringL	= "#RANKED_ABANDON_PENALTY"
		tempCondEle.stringR	= scoreBreakdown.penaltyPointsForAbandoning * -1
		tempCondEle.colorL	= <1, 0.26, 0.26>
		tempCondEle.colorR	= <1, 0.26, 0.26>
		tempCondEle.alternatingBGOffset = altBgOffset
		tempCondEle.tooltipTitle = "#RANKED_ABANDON_PENALTY"
		tempCondEle.tooltipBody  = "#RANKED_ABANDON_PENALTY_DESC"
		extraInfo.conditionals.push(tempCondEle)
	}

	if (scoreBreakdown.lossProtectionAdjustment > 0)
	{
		ConditionalElement tempCondEle
		tempCondEle.stringL	= "#RANKED_LOSS_FORGIVENESS"
		tempCondEle.stringR	= scoreBreakdown.lossProtectionAdjustment
		tempCondEle.alternatingBGOffset = altBgOffset
		tempCondEle.tooltipTitle = "#RANKED_LOSS_FORGIVENESS"
		tempCondEle.tooltipBody  = "#RANKED_LOSS_FORGIVENESS_DESC"
		extraInfo.conditionals.push(tempCondEle)
	}

	if (scoreBreakdown.demotionPenality > 0)
	{
		ConditionalElement tempCondEle
		tempCondEle.stringL	= "#RANKED_TIER_DERANKING"
		tempCondEle.stringR	= scoreBreakdown.demotionPenality * -1
		tempCondEle.colorL	= <1, 0.26, 0.26>
		tempCondEle.colorR	= <1, 0.26, 0.26>
		tempCondEle.alternatingBGOffset = altBgOffset
		tempCondEle.tooltipTitle = "#RANKED_TIER_DERANKING"
		tempCondEle.tooltipBody  = "#RANKED_TIER_DERANKING_DESC"
		extraInfo.conditionals.push(tempCondEle)
	}

	if (scoreBreakdown.demotionProtectionAdjustment > 0)
	{
		ConditionalElement tempCondEle
		tempCondEle.stringL	= "#RANKED_DEMOTION_PROTECTION_LINE2"
		tempCondEle.stringR	= scoreBreakdown.demotionProtectionAdjustment
		tempCondEle.tooltipTitle = "#RANKED_DEMOTION_PROTECTION_LINE2"
		tempCondEle.tooltipBody  = "#RANKED_DEMOTION_PROTECTION_DESC"
		tempCondEle.alternatingBGOffset = altBgOffset
		extraInfo.conditionals.push(tempCondEle)
	}

	BonusBreakdownInfo kills
	kills.bonusName = "#SCOREBOARD_KILLS"
	kills.bonusValue = scoreBreakdown.kills
	kills.tooltipTitle = "#SCOREBOARD_KILLS"
	kills.tooltipBody = "#SCOREBOARD_KILLS_DESC"
	extraInfo.stats.push(kills)

	BonusBreakdownInfo assists
	assists.bonusName = "#SCOREBOARD_ASSISTS"
	assists.bonusValue = scoreBreakdown.assists
	assists.tooltipTitle = "#SCOREBOARD_ASSISTS"
	assists.tooltipBody = "#SCOREBOARD_ASSISTS_DESC"
	extraInfo.stats.push(assists)

	BonusBreakdownInfo participations
	participations.bonusName = "#SCOREBOARD_PARTICIPATION"
	participations.bonusValue = scoreBreakdown.participationUnique
	participations.tooltipTitle = "#SCOREBOARD_PARTICIPATION"
	participations.tooltipBody = "#SCOREBOARD_PARTICIPATION_DESC"
	extraInfo.stats.push(participations)


		
		extraInfo.trialsData.trials.clear()

		int trialState = RankedTrials_GetTrialState( player )
		extraInfo.trialsData.hasTrial = RankedTrials_PlayerHasAssignedTrial( player )

		if ( extraInfo.trialsData.hasTrial )
		{
			
			ItemFlavor currentTrial = RankedTrials_GetAssignedTrial( player )

			extraInfo.trialsData.trialsAttempts = RankedTrials_GetGamesPlayedInTrialsState( player )
			extraInfo.trialsData.maxTrialsAttempts = RankedTrials_GetGamesAllowedInTrialsState( player, currentTrial )

			
			int trialsCount = RankedTrials_GetTrialsCountForTrial( currentTrial )
			extraInfo.trialsData.trialsCount = trialsCount

			
			foreach ( int statIdx in eRankedTrialGoalIdx )
			{
				RankedPromoTrial trial

				if ( trialsCount > statIdx )
				{
					trial.active	  		= true
					string unlocalizedDesc 	= RankedTrials_GetDescription( currentTrial, statIdx )

					bool usesComboStats 	= statIdx > eRankedTrialGoalIdx.PRIMARY && RankedTrials_SecondaryTrialRequiresSingleMatchPerformance( currentTrial )
					trial.statGoal 			= usesComboStats ? RankedTrials_GetSecondaryTrialSingleMatchComboCount( currentTrial ) : RankedTrials_GetTrialStatGoalByIndex( currentTrial, statIdx )
					trial.statCurrent 		= usesComboStats ? RankedTrials_GetSecondaryStatMatchComboStatProgress( player ) : RankedTrials_GetProgressValueForStatByIndex( player, statIdx )
					trial.description 		= Localize( unlocalizedDesc, trial.statGoal )

					
					if ( usesComboStats )
					{
						int statOne 		= RankedTrials_GetTrialStatGoalByIndex( currentTrial, eRankedTrialGoalIdx.SECONDARY_ONE )
						int statTwo 		= RankedTrials_GetTrialStatGoalByIndex( currentTrial, eRankedTrialGoalIdx.SECONDARY_TWO )
						trial.description 	= Localize( unlocalizedDesc, statOne, statTwo )
					}

					
					
					SharedRankedDivisionData ornull nextRank 		= GetNextRankedDivisionFromScore( scoreBreakdown.finalLP )
					if ( trialState != eRankedTrialState.SUCCESS && nextRank != null )
					{
						expect SharedRankedDivisionData( nextRank )
						vector rankColor 							= GetKeyColor( COLORID_RANKED_BORDER_COLOR_ROOKIE, nextRank.tier.index ) / 255
						trial.progressBarColor 						= rankColor
					}
					else
					{
						int ladderPosition                   		= Ranked_GetLadderPosition( player  )
						SharedRankedDivisionData currentRank 		= GetCurrentRankedDivisionFromScoreAndLadderPosition( scoreBreakdown.finalLP, ladderPosition )
						vector rankColor 							= GetKeyColor( COLORID_RANKED_BORDER_COLOR_ROOKIE, currentRank.tier.index ) / 255
						trial.progressBarColor 						= rankColor
					}
				}
				else
				{
					trial.active	  = false
					trial.description = ""
					trial.statCurrent = 0
					trial.statGoal 	  = 1
					trial.progressBarColor = GetKeyColor( COLORID_RANKED_BORDER_COLOR_ROOKIE ) / 255
				}

				extraInfo.trialsData.trials.push( trial )
			}

			
			switch ( trialState )
			{
				case eRankedTrialState.INCOMPLETE:
					int attemptsRemaining = extraInfo.trialsData.maxTrialsAttempts - extraInfo.trialsData.trialsAttempts
					extraInfo.trialsData.trialsInfoString = Localize( "#RANKED_PROMOTION_ATTEMPTS_REMAINING", attemptsRemaining )
					extraInfo.trialsData.trialsStatusColor = <0.7, 0.7, 0.7>
					extraInfo.trialsData.trialsStatusBannerColor =  <0.7, 0.7, 0.7>
					extraInfo.trialsData.trialsStatusBannerAlpha =  0.0
					extraInfo.trialsData.trialsStatusMessage = Localize( "#X/Y_STYLED", extraInfo.trialsData.trialsAttempts, extraInfo.trialsData.maxTrialsAttempts )
					break
				case eRankedTrialState.SUCCESS:
					extraInfo.trialsData.trialsInfoString = Localize( "#RANKED_PROMOTION_SUCCESS_DESCRIPTION", scoreBreakdown.promotionBonus )
					extraInfo.trialsData.trialsStatusColor = <1, 0.86, 0.24>
					extraInfo.trialsData.trialsStatusBannerColor = <1, 0.86, 0.24>
					extraInfo.trialsData.trialsStatusBannerAlpha = 0.25
					extraInfo.trialsData.trialsStatusMessage = Localize( "#RANKED_PROMOTION_SUCCESS" )
					break
				case eRankedTrialState.FAILURE:
					int lpToRetry = 0
					extraInfo.trialsData.trialsInfoString = ""
					int currentScore                     		= scoreBreakdown.finalLP
					SharedRankedDivisionData ornull nextRank 	= GetNextRankedDivisionFromScore( currentScore )
					if ( nextRank != null )
					{
						expect SharedRankedDivisionData( nextRank )
						lpToRetry = nextRank.scoreMin - currentScore
						if ( lpToRetry > 0 )
						{
							extraInfo.trialsData.trialsInfoString = Localize( "#RANKED_PROMOTION_FAILED_DESCRIPTION", lpToRetry )
						}
					}
					extraInfo.trialsData.trialsStatusColor = <1, 0.18, 0.05>
					extraInfo.trialsData.trialsStatusBannerColor = <0.5, 0.07, 0.01>
					extraInfo.trialsData.trialsStatusBannerAlpha = 0.65
					extraInfo.trialsData.trialsStatusMessage = Localize( "#RANKED_PROMOTION_FAILED" )
					break
				case eRankedTrialState.NOT_IN_TRIAL:
				default:
					extraInfo.trialsData.trialsInfoString = ""
					break;
			}
		}
		else
		{
			
			foreach ( int statIdx in eRankedTrialGoalIdx )
			{
				RankedPromoTrial trial
				trial.active = false
				trial.description = ""
				trial.statGoal = 1
				trial.statCurrent = 0
				extraInfo.trialsData.trials.push( trial )
			}
		}














	foreach(int index, conditional in extraInfo.conditionals)
	{
		if ( index % 2 == 0 )
			conditional.bgColor = <0.16, 0.16, 0.16>
		else
			conditional.bgColor = <0.35, 0.35, 0.35>
	}

	
	RankedMatchSummaryScreenData screenData

	
	screenData.isProgressPanelVisible = !p.isFirstTime
	screenData.isRankUpAnimationInProgress = false

	SeasonStyleData seasonStyle = GetSeasonStyle()
	screenData.titleTextColor = seasonStyle.titleTextColor
	screenData.themeColor = seasonStyle.seasonColor

	
	p.rankedMatchSummaryScreenDataModel = RTKStruct_GetOrCreateScriptStruct( p.rankedMatchSummaryModel, "screen", "RankedMatchSummaryScreenData" )
	p.summaryBreakdownModel = RTKStruct_GetOrCreateScriptStruct( p.rankedMatchSummaryModel, "breakdown", "RankLadderPointsBreakdown" )
	p.summaryExtraInfoModel = RTKStruct_GetOrCreateScriptStruct( p.rankedMatchSummaryModel, "extraInfo", "RankedMatchSummaryExtraInfo" )

	RTKStruct_SetValue( p.rankedMatchSummaryScreenDataModel, screenData )
	RTKStruct_SetValue( p.summaryBreakdownModel, scoreBreakdown )
	RTKStruct_SetValue( p.summaryExtraInfoModel,  extraInfo )
}

void function BuildRankedBadgeDataModel( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	p.progressModel 							= RTKStruct_GetOrCreateScriptStruct( p.summaryExtraInfoModel, "progressData", "RankedProgressBarData" )
	RankedProgressBarData progressData
	PromoTrialsData trialsData

	entity player 						 		= GetLocalClientPlayer()
	bool inProvisionals					 		= !Ranked_HasCompletedProvisionalMatches( player )
	int currentScore                     		= RTKStruct_GetInt( p.summaryBreakdownModel, "finalLP" ) 
	int previousScore 							= RTKStruct_GetInt( p.summaryBreakdownModel, "startingLP" )
	int ladderPosition                   		= Ranked_GetLadderPosition( player  )
	SharedRankedDivisionData currentRank 		= GetCurrentRankedDivisionFromScoreAndLadderPosition( currentScore, ladderPosition )
	SharedRankedDivisionData ornull nextRank 	= GetNextRankedDivisionFromScore( currentScore )
	SharedRankedDivisionData previousRank 		= GetCurrentRankedDivisionFromScore( previousScore )

	p.numRanksEarned 							= ( currentRank.index - previousRank.index )
	p.scoreStart 								= previousScore
	p.scoreEnd									= currentScore
	p.ladderPosition							= ladderPosition

	if ( ( p.numRanksEarned > 0 ) && currentRank.isLadderOnlyDivision ) 
	{
		if( !(GetNextRankedDivisionFromScore( previousScore ) == null) ) 
			p.numRanksEarned = 2 
	}

	bool useProvisionalBadgeAsset 				= inProvisionals

	
	progressData.startScore 					= previousScore
	progressData.endScore 						= currentScore
	progressData.totalRanks 					= p.numRanksEarned
	progressData.currentTweenIndex 				= 0

	int currentAnimScore = previousScore
	for ( int i = 0; i <= abs( p.numRanksEarned ); i++ )
	{
		RankedProgressBarTweenData tween

		SharedRankedDivisionData thisDivision 	= GetCurrentRankedDivisionFromScoreAndLadderPosition( currentAnimScore, ladderPosition )
		SharedRankedDivisionData ornull nextDivision = GetNextRankedDivisionFromScore( currentAnimScore )

		tween.isDoubleBadge 					= !inProvisionals && !thisDivision.isLadderOnlyDivision && nextDivision != null

			bool hasPromoTrial				 	= RankedTrials_PlayerHasIncompleteTrial( player )
			tween.isDoubleBadge 				= !inProvisionals && !thisDivision.isLadderOnlyDivision && nextDivision != null && !hasPromoTrial
			useProvisionalBadgeAsset			= inProvisionals || hasPromoTrial

			if ( nextDivision != null )
			{
				expect SharedRankedDivisionData( nextDivision )
				tween.hasPromoTrialAtEnd = RankedTrials_NextRankHasTrial( thisDivision, nextDivision ) && !RankedTrials_IsKillswitchEnabled()
				tween.promoTrialCapImage = nextDivision.tier.promotionalMetallicImage
			}


		tween.badge1.divisionName				= thisDivision.divisionName
		tween.badge1.rankColor					= GetKeyColor( COLORID_RANKED_BORDER_COLOR_ROOKIE, thisDivision.tier.index ) / 255
		tween.badge1.badgeRuiAsset 				= useProvisionalBadgeAsset ? RANKED_PLACEMENT_BADGE : thisDivision.tier.iconRuiAsset
		tween.badge1.rankedIcon 				= string( thisDivision.tier.icon )
		tween.badge1.emblemDisplayMode 			= thisDivision.emblemDisplayMode

		
		tween.badge1.isLadderOnlyRank			= thisDivision.isLadderOnlyDivision || thisDivision.emblemDisplayMode == emblemDisplayMode.DISPLAY_LADDER_POSITION || thisDivision.emblemDisplayMode == emblemDisplayMode.DISPLAY_RP

		switch ( thisDivision.emblemDisplayMode )
		{
			case emblemDisplayMode.DISPLAY_DIVISION:
				tween.badge1.emblemText 		= thisDivision.emblemText
				break
			case emblemDisplayMode.DISPLAY_RP:
				string rankScoreShortened 		= FormatAndLocalizeNumber( "1", float( currentScore ), IsTenThousandOrMore( currentScore ) )
				tween.badge1.emblemText 		= Localize( "#RANKED_POINTS_GENERIC", rankScoreShortened )
				break
			case emblemDisplayMode.DISPLAY_LADDER_POSITION:
				string ladderPosShortened
				if ( ladderPosition == SHARED_RANKED_INVALID_LADDER_POSITION )
					ladderPosShortened 			= ""
				else
					ladderPosShortened 			= Localize( "#RANKED_LADDER_POSITION_DISPLAY", FormatAndLocalizeNumber( "1", float( ladderPosition ), IsTenThousandOrMore( ladderPosition ) ) )
				tween.badge1.emblemText 		= ladderPosShortened
				break;
			case emblemDisplayMode.NONE:
			default:
				tween.badge1.emblemText			= ""
				break;
		}

		tween.badge1.ladderPosition 			= ladderPosition
		tween.badge1.rankScore 					= currentScore

		
		tween.badge1.badgeLabel					= useProvisionalBadgeAsset ? "" : tween.badge1.emblemText

		bool isPlacementMode 					= inProvisionals
		bool useDynamicPips						= false

			isPlacementMode 					= inProvisionals || hasPromoTrial
			tween.badge1.isPromotional			= hasPromoTrial
			useDynamicPips 						= !inProvisionals && hasPromoTrial

		tween.badge1.isPlacementMode 			= isPlacementMode

		int badge1MatchesCompleted 				= 0
		int badge1MaxMatches 					= 10
		if ( inProvisionals )
		{
			badge1MatchesCompleted 				= Ranked_GetNumProvisionalMatchesCompleted( player )
		}

		else if ( hasPromoTrial )
		{
			ItemFlavor currentTrial 			= RankedTrials_GetAssignedTrial( player )
			badge1MatchesCompleted 				= RankedTrials_GetGamesPlayedInTrialsState( player )
			badge1MaxMatches 					= RankedTrials_GetGamesAllowedInTrialsState( player, currentTrial )
		}


		tween.badge1.completedMatches 			= badge1MatchesCompleted
		tween.badge1.maxMatches 				= badge1MaxMatches
		tween.badge1.useDynamicPips				= useDynamicPips
		tween.badge1.startPip 					= 0

		if ( inProvisionals )
		{
			for ( int idx = 0; idx < badge1MatchesCompleted; idx++ )
			{
				tween.badge1.wonMatches.push( true )
			}
		}

		if ( tween.isDoubleBadge )
		{
			expect SharedRankedDivisionData( nextDivision )
			tween.badge2.divisionName			= nextDivision.divisionName
			tween.badge2.rankColor				= GetKeyColor( COLORID_RANKED_BORDER_COLOR_ROOKIE, nextDivision.tier.index ) / 255
			tween.badge2.badgeRuiAsset 			= inProvisionals ? RANKED_PLACEMENT_BADGE : nextDivision.tier.iconRuiAsset
			tween.badge2.rankedIcon 			= string( nextDivision.tier.icon )
			tween.badge2.emblemDisplayMode 		= nextDivision.emblemDisplayMode
			
			tween.badge2.isLadderOnlyRank		= nextDivision.isLadderOnlyDivision || nextDivision.emblemDisplayMode == emblemDisplayMode.DISPLAY_LADDER_POSITION || nextDivision.emblemDisplayMode == emblemDisplayMode.DISPLAY_RP
			tween.badge2.emblemText 			= ""

			switch ( nextDivision.emblemDisplayMode )
			{
				case emblemDisplayMode.DISPLAY_DIVISION:
					tween.badge2.emblemText = nextDivision.emblemText
					break

				case emblemDisplayMode.DISPLAY_RP:
					string rankScoreShortened = FormatAndLocalizeNumber( "1", float( currentScore ), IsTenThousandOrMore( currentScore ) )
					tween.badge2.emblemText = Localize( "#RANKED_POINTS_GENERIC", rankScoreShortened )
					break

				case emblemDisplayMode.DISPLAY_LADDER_POSITION:
					string ladderPosShortened
					if ( ladderPosition == SHARED_RANKED_INVALID_LADDER_POSITION )
						ladderPosShortened = ""
					else
						ladderPosShortened = Localize( "#RANKED_LADDER_POSITION_DISPLAY", FormatAndLocalizeNumber( "1", float( ladderPosition ), IsTenThousandOrMore( ladderPosition ) ) )
					tween.badge2.emblemText = ladderPosShortened
					break;

				case emblemDisplayMode.NONE:
				default:
					tween.badge2.emblemText = ""
					break;
			}

			
			tween.badge2.badgeLabel				= useProvisionalBadgeAsset ? "" : tween.badge2.emblemText
			tween.badge2.ladderPosition 		= ladderPosition
			tween.badge2.rankScore 				= currentScore
			tween.badge2.isPlacementMode 		= inProvisionals
			int badge2matchesCompleted 			= Ranked_GetNumProvisionalMatchesCompleted( player )
			tween.badge2.completedMatches 		= badge2matchesCompleted
			tween.badge2.useDynamicPips			= false
			tween.badge2.startPip 				= 0
		}

		if ( nextDivision != null)
		{
			expect SharedRankedDivisionData( nextDivision )
			tween.minRankScore = thisDivision.scoreMin
			tween.maxRankScore = nextDivision.scoreMin

			tween.startScore = currentAnimScore

			if ( currentScore > previousScore )
				tween.endScore = minint( currentScore, nextDivision.scoreMin )
			else
				tween.endScore = maxint( currentScore, thisDivision.scoreMin )

			tween.progressFracStart = float( tween.startScore - tween.minRankScore ) / float( tween.maxRankScore - tween.minRankScore )
			tween.progressFracEnd = float( tween.endScore - tween.minRankScore ) / float( tween.maxRankScore - tween.minRankScore )

			
			tween.adjustedMinRankScore = 0
			tween.adjustedMaxRankScore = tween.maxRankScore - tween.minRankScore
			tween.adjustedStartScore = tween.startScore - tween.minRankScore
			tween.adjustedEndScore = tween.endScore - tween.minRankScore
		}
		else
		{
			tween.minRankScore = thisDivision.scoreMin
			tween.endScore = currentScore

			tween.adjustedMinRankScore = 0
			tween.adjustedEndScore = tween.endScore - tween.minRankScore
		}

		
		
		currentAnimScore = ( p.numRanksEarned > 0 ) ? tween.endScore : tween.endScore - 1

		
		progressData.tweens.push( tween )
	}

	progressData.currentTween 					= progressData.tweens[0]

	RTKStruct_SetValue( p.progressModel, progressData )
}

void function AnimateRankedProgressBar( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	
	
	if ( p.hasLPBarAnimationStarted )
		return

	p.hasLPBarAnimationStarted = true

	entity player 			= GetLocalClientPlayer()
	bool inProvisionals 	= !Ranked_HasCompletedProvisionalMatches( player )
	bool animateProgressBar = !inProvisionals && p.isFirstTime

		bool hasPromoTrial	= RankedTrials_PlayerHasIncompleteTrial( player )
		animateProgressBar  = !inProvisionals && p.isFirstTime && !hasPromoTrial


	
	RTKStruct_SetBool( p.rankedMatchSummaryScreenDataModel, "isProgressPanelVisible", true )

	
	rtk_behavior ornull barAnimator = self.PropGetBehavior( "progressBarAnimator" )
	if ( barAnimator == null )
		return

	expect rtk_behavior( barAnimator )

	
	if ( animateProgressBar )
	{
		
		RTKStruct_SetInt( p.progressModel, "currentTweenIndex", 0 )

		
		RTKRankedMatchSummary_UpdateTweenDataModel( self )

		
		self.AutoSubscribe( barAnimator, "onAnimationFinished", function ( rtk_behavior barAnimator, string animName ) : ( self, inProvisionals ) {
			StopUISoundByName( POSTGAME_XP_INCREASE )
			if ( !RTKAnimator_IsPlaying( barAnimator ) )
			{
				if ( RTKRankedMatchSummary_UpdateTweenDataModel( self, true ) )
				{
					RTKAnimator_PlayAnimation( barAnimator, "AnimateBar" )
				}
				else
				{
					PrivateData p
					self.Private( p )

					bool hasProgressedOutOfProvisional = false

						hasProgressedOutOfProvisional = Ranked_GetXProgMergedPersistenceData( GetLocalClientPlayer(), RANKED_PROVISIONAL_MATCH_HAS_PROGRESSED_OUT_PERSISTENCE_VAR_NAME ) != 0




					bool isProvisionalGraduation = ( !inProvisionals && !hasProgressedOutOfProvisional )

					if ( p.numRanksEarned > 0 || isProvisionalGraduation )
					{
						thread StartRankUpAnimation( self, isProvisionalGraduation )
					}
					else if ( p.numRanksEarned < 0 )
					{
						PlayLobbyCharacterDialogue( "glad_rankDown"  )
					}
				}
			}
		} )

		self.AutoSubscribe( barAnimator, "onAnimationStarted", function ( rtk_behavior animator, string animName ) : ( ) {
			EmitUISound( POSTGAME_XP_INCREASE )
		} )

		
		RTKAnimator_PlayAnimation( barAnimator, "AnimateBar" )
	}
	else 
	{
		rtk_array tweens = RTKStruct_GetArray( p.progressModel, "tweens" )
		int tweensCount = RTKArray_GetCount( tweens )
		RTKStruct_SetInt( p.progressModel, "currentTweenIndex", tweensCount - 1 )
		RTKRankedMatchSummary_UpdateTweenDataModel( self )
	}
}

void function StartRankUpAnimation( rtk_behavior self, bool isProvisionalGraduation = false )
{
	PrivateData p
	self.Private( p )

	
	OnThreadEnd(
		function() : ( self )
		{
			if ( self == null )
				return

			PrivateData p
			self.Private( p )

			RTKStruct_SetBool( p.rankedMatchSummaryScreenDataModel, "isRankUpAnimationInProgress", false )
			SetContinueButtonRegistration( self, true )
		}
	)

	
	EndSignal( uiGlobal.signalDummy, "OnPostGameRankedMenu_Close" )

	
	SetContinueButtonRegistration( self, false )
	RTKStruct_SetBool( p.rankedMatchSummaryScreenDataModel, "isRankUpAnimationInProgress", true )

	
	wait 0.1
	RankUpAnimation( p.numRanksEarned, p.scoreStart, p.ladderPosition, p.scoreEnd, isProvisionalGraduation )
	wait 0.1
}

bool function RTKRankedMatchSummary_UpdateTweenDataModel( rtk_behavior self, bool incrementTween = false )
{
	PrivateData p
	self.Private( p )

	
	int currentTweenIndex = RTKStruct_GetInt( p.progressModel, "currentTweenIndex" )

	if ( incrementTween )
		currentTweenIndex++

	rtk_array tweens = RTKStruct_GetArray( p.progressModel, "tweens" )
	int tweensCount = RTKArray_GetCount( tweens )

	if ( currentTweenIndex < tweensCount )
	{
		rtk_struct tween = RTKArray_GetStruct( tweens, currentTweenIndex )
		RTKStruct_SetStruct( p.progressModel, "currentTween", tween )
		RTKStruct_SetInt( p.progressModel, "currentTweenIndex", currentTweenIndex )
		return true
	}

	return false
}

void function SetContinueButtonRegistration( rtk_behavior self, bool register )
{
	PrivateData p
	self.Private( p )

	if ( register )
	{
		if ( !p.callbacksRegistered )
		{
			RegisterButtonPressedCallback( KEY_ESCAPE, OnContinueButton_Activated )
			RegisterButtonPressedCallback( KEY_SPACE, OnContinueButton_Activated )
			RegisterButtonPressedCallback( BUTTON_A, OnContinueButton_Activated )
			RegisterButtonPressedCallback( BUTTON_B, OnContinueButton_Activated )
			p.callbacksRegistered = true
		}
	}
	else
	{
		if ( p.callbacksRegistered )
		{
			DeregisterButtonPressedCallback( KEY_ESCAPE, OnContinueButton_Activated )
			DeregisterButtonPressedCallback( KEY_SPACE, OnContinueButton_Activated )
			DeregisterButtonPressedCallback( BUTTON_A, OnContinueButton_Activated )
			DeregisterButtonPressedCallback( BUTTON_B, OnContinueButton_Activated )
			p.callbacksRegistered = false
		}
	}
}

void function OnContinueButton_Activated( var button )
{
	if ( GetActiveMenuName() == POSTGAME_RANKED_MENU_NAME )
		thread CloseActiveMenu()
}
