global function RTKPostGameWeaponTrialCelebrations_OnInitialize
global function RTKPostGameWeaponTrialCelebrations_OnDestroy
#if DEV
global function DEV_TestWeaponTrialCelebrationSounds
#endif

global struct RTKPostGameWeaponTrialCelebrations_Properties
{
	rtk_behavior animator
	rtk_panel trialsList
	rtk_behavior trialsTweenStagger
	rtk_panel trialIconList
	rtk_panel trialsCompleteHeader
	rtk_panel celebrationWeaponIcons
	rtk_panel ultimateTrialsList
}

global struct RTKWeaponTrialCelebrationRuiArgs
{
	asset  weaponIcon
	string weaponName
	string weaponLevel
	float  startTime
}

global struct RTKWeaponTrialCelebrationHeaderData
{
	string weaponName
	string celebrationType
}

global struct RTKWeaponTrialWeaponIconData
{
	asset icon = $""
	string weaponName
}

struct PrivateData
{
	int                                              menuGUID = -1
	rtk_struct                                       postGameWeaponTrialCelebrationsModel
	array<MasteryWeapon_TrialStatusChangesPerWeapon> weaponTrialStatusChanges
	int                                              lastProcessedTrialIndex = -1
}

void function RTKPostGameWeaponTrialCelebrations_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	p.postGameWeaponTrialCelebrationsModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "postGameWeaponTrialCelebrations" )
	rtk_struct weaponModel  = RTKStruct_GetOrCreateEmptyStruct( p.postGameWeaponTrialCelebrationsModel, "weapon" )
	rtk_struct ruiArgsModel = RTKStruct_AddStructProperty( weaponModel, "ruiArgs", "RTKWeaponTrialCelebrationRuiArgs" )
	rtk_array trialsModel   = RTKStruct_AddArrayOfStructsProperty( p.postGameWeaponTrialCelebrationsModel, "trials", "MasteryWeapon_TrialQueryResult" )
	rtk_array allWeaponTrialsArray = RTKStruct_AddArrayOfStructsProperty( p.postGameWeaponTrialCelebrationsModel, "allWeaponsTrials", "MasteryWeapon_FinalRewardResult" )
	rtk_struct headerModel 	= RTKStruct_AddStructProperty( p.postGameWeaponTrialCelebrationsModel, "headerData", "RTKWeaponTrialCelebrationHeaderData" )
	rtk_array weaponIconsArray = RTKStruct_AddArrayOfStructsProperty( p.postGameWeaponTrialCelebrationsModel, "weaponIcons", "RTKWeaponTrialWeaponIconData" )

	
	array<ItemFlavor> allWeapons = GetAllWeaponItemFlavors()
	foreach (index, weapon in allWeapons)
	{
		rtk_struct weaponIconStruct = RTKArray_PushNewStruct( weaponIconsArray )
		RTKStruct_SetAssetPath( weaponIconStruct, "icon",  WeaponItemFlavor_GetHudIcon( weapon ) )
	}

	self.GetPanel().SetBindingRootPath( "&menus.postGameWeaponTrialCelebrations" )

	RTKPostGameWeaponTrialCelebrations_PresentCelebrations( self )

	int menuGUID = AssignMenuGUID()
	p.menuGUID = menuGUID
	
	RTKFooters_Add( menuGUID, CENTER, BUTTON_INVALID, "#A_BUTTON_CONTINUE", BUTTON_INVALID, "#A_BUTTON_CONTINUE", ClosePostGameWeaponTrialCelebrationsMenu )
	RTKFooters_Update()
}

void function RTKPostGameWeaponTrialCelebrations_PresentCelebrations( rtk_behavior self )
{
	rtk_behavior animator = self.PropGetBehavior( "animator" )
	string bgAnim         = "EnterScene"
	if ( RTKAnimator_HasAnimation( animator, bgAnim ) )
		RTKAnimator_PlayAnimation( animator, bgAnim )

	thread PresentCelebrationsThread( self )
}

void function PresentCelebrationsThread( rtk_behavior self )
{
	EndSignal( uiGlobal.signalDummy, "EndPostGameWeaponTrialCelebrations" )

	PrivateData p
	self.Private( p )

	p.weaponTrialStatusChanges        = Mastery_GetWeaponTrialStatusChanges() 
	rtk_behavior tweenStaggerBehavior = self.PropGetBehavior( "trialsTweenStagger" )
	Assert( tweenStaggerBehavior != null )

	bool hasHeaderCelebrationPlayed = false

	foreach ( entry in p.weaponTrialStatusChanges )
	{
		if (hasHeaderCelebrationPlayed)
		{
			ResetFinalTrialHeader( self )
			hasHeaderCelebrationPlayed = false
		}

		array<MasteryWeapon_TrialQueryResult> trialList
		int numTrialsToProcess = 0

		foreach ( trialStatusChange in entry.trialStatusChangeList )
		{
			trialList.append( trialStatusChange.state1 )

			if ( trialStatusChange.statusChange != eWeaponTrialStatusChangeType.NONE )
				numTrialsToProcess++
		}

		rtk_array trialsModel = RTKStruct_GetArray( p.postGameWeaponTrialCelebrationsModel, "trials" )
		RTKArray_SetValue( trialsModel, trialList )
		
		rtk_panel trialsListPanel = self.PropGetPanel( "trialsList" )
		while ( trialsListPanel.GetChildren().len() <= 0 )
			WaitFrame()

		array<rtk_panel> trialPanels = trialsListPanel.GetChildren()
		array<rtk_behavior> trialRenderGroups

		foreach ( trialIndex, trialStatusChange in entry.trialStatusChangeList )
		{
			rtk_behavior renderGroup = trialPanels[trialIndex].FindBehaviorByTypeName( "RenderGroup" )
			renderGroup.SetActive( trialStatusChange.state1.trialData.isUnlocked == false )
			trialRenderGroups.append( renderGroup )
		}

		RTKPostGameWeaponTrialCelebrations_InitWeaponTrialData( self, entry )

		foreach ( trialIndex, trialStatusChange in entry.trialStatusChangeList )
		{
			if ( trialStatusChange.statusChange == eWeaponTrialStatusChangeType.NONE )
				continue

			if ( p.lastProcessedTrialIndex == -1 )
			{
				trialsListPanel.SetPositionX( GetTrialsListXPositionForTrial( trialIndex ) )

				
				tweenStaggerBehavior.SetActive( false )
				float timeBetweenStaggerAnimStarts = 0.0669
				float staggerStartDelayBaseline = 1.35
				float staggerStartDelay = staggerStartDelayBaseline - (timeBetweenStaggerAnimStarts * trialIndex) 
				tweenStaggerBehavior.PropSetFloat( "startDelay", staggerStartDelay )
				tweenStaggerBehavior.SetActive( true )
				EmitUISound( "UI_Menu_WeaponMastery_CardBottomSlide" )

				float staggerAnimDuration = 0.2669
				float staggerCompletionDuration = (4 * timeBetweenStaggerAnimStarts) + staggerAnimDuration
				wait staggerStartDelay + staggerCompletionDuration
			}
			else
			{
				CenterTrial( self, trialIndex )
				wait 0.3337 
				trialRenderGroups[trialIndex].SetActive( false )
			}

			wait 0.4 
			AnimateTrialStatusChange( trialPanels[trialIndex], trialStatusChange.statusChange )
			wait 0.4667
			RTKArray_SetValueAt( trialsModel, trialIndex, trialStatusChange.state2 )

			p.lastProcessedTrialIndex = trialIndex
			numTrialsToProcess--
			if ( numTrialsToProcess > 0 )
				wait 1.2
		}

		
		MasteryWeapon_FinalRewardResult finalReward = expect MasteryWeapon_FinalRewardResult( Mastery_GetWeaponFinalReward( entry.weapon, 1 ) )
		if ( finalReward.isCompleted )
		{
			wait 2
			foreach ( renderGroup in trialRenderGroups )
				renderGroup.SetActive( true )

			waitthread AnimateFinalTrialCompleted( self, trialPanels, entry.weapon )
			hasHeaderCelebrationPlayed = true
		}

		wait 3.0
		p.lastProcessedTrialIndex = -1
	}

	
	array<MasteryWeapon_FinalRewardResult> allWeaponsTrials = [ Mastery_GetAllWeaponReward() ]
	if ( allWeaponsTrials[0].isCompleted )
	{
		ResetFinalTrialHeader( self )
		rtk_behavior animator = self.PropGetBehavior( "animator" )
		string animationName = "PrepForUltimateTrial"
		RTKAnimator_PlayAnimation( animator, animationName )
		EmitUISound( "UI_Menu_WeaponMastery_SingleWeapon_CardSlideOut" )
		wait 0.5

		waitthread AnimateUltimateTrialCompleted( self, allWeaponsTrials )
	}
}

void function ResetFinalTrialHeader( rtk_behavior self )
{
	rtk_panel header = self.PropGetPanel( "trialsCompleteHeader" )
	rtk_behavior animator = header.FindBehaviorByTypeName( "Animator" )
	string animationName = "Reset"
	RTKAnimator_PlayAnimation( animator, animationName )

	foreach ( trialIconPanel in self.PropGetPanel( "trialIconList" ).GetChildren() )
	{
		rtk_behavior iconAnimator = trialIconPanel.FindBehaviorByTypeName( "Animator" )
		string iconAnimation = "FadeOut"
		RTKAnimator_PlayAnimation( iconAnimator, iconAnimation )
	}
}


void function AnimateFinalTrialCompleted( rtk_behavior self, array<rtk_panel> trialPanels, ItemFlavor weapon )
{
	PrivateData p
	self.Private( p )

	
	EmitUISound( "UI_Menu_WeaponMastery_SingleWeapon_AllTrialsComplete" )

	
	rtk_struct headerDataModel = RTKStruct_GetStruct( p.postGameWeaponTrialCelebrationsModel, "headerData" )
	RTKWeaponTrialCelebrationHeaderData headerData
	headerData.weaponName = Localize( ItemFlavor_GetShortName( weapon ) )
	headerData.celebrationType = Localize( "#MASTERY_TRIALS_TRIALS_COMPLETE" )
	RTKStruct_SetValue( headerDataModel, headerData )

	
	foreach ( trialPanel in trialPanels)
	{
		trialPanel.FindBehaviorByTypeName( "RenderGroup" ).SetActive( true )
		rtk_behavior animator = trialPanel.FindBehaviorByTypeName( "Animator" )
		string animationName  = "ExitScene"

		RTKAnimator_PlayAnimation( animator, animationName )
	}
	wait 0.5

	
	rtk_panel header = self.PropGetPanel( "trialsCompleteHeader" )
	rtk_behavior animator = header.FindBehaviorByTypeName( "Animator" )
	string animationName = "EnterScene"
	RTKAnimator_PlayAnimation( animator, animationName )

	rtk_panel trialIconListPanel = self.PropGetPanel( "trialIconList" )
	rtk_behavior trialIconTweenStagger = trialIconListPanel.FindBehaviorByTypeName( "TweenStagger" )
	Assert( trialIconTweenStagger != null )
	trialIconTweenStagger.SetActive( true )

	rtk_behavior wooshAnimator = self.PropGetBehavior( "animator" )
	string wooshAnimationName = "ChevronBlurWoosh"
	RTKAnimator_PlayAnimation( wooshAnimator, wooshAnimationName )
	wait 1.0

	trialIconTweenStagger.SetActive( false )
}


void function AnimateUltimateTrialCompleted( rtk_behavior self, array<MasteryWeapon_FinalRewardResult> allWeaponsTrials )
{
	PrivateData p
	self.Private( p )

	
	EmitUISound( "UI_Menu_WeaponMastery_AllWeapons_AllTrialsComplete" )

	
	rtk_struct headerDataModel = RTKStruct_GetStruct( p.postGameWeaponTrialCelebrationsModel, "headerData" )
	RTKWeaponTrialCelebrationHeaderData headerData
	headerData.weaponName = Localize( "#MASTERY_TRIALS_ALL_WEAPONS" )
	headerData.celebrationType = Localize( "#MASTERY_TRIALS_MASTERY_COMPLETE" )
	RTKStruct_SetValue( headerDataModel, headerData )

	
	allWeaponsTrials[0].isCompleted = false 
	rtk_array allWeaponTrialsArray = RTKStruct_GetArray( p.postGameWeaponTrialCelebrationsModel, "allWeaponsTrials" )
	RTKArray_SetValue( allWeaponTrialsArray, allWeaponsTrials )

	
	rtk_behavior headerAnimator = self.PropGetPanel( "trialsCompleteHeader" ).FindBehaviorByTypeName( "Animator" )
	string headerAnimationName = "EnterSceneUltimate"
	RTKAnimator_PlayAnimation( headerAnimator, headerAnimationName )
	wait 4.0

	
	array<rtk_panel> ultimateTrialCard = self.PropGetPanel( "ultimateTrialsList" ).GetChildren()
	foreach ( rtk_panel card in ultimateTrialCard )
	{
		rtk_behavior CardAnimator = card.FindBehaviorByTypeName( "Animator" )
		string CardAnimationName = "EnterScene"
		RTKAnimator_PlayAnimation( CardAnimator, CardAnimationName )
		EmitUISound( "UI_Menu_WeaponMastery_Trial_Complete_All" )
		wait 0.65

		CardAnimationName = "Complete"
		RTKAnimator_PlayAnimation( CardAnimator, CardAnimationName )
		allWeaponsTrials[0].isCompleted = true
		allWeaponsTrials[0].curVal = allWeaponsTrials[0].goalVal
		RTKArray_SetValue( allWeaponTrialsArray, allWeaponsTrials )
	}
}

void function CenterTrial( rtk_behavior self, int trialIndex )
{
	Assert( trialIndex >= 0 )

	PrivateData p
	self.Private( p )

	rtk_behavior animator 		= self.PropGetBehavior( "animator" )
	rtk_array animations        = animator.PropGetArray( "tweenAnimations" )
	string animationName  		= "CenterTrial"
	rtk_struct centerTrialAnim  = null

	for ( int i = 0; i < RTKArray_GetCount( animations ); i++ )
	{
		rtk_struct animation = RTKArray_GetStruct( animations, i )

		if ( RTKStruct_GetString( animation, "name" ) == animationName )
		{
			centerTrialAnim = animation
			break
		}
	}

	if ( centerTrialAnim != null )
	{
		rtk_array tweens            = RTKStruct_GetArray( centerTrialAnim, "tweens" )
		rtk_struct tween            = RTKArray_GetStruct( tweens, 0 )
		int trialIndexForStartValue = p.lastProcessedTrialIndex == -1 ? trialIndex : p.lastProcessedTrialIndex

		RTKStruct_SetFloat( tween, "startValue", GetTrialsListXPositionForTrial( trialIndexForStartValue ) )
		RTKStruct_SetFloat( tween, "endValue", GetTrialsListXPositionForTrial( trialIndex ) )

		RTKAnimator_PlayAnimation( animator, animationName )
		EmitUISound( "UI_Menu_WeaponMastery_CardSlide" )
	}
}

float function GetTrialsListXPositionForTrial( int trialIndex )
{
	
	float defaultPosition = -230.0
	float singleOffset = 500.0
	float position = defaultPosition - ( singleOffset * trialIndex )

	return position
}

void function AnimateTrialStatusChange( rtk_panel trialPanel, int statusChangeType )
{
	Assert( statusChangeType == eWeaponTrialStatusChangeType.UNLOCKED || statusChangeType == eWeaponTrialStatusChangeType.COMPLETED )

	rtk_behavior animator = trialPanel.FindBehaviorByTypeName( "Animator" )
	string animationName  = statusChangeType == eWeaponTrialStatusChangeType.UNLOCKED ? "Unlock" : "Complete"
	string soundName      = statusChangeType == eWeaponTrialStatusChangeType.UNLOCKED ? "UI_Menu_WeaponMastery_Trial_Unlocked" : "UI_Menu_WeaponMastery_Trial_Complete"

	RTKAnimator_PlayAnimation( animator, animationName )
	EmitUISound( soundName )
}

void function RTKPostGameWeaponTrialCelebrations_InitWeaponTrialData( rtk_behavior self, MasteryWeapon_TrialStatusChangesPerWeapon weaponTrialsData )
{
	PrivateData p
	self.Private( p )

	ItemFlavor weaponItem = weaponTrialsData.weapon
	int weaponLevel = Mastery_GetWeaponLevel( weaponItem )

	
	
	RTKWeaponTrialCelebrationRuiArgs ruiArgs
	ruiArgs.weaponIcon  = WeaponItemFlavor_GetHudIcon( weaponItem )
	ruiArgs.weaponName  = Localize( ItemFlavor_GetShortName( weaponItem ) ).toupper()
	ruiArgs.weaponLevel = Localize( "#HUD_LEVEL_N", weaponLevel ).toupper()
	ruiArgs.startTime   = ClientTime()

	rtk_struct weaponModel  = RTKStruct_GetStruct( p.postGameWeaponTrialCelebrationsModel, "weapon" )
	rtk_struct ruiArgsModel = RTKStruct_GetStruct( weaponModel, "ruiArgs" )
	RTKStruct_SetValue( ruiArgsModel, ruiArgs )

	EmitUISound( weaponLevel <= 80 ? "UI_Menu_WeaponMastery_LevelUp_Generic" : "UI_Menu_WeaponMastery_LevelUp_100" )
}

void function RTKPostGameWeaponTrialCelebrations_OnDestroy( rtk_behavior self )
{
	Signal( uiGlobal.signalDummy, "EndPostGameWeaponTrialCelebrations" )

	PrivateData p
	self.Private( p )

	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "postGameWeaponTrialCelebrations" )

	RTKFooters_RemoveAll( p.menuGUID )
	RTKFooters_Update()
}

#if DEV
void function DEV_TestWeaponTrialCelebrationSounds( int weaponLevel )
{
	thread DEV_TestWeaponTrialCelebrationSoundsThread( weaponLevel )
}

void function DEV_TestWeaponTrialCelebrationSoundsThread( int weaponLevel )
{
	string levelUpSound = weaponLevel != 100 ? "UI_Menu_WeaponMastery_LevelUp_Generic" : "UI_Menu_WeaponMastery_LevelUp_100"
	string completeSound = "UI_Menu_WeaponMastery_Trial_Complete"
	string unlockedSound = "UI_Menu_WeaponMastery_Trial_Unlocked"
	string slideSound = "UI_Menu_WeaponMastery_CardSlide"

	printt( "Playing:", levelUpSound )
	EmitUISound( levelUpSound )

	wait 2.903
	printt( "Playing:", completeSound )
	EmitUISound( completeSound )

	wait 0.7006
	printt( "Playing:", slideSound )
	EmitUISound( slideSound )

	wait 0.9009
	printt( "Playing:", unlockedSound )
	EmitUISound( unlockedSound )
}
#endif

