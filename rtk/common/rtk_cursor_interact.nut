global function RTKCursorInteract_OnMouseWheeled
global function RTKCursorInteract_OnKeyCodePressed
global function RTKCursorInteract_OnHoverEnter
global function RTKCursorInteract_OnHoverLeave

global function RTKCursorInteract_AutoSubscribeMouseWheeledListener
global function RTKCursorInteract_AddOnMouseWheeledListener
global function RTKCursorInteract_RemoveOnMouseWheeledListener

global function RTKCursorInteract_AutoSubscribeOnKeyCodePressedListener
global function RTKCursorInteract_AddOnKeyCodePressedListener
global function RTKCursorInteract_RemoveOnKeyCodePressedListener

global function RTKCursorInteract_AutoSubscribeOnHoverEnterListener
global function RTKCursorInteract_AddOnHoverEnterListener
global function RTKCursorInteract_RemoveOnHoverEnterListener

global function RTKCursorInteract_AutoSubscribeOnHoverLeaveListener
global function RTKCursorInteract_AddOnHoverLeaveListener
global function RTKCursorInteract_RemoveOnHoverLeaveListener

global struct RTKCursorInteract_Properties
{
	array< int > keycodes = []
	bool mouseEnabled = true
	bool controllerEnabled = true

	bool absorbOnMouseWheeled = true
	bool absorbOnKeyCodePressed = true

	void functionref( float ) onMouseWheeled
	void functionref( int ) onKeyCodePressed
	void functionref() onHoverEnter
	void functionref() onHoverLeave
}




void function RTKCursorInteract_AutoSubscribeMouseWheeledListener( rtk_behavior parentSelf, rtk_behavior self, void functionref( float ) handler )
{
	parentSelf.AutoSubscribe( self, "onMouseWheeled", handler )
}

int function RTKCursorInteract_AddOnMouseWheeledListener( rtk_behavior self, void functionref( float ) handler )
{
	return self.AddEventListener( "onMouseWheeled", handler )
}

void function RTKCursorInteract_RemoveOnMouseWheeledListener( rtk_behavior self ,  int HandlerID )
{
	self.RemoveEventListener( "onMouseWheeled", HandlerID )
}




void function RTKCursorInteract_AutoSubscribeOnKeyCodePressedListener( rtk_behavior parentSelf, rtk_behavior self, void functionref( int ) handler )
{
	parentSelf.AutoSubscribe( self, "onKeyCodePressed", handler )
}

int function RTKCursorInteract_AddOnKeyCodePressedListener( rtk_behavior self, void functionref( int ) handler )
{
	return self.AddEventListener( "onKeyCodePressed", handler )
}

void function RTKCursorInteract_RemoveOnKeyCodePressedListener( rtk_behavior self ,  int HandlerID )
{
	self.RemoveEventListener( "onKeyCodePressed", HandlerID )
}




void function RTKCursorInteract_AutoSubscribeOnHoverEnterListener( rtk_behavior parentSelf, rtk_behavior self, void functionref() handler )
{
	parentSelf.AutoSubscribe( self, "onHoverEnter", handler )
}

int function RTKCursorInteract_AddOnHoverEnterListener( rtk_behavior self, void functionref() handler )
{
	return self.AddEventListener( "onHoverEnter", handler )
}

void function RTKCursorInteract_RemoveOnHoverEnterListener( rtk_behavior self ,  int HandlerID )
{
	self.RemoveEventListener( "onHoverEnter", HandlerID )
}




void function RTKCursorInteract_AutoSubscribeOnHoverLeaveListener( rtk_behavior parentSelf, rtk_behavior self, void functionref() handler )
{
	parentSelf.AutoSubscribe( self, "onHoverLeave", handler )
}

int function RTKCursorInteract_AddOnHoverLeaveListener( rtk_behavior self, void functionref() handler )
{
	return self.AddEventListener( "onHoverLeave", handler )
}

void function RTKCursorInteract_RemoveOnHoverLeaveListener( rtk_behavior self ,  int HandlerID )
{
	self.RemoveEventListener( "onHoverLeave", HandlerID )
}




bool function RTKCursorInteract_InputInteractable( rtk_behavior self )
{
	bool isControlerActive = IsControllerModeActive()
	bool controllerEnabled = self.PropGetBool( "controllerEnabled" )
	bool mouseEnabled = self.PropGetBool( "mouseEnabled" )

	return ( mouseEnabled && !isControlerActive ) || ( controllerEnabled && isControlerActive )
}




bool function RTKCursorInteract_OnMouseWheeled( rtk_behavior self, float delta )
{
	if( RTKCursorInteract_InputInteractable( self ) )
	{
		self.InvokeEvent( "onMouseWheeled", delta )
		return  self.PropGetBool( "absorbOnMouseWheeled" )
	}

	return false
}

bool function RTKCursorInteract_OnKeyCodePressed( rtk_behavior self, int code )
{
	array< int > keycodes
	RTKArray_GetValue(  self.PropGetArray( "keycodes" ), keycodes )

	
	if( RTKCursorInteract_InputInteractable( self ) && keycodes.contains(code) || keycodes.len() == 0 )
	{
		self.InvokeEvent( "onKeyCodePressed", code )
		return self.PropGetBool( "absorbOnKeyCodePressed" )
	}

	return false
}

void function RTKCursorInteract_OnHoverEnter( rtk_behavior self )
{
	if( RTKCursorInteract_InputInteractable( self ) )
	{
		self.InvokeEvent( "onHoverEnter" )
	}
}

void function RTKCursorInteract_OnHoverLeave( rtk_behavior self )
{
	if( RTKCursorInteract_InputInteractable( self ) )
	{
		self.InvokeEvent( "onHoverLeave" )
	}
}
