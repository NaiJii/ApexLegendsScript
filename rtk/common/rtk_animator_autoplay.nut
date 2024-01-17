






global function RTKAnimatorAutoPlay_OnInitialize

global struct RTKAnimatorAutoPlay_Properties
{
	rtk_behavior animator
	array<string> animations
}

void function RTKAnimatorAutoPlay_OnInitialize( rtk_behavior self )
{
	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	rtk_array animations = self.PropGetArray( "animations" )

	Assert( animator != null, "Missing animator" )

	expect rtk_behavior( animator )

	for ( int i = 0; i < RTKArray_GetCount( animations ); i++ )
	{
		string animation = RTKArray_GetString( animations, i )
		if ( RTKAnimator_HasAnimation( animator, animation ) )
		{
			RTKAnimator_PlayAnimation( animator, animation )
		}
	}
}

