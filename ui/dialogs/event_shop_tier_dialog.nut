global function InitEventShopTierDialog

global function UI_OpenEventShopTierDialog
global function UI_CloseEventShopTierDialog

const string SFX_MENU_OPENED = "UI_Menu_Focus_Large"

struct {
	var menu
	var contentElm
} file

void function InitEventShopTierDialog( var newMenuArg )
{
	var menu = newMenuArg
	file.menu = menu

	SetPopup( menu, true )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, EventShopTierDialog_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, EventShopTierDialog_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, EventShopTierDialog_OnNavigateBack )

	file.contentElm = Hud_GetChild( menu, "DialogContent" )
}

void function EventShopTierDialog_OnOpen()
{
	ItemFlavor ornull activeEventShop = EventShop_GetCurrentActiveEventShop()
	Assert ( activeEventShop != null, "Cannot open dialog with a null current active event shop." )
	expect ItemFlavor( activeEventShop )

	string currencyName = ItemFlavor_GetShortName( EventShop_GetEventShopCurrency( activeEventShop ) )

	RuiSetString( Hud_GetRui( file.contentElm ), "messageText", Localize( EventShop_GetRewardsTitle( activeEventShop ), Localize( currencyName ) ) )
	int currencyProgression = expect int( EventShop_GetCurrencyProgressionType( activeEventShop ) )
	RuiSetString( Hud_GetRui( file.contentElm ), "messageText", Localize( currencyProgression == eShopCurrencyProgression.GAMEPLAY ? "#EVENTS_EVENT_SHOP_TIER_DIALOG_TITLE_1" : "#EVENTS_EVENT_SHOP_TIER_DIALOG_TITLE_2" ) )
	EmitUISound( SFX_MENU_OPENED )
}

void function EventShopTierDialog_OnClose()
{
}

void function EventShopTierDialog_OnNavigateBack()
{
	UI_CloseEventShopTierDialog()
}

void function OnOpenRadioPlay( var button )
{
	AdvanceMenu( GetMenu( "RadioPlayDialog" ) )
}

void function UI_OpenEventShopTierDialog()
{
	if ( !IsFullyConnected() )
		return

	AdvanceMenu( GetMenu( "EventShopTierDialog" ) )
}


void function UI_CloseEventShopTierDialog()
{
	if ( GetActiveMenu() == file.menu )
	{
		CloseActiveMenu()
	}
	else if ( MenuStack_Contains( file.menu ) )
	{
		if( IsDialog( GetActiveMenu() ) )
		{
			
			CloseAllMenus()
		}
		else
		{
			
			MenuStack_Remove( file.menu )
		}
	}
}

