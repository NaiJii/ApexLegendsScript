global function InitMilestonePackInfoDialog
global function OpenMilestonePackInfoDialog

struct {
	var menu
	var infoPanel
}file

void function InitMilestonePackInfoDialog( var newMenuArg )
{
	var menu = newMenuArg
	file.menu = menu

	file.infoPanel = Hud_GetChild( menu, "InfoPanel" )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_CLOSE", "#B_BUTTON_CLOSE" )
	SetDialog( menu, true )
}

void function OpenMilestonePackInfoDialog( var button )
{
	if ( GetActiveMenu() != file.menu )
		AdvanceMenu( GetMenu( "MilestonePackInfoDialog" ) )
}


