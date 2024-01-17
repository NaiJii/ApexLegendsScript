global function InitSweepstakesFlowDialog

global function UI_OpenEventShopSweepstakesFlowDialog
global function UI_CloseEventShopSweepstakesFlowDialog

const string SFX_MENU_OPENED = "UI_Menu_Focus_Large"

struct {
	var menu
	var contentElm
} file

void function InitSweepstakesFlowDialog( var newMenuArg )
{
	var menu = newMenuArg
	file.menu = menu

	SetPopup( menu, true )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, EventShopSweepstakesFlowDialog_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, EventShopSweepstakesFlowDialog_OnClose )
}

void function EventShopSweepstakesFlowDialog_OnClose()
{
	UI_CloseEventShopSweepstakesFlowDialog()
}

void function UI_OpenEventShopSweepstakesFlowDialog()
{
	if ( !IsFullyConnected() )
		return

	AdvanceMenu( GetMenu( "SweepstakesFlowDialog" ) )
}


void function UI_CloseEventShopSweepstakesFlowDialog()
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

