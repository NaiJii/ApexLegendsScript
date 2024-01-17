global function InitSweepstakesRulesDialog

global function UI_OpenEventShopSweepstakesRulesDialog
global function UI_CloseEventShopSweepstakesRulesDialog

const string SFX_MENU_OPENED = "UI_Menu_Focus_Large"

struct {
	var menu
	var contentElm
} file

void function InitSweepstakesRulesDialog( var newMenuArg )
{
	var menu = newMenuArg
	file.menu = menu

	SetPopup( menu, true )

	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, EventShopSweepstakesRulesDialog_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, EventShopSweepstakesRulesDialog_OnClose )

	file.contentElm = Hud_GetChild( menu, "DialogContent" )
}

void function EventShopSweepstakesRulesDialog_OnClose()
{
	UI_CloseEventShopSweepstakesRulesDialog()
}

void function UI_OpenEventShopSweepstakesRulesDialog()
{
	if ( !IsFullyConnected() )
		return

	AdvanceMenu( GetMenu( "SweepstakesRulesDialog" ) )
}


void function UI_CloseEventShopSweepstakesRulesDialog()
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

