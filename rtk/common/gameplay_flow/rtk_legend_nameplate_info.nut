global function RTKLegendNameplateInfo_OnInitialize
global function RTKLegendNameplateInfo_OnDestroy
global function RTKLegendNameplateInfo_OnVisualChange

global struct RTKLegendNameplateInfo_Properties
{
	string characterGUID
}

global struct RTKLegendNameplateInfo_Perk_Description
{
	string perkDescriptionString
	asset perkIconImage
}

global struct RTKLegendNameplateInfo
{
	string nameString
	string footnoteString
	string classNameString
	string classFootnoteString
	asset classIconImage
	array< RTKLegendNameplateInfo_Perk_Description > perkDescription = []
}

struct PrivateData
{
	rtk_struct legendNameplateInfo
	string	   charGuid
}

void function RTKLegendNameplateInfo_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	p.legendNameplateInfo = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "nameplate", "", [ "legendInfo" ] )
}

void function RTKLegendNameplateInfo_OnDestroy( rtk_behavior self )
{
	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "nameplate", [ "legendInfo" ] )
}

void function RTKLegendNameplateInfo_OnVisualChange( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	string charGuid = self.PropGetString( "characterGUID" )
	if ( charGuid == "" )
		return

	if ( charGuid == p.charGuid )
		return

	p.charGuid = charGuid

	SettingsAssetGUID characterGuid = ConvertItemFlavorGUIDStringToGUID(charGuid)
	if (!IsValidItemFlavorGUID( characterGuid ))
	{
		Assert( false, "The provided GUID isn't valid" )
		return
	}

	ItemFlavor character = GetItemFlavorByGUID( characterGuid )

	RTKLegendNameplateInfo legendInfo
	legendInfo.nameString = Localize( ItemFlavor_GetLongName( character ) )
	legendInfo.footnoteString = Localize( ItemFlavor_GetShortDescription( character ) )
	legendInfo.classNameString = Localize( CharacterClass_GetRoleTitle (CharacterClass_GetRole( character )).toupper() )
	legendInfo.classFootnoteString = Localize( CharacterClass_GetRoleSubtitle (CharacterClass_GetRole( character )).toupper() )
	legendInfo.classIconImage = CharacterClass_GetRoleIcon(CharacterClass_GetRole( character ) )

	int legendRole = CharacterClass_GetRole( character )
	ClassRoleSettingsInfo info = Perks_GetSettingsInfoForClassRole( legendRole )
	for( int i = 0; i < info.perks.len(); i++ )
	{
		RTKLegendNameplateInfo_Perk_Description perkDesc
		perkDesc.perkDescriptionString = Localize( CharacterClass_GetRolePerkShortDescriptionAtIndex(CharacterClass_GetRole( character ), i).toupper() )
		perkDesc.perkIconImage = CharacterClass_GetRolePerkIconAtIndex(CharacterClass_GetRole( character ), i )

		legendInfo.perkDescription.append(perkDesc)
	}

	rtk_struct LegendInfoStruct = RTKStruct_GetOrCreateScriptStruct(p.legendNameplateInfo, "info", "RTKLegendNameplateInfo")

	RTKStruct_SetValue( LegendInfoStruct, legendInfo )

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "nameplate", true, [ "legendInfo" ] ) )
}

