
global function DesertlandsTrainAnnouncer_Init
global function ServerCallback_SetDesertlandsTrainAtStation
global function SCB_DLandsTrain_SetCustomSpeakerIdx



global function IsDesertlandsTrainAtStation
global function DesertlandsTrain_PreMapInit


















































const string TRAIN_MOVER_NAME = "desertlands_train_mover"
const int TRAIN_CAR_COUNT = 6


















































































































struct
{







































		bool trainStoppedAtStation = false
		int  true_trainCarCount = TRAIN_CAR_COUNT


		int customQueueIdx

} file






















void function DesertlandsTrainAnnouncer_Init()
{
	RegisterCSVDialogue( $"datatable/dialogue/train_dialogue.rpak" )
	AddCallback_EntitiesDidLoad( InitTrainClientEnts )
	AddCallback_FullUpdate( TrainOnFullUpdate )
}




void function InitTrainClientEnts()
{
	if ( !Desertlands_IsTrainEnabled() )
		return


	
	entity trainMover = GetEntByScriptName( format( "%s_%i", TRAIN_MOVER_NAME, 0 ) )
	foreach ( entity ambientGeneric in GetEntArrayByScriptName( "Vehicles_Train_SpeedController" ) )
		ambientGeneric.SetSoundCodeControllerEntity( trainMover )
}


void function DesertlandsTrain_PreMapInit()
{
	AddCallback_OnNetworkRegistration( DesertlandsTrain_OnNetworkRegistration )
}

void function DesertlandsTrain_OnNetworkRegistration()
{
	Remote_RegisterClientFunction( "SCB_DLandsTrain_SetCustomSpeakerIdx", "int", 0, NUM_TOTAL_DIALOGUE_QUEUES )
}


void function SCB_DLandsTrain_SetCustomSpeakerIdx( int speakerIdx )
{
	file.customQueueIdx = speakerIdx
	InitAnnouncerEnts()
}



void function InitAnnouncerEnts()
{
	int numTrainCars = GetCurrentPlaylistVarInt( "desertlands_script_train_car_count", TRAIN_CAR_COUNT )
	array<entity> customSpeakers1

	if ( numTrainCars >= 1 )
	{
		entity announcerTarget0 = GetEntByScriptName( "train_announcer_target_0" )
		customSpeakers1.append( announcerTarget0 )
	}

	if ( numTrainCars >= 3 )
	{
		entity announcerTarget2 = GetEntByScriptName( "train_announcer_target_2" )
		customSpeakers1.append( announcerTarget2 )
	}

	if ( numTrainCars >= 5 )
	{
		entity announcerTarget4 = GetEntByScriptName( "train_announcer_target_4" )
		customSpeakers1.append( announcerTarget4 )
	}

	if ( customSpeakers1.len() != 0 )
	{
		RegisterCustomDialogueQueueSpeakerEntities( file.customQueueIdx, customSpeakers1 )
	}
}




void function TrainOnFullUpdate()
{
	if ( !Desertlands_IsTrainEnabled() )
		return
}



























































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































bool function Desertlands_IsTrainEnabled()
{
	if ( GetCurrentPlaylistVarBool( "desertlands_script_train_enable", true ) )
	{
		bool entitiesExist = true
		for ( int idx = 0; idx < file.true_trainCarCount; idx++ )
		{
			array<entity> movers = GetEntArrayByScriptName( format( "%s_%i", TRAIN_MOVER_NAME, idx ) )
			if ( movers.len() < 1 )
			{
				entitiesExist = false
				break
			}
		}

		if ( entitiesExist )
			return true
		else
			return false
	}

	return false
}














































































void function ServerCallback_SetDesertlandsTrainAtStation( bool isAtStation )
{
	file.trainStoppedAtStation = isAtStation
}




bool function IsDesertlandsTrainAtStation()
{
	return file.trainStoppedAtStation
}




















































































































































