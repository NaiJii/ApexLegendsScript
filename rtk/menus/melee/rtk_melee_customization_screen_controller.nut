global function RTKMeleeCustomizationScreen_InitMetaData
global function RTKMeleeCustomizationScreen_OnInitialize
global function RTKMeleeCustomizationScreen_OnDestroy

global function InitMeleeCustomizationMenu
global function InitMeleeCustomizationPanel
global function MeleeCustomizationScreen_ClientToUI_UpdateDeathboxEquipState

global struct RTKMeleeCustomizationScreen_Properties
{
	rtk_behavior equipButton

	rtk_panel deathboxList




}

global struct MeleeCustomizationItemModel
{
	string name
	int quality
	asset eventIcon
	bool equipped
	bool locked
	bool selected
	string actionText
}

global struct MeleeCustomizationModel
{
	MeleeCustomizationItemModel& previewItem
	string videoAsset

	array<MeleeCustomizationItemModel> listDeathboxes




}

struct
{
	bool isVisible = false
	array<ItemFlavor> deathboxSkins = []






	int focusedIndex = -1
	int previewIndex = -1
} file

struct PrivateData
{
	int menuGUID = -1
}







void function RTKMeleeCustomizationScreen_InitMetaData( string behaviorType, string structType )
{
	RTKMetaData_BehaviorIsRuiBehavior( behaviorType, true )
}

void function RTKMeleeCustomizationScreen_OnInitialize( rtk_behavior self )
{
	PrivateData p
	self.Private( p )








	{
		MeleeCustomizationScreen_OnInitialize( self )
	}

	
	int menuGUID = AssignMenuGUID()
	p.menuGUID = menuGUID
	RTKFooters_Add( menuGUID, LEFT, BUTTON_B, "#B_BUTTON_BACK", BUTTON_INVALID, "#B_BUTTON_BACK", ExitCustomization )



	{
		RTKFooters_Add( menuGUID, LEFT, BUTTON_X, "#X_BUTTON_EVENT_SHOP", BUTTON_INVALID, "#X_BUTTON_EVENT_SHOP", EquipFocusedDeathbox, CanUnlockFocusedEventShop )
		RTKFooters_Add( menuGUID, LEFT, BUTTON_X, "#X_BUTTON_SELECT", BUTTON_INVALID, "#X_BUTTON_SELECT", EquipFocusedDeathbox, CanEquipFocusedDeathbox )
	}
	RTKFooters_Update()

	file.isVisible = true

	self.GetPanel().SetBindingRootPath( RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, "meleeCustomization", true, ["legend"] ) )
}

void function RTKMeleeCustomizationScreen_OnDestroy( rtk_behavior self )
{
	file.isVisible = false

	PrivateData p
	self.Private( p )

	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "meleeCustomization", ["legend"] )

	file.deathboxSkins.clear()





	RTKFooters_RemoveAll( p.menuGUID )
	RTKFooters_Update()
}

void function MeleeCustomizationScreen_OnInitialize( rtk_behavior self )
{
	
	file.deathboxSkins = GetSelectableDeathboxSkins()

	
	rtk_struct rtkModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "meleeCustomization", "MeleeCustomizationModel", ["legend"] )
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listDeathboxes" )
	foreach (int index, ItemFlavor itemFlav in file.deathboxSkins)
	{
		rtk_struct listItemEntry = RTKArray_PushNewStruct( listItems )

		MeleeCustomizationItemModel listItem
		listItem.name = Localize( ItemFlavor_GetLongName( itemFlav ) )
		listItem.quality = ItemFlavor_GetQuality( itemFlav )
		listItem.eventIcon = ItemFlavor_GetSourceIcon( itemFlav )
		listItem.equipped = IsDeathboxEquipped( itemFlav )
		listItem.locked = !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_Deathbox( GetTopLevelCustomizeContext() ), itemFlav )
		listItem.selected = false

		if ( !listItem.locked )
			listItem.actionText = "#SELECT"
		else
			listItem.actionText = IsRewardForActiveEvent( itemFlav ) ? "#MENU_STORE_PANEL_EVENT_SHOP" : "#UNLOCK"

		RTKStruct_SetValue( listItemEntry, listItem )
	}

	
	PreviewDeathbox( 0 )

	
	rtk_panel ornull itemList = self.PropGetPanel( "deathboxList" )
	if ( itemList != null )
	{
		expect rtk_panel( itemList )
		self.AutoSubscribe( itemList, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ){
			array< rtk_behavior > itemListButtons = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in itemListButtons )
			{
				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex ) {
					if ( keycode == MOUSE_RIGHT )
						EquipDeathboxToCharacter( newChildIndex )
					else
						EmitUISound( "UI_Menu_Banner_Preview" )

					PreviewDeathbox( newChildIndex )
				} )

				self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, newChildIndex ) {
					file.focusedIndex = newChildIndex
					RTKFooters_Update()
				} )

				self.AutoSubscribe( button, "onIdle", function( rtk_behavior button, int prevState ) : ( self ) {
					file.focusedIndex = -1
					RTKFooters_Update()
				} )
			}
		} )
	}

	
	rtk_behavior ornull equipButton = self.PropGetBehavior( "equipButton" )
	if ( equipButton != null )
	{
		expect rtk_behavior( equipButton )
		self.AutoSubscribe( equipButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			EquipDeathboxAtIndex( file.previewIndex )
		} )
	}
}













































































bool function CanUnlockFocusedDeathbox()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.deathboxSkins.len() )
		return false

	return !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_Deathbox( GetTopLevelCustomizeContext() ), file.deathboxSkins[ file.focusedIndex ] ) && !IsRewardForActiveEvent( file.deathboxSkins[ file.focusedIndex ] )
}

bool function CanEquipFocusedDeathbox()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.deathboxSkins.len() )
		return false

	if ( !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_Deathbox( GetTopLevelCustomizeContext() ), file.deathboxSkins[ file.focusedIndex ] ) )
		return false

	return !IsDeathboxEquipped( file.deathboxSkins[ file.focusedIndex ] )
}

bool function CanUnlockFocusedEventShop()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.deathboxSkins.len() )
		return false

	return !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_Deathbox( GetTopLevelCustomizeContext() ), file.deathboxSkins[ file.focusedIndex ] ) && IsRewardForActiveEvent( file.deathboxSkins[ file.focusedIndex ] )
}

void function InitMeleeCustomizationMenu( var menu )
{
	SetDialog( menu, true )
	SetClearBlur( menu, false )
}

void function InitMeleeCustomizationPanel( var panel )
{
	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, MeleeCustomizationPanel_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, MeleeCustomizationPanel_OnHide )
}

void function MeleeCustomizationPanel_OnShow( var panel )
{













	SetCurrentTabForPIN( Hud_GetHudName( panel ) )
}

void function MeleeCustomizationPanel_OnHide( var panel )
{













	OnMeleeCustomizationClosed()
}

array<ItemFlavor> function GetSelectableDeathboxSkins()
{
	ItemFlavor character = GetTopLevelCustomizeContext()
	LoadoutEntry entry = Loadout_Deathbox( character )






	EHI playerEHI = LocalClientEHI()
	array<ItemFlavor> allDeathboxSkins = clone GetValidItemFlavorsForLoadoutSlot( playerEHI, entry )

	array<ItemFlavor> selectableDeathboxSkins
	foreach ( ItemFlavor deathboxSkin in allDeathboxSkins )
	{
		
		if ( !IsItemFlavorUnlockedForLoadoutSlot( playerEHI, entry, deathboxSkin ) && MeleeCustomization_ShouldHideIfLocked( deathboxSkin ) && !IsRewardForActiveEvent( deathboxSkin ) )
			continue

		selectableDeathboxSkins.append( deathboxSkin )
	}

	
	selectableDeathboxSkins.sort( int function( ItemFlavor a, ItemFlavor b ) : () {
		
		bool aIsEquipped = IsDeathboxEquipped( a )
		bool bIsEquipped = IsDeathboxEquipped( b )
		if ( aIsEquipped && !bIsEquipped )
			return -1
		else if ( bIsEquipped && !aIsEquipped )
			return 1

		
		int aQuality = ItemFlavor_HasQuality( a ) ? ItemFlavor_GetQuality( a ) : -1
		int bQuality = ItemFlavor_HasQuality( b ) ? ItemFlavor_GetQuality( b ) : -1
		if ( aQuality > bQuality )
			return -1
		else if ( aQuality < bQuality )
			return 1

		
		string aTag = string(ItemFlavor_GetSourceIcon( a ))
		string bTag = string(ItemFlavor_GetSourceIcon( b ))
		if ( aTag > bTag )
			return -1
		else if ( aTag < bTag )
			return 1

		
		return SortStringAlphabetize( Localize( ItemFlavor_GetLongName( a ) ), Localize( ItemFlavor_GetLongName( b ) ) )
	} )

	return selectableDeathboxSkins
}

bool function IsRewardForActiveEvent( ItemFlavor item )
{
	ItemFlavor ornull activeEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
	if ( activeEvent != null )
	{
		expect ItemFlavor( activeEvent )
		return MilestoneEvent_IsMilestoneGrantReward( activeEvent, ItemFlavor_GetGRXIndex( item ) )
	}

	return false
}

void function PreviewDeathbox( int index )
{
	if ( index < 0 || index >= file.deathboxSkins.len() )
		return

	file.previewIndex = index

	asset videoAsset = GetGlobalSettingsStringAsAsset( ItemFlavor_GetAsset( file.deathboxSkins[ index ] ), "video" )
	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "meleeCustomization", true, [ "legend" ] ) )
	RTKStruct_SetString( rtkModel, "videoAsset", string( videoAsset ) )

	
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listDeathboxes" )
	int listItemCount = RTKArray_GetCount( listItems )
	for ( int i = 0; i < listItemCount; i++ )
	{
		bool selected = ( i == index )

		rtk_struct entry = RTKArray_GetStruct( listItems, i )
		RTKStruct_SetBool( entry, "selected", selected )
		if ( selected )
			RTKStruct_SetStruct( rtkModel, "previewItem", entry )
	}
}

bool function EquipDeathboxToCharacter( int index )
{
	if ( index < 0 || index >= file.deathboxSkins.len() )
		return false

	ItemFlavor character = GetTopLevelCustomizeContext()
	LoadoutEntry entry = Loadout_Deathbox( character )
	EHI playerEHI = LocalClientEHI()

	if ( !IsItemFlavorUnlockedForLoadoutSlot( playerEHI, entry, file.deathboxSkins[ index ] ) )
	{
		
		if ( IsRewardForActiveEvent( file.deathboxSkins[ index ] ) )
		{
			EmitUISound( "ui_menu_accept" )
			EventsPanel_SetOpenPageIndex( eEventsPanelPage.MILESTONES )
			JumpToSeasonTab( "RTKEventsPanel" )
		}
		else
		{
			EmitUISound( "menu_deny" )
		}

		return false
	}

	ItemFlavor ornull selectedMeleeSkin = GetLegendMeleeCustomizeItem()
	if ( selectedMeleeSkin == null )
		return false

	expect ItemFlavor( selectedMeleeSkin )

	if ( IsDeathboxEquipped( file.deathboxSkins[ index ] ) )
	{
		EmitUISound( "UI_Menu_Banner_Preview" )
		return false
	}

	PIN_Customization( character, selectedMeleeSkin, "deathbox_equip" )
	RequestToggleGoldenHorseDeathboxEquipForMeleeSkin( playerEHI, Loadout_MeleeSkin( character ), selectedMeleeSkin )

	EmitUISound( "UI_Menu_Equip_Generic" )

	return true
}

void function EquipDeathboxAtIndex( int index )
{
	if ( index < 0 )
		return

	EquipDeathboxToCharacter( index )
}

void function EquipFocusedDeathbox( var unused )
{
	EquipDeathboxAtIndex( file.focusedIndex )
}

void function ExitCustomization( var unused )
{
	UICodeCallback_NavigateBack()
}

bool function IsDeathboxEquipped( ItemFlavor deathbox )
{
	ItemFlavor ornull selectedMeleeSkin = GetLegendMeleeCustomizeItem()
	if ( selectedMeleeSkin == null )
		return false

	return Deathbox_GetEquipped( GetTopLevelCustomizeContext(), expect ItemFlavor( selectedMeleeSkin ) ) == deathbox
}

void function MeleeCustomizationScreen_ClientToUI_UpdateDeathboxEquipState( int characterGUID, int meleeSkinGUID )
{
	if ( !file.isVisible )
		return

	ItemFlavor character = GetItemFlavorByGUID( characterGUID )
	ItemFlavor meleeSkin = GetItemFlavorByGUID( meleeSkinGUID )

	if ( GetTopLevelCustomizeContext() != character )
		return

	ItemFlavor ornull selectedMeleeSkin = GetLegendMeleeCustomizeItem()
	if ( selectedMeleeSkin == null || expect ItemFlavor( selectedMeleeSkin ) != meleeSkin )
		return

	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "meleeCustomization", true, [ "legend" ] ) )
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listDeathboxes" )
	int listItemCount = RTKArray_GetCount( listItems )
	for ( int i = 0; i < listItemCount && i < file.deathboxSkins.len(); i++ )
	{
		rtk_struct entry = RTKArray_GetStruct( listItems, i )
		RTKStruct_SetBool( entry, "equipped", IsDeathboxEquipped( file.deathboxSkins[ i ] ) )
		RTKStruct_SetBool( entry, "locked", !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_Deathbox( character ), file.deathboxSkins[ i ] ) )

		
		if ( i == file.previewIndex )
			RTKStruct_SetStruct( rtkModel, "previewItem", entry )
	}

	RTKFooters_Update()
}




























































































































































