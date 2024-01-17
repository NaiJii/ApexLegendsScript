global struct RTKFooterButton_Properties
{
	rtk_behavior button
	int activateGUID = -1
}

global function RTKFooterButton_OnInitialize

void function RTKFooterButton_OnInitialize( rtk_behavior self )
{
	rtk_behavior ornull btn = self.PropGetBehavior( "button" )
	if( btn != null )
	{
		expect rtk_behavior( btn )

		self.AutoSubscribe( btn, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			int activateGUID = self.PropGetInt( "activateGUID" )
			printl( "Footer button pressed. keyCode:" + keycode + ", activateGUID:" + activateGUID )
			if ( activateGUID != -1 )
			{
				EmitUISound( "ui_menu_accept" )
				RTKFooters_OnFooterActivate( activateGUID )
			}
		} )
	}
}
