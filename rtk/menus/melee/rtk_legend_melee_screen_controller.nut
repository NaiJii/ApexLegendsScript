global function RTKLegendMeleeScreen_InitMetaData
global function RTKLegendMeleeScreen_OnInitialize
global function RTKLegendMeleeScreen_OnDestroy

global function InitRTKLegendMeleePanel
global function GetLegendMeleeCustomizeItem
global function OnMeleeCustomizationClosed

global struct RTKLegendMeleeScreen_Properties
{
	rtk_panel itemList
	rtk_behavior equipButton
	rtk_behavior customizeButton
}

global struct MeleeItemModel
{
	string name
	int quality
	asset eventIcon
	bool equipped
	bool locked
	bool selected
	string actionText
}

global struct MeleeModel
{
	array<MeleeItemModel> listItems
	MeleeItemModel& previewItem
	string listHeader
	bool inCustomization

	
	bool isDefault
	asset deathboxImage
	string deathboxName
	string deathboxDesc
}

struct
{
	bool isVisible = false
	array<ItemFlavor> meleeSkins = []
	int focusedIndex = -1
	int previewIndex = -1
	int customizeIndex = -1
} file

void function RTKLegendMeleeScreen_InitMetaData( string behaviorType, string structType )
{
	RTKMetaData_BehaviorIsRuiBehavior( behaviorType, true )
}

void function RTKLegendMeleeScreen_OnInitialize( rtk_behavior self )
{
	RunClientScript( "EnableModelTurn" )
	RunMenuClientFunction( "ClearAllCharacterPreview" )
	UI_SetPresentationType( ePresentationType.MELEE_INSPECT )

	
	file.meleeSkins = GetSelectableMeleeSkins()

	
	rtk_struct rtkModel = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "melee", "MeleeModel", ["legend"] )
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listItems" )
	ItemFlavor equippedSkin = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
	int ownedCount = 0
	foreach (int index, ItemFlavor itemFlav in file.meleeSkins)
	{
		rtk_struct listItemEntry = RTKArray_PushNewStruct( listItems )

		MeleeItemModel listItem
		listItem.name = Localize( ItemFlavor_GetLongName( itemFlav ) )
		listItem.quality = ItemFlavor_GetQuality( itemFlav )
		listItem.eventIcon = ItemFlavor_GetSourceIcon( itemFlav )
		listItem.equipped = itemFlav == equippedSkin
		listItem.locked = !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), itemFlav )
		listItem.selected = false

		if ( !listItem.locked )
		{
			ownedCount++
			listItem.actionText = "#EQUIP"
		}
		else
		{
			listItem.actionText = IsRewardForActiveEvent( itemFlav ) ? "#MENU_STORE_PANEL_EVENT_SHOP" : "#UNLOCK"
		}













		RTKStruct_SetValue( listItemEntry, listItem )
	}

	RTKStruct_SetString( rtkModel, "listHeader", Localize( "#OWNED_COLLECTED", ownedCount, file.meleeSkins.len() ) )

	
	PreviewItem( 0, true )

	
	rtk_panel ornull itemList = self.PropGetPanel( "itemList" )
	if ( itemList != null )
	{
		expect rtk_panel( itemList )
		self.AutoSubscribe( itemList, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ){
			array< rtk_behavior > itemListButtons = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in itemListButtons )
			{
				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex ) {
					bool equipSuccess = false
					bool equipFail = false
					if ( keycode == MOUSE_RIGHT )
					{
						equipSuccess = EquipItem( newChildIndex )
						equipFail = !equipSuccess
					}

					else if ( keycode == MOUSE_MIDDLE )
						CustomizeItem( newChildIndex )

					else
						EmitUISound( "UI_Menu_Banner_Preview" )

					if ( !equipFail )
						PreviewItem( newChildIndex, equipSuccess )
				} )

				self.AutoSubscribe( button, "onHighlighted", function( rtk_behavior button, int prevState ) : ( self, newChildIndex ) {
					file.focusedIndex = newChildIndex
					UpdateFooterOptions()
				} )

				self.AutoSubscribe( button, "onIdle", function( rtk_behavior button, int prevState ) : ( self ) {
					file.focusedIndex = -1
					UpdateFooterOptions()
				} )
			}
		} )
	}

	
	rtk_behavior ornull equipButton = self.PropGetBehavior( "equipButton" )
	if ( equipButton != null )
	{
		expect rtk_behavior( equipButton )
		self.AutoSubscribe( equipButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			EquipItemAtIndex( file.previewIndex )
		} )
	}

	
	rtk_behavior ornull customizeButton = self.PropGetBehavior( "customizeButton" )
	if ( customizeButton != null )
	{
		expect rtk_behavior( customizeButton )
		self.AutoSubscribe( customizeButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			CustomizeItemAtIndex( file.previewIndex )
		} )
	}

	file.isVisible = true
}

void function RTKLegendMeleeScreen_OnDestroy( rtk_behavior self )
{
	file.isVisible = false

	UI_SetPresentationType( ePresentationType.INACTIVE )

	RTKDataModelType_DestroyStruct( RTK_MODELTYPE_MENUS, "melee", ["legend"] )

	file.meleeSkins.clear()
}

void function InitRTKLegendMeleePanel( var panel )
{
	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, LegendMeleePanel_OnShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, LegendMeleePanel_OnHide )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )

#if PC_PROG_NX_UI
		AddPanelFooterOption( panel, LEFT, BUTTON_TRIGGER_LEFT, false, "#MENU_ZOOM_CONTROLS_GAMEPAD", "#MENU_ZOOM_CONTROLS", null )
#else
		AddPanelFooterOption( panel, RIGHT, BUTTON_TRIGGER_LEFT, false, "#MENU_ZOOM_CONTROLS_GAMEPAD", "#MENU_ZOOM_CONTROLS", null )
#endif

	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_UNLOCK", "#X_BUTTON_UNLOCK", EquipFocusedItem, CanUnlockFocused )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EVENT_SHOP", "#X_BUTTON_EVENT_SHOP", EquipFocusedItem, CanUnlockFocusedEventShop )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", EquipFocusedItem, CanEquipFocused )


	AddPanelFooterOption( panel, LEFT, BUTTON_Y, false, "#Y_BUTTON_CUSTOMIZE", "#Y_BUTTON_CUSTOMIZE", CustomizeFocusedItem, CanCustomizeFocused )

}

void function LegendMeleePanel_OnShow( var panel )
{
	SetCurrentTabForPIN( Hud_GetHudName( panel ) )

	var parentMenu = Hud_GetParent( panel )
	Hud_SetVisible( Hud_GetChild( parentMenu, "LegendMeleePanelModelRotateMouseCapture"), true )

	AddCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), OnMeleeSkinChanged )
}


void function LegendMeleePanel_OnHide( var panel )
{
	var parentMenu = Hud_GetParent( panel )
	Hud_SetVisible( Hud_GetChild( parentMenu, "LegendMeleePanelModelRotateMouseCapture"), false )

	RemoveCallback_ItemFlavorLoadoutSlotDidChange_SpecificPlayer( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), OnMeleeSkinChanged )
}

bool function CanUnlockFocused()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.meleeSkins.len() )
		return false

	return !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ file.focusedIndex ] ) && !IsRewardForActiveEvent( file.meleeSkins[ file.focusedIndex ] )
}

bool function CanUnlockFocusedEventShop()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.meleeSkins.len() )
		return false

	return !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ file.focusedIndex ] ) && IsRewardForActiveEvent( file.meleeSkins[ file.focusedIndex ] )
}

bool function CanEquipFocused()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.meleeSkins.len() )
		return false

	if ( !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ file.focusedIndex ] ) )
		return false

	return file.meleeSkins[ file.focusedIndex ] != LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
}

bool function CanCustomizeFocused()
{
	if ( file.focusedIndex < 0 || file.focusedIndex >= file.meleeSkins.len() )
		return false

	if ( !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ file.focusedIndex ] ) )
		return false

	return file.meleeSkins[ file.focusedIndex ] != GetDefaultItemFlavorForLoadoutSlot(  LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
}

void function OnMeleeSkinChanged( EHI playerEHI, ItemFlavor flavor )
{
	RefreshList()
}

array<ItemFlavor> function GetSelectableMeleeSkins()
{
	ItemFlavor character = GetTopLevelCustomizeContext()
	LoadoutEntry entry = Loadout_MeleeSkin( character )

	EHI playerEHI = LocalClientEHI()
	array<ItemFlavor> allMeleeSkins = clone GetValidItemFlavorsForLoadoutSlot( playerEHI, entry )

	
	array<ItemFlavor> availableHeirlooms
	array<GRXScriptOffer> offers = GRX_GetLocationOffers( "heirloom_set_shop" )
	foreach ( offerIndex, offer in offers )
		availableHeirlooms.append( ItemFlavorBag_GetMeleeSkinItem( offer.output ) )

	
	array<ItemFlavor> selectableMeleeSkins
	foreach ( ItemFlavor meleeSkin in allMeleeSkins )
	{
		
		if ( !IsItemFlavorUnlockedForLoadoutSlot( playerEHI, entry, meleeSkin ) )
		{
			
			if ( MeleeSkin_ShouldHideIfLocked( meleeSkin ) && !IsRewardForActiveEvent( meleeSkin ) )
				continue

			
			bool isHeirloom = ( GetItemFlavorAssociatedCharacterOrWeapon( meleeSkin ) != null )
			if ( isHeirloom && !availableHeirlooms.contains( meleeSkin ) )
				continue
		}

		selectableMeleeSkins.append( meleeSkin )
	}

	
	ItemFlavor equippedItem = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
	selectableMeleeSkins.sort( int function( ItemFlavor a, ItemFlavor b ) : ( equippedItem ) {
		
		bool aIsEquipped = ( equippedItem == a )
		bool bIsEquipped = ( equippedItem == b )
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

	return selectableMeleeSkins
}

bool function IsRewardForActiveEvent( ItemFlavor item )
{
	ItemFlavor ornull activeEvent = GetActiveMilestoneEvent( GetUnixTimestamp() )
	if ( activeEvent != null )
	{
		expect ItemFlavor( activeEvent )
		return MilestoneEvent_IsMythicEventItem( activeEvent, ItemFlavor_GetGRXIndex( item ) )
	}

	return false
}

void function RefreshList()
{
	if ( !file.isVisible )
		return

	ItemFlavor equippedSkin = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )

	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "melee", true, [ "legend" ] ) )
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listItems" )
	int listItemCount = RTKArray_GetCount( listItems )
	int ownedCount = 0
	for ( int i = 0; i < listItemCount && i < file.meleeSkins.len(); i++ )
	{
		rtk_struct entry = RTKArray_GetStruct( listItems, i )
		RTKStruct_SetBool( entry, "equipped", file.meleeSkins[ i ] == equippedSkin )

		bool locked = !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ i ] )
		RTKStruct_SetBool( entry, "locked", locked )
		if ( !locked )
			ownedCount++

		
		if ( i == file.previewIndex )
			RTKStruct_SetStruct( rtkModel, "previewItem", entry )
	}

	RTKStruct_SetString( rtkModel, "listHeader", Localize( "#OWNED_COLLECTED", ownedCount, listItemCount ) )

	UpdateFooterOptions()
}

void function PreviewItem( int index, bool playFX )
{
	if ( index < 0 || index >= file.meleeSkins.len() )
		return

	file.previewIndex = index

	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "melee", true, [ "legend" ] ) )

	ItemFlavor defaultMeleeSkin = GetDefaultItemFlavorForLoadoutSlot(  LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
	if ( file.meleeSkins[ index ] == defaultMeleeSkin )
	{
		RTKStruct_SetBool( rtkModel, "isDefault", true )
		RunClientScript( "UIToClient_ClearMeleeSkinPreview" )
	}
	else if ( IsItemFlavorStructValid( file.meleeSkins[ index ].guid, eValidation.DONT_ASSERT ) )
	{
		RTKStruct_SetBool( rtkModel, "isDefault", false )
		RunClientScript( "UIToClient_PreviewMeleeSkin", ItemFlavor_GetGUID( file.meleeSkins[ index ] ) )
	}

	
	rtk_array listItems = RTKStruct_GetArray( rtkModel, "listItems" )
	int listItemCount = RTKArray_GetCount( listItems )
	for ( int i = 0; i < listItemCount; i++ )
	{
		bool selected = ( i == index )

		rtk_struct entry = RTKArray_GetStruct( listItems, i )
		RTKStruct_SetBool( entry, "selected", selected )
		if ( selected )
			RTKStruct_SetStruct( rtkModel, "previewItem", entry )
	}

	ItemFlavor equippedDeathbox = Deathbox_GetEquipped( GetTopLevelCustomizeContext(), file.meleeSkins[ index ] )
	RTKStruct_SetAssetPath( rtkModel, "deathboxImage", ItemFlavor_GetIcon( equippedDeathbox ) )
	RTKStruct_SetString( rtkModel, "deathboxName", ItemFlavor_GetLongName( equippedDeathbox ) )
	RTKStruct_SetString( rtkModel, "deathboxDesc", ItemFlavor_GetLongDescription( equippedDeathbox ) )
}

bool function EquipItem( int index )
{
	if ( index < 0 || index >= file.meleeSkins.len() )
		return false

	ItemFlavor character = GetTopLevelCustomizeContext()
	LoadoutEntry entry = Loadout_MeleeSkin( character )
	EHI playerEHI = LocalClientEHI()

	
	ItemFlavor meleeSkinToEquip = file.meleeSkins[ index ]
	ItemFlavor equippedSkin = LoadoutSlot_GetItemFlavor( playerEHI, entry )
	if ( meleeSkinToEquip == equippedSkin )
	{
		PreviewItem( index, false )
		EmitUISound( "UI_Menu_Banner_Preview" )
		return false
	}

	if ( !IsItemFlavorUnlockedForLoadoutSlot( playerEHI, entry, meleeSkinToEquip ) )
	{
		bool inspectOffer = false
		array<GRXScriptOffer> offers = GRX_GetLocationOffers( "heirloom_set_shop" )
		foreach ( offerIndex, offer in offers )
		{
			ItemFlavor offerSkin = ItemFlavorBag_GetMeleeSkinItem( offer.output )
			if ( offerSkin == meleeSkinToEquip )
			{
				StoreInspectMenu_AttemptOpenWithOffer( offer )
				EmitUISound( "ui_menu_accept" )
				inspectOffer = true
				break
			}
		}

		if ( !inspectOffer )
		{
			
			if ( IsRewardForActiveEvent( meleeSkinToEquip ) )
			{
				EmitUISound( "ui_menu_accept" )
				EventsPanel_SetOpenPageIndex( eEventsPanelPage.COLLECTION )
				JumpToSeasonTab( "RTKEventsPanel" )
			}
			else
			{
				EmitUISound( "menu_deny" )
			}
		}

		return false
	}

	PIN_Customization( character, meleeSkinToEquip, "equip" )
	RequestSetItemFlavorLoadoutSlot( playerEHI, entry, meleeSkinToEquip )

	EmitUISound( "UI_Menu_Equip_Generic" )

	return true
}

void function CustomizeItem( int index )
{
	if ( index < 0 || index >= file.meleeSkins.len() )
		return

	if ( !IsItemFlavorUnlockedForLoadoutSlot( LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ), file.meleeSkins[ index ] ) )
	{
		EmitUISound( "menu_deny" )
		return
	}

	ItemFlavor defaultMeleeSkin = GetDefaultItemFlavorForLoadoutSlot(  LocalClientEHI(), Loadout_MeleeSkin( GetTopLevelCustomizeContext() ) )
	if ( file.meleeSkins[ index ] == defaultMeleeSkin )
	{
		EmitUISound( "menu_deny" )
		return
	}

	file.customizeIndex = index

	var menu = GetMenu( "MeleeCustomizationMenu" )
	AdvanceMenu( menu )












	ShowPanel( Hud_GetChild( menu, "MeleeCustomizationPanel" ) )


	EmitUISound( "ui_menu_accept" )

	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "melee", true, [ "legend" ] ) )
	RTKStruct_SetBool( rtkModel, "inCustomization", true )
}

void function EquipItemAtIndex( int index )
{
	if ( index < 0 )
		return

	bool equipSuccess = EquipItem( index )
	if ( equipSuccess )
		PreviewItem( index, true )
}

void function CustomizeItemAtIndex( int index )
{
	if ( index < 0 )
		return

	CustomizeItem( index )
}

void function EquipFocusedItem( var button )
{
	EquipItemAtIndex( file.focusedIndex )
}

void function CustomizeFocusedItem( var button )
{
	CustomizeItemAtIndex( file.focusedIndex )
}

ItemFlavor ornull function GetLegendMeleeCustomizeItem()
{
	if ( file.customizeIndex < 0 || file.customizeIndex >= file.meleeSkins.len() )
		return null

	return file.meleeSkins[ file.customizeIndex ]
}

void function OnMeleeCustomizationClosed()
{
	if ( !file.isVisible )
		return

	rtk_struct rtkModel = expect rtk_struct( RTKDataModelType_GetStruct( RTK_MODELTYPE_MENUS, "melee", true, [ "legend" ] ) )
	RTKStruct_SetBool( rtkModel, "inCustomization", false )

	if ( file.previewIndex >= 0 && file.previewIndex < file.meleeSkins.len() )
	{
		ItemFlavor equippedDeathbox = Deathbox_GetEquipped( GetTopLevelCustomizeContext(), file.meleeSkins[ file.previewIndex ] )
		RTKStruct_SetAssetPath( rtkModel, "deathboxImage", ItemFlavor_GetIcon( equippedDeathbox ) )
		RTKStruct_SetString( rtkModel, "deathboxName", ItemFlavor_GetLongName( equippedDeathbox ) )
		RTKStruct_SetString( rtkModel, "deathboxDesc", ItemFlavor_GetLongDescription( equippedDeathbox ) )
	}
}

