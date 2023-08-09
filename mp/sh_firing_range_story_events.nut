
global function ShFiringRangeStoryEvents_Init


struct RealmStoryData
{
	entity door
}

struct
{
	table< int,  RealmStoryData > realmStoryDataByRealmTable
} file

const array<string> BTS_DIALOGUE_ARRAY = [ "diag_mp_bStage_18_0_start_3p", "diag_mp_bStage_18_0_01_3p", "diag_mp_bStage_18_0_02_3p", "diag_mp_bStage_18_0_03_3p", "diag_mp_bStage_18_0_04_3p" ]

const asset BTS_DOOR_MDL = $"mdl/door/metal_swinging_door_01.rmdl"
const string BTS_DOOR_SCRIPT_NAME = "FR_BTS_DOOR_SCRIPTNAME"




















void function ShFiringRangeStoryEvents_Init()
{
	if ( GetMapName() != "mp_rr_canyonlands_staging_mu1" ) 
		return

	if ( !IsFiringRangeGameMode() )
		return

	PrecacheScriptString( BTS_DOOR_SCRIPT_NAME )

	AddCallback_EntitiesDidLoad( EntitiesDidLoad )






	RegisterSignal( "EndBTSConvo" )
}



void function EntitiesDidLoad()
{

}
















































































































































































