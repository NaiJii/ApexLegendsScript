
global function InitTutorialOverlayMenu


global function RTKTutorialOverlay_OnInitialize
global function RTKTutorialOverlay_OnDestroy


global function RTKTutorialOverlay_Activate
global function RTKTutorialOverlay_Deactivate
global function RTKTutorialOverlay_IsActive

global enum eTutorialOverlayID
{
	
	READY_UP,
	APEX_PACK,
}

global struct RTKTutorialOverlayHintInfoModel
{
	string bodyText
	int anchor
	vector offset
}

const string MODEL_TUTORIAL_OVERLAY = "tutorialOverlay"
const string MODEL_TUTORIAL_OVERLAY_HINT_INFO = "hintInfo"

struct FileStruct
{
	table < int, var > tutorialBlocks
	int activeID = -1
}
FileStruct& file

void function InitTutorialOverlayMenu( var menu )
{























}

void function RTKTutorialOverlay_OnInitialize( rtk_behavior self )
{
	if ( !( file.activeID in file.tutorialBlocks ) )
		return

	RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, MODEL_TUTORIAL_OVERLAY )
	rtk_struct hintInfoModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, MODEL_TUTORIAL_OVERLAY_HINT_INFO, "RTKTutorialOverlayHintInfoModel", [ MODEL_TUTORIAL_OVERLAY ] )

	var tutorialBlock = file.tutorialBlocks[file.activeID]
	RTKStruct_SetString( hintInfoModel, "bodyText", GetSettingsBlockString( tutorialBlock, "text" ) )
	RTKStruct_SetInt( hintInfoModel, "anchor", GetSettingsBlockInt( tutorialBlock, "anchor" ) )
	RTKStruct_SetFloat3( hintInfoModel, "offset", GetSettingsBlockVector2( tutorialBlock, "offset" ) )
}

void function RTKTutorialOverlay_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, MODEL_TUTORIAL_OVERLAY )
}

void function RTKTutorialOverlay_Activate( int id )
{














}

void function RTKTutorialOverlay_Deactivate( int id )
{







}

bool function RTKTutorialOverlay_IsActive()
{
	return ( file.activeID != -1 )
}

