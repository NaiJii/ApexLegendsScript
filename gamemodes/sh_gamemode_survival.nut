

global function PreGame_GetWaitingForPlayersHasBlackScreen
global function PreGame_GetWaitingForPlayersSpawningEnabled
global function PreGame_GetWaitingForPlayersDelayMin
global function PreGame_GetWaitingForPlayersDelayMax
global function PreGame_GetWaitingForPlayersCountdown
global function CharSelect_GetIntroMusicStartTime
global function CharSelect_GetIntroTransitionDuration
global function CharSelect_GetIntroCountdownDuration
global function CharSelect_GetPickingDelayBeforeAll
global function CharSelect_GetPickingDelayOnFirst
global function CharSelect_GetPickingSingleDurationMax
global function CharSelect_GetPickingSingleDurationMin
global function CharSelect_GetPickingDelayAfterEachLock
global function CharSelect_GetPickingDelayAfterAll
global function CharSelect_GetOutroSceneChangeDuration
global function CharSelect_GetOutroAllSquadsPresentDuration
global function CharSelect_GetOutroSquadPresentDuration
global function CharSelect_GetOutroMVPPresentDuration
global function CharSelect_GetOutroChampionPresentDuration
global function CharSelect_GetOutroTransitionDuration





































































global function GamemodeSurvivalShared_UI_Init


global function IsSquadDataPersistenceEmpty

global const float MAX_MAP_BOUNDS = 61000.0

global const string SURVIVAL_DEFAULT_TITAN_DEFENSE = "mp_titanability_arm_block"

global const float CHARACTER_SELECT_OPEN_TRANSITION_DURATION = 3.0
global const float CHARACTER_SELECT_CLOSE_TRANSITION_DURATION = 3.0
global const float CHARACTER_SELECT_CHARACTER_LOCK_DURATION = 0.5
global const float CHARACTER_SELECT_FINISHED_HOLD_DURATION = 2.5
global const float CHARACTER_SELECT_PRE_PICK_COUNTDOWN_DURATION = 4.0
global const float CHARACTER_SELECT_SCENE_ROTATE_DURATION = 4.0

global const float SURVIVAL_MINIMAP_RING_SCALE = 65536
global const SMALL_HEALTH_USE_TIME = 4.0
global const MEDIUM_HEALTH_USE_TIME = 7.0
global const LARGE_HEALTH_USE_TIME = 12.0
global const SYRINGE_HEALTH_USE_TIME = 4.0

global const int SURVIVAL_MAP_GRIDSIZE = 7

global const SURVIVAL_PLANE_MODEL = $"mdl/vehicles_r2/spacecraft/draconis/draconis_flying_small.rmdl"
global const SURVIVAL_SQUAD_SUMMARY_MODEL = $"mdl/levels_terrain/mp_lobby/mp_setting_menu.rmdl"
global const string SURVIVAL_PLANE_NAME = "planeEnt"

const int USEHEALTHPACK_DENY_NONE = -1
const int USEHEALTHPACK_ALLOW = 0
const int USEHEALTHPACK_DENY_ULT_FULL = 1
const int USEHEALTHPACK_DENY_HEALTH_FULL = 2
const int USEHEALTHPACK_DENY_SHIELD_FULL = 3
const int USEHEALTHPACK_DENY_NO_HEALTH_KITS = 4
const int USEHEALTHPACK_DENY_NO_SHIELD_KITS = 5
const int USEHEALTHPACK_DENY_NO_KITS = 6
const int USEHEALTHPACK_DENY_FULL = 7

const string PODIUM_FX_SPARKS_L1 = "sparks_L1"
const string PODIUM_FX_SPARKS_L2 = "sparks_L2"
const string PODIUM_FX_SPARKS_R1 = "sparks_R1"
const string PODIUM_FX_SPARKS_R2 = "sparks_R2"
const string PODIUM_FX_FIREBALL_L1 = "Fireball_L1"
const string PODIUM_FX_FIREBALL_L2 = "Fireball_L2"
const string PODIUM_FX_FIREBALL_R1 = "Fireball_R1"
const string PODIUM_FX_FIREBALL_R2 = "Fireball_R2"
const string PODIUM_FX_CONFETTI = "confetti_burst"



global const int NUMBER_OF_SUMMARY_DISPLAY_VALUES = 7 
global const array< int > SUMMARY_DISPLAY_EMPTY_SET = [ 0, 0, 0, 0, 0, 0, 0 ]

enum eUseHealthKitResult
{
	ALLOW,
	DENY_NONE,
	DENY_ULT_FULL,
	DENY_ULT_NOTREADY,
	DENY_HEALTH_FULL,
	DENY_SHIELD_FULL,
	DENY_NO_HEALTH_KIT,
	DENY_NO_SHIELD_KIT,
	DENY_NO_KITS,
	DENY_NO_SHIELDS,
	DENY_FULL,
	DENY_SPRINTING,
}

table< int, string > healthKitResultStrings =
{
	[eUseHealthKitResult.ALLOW] = "",
	[eUseHealthKitResult.DENY_NONE] = "",
	[eUseHealthKitResult.DENY_ULT_FULL] = "#DENY_ULT_FULL",
	[eUseHealthKitResult.DENY_ULT_NOTREADY ] = "#DENY_ULT_NOTREADY",
	[eUseHealthKitResult.DENY_HEALTH_FULL] = "#DENY_HEALTH_FULL",
	[eUseHealthKitResult.DENY_SHIELD_FULL] = "#DENY_SHIELD_FULL",
	[eUseHealthKitResult.DENY_NO_HEALTH_KIT] = "#DENY_NO_HEALTH_KIT",
	[eUseHealthKitResult.DENY_NO_SHIELD_KIT] = "#DENY_NO_SHIELD_KIT",
	[eUseHealthKitResult.DENY_NO_KITS] = "#DENY_NO_KITS",
	[eUseHealthKitResult.DENY_NO_SHIELDS] = "#DENY_NO_SHIELDS",
	[eUseHealthKitResult.DENY_FULL] = "#DENY_FULL",
	[eUseHealthKitResult.DENY_SPRINTING] = "#DENY_SPRINTING",
}

global struct TargetKitHealthAmounts
{
	float targetHealth
	float targetShields
}

global enum eSurvivalHints
{
	EQUIP,
	ORDNANCE,

	ORDNANCE_FUSE,
	ORDNANCE_FUSE_MULTI,


	CRYPTO_DRONE_ACCESS,





}

global enum ePodiumBanner
{
	NORMAL = 0,
	ANNIVERSARY,
	FREEDM,
	CONTROL,
	LTM,
	MIXTAPE,

	_COUNT
}

global enum ePodiumBackground
{
	MP_RR_DESERTLANDS_HU = 0,
	MP_RR_DIVIDED_MOON,
	MP_RR_CANYONLANDS_HU,
	MP_RR_OLYMPUS_MU2,
	MP_RR_TROPICS_ISLAND_MU1,
	MP_RR_ADQUEDUCT,
	MP_RR_ARENA_HABITAT,
	MP_RR_PARTY_CRASHER,
	MP_RR_ARENA_PHASE_RUNNER,
	MP_RR_FREEDM_SKULLTOWN,
	MP_RR_ARENA_SKYGARDER,

	_COUNT
}

global struct VictoryPlatformModelData
{
	bool   isSet = false 
	asset  modelAsset = $"mdl/dev/empty_model.rmdl"
	vector originOffset = < 0, 0, -10 >
	vector modelAngles = < 0, 0, 0 >
}

struct
{
	entity                     planeCenterEnt
	entity                     planeEnt







	VictoryPlatformModelData & victorySequencePlatforData




} file


bool function HasFastIntro()
{
	if ( GetCurrentPlaylistVarBool( "fast_intro", false ) )
		return true

	return GetConVarBool( "fast_intro" )
}


bool function PreGame_GetWaitingForPlayersHasBlackScreen()		{ return GetCurrentPlaylistVarBool( "waiting_for_players_has_black_screen", false ) }
bool function PreGame_GetWaitingForPlayersSpawningEnabled()		{ return GetCurrentPlaylistVarBool( "waiting_for_players_spawning_enabled", false ) }
float function PreGame_GetWaitingForPlayersDelayMin()			{ return GetCurrentPlaylistVarFloat( "waiting_for_players_min_wait", 0.0 ) }
float function PreGame_GetWaitingForPlayersDelayMax()			{ return GetCurrentPlaylistVarFloat( "waiting_for_players_timeout_seconds", 20.0 ) }
float function PreGame_GetWaitingForPlayersCountdown()			{ return (HasFastIntro() ? 0.0 : GetCurrentPlaylistVarFloat( "waiting_for_players_countdown_seconds", 8.0 ) ) }

float function CharSelect_GetIntroMusicStartTime()		 		{ return GetCurrentPlaylistVarFloat( "charselect_intro_music_start_time", -0.8 ) }
float function CharSelect_GetIntroTransitionDuration()			{ return GetCurrentPlaylistVarFloat( "charselect_intro_transition_duration", 3.0 ) }
float function CharSelect_GetIntroCountdownDuration()			{ return GetCurrentPlaylistVarFloat( "charselect_intro_countdown_duration", 0.0 ) }

float function CharSelect_GetPickingDelayBeforeAll()			{ return GetCurrentPlaylistVarFloat( "charselect_picking_delay_before_all", 0.0 ) }
float function CharSelect_GetPickingDelayOnFirst()				{ return GetCurrentPlaylistVarFloat( "charselect_picking_delay_on_first", 1.5 ) }
float function CharSelect_GetPickingSingleDurationMax()			{ return (HasFastIntro() ? 0.0 : GetCurrentPlaylistVarFloat( "character_select_time_max", 8.0 ) ) }
float function CharSelect_GetPickingSingleDurationMin()			{ return (HasFastIntro() ? 0.0 : GetCurrentPlaylistVarFloat( "character_select_time_min", 6.0 ) ) }
float function CharSelect_GetPickingDelayAfterEachLock()		{ return GetCurrentPlaylistVarFloat( "charselect_picking_delay_after_each_lock", 0.5 ) }
float function CharSelect_GetPickingDelayAfterAll()				{ return GetCurrentPlaylistVarFloat( "charselect_picking_delay_after_all", 1.5 ) }

float function CharSelect_GetOutroSceneChangeDuration()			{ return GetCurrentPlaylistVarFloat( "charselect_outro_scene_change_duration", 4.0 ) }
float function CharSelect_GetOutroAllSquadsPresentDuration()	{ return GetCurrentPlaylistVarFloat( "charselect_outro_all_squads_present_duration", 0.0 ) }
float function CharSelect_GetOutroSquadPresentDuration()		{ return GetCurrentPlaylistVarFloat( "charselect_outro_squad_present_duration", 6.0  ) }
float function CharSelect_GetOutroMVPPresentDuration()			{ return GetCurrentPlaylistVarFloat( "charselect_outro_mvp_present_duration", 0.0 ) }
float function CharSelect_GetOutroChampionPresentDuration()		{ return GetCurrentPlaylistVarFloat( "charselect_outro_champion_present_duration", 8.0 ) }
float function CharSelect_GetOutroTransitionDuration()			{ return GetCurrentPlaylistVarFloat( "charselect_outro_transition_duration", 3.0 ) }































































































































void function GamemodeSurvivalShared_UI_Init()
{
	AddUICallback_InputModeChanged( UIInputChanged )
}

void function UIInputChanged( bool controllerModeActive )
{

}













































































































































































































































































































































































































































































































































































































































































































































































































































































































































bool function IsSquadDataPersistenceEmpty( entity player )
{
	int maxTrackedSquadMembers = PersistenceGetArrayCount( "lastGameSquadStats" )
	for ( int i = 0 ; i < maxTrackedSquadMembers ; i++ )
	{
		int eHandle = player.GetPersistentVarAsInt( "lastGameSquadStats[" + i + "].eHandle" )

		
		if ( eHandle > 0 )
			return false
	}
	return true
}











