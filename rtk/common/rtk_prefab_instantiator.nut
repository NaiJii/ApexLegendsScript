global function RTKPrefabInstantiator_OnInitialize
global function RTKPrefabInstantiator_Instantiate
global function RTKPrefabInstantiator_SetPrefabArray
global function RTKPrefabInstantiator_SetIndexManual

global struct RTKPrefabInstantiator_Properties
{
	int prefabIndex
	array<asset> prefabArray
	string instanceName = "PrefabInstance"

	rtk_panel parentPanel
	rtk_panel prevInstance
	int prevIndex = -1
}

void function RTKPrefabInstantiator_OnInitialize( rtk_behavior self )
{
	RTKStruct_AddPropertyListener( self.GetProperties(), "prefabIndex", void function ( rtk_struct properties, string propName, int propType, var propValue ) : ( self ) {
		RTKPrefabInstantiator_Instantiate( self )
	} )
}

void function RTKPrefabInstantiator_Instantiate( rtk_behavior self )
{
	
	int index = self.PropGetInt( "prefabIndex" )
	int PrevIndex = self.PropGetInt( "prevIndex" )

	rtk_array prefabs = self.PropGetArray( "prefabArray" )
	if ( index < 0 || index >= RTKArray_GetCount( prefabs ) )
		return

	asset prefab = RTKArray_GetAssetPath( prefabs, index )
	if ( prefab == RTKArray_GetAssetPath( prefabs, PrevIndex ) )
		return

	
	rtk_panel ornull parentPanel = self.PropGetPanel( "parentPanel" )
	if ( parentPanel == null )
		parentPanel = self.GetPanel()
	expect rtk_panel ( parentPanel )

	
	rtk_panel ornull prevInstance = self.PropGetPanel( "prevInstance" )
	if ( prevInstance != null )
		RTKPanel_Destroy( expect rtk_panel( prevInstance ) )

	
	string instanceName = self.PropGetString( "instanceName" )
	rtk_panel newInstance = RTKPanel_Instantiate( prefab, parentPanel, instanceName )
	self.PropSetPanel( "prevInstance", newInstance )
	self.PropSetInt( "prevIndex", index )
	newInstance.SetBindingRootPath( "*" )
}


void function RTKPrefabInstantiator_SetPrefabArray( rtk_behavior self, array<asset> prefabs )
{
	rtk_array rtkArray
	RTKArray_SetValue( rtkArray , prefabs )
	self.PropSetArray( "prefabArray", rtkArray )
}


void function RTKPrefabInstantiator_SetIndexManual( rtk_behavior self, int index )
{
	self.PropSetInt( "prefabIndex", index )
}
