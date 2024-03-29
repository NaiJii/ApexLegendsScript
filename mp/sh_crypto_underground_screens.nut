







global function ClCryptoUndergroundScreens_Init

global function ServerCallback_OnBunkerLoreScreenAttemptHack

global function SCB_SetCryptoLoreScreenDialogueIdx




global function IsBunkerLoreScreen
global function IsBunkerLoreScreenHacked
global function CryptoUndergroundScreens_PreMapInit







const asset SCREEN_CSV_DIALOGUE = $"datatable/dialogue/canyonlands_mu2_tt_underground_dialogue.rpak"

const string SCREEN_Z5_SCRIPTNAME = "hb_tv_prop_5"
const string SCREEN_Z6_SCRIPTNAME = "hb_tv_prop_6"
const string SCREEN_Z12_SCRIPTNAME = "hb_tv_prop_12"

const array<string> ALL_SCREEN_SCRIPTNAMES =
[
	SCREEN_Z5_SCRIPTNAME,
	SCREEN_Z6_SCRIPTNAME,
	SCREEN_Z12_SCRIPTNAME
]

const float SCREEN_LOADING_DURATION = 6.0
const float SCREEN_LOADING_FADE_OUT_DURATION = 1.0
const float SCREEN_LOADING_FADE_OUT_BUFFER = 0.5

const float SCREEN_MESSAGE_FADE_IN_DURATION = 1.5
const float SCREEN_MESSAGE_FADE_OUT_DURATION = 1.0

const float SCREEN_MESSAGE_1_DURATION = 20.5
const float SCREEN_MESSAGE_2_DURATION = 21.0
const float SCREEN_MESSAGE_3_DURATION = 25.5

const float SCREEN_VO_BUFFER_DURATION = 1.0



const string HACKING_PROGRESS_SFX = "survival_titan_linking_loop"
const string HACK_SUCCESS_SFX = "Canyonlands_Crypto_T_Screen_Hacked"
const string HACK_LOADING_SFX = "Canyonlands_Crypto_T_Screen_Loading"
const string HACK_AMBIENT_SFX = "Canyonlands_Crypto_T_Screen_Ambient"
const string HACK_FADE_OUT_SFX = "Canyonlands_Crypto_T_Screen_End"



struct BunkerScreenData
{
	array<entity> models


		bool       ruiIsDestroyed = false
		array<var> topos
		array<var> ruis





		bool hasHacked = false


	bool hasFinished = false
}


struct
{
	array<BunkerScreenData> allScreenDatas
	int customQueueIdx





} file






















void function CryptoUndergroundScreens_PreMapInit()
{
	AddCallback_OnNetworkRegistration( OnNetworkRegistration )
}

void function OnNetworkRegistration()
{
	Remote_RegisterClientFunction( "SCB_SetCryptoLoreScreenDialogueIdx", "int", 0, NUM_TOTAL_DIALOGUE_QUEUES )
}

















void function ClCryptoUndergroundScreens_Init()
{
	
	RegisterCSVDialogue( SCREEN_CSV_DIALOGUE )

	AddCallback_OnEnterDroneView( Drone_OnBeginView )
	AddCallback_OnLeaveDroneView( Drone_OnEndView )
	AddCallback_OnRecallDrone( Drone_OnRecall )

	AddCallback_FullUpdate( CryptoUndergroundScreensOnFullUpdate )
	AddCallback_EntitiesDidLoad( EntitiesDidLoad )
}




void function EntitiesDidLoad()
{
	
	if ( DoBunkerScreensExist() )
		SetupBunkerLoreScreens()
}





























const float BUNKER_SCREEN_WIDTH = 82.0
const float BUNKER_SCREEN_HEIGHT = 34.0


bool function DoBunkerScreensExist()
{
	foreach ( string scriptName in ALL_SCREEN_SCRIPTNAMES )
	{
		array<entity> screenArray = GetEntArrayByScriptName( scriptName )
		if ( screenArray.len() != 3 )
			return false
	}

	return true
}




bool function IsBunkerLoreScreen( entity ent )
{
	foreach ( BunkerScreenData data in file.allScreenDatas )
	{
		if ( data.models.contains( ent ) )
			return true
	}

	return false
}




bool function IsBunkerLoreScreenHacked( entity ent, entity player )
{
	BunkerScreenData data = GetBunkerScreenDataForModel( ent )





		return data.hasHacked


	return false
}




void function Drone_OnBeginView()
{
	if ( GetLocalClientPlayer() != GetLocalViewPlayer() )
		return

	foreach ( BunkerScreenData data in file.allScreenDatas )
	{
		foreach ( var rui in data.ruis )
			RuiSetVisible( rui, true )
	}
}




void function Drone_OnEndView()
{
	if ( GetLocalClientPlayer() != GetLocalViewPlayer() )
		return

	Signal( GetLocalClientPlayer(), "OnContinousUseStopped" )

	foreach ( BunkerScreenData data in file.allScreenDatas )
	{
		foreach ( var rui in data.ruis )
			RuiSetVisible( rui, false )
	}
}




void function Drone_OnRecall()
{
	if ( GetLocalClientPlayer() != GetLocalViewPlayer() )
		return

	Signal( GetLocalClientPlayer(), "OnContinousUseStopped" )
}




BunkerScreenData function GetBunkerScreenDataForModel( entity screenModel )
{
	Assert( ALL_SCREEN_SCRIPTNAMES.contains( screenModel.GetScriptName() ), "Entity is not a bunker lore screen." )

	BunkerScreenData screenData

	foreach ( BunkerScreenData data in file.allScreenDatas )
	{
		if ( data.models.contains( screenModel ) )
			return data
	}

	return screenData
}
















void function CryptoUndergroundScreensOnFullUpdate()
{
	foreach ( int idx, BunkerScreenData data in file.allScreenDatas )
		data.models = GetEntArrayByScriptName( ALL_SCREEN_SCRIPTNAMES[idx] )
}























void function SetupBunkerLoreScreens()
{
	foreach ( string scriptName in ALL_SCREEN_SCRIPTNAMES )
	{
		BunkerScreenData data
		data.models = GetEntArrayByScriptName( scriptName )
		file.allScreenDatas.append( data )
	}


		foreach ( BunkerScreenData data in file.allScreenDatas )
			CreateIdleRuiForBunkerLoreScreen( data )






}






































void function CreateIdleRuiForBunkerLoreScreen( BunkerScreenData data )
{
	foreach ( entity model in data.models )
	{
		if ( !IsValid( model ) )
			continue

		var topo = CreateRUITopology_Worldspace( model.GetOrigin(), model.GetAngles() + <0, -90, 0>, BUNKER_SCREEN_WIDTH, BUNKER_SCREEN_HEIGHT )
		var rui  = RuiCreate( $"ui/lore_screen_idle_crypto.rpak", topo, RUI_DRAW_WORLD, 0 )
		RuiSetVisible( rui, false )

		data.topos.append( topo )
		data.ruis.append( rui )
	}
}













void function ServerCallback_OnBunkerLoreScreenAttemptHack( entity screenModel, entity drone )
{
	entity localPlayer = GetLocalClientPlayer()

	if ( !IsValid( localPlayer ) || localPlayer != GetLocalViewPlayer() )
		return

	DroneHackExtendedUse_ServerClient( screenModel, localPlayer, drone )
}




void function DroneHackExtendedUse_ServerClient( entity screenModel, entity player, entity drone )
{
	ExtendedUseSettings settings

	settings.successFunc = CreateScreenHackFunc( drone )
	settings.duration = 3.0
	settings.useInputFlag = IN_USE_LONG


		settings.loopSound = HACKING_PROGRESS_SFX
		settings.icon = $"rui/hud/gametype_icons/survival/data_knife"
		settings.displayRuiType = eExtendedUseRuiType.FULLSCREEN
		settings.displayRuiFunc = DisplayRuiForHackableScreen
		settings.displayRui = $"ui/health_use_progress.rpak"
		settings.hint = "#CAMERA_DECODING_MESSAGE"








	thread ExtendedUse( screenModel, player, settings )
}




void function DisplayRuiForHackableScreen( entity ent, entity player, var rui, ExtendedUseSettings settings )
{
	DisplayRuiForHackableScreen_Internal( rui, settings.icon, Time(), Time() + settings.duration, settings.hint )
}

void function DisplayRuiForHackableScreen_Internal( var rui, asset icon, float startTime, float endTime, string hint )
{
	RuiSetBool( rui, "isVisible", true )
	RuiSetImage( rui, "icon", icon )
	RuiSetGameTime( rui, "startTime", startTime )
	RuiSetGameTime( rui, "endTime", endTime )
	RuiSetString( rui, "hintKeyboardMouse", hint )
	RuiSetString( rui, "hintController", hint )
}























void functionref( entity screenModel, entity player, ExtendedUseSettings settings ) function CreateScreenHackFunc( entity drone )
{
	return void function( entity screenModel, entity player, ExtendedUseSettings settings ) : ( drone )
	{
		thread OnBunkerScreenHack_ServerClient( screenModel, player, drone )
	}
}




bool function HasPlayerHackedScreen( entity player, BunkerScreenData data )
{




		if ( data.hasHacked )
			return true


	return false
}




void function OnBunkerScreenHack_ServerClient( entity screenModel, entity player, entity drone )
{
	EndSignal( drone, "OnDestroy" ) 





		entity localPlayer = GetLocalClientPlayer()
		EndSignal( localPlayer, "OnDeath" )
		EndSignal( localPlayer, "CameraViewEnd" ) 


	
	BunkerScreenData data = GetBunkerScreenDataForModel( screenModel )
	float messageDuration = 0.0
	int messageIdx        = -1

	asset image1 = $""
	asset image2 = $""
	asset image3 = $""
	asset image4 = $""
	asset image5 = $""
	asset image6 = $""


	switch ( screenModel.GetScriptName() )
	{
		case SCREEN_Z6_SCRIPTNAME:
			messageDuration = SCREEN_MESSAGE_1_DURATION
			messageIdx = 1
			image1 = $"rui/events/s05_crypto_lore/on_the_run_00"
			image2 = $"rui/events/s05_crypto_lore/on_the_run_01"
			image3 = $"rui/events/s05_crypto_lore/on_the_run_02"
			image4 = $"rui/events/s05_crypto_lore/on_the_run_03"
			image5 = $"rui/events/s05_crypto_lore/on_the_run_00"
			break

		case SCREEN_Z5_SCRIPTNAME:
			messageDuration = SCREEN_MESSAGE_2_DURATION
			messageIdx = 2
			image1 = $"rui/events/s05_crypto_lore/interview_00"
			image2 = $"rui/events/s05_crypto_lore/interview_01"
			image3 = $"rui/events/s05_crypto_lore/interview_02"
			image4 = $"rui/events/s05_crypto_lore/interview_03"
			image5 = $"rui/events/s05_crypto_lore/interview_04"
			image6 = $"rui/events/s05_crypto_lore/interview_05"
			break

		case SCREEN_Z12_SCRIPTNAME:
			messageDuration = SCREEN_MESSAGE_3_DURATION
			messageIdx = 3
			image1 = $"rui/events/s05_crypto_lore/escape_00"
			image2 = $"rui/events/s05_crypto_lore/escape_01"
			image3 = $"rui/events/s05_crypto_lore/escape_02"
			image4 = $"rui/events/s05_crypto_lore/escape_03"
			image5 = $"rui/events/s05_crypto_lore/escape_00"
			break
	}

	OnThreadEnd(
		function() : ( data, player )
		{

				foreach ( var rui in data.ruis )
					RuiDestroyIfAlive( rui )

				data.ruis.clear()


			if ( !data.hasFinished )
			{




					data.hasHacked = false





					foreach ( BunkerScreenData bunkerData in file.allScreenDatas )
					{
						foreach ( var topo in data.topos )
							RuiTopology_Destroy( topo )

						data.topos.clear()

						foreach ( entity model in bunkerData.models )
						{
							if ( IsValid( model ) )
								StopSoundOnEntity( model, HACK_AMBIENT_SFX )
						}
					}
					CreateIdleRuiForBunkerLoreScreen( data )

			}
		}
	)





		EmitSoundOnEntity( drone, HACK_SUCCESS_SFX )
		data.hasHacked = true



		
		foreach ( var rui in data.ruis )
		{
			RuiSetGameTime( rui, "idleEndTime", Time() )
			RuiSetFloat( rui, "loadingFadeOutDuration", SCREEN_LOADING_FADE_OUT_DURATION )
			RuiSetInt( rui, "messageIdx", messageIdx )
		}

		EmitSoundOnEntity( drone, HACK_LOADING_SFX )


	wait SCREEN_LOADING_DURATION


		foreach ( var rui in data.ruis )
			RuiSetGameTime( rui, "fadeOutStartTime", Time() )


	wait SCREEN_LOADING_FADE_OUT_DURATION + SCREEN_LOADING_FADE_OUT_BUFFER


		foreach ( var rui in data.ruis )
			RuiDestroyIfAlive( rui )

		data.ruis.clear()

		
		foreach ( var topo in data.topos )
		{
			var rui = RuiCreate( $"ui/lore_screen_wide.rpak", topo, RUI_DRAW_WORLD, 0 )
			RuiSetVisible( rui, IsPlayerInCryptoDroneCameraView( localPlayer ) )
			RuiSetFloat( rui, "messageFadeInTime", SCREEN_MESSAGE_FADE_IN_DURATION )
			RuiSetFloat( rui, "messageFadeOutTime", SCREEN_MESSAGE_FADE_OUT_DURATION )
			RuiSetFloat( rui, "messageDuration", messageDuration )
			RuiSetFloat( rui, "lightnessVal", -0.5 )

			RuiSetAsset( rui, "messageImage1", image1 )
			RuiSetAsset( rui, "messageImage2", image2 )
			RuiSetAsset( rui, "messageImage3", image3 )
			RuiSetAsset( rui, "messageImage4", image4 )
			RuiSetAsset( rui, "messageImage5", image5 )
			RuiSetAsset( rui, "messageImage6", image6 )

			data.ruis.append( rui )
		}

		thread PlayScreenVO( drone, messageIdx )

		foreach ( BunkerScreenData bunkerData in file.allScreenDatas )
		{
			foreach ( entity model in bunkerData.models )
				EmitSoundOnEntity( model, HACK_AMBIENT_SFX )
		}


	wait SCREEN_MESSAGE_FADE_IN_DURATION

	wait messageDuration





		foreach ( BunkerScreenData bunkerData in file.allScreenDatas )
		{
			foreach ( entity model in bunkerData.models )
				StopSoundOnEntity( model, HACK_AMBIENT_SFX )
		}
		EmitSoundOnEntity( drone, HACK_FADE_OUT_SFX )


	wait SCREEN_MESSAGE_FADE_OUT_DURATION + 0.25

	data.hasFinished = true
}




void function PlayScreenVO( entity drone, int messageIdx )
{
	entity localPlayer = GetLocalClientPlayer()
	EndSignal( localPlayer, "OnDeath" )
	EndSignal( drone, "OnDestroy" )
	EndSignal( localPlayer, "CameraViewEnd" )

	array<string> dialogueRefs

	dialogueRefs.append( format( "bc_CynMU2Lore_Part%i_a", messageIdx ) )
	dialogueRefs.append( format( "bc_CynMU2Lore_Part%i_b", messageIdx ) )
	dialogueRefs.append( format( "bc_CynMU2Lore_Part%i_c", messageIdx ) )

	int dialogueFlags = eDialogueFlags.BLOCK_LOWER_PRIORITY_QUEUE_ITEMS | eDialogueFlags.MUTE_PLAYER_PING_DIALOGUE_FOR_DURATION | eDialogueFlags.MUTE_PLAYER_PING_CHIMES_FOR_DURATION | eDialogueFlags.USE_CUSTOM_QUEUE

	foreach ( string dialogueRef in dialogueRefs )
	{
		float duration = GetSoundDuration( GetAnyDialogueAliasFromName( dialogueRef ) )
		waitthread PlayClientDialogueOnEntity( GetAnyAliasIdForName( dialogueRef ), dialogueFlags, drone, file.customQueueIdx )

		if ( dialogueRefs.top() != dialogueRef )
			wait SCREEN_VO_BUFFER_DURATION
	}
}



void function SCB_SetCryptoLoreScreenDialogueIdx( int queueIdx )
{
	file.customQueueIdx = queueIdx
}


