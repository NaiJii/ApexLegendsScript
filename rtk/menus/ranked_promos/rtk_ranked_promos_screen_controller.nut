global function RTKRankedPromotionTrials_InitMetaData
global function RTKRankedPromotionTrials_OnInitialize
global function RTKRankedPromotionTrials_OnEnable
global function RTKRankedPromotionTrials_OnDrawEnd
global function RTKRankedPromotionTrials_PopulateTrialsDataModel
global function RTKRankedPromotionTrials_ToggleExpander
global function RTKRankedPromotionTrials_OnDestroy

global struct RTKRankedPromotionTrials_Properties
{
	rtk_behavior expandButton
	rtk_behavior contentVerticalContainer
	rtk_panel trialsPanel
	rtk_panel containerPanel
}

global struct RTKRankedPromotionTrial
{
	bool active
	string description
	int statGoal
	int statCurrent
	vector progressBarColor
}

global struct RTKRankedPromotionTrialsData
{
	bool hasTrial

	int trialsAttempts
	int maxTrialsAttempts

	int trialsCount

	array<RTKRankedPromotionTrial> trials

	bool isExpanderEnabled
	bool isTrialPanelExpanded
}

struct PrivateData
{
	string rootCommonPath = ""
	rtk_struct rankedPromosStruct
	bool recalculateRootHeight = false
}

void function RTKRankedPromotionTrials_InitMetaData( string behaviorType, string structType )
{
	RTKMetaData_SetAllowedBehaviorTypes( structType, "expandButton", [ "Button" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "contentVerticalContainer", [ "VerticalContainer" ] )
}

void function RTKRankedPromotionTrials_OnInitialize ( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	
	rtk_struct rankedStruct = RTKDataModelType_CreateStruct( RTK_MODELTYPE_COMMON, "ranked" )
	p.rankedPromosStruct = RTKDataModelType_CreateStruct( RTK_MODELTYPE_COMMON, "promoTrials", "RTKRankedPromotionTrialsData",  [ "ranked" ] )
	rtk_array trialsModel = RTKStruct_GetArray( p.rankedPromosStruct, "trials" )

	if ( RTKArray_GetCount( trialsModel ) > 0 )
		RTKArray_Clear( trialsModel )

	foreach ( int statIdx in eRankedTrialGoalIdx )
	{
		rtk_struct trialStruct = RTKArray_PushNewStruct( trialsModel )

		
		RTKRankedPromotionTrial trialModel
		RTKStruct_GetValue( trialStruct, trialModel )

		
		trialModel.description = ""
		trialModel.statCurrent = 0
		trialModel.statGoal = 1
		trialModel.active = false
		trialModel.progressBarColor = <0.84, 0.84, 0.84>

		
		RTKStruct_SetValue( trialStruct, trialModel )
	}

	p.rootCommonPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_COMMON, "promoTrials", true, [ "ranked" ] )
	self.GetPanel().SetBindingRootPath( p.rootCommonPath )

	bool isSwitchPlatform = false
#if PC_PROG_NX_UI
		isSwitchPlatform = true
#endif

	RTKStruct_SetBool( p.rankedPromosStruct, "isExpanderEnabled", isSwitchPlatform )
	if ( isSwitchPlatform )
	{
		rtk_behavior ornull expandButton = self.PropGetBehavior( "expandButton" )
		if ( expandButton != null )
		{
			expect rtk_behavior( expandButton )
			self.AutoSubscribe( expandButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, p ) {
				EmitUISound( "ui_menu_accept" )
				RTKRankedPromotionTrials_ToggleExpander( self )
			} )
		}
	}
}

void function RTKRankedPromotionTrials_ToggleExpander( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	bool isExpanded = RTKStruct_GetBool( p.rankedPromosStruct, "isTrialPanelExpanded" )

	
	rtk_behavior ornull contentVerticalContainer = self.PropGetBehavior( "contentVerticalContainer" )
	if ( contentVerticalContainer != null )
	{
		expect rtk_behavior( contentVerticalContainer )

		contentVerticalContainer.PropSetBool( "fitContentHeight", !isExpanded )
	}

	
	rtk_panel ornull trialsPanel = self.PropGetPanel( "trialsPanel" )
	if ( trialsPanel != null )
	{
		expect rtk_panel( trialsPanel )
		trialsPanel.SetVisible( !isExpanded )
	}

	
	rtk_panel ornull containerPanel = self.PropGetPanel( "containerPanel" )
	if ( containerPanel != null )
	{
		expect rtk_panel( containerPanel )
		containerPanel.SetSizeDelta( !isExpanded ? <0, 0, 0> : <0, 55, 0> )
	}

	p.recalculateRootHeight = true

	
	RTKStruct_SetBool( p.rankedPromosStruct, "isTrialPanelExpanded", !isExpanded )
}

void function RTKRankedPromotionTrials_OnEnable ( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	RTKRankedPromotionTrials_PopulateTrialsDataModel( self )

	
	p.recalculateRootHeight = true
}

void function RTKRankedPromotionTrials_OnDrawEnd( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	if ( !p.recalculateRootHeight )
		return

	bool isExpanded = RTKStruct_GetBool( p.rankedPromosStruct, "isTrialPanelExpanded" )
	float height = -1.0

	
	rtk_panel ornull containerPanel = self.PropGetPanel( "containerPanel" )
	if ( containerPanel != null )
	{
		expect rtk_panel( containerPanel )
		height = containerPanel.GetHeight()
	}

	if ( height >= 0 )
	{
		
		var playPanel = GetPanel( "PlayPanel" )
		if ( playPanel != null && IsTabPanelActive( playPanel ) )
		{
			var trialsVguiPanel = Hud_GetChild( playPanel, "RTKRankedPromosTrials" )
			Hud_SetHeight( trialsVguiPanel, isExpanded ? height : 55.0 )
		}
	}

	p.recalculateRootHeight = false
}

void function RTKRankedPromotionTrials_PopulateTrialsDataModel ( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	
	entity player = GetLocalClientPlayer()
	int trialsAttempts = 0
	int maxAttempts = 0
	bool hasTrial = RankedTrials_PlayerHasIncompleteTrial( player )

	if ( hasTrial )
	{
		
		ItemFlavor currentTrial = RankedTrials_GetAssignedTrial( player )

		trialsAttempts = RankedTrials_GetGamesPlayedInTrialsState( player )
		maxAttempts = RankedTrials_GetGamesAllowedInTrialsState( player, currentTrial )

		
		int trialsCount = RankedTrials_GetTrialsCountForTrial( currentTrial )

		
		RTKStruct_SetBool( p.rankedPromosStruct, "hasTrial", hasTrial )
		RTKStruct_SetInt( p.rankedPromosStruct, "trialsAttempts", trialsAttempts )
		RTKStruct_SetInt( p.rankedPromosStruct, "maxTrialsAttempts", maxAttempts )
		RTKStruct_SetInt( p.rankedPromosStruct, "trialsCount", trialsCount )
		RTKStruct_SetBool( p.rankedPromosStruct, "isTrialPanelExpanded", true )

		
		foreach ( int statIdx in eRankedTrialGoalIdx )
		{
			rtk_array trialsModel = RTKStruct_GetArray( p.rankedPromosStruct, "trials" )
			rtk_struct trialStruct = RTKArray_GetStruct( trialsModel, statIdx )

			
			RTKRankedPromotionTrial trialModel
			RTKStruct_GetValue( trialStruct, trialModel )

			bool active = false
			string desc = ""
			int goalVal = 1
			int statVal = 0

			if ( trialsCount > statIdx )
			{
				
				bool usesComboStats 	= statIdx > eRankedTrialGoalIdx.PRIMARY && RankedTrials_SecondaryTrialRequiresSingleMatchPerformance( currentTrial )
				string unlocalizedDesc 	= RankedTrials_GetDescription( currentTrial, statIdx )
				goalVal 				= usesComboStats ? RankedTrials_GetSecondaryTrialSingleMatchComboCount( currentTrial ) : RankedTrials_GetTrialStatGoalByIndex( currentTrial, statIdx )
				statVal 				= usesComboStats ? RankedTrials_GetSecondaryStatMatchComboStatProgress( player ) : RankedTrials_GetProgressValueForStatByIndex( player, statIdx )
				desc 					= Localize( unlocalizedDesc, goalVal )

				
				if ( usesComboStats )
				{
					int statOne 		= RankedTrials_GetTrialStatGoalByIndex( currentTrial, eRankedTrialGoalIdx.SECONDARY_ONE )
					int statTwo 		= RankedTrials_GetTrialStatGoalByIndex( currentTrial, eRankedTrialGoalIdx.SECONDARY_TWO )
					desc 				= Localize( unlocalizedDesc, statOne, statTwo )
				}

				active = true
			}

			trialModel.active = active
			trialModel.description = desc
			trialModel.statGoal = goalVal
			trialModel.statCurrent = statVal

			
			RTKStruct_SetValue( trialStruct, trialModel )
		}
	}
}

void function RTKRankedPromotionTrials_OnDestroy ( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_COMMON, "promoTrials", ["ranked"] )
}
