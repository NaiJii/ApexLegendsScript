global function ShStickers_LevelInit
global function Loadout_Sticker






global function GetMaxStickersForObjectType

global function GetAllStickerObjectTypes
global function GetStickerObjectName
global function GetStickerPresentationType
global function CreateNestedRuiForSticker


global function Sticker_IsTheEmpty
global function Sticker_GetStoryBlurbBodyText
global function Sticker_HasStoryBlurb
global function Sticker_GetDecalMaterialAsset
global function Sticker_GetReplacementMaterialAsset
global function Sticker_GetSortOrdinal
global function Sticker_GetDecalScale























#if DEV
global function DEV_PrintStickerLoadout
#endif

global enum eStickerObjectType
{
	injector,
	shield_cell,
	shield_battery,
	phoenix_kit,
}









struct StickerFlashData
{
	entity flashEnt
	int    flashType
	vector flashColor
}

struct FileStruct_LifetimeLevel
{
	table<int, array<LoadoutEntry> > stickerSlotMap
	table<ItemFlavor, int>           stickerSortOrdinalMap

	table<int, StickerFlashData> stickerFlashData
}
FileStruct_LifetimeLevel& fileLevel


void function ShStickers_LevelInit()
{
	FileStruct_LifetimeLevel newFileLevel
	fileLevel = newFileLevel









	AddCallback_RegisterRootItemFlavors( RegisterStickers )








}


void function RegisterStickers()
{
	array<ItemFlavor> stickerItemList = []
	foreach ( asset stickerAsset in GetBaseItemFlavorsFromArray( "stickers" ) )
	{
		if ( stickerAsset == $"" )
			continue

		ItemFlavor ornull stickerItem = RegisterItemFlavorFromSettingsAsset( stickerAsset )
		if ( stickerItem == null )
			continue

		expect ItemFlavor( stickerItem )
		stickerItemList.append( stickerItem )
	}

	MakeItemFlavorSet( stickerItemList, fileLevel.stickerSortOrdinalMap )

	foreach ( int stickerObjectType in eStickerObjectType )
	{
		fileLevel.stickerSlotMap[stickerObjectType] <- []
		string stickerObjectName = GetEnumString( "eStickerObjectType", stickerObjectType )

		for ( int i = 0; i < GetMaxStickersForObjectType( stickerObjectType ); i++ )
		{
			LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, stickerObjectName + "_sticker_" + i, eLoadoutEntryClass.ACCOUNT )
			entry.category     = eLoadoutCategory.STICKERS
#if DEV
				entry.DEV_name       = "Sticker " + stickerObjectName + " " + i
#endif
			entry.defaultItemFlavor   = stickerItemList[0]
			entry.validItemFlavorList = stickerItemList
			entry.isSlotLocked        = bool function( EHI playerEHI ) { return !IsLobby()	}
			entry.networkTo           = eLoadoutNetworking.PLAYER_EXCLUSIVE

			fileLevel.stickerSlotMap[stickerObjectType].append( entry )

			
			










		}
	}

	









}




































































































int function GetMaxStickersForObjectType( int stickerObjectType )
{
	if ( stickerObjectType == eStickerObjectType.injector )
		return 1

	return 3
}


array<int> function GetAllStickerObjectTypes()
{
	array<int> stickerObjectTypes
	foreach ( int stickerObjectType in eStickerObjectType )
		stickerObjectTypes.append( stickerObjectType )

	return stickerObjectTypes
}


string function GetStickerObjectName( int stickerObjectType )
{
	switch ( stickerObjectType )
	{
		case eStickerObjectType.shield_cell:
			return "#SURVIVAL_PICKUP_HEALTH_COMBO_SMALL"

		case eStickerObjectType.shield_battery:
			return "#SURVIVAL_PICKUP_HEALTH_COMBO_LARGE"

		case eStickerObjectType.phoenix_kit:
			return "#SURVIVAL_PICKUP_HEALTH_COMBO_FULL"

		case eStickerObjectType.injector:
			return "#HEALTH_INJECTOR"
	}

	Assert( false, "Unsupported stickerObjectType value " + stickerObjectType + " passed to GetStickerObjectName()" )
	unreachable
}


int function GetStickerPresentationType( int stickerObjectType )
{
	switch ( stickerObjectType )
	{
		case eStickerObjectType.injector:
			return ePresentationType.APPLIED_STICKER_INJECTOR

		case eStickerObjectType.shield_cell:
			return ePresentationType.APPLIED_STICKER_SMALL_CELL

		case eStickerObjectType.shield_battery:
		case eStickerObjectType.phoenix_kit:
			return ePresentationType.APPLIED_STICKER_LARGE_CELL
	}

	Assert( false, "Unsupported stickerObjectType value " + stickerObjectType + " passed to GetStickerPresentationType()" )
	unreachable
}


var function CreateNestedRuiForSticker( var baseRui, string argName, ItemFlavor stickerItem )
{
	var nestedRui = RuiCreateNested( baseRui, argName, $"ui/basic_image.rpak" )
	RuiSetImage( nestedRui, "basicImage", ItemFlavor_GetIcon( stickerItem ) )	

	return nestedRui
}



LoadoutEntry function Loadout_Sticker( int stickerObjectType, int index )
{
	return fileLevel.stickerSlotMap[stickerObjectType][index]
}

bool function Sticker_HasStoryBlurb( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.sticker )

	return ( Sticker_GetStoryBlurbBodyText( flavor ) != "" )
}

string function Sticker_GetStoryBlurbBodyText( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.sticker )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "customSkinMenuBlurb" )
}

bool function Sticker_IsTheEmpty( ItemFlavor stickerItem )
{
	Assert( ItemFlavor_GetType( stickerItem ) == eItemType.sticker )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( stickerItem ), "isTheEmpty" )
}


asset function Sticker_GetDecalMaterialAsset( ItemFlavor stickerItem )
{
	Assert( ItemFlavor_GetType( stickerItem ) == eItemType.sticker )

	return GetKeyValueAsAsset( { kn = GetGlobalSettingsAsset( ItemFlavor_GetAsset( stickerItem ), "stickerMaterial" ) + "_rgdu.rpak" }, "kn" );
}


asset function Sticker_GetReplacementMaterialAsset( ItemFlavor stickerItem )
{
	Assert( ItemFlavor_GetType( stickerItem ) == eItemType.sticker )

	return GetKeyValueAsAsset( { kn = GetGlobalSettingsAsset( ItemFlavor_GetAsset( stickerItem ), "nonDecalStickerMaterial" ) + "_rgdp.rpak" }, "kn" );
}

int function Sticker_GetSortOrdinal( ItemFlavor stickerItem )
{
	Assert( ItemFlavor_GetType( stickerItem ) == eItemType.sticker )

	return fileLevel.stickerSortOrdinalMap[stickerItem]
}

float function Sticker_GetDecalScale( ItemFlavor stickerItem, int stickerObjectType, int targetSlot )
{
	Assert( ItemFlavor_GetType( stickerItem ) == eItemType.sticker )

	string defaultKey = ""
	string arrayKey = ""
	switch ( stickerObjectType )
	{
		case eStickerObjectType.shield_cell:
			defaultKey = "shieldCellScale"
			arrayKey = "shieldCellScales"
			break

		case eStickerObjectType.shield_battery:
			defaultKey = "shieldBatteryScale"
			arrayKey = "shieldBatteryScales"
			break

		case eStickerObjectType.phoenix_kit:
			defaultKey = "phoenixKitScale"
			arrayKey = "phoenixKitScales"
			break

		case eStickerObjectType.injector:
			defaultKey = "injectorScale"
			arrayKey = "injectorScales"
			break

		default:
			return 0
	}

	asset stickerAsset = ItemFlavor_GetAsset( stickerItem )

	foreach ( var block in IterateSettingsAssetArray( stickerAsset, arrayKey ) )
	{
		int slot = GetSettingsBlockInt( block, "slot" )
		if ( slot == targetSlot )
			return GetSettingsBlockFloat( block , "scale" )
	}

	return GetGlobalSettingsFloat( stickerAsset, defaultKey )
}

































































































































































#if DEV
void function DEV_PrintStickerLoadout()
{
	EHI playerEHI = ToEHI( GetLocalClientPlayer() )

	LoadoutEntry injectorStickerSlot = Loadout_Sticker( eStickerObjectType.injector, 0 )
	ItemFlavor injectorSticker = LoadoutSlot_GetItemFlavor( playerEHI, injectorStickerSlot )
	printt( "injectorStickerSlot contains:     ", string(ItemFlavor_GetAsset( injectorSticker )) )

	LoadoutEntry shieldCellStickerSlot = Loadout_Sticker( eStickerObjectType.shield_cell, 0 )
	ItemFlavor shieldCellSticker = LoadoutSlot_GetItemFlavor( playerEHI, shieldCellStickerSlot )
	printt( "shieldCellStickerSlot contains:   ", string(ItemFlavor_GetAsset( shieldCellSticker )) )

	LoadoutEntry shieldBatteryStickerSlot = Loadout_Sticker( eStickerObjectType.shield_battery, 0 )
	ItemFlavor shieldBatterySticker = LoadoutSlot_GetItemFlavor( playerEHI, shieldBatteryStickerSlot )
	printt( "shieldBatteryStickerSlot contains:", string(ItemFlavor_GetAsset( shieldBatterySticker )) )

	LoadoutEntry phoenixKitStickerSlot = Loadout_Sticker( eStickerObjectType.phoenix_kit, 0 )
	ItemFlavor phoenixKitSticker = LoadoutSlot_GetItemFlavor( playerEHI, phoenixKitStickerSlot )
	printt( "phoenixKitStickerSlot contains:   ", string(ItemFlavor_GetAsset( phoenixKitSticker )) )
}
#endif

