global function RTKMultiItemSelector_OnInitialize
global function RTKMultiItemSelector_AddOnAdditionListener
global function RTKMultiItemSelector_AddOnSubtractionListener

global struct RTKMultiItemSelector_Properties
{
	rtk_behavior subtractionButton
	rtk_behavior additionButton

	void functionref( ) onSubtraction = null
	void functionref( ) onAddition = null
}

int function RTKMultiItemSelector_AddOnSubtractionListener( rtk_behavior self, void functionref() handler )
{
	return self.AddEventListener( "onSubtraction", handler )
}

int function RTKMultiItemSelector_AddOnAdditionListener( rtk_behavior self, void functionref() handler )
{
	return self.AddEventListener( "onAddition", handler )
}

void function RTKMultiItemSelector_OnInitialize( rtk_behavior self )
{
	rtk_behavior ornull subtractionButton = self.PropGetBehavior( "subtractionButton" )
	rtk_behavior ornull additionButton = self.PropGetBehavior( "additionButton" )

	if ( subtractionButton != null )
	{
		expect rtk_behavior( subtractionButton )
		self.AutoSubscribe( subtractionButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			self.InvokeEvent( "onSubtraction" )
		} )
	}

	if ( additionButton != null )
	{
		expect rtk_behavior( additionButton )
		self.AutoSubscribe( additionButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			self.InvokeEvent( "onAddition" )
		} )
	}
}
