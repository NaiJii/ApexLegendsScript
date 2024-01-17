globalize_all_functions

void function RTKAnim_SetAnimationDuration( rtk_behavior animator, string animName, float duration )
{
	rtk_array anims  = animator.PropGetArray( "tweenAnimations" )
	int animCount = RTKArray_GetCount( anims )

	for ( int i = 0; i < animCount; i++ )
	{
		rtk_struct anim = RTKArray_GetStruct( anims, i )
		if ( RTKStruct_GetString( anim, "name" ) != animName )
			continue

		rtk_array tweens = RTKStruct_GetArray( anim, "tweens" )
		int tweenCount = RTKArray_GetCount( tweens )
		for ( int j = 0; j < tweenCount; j++ )
		{
			RTKStruct_SetFloat( RTKArray_GetStruct( tweens, j ), "duration", duration )
		}
	}
}
