global function RTKCrossProgressionPanel_OnInitialize
global function RTKCrossProgressionPanel_OnDestroy
global function RTKCrossProgressionPanel_UpdateDataModel
global function RTKCrossProgressionPanel_SetDialogHeight
global function RTKCrossProgressionPanel_SetHeader
global function RTKMutator_HasNxProfile

global struct RTKCrossProgressionPanel_Properties
{
	rtk_behavior migrateButton
	rtk_behavior faqButton
	rtk_behavior continueButton
}

global struct RTKCrossProgressionFlowModel
{
	int state
}

struct PrivateData
{
	string crossProgressionRootPath = ""
}

global enum eCrossProgressionState
{
	ANNOUNCEMENT,
	MIGRATING,
	MIGRATED,
	_COUNT,
}

const string CROSS_PROGRESSION_DATA_MODEL_NAME = "crossProgression"
const string FLOW_DATA_MODEL_NAME = "flow"
const string MIGRATION_DATA_MODEL_NAME = "migration"

struct
{
	int offlineMigrationState = eCrossProgressionState.ANNOUNCEMENT
} file

void function OnStartMigrate()
{
	RTKCrossProgressionPanel_SetHeader()
	RTKCrossProgressionPanel_SetDialogHeight()
	UI_CrossProgression_DoMigrateFlow()
	RTKCrossProgressionPanel_SetFlowModel()
}

void function OnAnnouncementContiue()
{
	if ( CrossProgression_IsOfflineMigration() )
	{
		XProgMigrateData migrateData = CrossProgressionGetMigrateData()

		if ( migrateData.hasMultipleProfiles )
		{
			file.offlineMigrationState = eCrossProgressionState.MIGRATED
			RTKCrossProgressionPanel_SetHeader()
			RTKCrossProgressionPanel_SetDialogHeight()
			RTKCrossProgressionPanel_UpdateDataModel()
		}
		else
		{
			UI_CloseCrossProgressionDialog()
		}
	}
	else
	{
		OnStartMigrate()
	}
}

void function OnContinue( var button )
{
	int state = RTKCrossProgressionPanel_GetState()
	printt( "[CrossProgression] OnContinue state", state )

	switch ( state )
	{
		case eCrossProgressionState.ANNOUNCEMENT:
			OnAnnouncementContiue()
			break

		case eCrossProgressionState.MIGRATED:
			UI_CloseCrossProgressionDialog()
			break

		case eCrossProgressionState.MIGRATING:
			break
	}
}

void function ViewFAQ()
{
	LaunchExternalWebBrowser( Localize(  "#CROSS_PROGRESSION_FAQ_URL" ), WEBBROWSER_FLAG_NONE )
}

void function OnButtonY( var button )
{
	int state = RTKCrossProgressionPanel_GetState()
	printt( "[CrossProgression] OnButtonY state", state )

	if ( state == eCrossProgressionState.MIGRATED )
		ViewFAQ()
}

void function RTKCrossProgressionPanel_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	rtk_struct crossProgression = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, CROSS_PROGRESSION_DATA_MODEL_NAME )
	rtk_struct flow = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, FLOW_DATA_MODEL_NAME, "RTKCrossProgressionFlowModel", [ CROSS_PROGRESSION_DATA_MODEL_NAME ] )
	rtk_struct migration = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, MIGRATION_DATA_MODEL_NAME, "XProgMigrateData", [ CROSS_PROGRESSION_DATA_MODEL_NAME ] )

	p.crossProgressionRootPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, CROSS_PROGRESSION_DATA_MODEL_NAME )
	self.GetPanel().SetBindingRootPath( p.crossProgressionRootPath )

	RTKCrossProgressionPanel_UpdateDataModel()
	RTKCrossProgressionPanel_SetDialogHeight()
	RTKCrossProgressionPanel_SetHeader()

	
	rtk_behavior ornull faqButton = self.PropGetBehavior( "faqButton" )
	if ( faqButton != null )
	{
		expect rtk_behavior( faqButton )
		self.AutoSubscribe( faqButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			ViewFAQ()
		} )
	}

	rtk_behavior ornull migrateButton = self.PropGetBehavior( "migrateButton" )
	if ( migrateButton != null )
	{
		expect rtk_behavior( migrateButton )
		self.AutoSubscribe( migrateButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			if ( RTKCrossProgressionPanel_GetState() == eCrossProgressionState.ANNOUNCEMENT )
				OnAnnouncementContiue()
		} )
	}

	RegisterButtonPressedCallback( KEY_SPACE, OnContinue )
	RegisterButtonPressedCallback( BUTTON_A, OnContinue )
	RegisterButtonPressedCallback( BUTTON_Y, OnButtonY )

	rtk_behavior ornull continueButton = self.PropGetBehavior( "continueButton" )
	if ( continueButton != null )
	{
		expect rtk_behavior( continueButton )
		self.AutoSubscribe( continueButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			UI_CloseCrossProgressionDialog()
		} )
	}
}

void function RTKCrossProgressionPanel_SetMigrationModel()
{
	string migrationDataPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, MIGRATION_DATA_MODEL_NAME, true, [ CROSS_PROGRESSION_DATA_MODEL_NAME ] )

	if ( RTKDataModel_HasDataModel( migrationDataPath ) )
	{
		rtk_struct migration = RTKDataModel_GetStruct( migrationDataPath )
		RTKStruct_SetValue( migration, CrossProgressionGetMigrateData() )
	}
}

void function RTKCrossProgressionPanel_SetFlowModel()
{
	string flowDataPath = RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, FLOW_DATA_MODEL_NAME, true, [ CROSS_PROGRESSION_DATA_MODEL_NAME ] )

	if ( RTKDataModel_HasDataModel( flowDataPath ) )
	{
		rtk_struct flow = RTKDataModel_GetStruct( flowDataPath )
		RTKCrossProgressionFlowModel flowModel
		flowModel.state = RTKCrossProgressionPanel_GetState()
		RTKStruct_SetValue( flow, flowModel )
	}
}

void function RTKCrossProgressionPanel_UpdateDataModel()
{
	RTKCrossProgressionPanel_SetMigrationModel()
	RTKCrossProgressionPanel_SetFlowModel()
}

int function RTKCrossProgressionPanel_GetState()
{
	if ( CrossProgression_IsOfflineMigration() )
		return file.offlineMigrationState

	if ( CrossProgression_IsMigrated() )
		return eCrossProgressionState.MIGRATED

	if ( !CrossProgression_IsMigrated() && IsCrossProgressing() )
		return eCrossProgressionState.MIGRATING

	if ( !CrossProgression_IsMigrated() && !IsCrossProgressing() )
		return eCrossProgressionState.ANNOUNCEMENT

	Assert( false, "Should be unreachable" )
	unreachable
}

void function RTKCrossProgressionPanel_SetHeader()
{
	string title
	string subtitle

	switch ( RTKCrossProgressionPanel_GetState() )
	{
		case eCrossProgressionState.MIGRATED:
			title = "#CROSS_PROGRESSION_PREVIEW_TITLE"
			subtitle = "#CROSS_PROGRESSION_PREVIEW_DESC"
			break
		case eCrossProgressionState.MIGRATING:
			title = "#CROSS_PROGRESSION_MIGRATING_TITLE"
			subtitle = ""
			break
		case eCrossProgressionState.ANNOUNCEMENT:
		default:
			title = "#CROSS_PROGRESSION_ROLLOUT_TITLE"
			subtitle = ""
			break
	}

	UI_CrossProgressionDialog_UpdateHeader( title, subtitle )
}

void function RTKCrossProgressionPanel_SetDialogHeight()
{
	float height

	switch ( RTKCrossProgressionPanel_GetState() )
	{
		case eCrossProgressionState.MIGRATED:
			height = 920.0
			break
		case eCrossProgressionState.MIGRATING:
		case eCrossProgressionState.ANNOUNCEMENT:
		default:
			height = 540.0
			break
	}

	UI_CrossProgressionDialog_SetHeight( height )
}

void function RTKCrossProgressionPanel_OnDestroy( rtk_behavior self )
{
	DeregisterButtonPressedCallback ( KEY_SPACE, OnContinue )
	DeregisterButtonPressedCallback ( BUTTON_A, OnContinue )
	DeregisterButtonPressedCallback( BUTTON_Y, OnButtonY )

	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, CROSS_PROGRESSION_DATA_MODEL_NAME )
}

bool function RTKMutator_HasNxProfile( rtk_array profiles )
{
	for ( int i = 0; i < RTKArray_GetCount( profiles ); i++ )
	{
		rtk_struct profile = RTKArray_GetStruct( profiles, i )

		if ( RTKStruct_GetInt( profile, "platformId" ) == HARDWARE_SWITCH )
			return true
	}

	return false
}
