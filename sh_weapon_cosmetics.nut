global function ShWeaponCosmetics_LevelInit

global function Loadout_WeaponSkin
global function Loadout_GetLore
global function WeaponSkin_GetWorldModel
global function WeaponSkin_GetViewModel
global function WeaponSkin_HasStoryBlurb
global function WeaponSkin_GetStoryBlurbBodyText
global function WeaponSkin_GetSkinName
global function WeaponSkin_GetCamoIndex
global function WeaponSkin_GetHackyRUISchemeIdentifier
global function WeaponSkin_DoesReactToKills
global function WeaponSkin_GetReactToKillsLevelCount
global function WeaponSkin_GetReactToKillsDataForLevel
global function WeaponSkin_GetSortOrdinal
global function WeaponSkin_GetWeaponFlavor
global function WeaponSkin_GetVideo

global function Loadout_WeaponCharm
global function WeaponCharm_IsTheEmpty
global function WeaponCharm_GetCharmModel
global function WeaponCharm_HasStoryBlurb
global function WeaponCharm_GetStoryBlurbBodyText
global function WeaponCharm_GetAttachmentName
global function WeaponCharm_GetSortOrdinal
global function GetWeaponThatCharmIsCurrentlyEquippedToForPlayer

























global function WeaponSkin_ShouldHideIfLocked








global struct WeaponReactiveKillsData
{
	int                killCount
	string             killSoundEvent1p
	string             killSoundEvent3p
	string             persistentSoundEvent1p
	string             persistentSoundEvent3p
	float              emissiveIntensity
	array<asset>       killFX1PList
	array<asset>       killFX3PList
	array<string>      killFXAttachmentList
	array<asset>       persistentFX1PList
	array<asset>       persistentFX3PList
	array<string>      persistentFXAttachmentList
	table<string, int> bodygroupSubmodelIdxMap
	array<string>      weaponModsToAdd
	array<string>      weaponModsToRemove
}







struct FileStruct_LifetimeLevel
{

	table<ItemFlavor, LoadoutEntry>             loadoutWeaponSkinSlotMap

	table<ItemFlavor, LoadoutEntry>             loadoutWeaponCharmSlotMap

	table<ItemFlavor, int> cosmeticFlavorSortOrdinalMap









}
FileStruct_LifetimeLevel& fileLevel

struct
{
	array< void functionref(entity, ItemFlavor, ItemFlavor) > callbacks_UpdatePlayerWeaponCosmetics
	array< void functionref( entity ) > callback_UpdatePlayerWeaponEffects
} file






void function ShWeaponCosmetics_LevelInit()
{
	FileStruct_LifetimeLevel newFileLevel
	fileLevel = newFileLevel

	AddCallback_OnItemFlavorRegistered( eItemType.loot_main_weapon, OnItemFlavorRegistered_LootMainWeapon )
	





}


void function OnItemFlavorRegistered_LootMainWeapon( ItemFlavor weaponFlavor )
{
	
	{
		array<ItemFlavor> skinList = RegisterReferencedItemFlavorsFromArray( weaponFlavor, "skins", "flavor" )
		MakeItemFlavorSet( skinList, fileLevel.cosmeticFlavorSortOrdinalMap )
		foreach( ItemFlavor skin in skinList )
		{
			SetupWeaponSkin( skin )
		}

		LoadoutEntry entry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "weapon_skin_for_" + ItemFlavor_GetGUIDString( weaponFlavor ), eLoadoutEntryClass.WEAPON )
		entry.category     = eLoadoutCategory.WEAPON_SKINS
#if DEV
			entry.pdefSectionKey = "weapon " + ItemFlavor_GetGUIDString( weaponFlavor )
			entry.DEV_name       = DEV_ItemFlavor_GetCleanedAssetPath( weaponFlavor ) + " Skin"
#endif
		entry.defaultItemFlavor   = skinList[1]
		entry.favoriteItemFlavor  = skinList[0]
		entry.validItemFlavorList = skinList
		entry.isSlotLocked        = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		entry.networkTo           = eLoadoutNetworking.PLAYER_EXCLUSIVE
		entry.maxFavoriteCount    = 8
















		AddCallback_ItemFlavorLoadoutSlotDidChange_AnyPlayer( entry, void function( EHI playerEHI, ItemFlavor skin ) : ( weaponFlavor, entry ) {



		} )
		fileLevel.loadoutWeaponSkinSlotMap[weaponFlavor] <- entry
	}

	
	{
		array<ItemFlavor> charmList = RegisterReferencedItemFlavorsFromArray( weaponFlavor, "charms", "flavor" )
		MakeItemFlavorSet( charmList, fileLevel.cosmeticFlavorSortOrdinalMap )
		foreach( ItemFlavor charm in charmList )
		{
			SetupWeaponCharm( charm )
		}

		LoadoutEntry charmEntry = RegisterLoadoutSlot( eLoadoutEntryType.ITEM_FLAVOR, "weapon_charm_for_" + ItemFlavor_GetGUIDString( weaponFlavor ), eLoadoutEntryClass.WEAPON )
		charmEntry.category     = eLoadoutCategory.WEAPON_CHARMS
#if DEV
			charmEntry.pdefSectionKey = "weapon " + ItemFlavor_GetGUIDString( weaponFlavor )
			charmEntry.DEV_name       = DEV_ItemFlavor_GetCleanedAssetPath( weaponFlavor ) + " Charm"
#endif
		charmEntry.defaultItemFlavor    = charmList[0]
		charmEntry.validItemFlavorList  = charmList
		charmEntry.isSlotLocked         = bool function( EHI playerEHI ) {
			return !IsLobby()
		}
		charmEntry.networkTo            = eLoadoutNetworking.PLAYER_EXCLUSIVE
		charmEntry.isItemFlavorUnlocked = bool function( EHI playerEHI, ItemFlavor flavor, bool shouldIgnoreGRX = false, bool shouldIgnoreOtherSlots = false ) : ( weaponFlavor ) {
			if ( !shouldIgnoreOtherSlots ) 
			{
				ItemFlavor ornull flavorCurrentWeaponEquippedTo = GetWeaponThatCharmIsCurrentlyEquippedToForPlayer( playerEHI, flavor )
				if ( flavorCurrentWeaponEquippedTo != null && flavorCurrentWeaponEquippedTo != weaponFlavor )
					return false
			}
			return IsItemFlavorGRXUnlockedForLoadoutSlot( playerEHI, flavor, shouldIgnoreGRX, shouldIgnoreOtherSlots )
		}


















		AddCallback_ItemFlavorLoadoutSlotDidChange_AnyPlayer( charmEntry, void function( EHI playerEHI, ItemFlavor charm ) : ( weaponFlavor, charmEntry ) {



		} )

		fileLevel.loadoutWeaponCharmSlotMap[weaponFlavor] <- charmEntry
	}
}

void function SetupWeaponCharm( ItemFlavor charm )
{
	string charmModel = WeaponCharm_GetCharmModel( charm )





}

void function SetupWeaponSkin( ItemFlavor skin )
{
	if ( ItemFlavor_IsTheFavoriteSentinel( skin ) )
		return

	asset worldModel = WeaponSkin_GetWorldModel( skin )
	asset viewModel  = WeaponSkin_GetViewModel( skin )





















































}







LoadoutEntry function Loadout_WeaponSkin( ItemFlavor weaponFlavor )
{
	return fileLevel.loadoutWeaponSkinSlotMap[weaponFlavor]
}

asset ornull function Loadout_GetLore( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.loot_main_weapon )

	asset lore = GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "loreFlav" )

	if ( lore == "" )
		return null

	return lore
}

LoadoutEntry function Loadout_WeaponCharm( ItemFlavor weaponFlavor )
{
	return fileLevel.loadoutWeaponCharmSlotMap[weaponFlavor]
}


bool function WeaponCharm_IsTheEmpty( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "isTheEmpty" )
}

string function WeaponCharm_GetCharmModel( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	string charmName = GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "charmModel" )
	if ( charmName == $"" )
		return charmName;
	return charmName + ".rmdl"
}

bool function WeaponCharm_HasStoryBlurb( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	return ( WeaponCharm_GetStoryBlurbBodyText( flavor ) != "" )
}

string function WeaponCharm_GetStoryBlurbBodyText( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "customSkinMenuBlurb" )
}

string function WeaponCharm_GetAttachmentName( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "attachmentName" )
}

int function WeaponCharm_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_charm )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}


ItemFlavor ornull function GetWeaponThatCharmIsCurrentlyEquippedToForPlayer( EHI playerEHI, ItemFlavor charmFlav )
{
	if ( WeaponCharm_IsTheEmpty( charmFlav ) )
		return null

	foreach ( ItemFlavor weaponFlav in GetAllWeaponItemFlavors() )
	{
		LoadoutEntry otherEntry = Loadout_WeaponCharm( weaponFlav )

		if ( LoadoutSlot_GetItemFlavor_ForValidation( playerEHI, otherEntry ) == charmFlav )
			return weaponFlav
	}

	return null
}


int function WeaponSkin_GetSortOrdinal( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return fileLevel.cosmeticFlavorSortOrdinalMap[flavor]
}


















































































































ItemFlavor function WeaponSkin_GetWeaponFlavor( ItemFlavor skin )
{
	Assert( ItemFlavor_GetType( skin ) == eItemType.weapon_skin )

	Assert( GetGlobalSettingsAsset( ItemFlavor_GetAsset( skin ), "parentItemFlavor" ) != "", "No parentItemFlavor for skin "+ string(ItemFlavor_GetAsset( skin )) )

	return GetItemFlavorByAsset( GetGlobalSettingsAsset( ItemFlavor_GetAsset( skin ), "parentItemFlavor" ) )
}


asset function WeaponSkin_GetWorldModel( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "worldModel" )
}


asset function WeaponSkin_GetViewModel( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsAsset( ItemFlavor_GetAsset( flavor ), "viewModel" )
}


string function WeaponSkin_GetSkinName( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "skinName" )
}

bool function WeaponSkin_HasStoryBlurb( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return ( WeaponSkin_GetStoryBlurbBodyText( flavor ) != "" )
}

string function WeaponSkin_GetStoryBlurbBodyText( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsString( ItemFlavor_GetAsset( flavor ), "customSkinMenuBlurb" )
}

int function WeaponSkin_GetCamoIndex( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsInt( ItemFlavor_GetAsset( flavor ), "camoIndex" )
}


int function WeaponSkin_GetHackyRUISchemeIdentifier( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsInt( ItemFlavor_GetAsset( flavor ), "hackyRUISchemeIdentifier" )
}


bool function WeaponSkin_DoesReactToKills( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "featureReactsToKills" )
}


int function WeaponSkin_GetReactToKillsLevelCount( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )
	Assert( WeaponSkin_DoesReactToKills( flavor ) )

	var skinBlock = ItemFlavor_GetSettingsBlock( flavor )
	return GetSettingsArraySize( GetSettingsBlockArray( skinBlock, "featureReactsToKillsLevels" ) )
}


WeaponReactiveKillsData function WeaponSkin_GetReactToKillsDataForLevel( ItemFlavor flavor, int levelIdx )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )
	Assert( WeaponSkin_DoesReactToKills( flavor ) )

	var skinBlock           = ItemFlavor_GetSettingsBlock( flavor )
	var reactsToKillsLevels = GetSettingsBlockArray( skinBlock, "featureReactsToKillsLevels" )
	Assert( levelIdx < GetSettingsArraySize( reactsToKillsLevels ) )
	var levelBlock = GetSettingsArrayElem( reactsToKillsLevels, levelIdx )

	WeaponReactiveKillsData rtked
	rtked.killCount = GetSettingsBlockInt( levelBlock, "killCount" )
	rtked.killSoundEvent1p = GetSettingsBlockString( levelBlock, "killSoundEvent1p" )
	rtked.killSoundEvent3p = GetSettingsBlockString( levelBlock, "killSoundEvent3p" )
	rtked.persistentSoundEvent1p = GetSettingsBlockString( levelBlock, "persistentSoundEvent1p" )
	rtked.persistentSoundEvent3p = GetSettingsBlockString( levelBlock, "persistentSoundEvent3p" )
	rtked.emissiveIntensity = GetSettingsBlockFloat( levelBlock, "emissiveIntensity" )
	foreach ( var killFXBlock in IterateSettingsArray( GetSettingsBlockArray( levelBlock, "killFXList" ) ) )
	{
		rtked.killFX1PList.append( GetSettingsBlockStringAsAsset( killFXBlock, "fx1p" ) )
		rtked.killFX3PList.append( GetSettingsBlockStringAsAsset( killFXBlock, "fx3p" ) )
		rtked.killFXAttachmentList.append( GetSettingsBlockString( killFXBlock, "attachment" ) )
	}
	foreach ( var persistentFXBlock in IterateSettingsArray( GetSettingsBlockArray( levelBlock, "persistentFXList" ) ) )
	{
		rtked.persistentFX1PList.append( GetSettingsBlockStringAsAsset( persistentFXBlock, "fx1p" ) )
		rtked.persistentFX3PList.append( GetSettingsBlockStringAsAsset( persistentFXBlock, "fx3p" ) )
		rtked.persistentFXAttachmentList.append( GetSettingsBlockString( persistentFXBlock, "attachment" ) )
	}
	foreach ( var bodygroupChangeBlock in IterateSettingsArray( GetSettingsBlockArray( levelBlock, "bodygroupChangeList" ) ) )
	{
		string name     = GetSettingsBlockString( bodygroupChangeBlock, "bodygroupName" )
		int submodelIdx = GetSettingsBlockInt( bodygroupChangeBlock, "submodelIdx" )
		rtked.bodygroupSubmodelIdxMap[name] <- submodelIdx
	}
	foreach ( var weaponModBlock in IterateSettingsArray( GetSettingsBlockArray( levelBlock, "weaponModListAdd" ) ) )
	{
		rtked.weaponModsToAdd.append( GetSettingsBlockString( weaponModBlock, "weaponMod" ) )
	}
	foreach ( var weaponModBlock in IterateSettingsArray( GetSettingsBlockArray( levelBlock, "weaponModListRemove" ) ) )
	{
		rtked.weaponModsToRemove.append( GetSettingsBlockString( weaponModBlock, "weaponMod" ) )
	}
	return rtked
}


asset function WeaponSkin_GetVideo( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsStringAsAsset( ItemFlavor_GetAsset( flavor ), "video" )
}


bool function WeaponSkin_ShouldHideIfLocked( ItemFlavor flavor )
{
	Assert( ItemFlavor_GetType( flavor ) == eItemType.weapon_skin )

	return GetGlobalSettingsBool( ItemFlavor_GetAsset( flavor ), "shouldHideIfLocked" )
}



const bool CHARM_DEBUG = false





























































































































































































void function AddCallback_UpdatePlayerWeaponEffects( void functionref( entity player ) callbackFunc )
{
	Assert( !file.callback_UpdatePlayerWeaponEffects.contains( callbackFunc ), "Already added " + string( callbackFunc ) + " with AddCallback_UpdatePlayerWeaponEffects" )
	file.callback_UpdatePlayerWeaponEffects.append( callbackFunc )
}





















