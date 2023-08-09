global function RTKTimer_OnUpdate
global function RTKTimer_AddOnFinishListener
global function RTKTimer_RemoveOnFinishListener
global function RTKTimer_Reset

global struct RTKTimer_Properties
{
	int endTime
	int remainingTime

	void functionref( ) onFinish
}

int function RTKTimer_AddOnFinishListener( rtk_behavior self ,  void functionref() clickHandler )
{
	return self.AddEventListener( "onFinish", clickHandler )
}
void function RTKTimer_RemoveOnFinishListener( rtk_behavior self ,  int HandlerID )
{
	self.RemoveEventListener(  "onFinish", HandlerID )
}

void function RTKTimer_Reset( rtk_behavior self , int endTime )
{
	self.PropSetInt( "endTime", endTime)
	self.PropSetBool( "active", true )
}

void function RTKTimer_OnUpdate( rtk_behavior self, float deltaTime )
{
	int endTime       = self.PropGetInt( "endTime" )
	int remainingTime = maxint( 0, endTime - GetUnixTimestamp())
	self.PropSetInt( "remainingTime", remainingTime )
	if ( remainingTime <= 0 )
	{
		self.PropSetBool( "active", false )
		self.InvokeEvent( "onFinish" )
	}
}


