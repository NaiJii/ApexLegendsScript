global function RTKRevArmyCharSelect_OnInitialize

global struct RTKRevArmyCharSelect_Properties
{
	rtk_behavior modeInfoAnim
}

void function RTKRevArmyCharSelect_OnInitialize( rtk_behavior self )
{
	rtk_behavior modeInfoAnim = self.PropGetBehavior( "modeInfoAnim" )

	if ( modeInfoAnim != null )
	{
		self.AutoSubscribe( modeInfoAnim, "onAnimationFinished", function ( rtk_behavior animator, string animName ) : ( self ) {
			RTKRevArmyCharSelect_OnAnimFinished( self, animName )
		} )

		if ( RTKAnimator_HasAnimation( modeInfoAnim, "IntroBannerAnimIn" ) )
		{
			RTKAnimator_PlayAnimation( modeInfoAnim, "IntroBannerAnimIn" )
			EmitUISound( "Lobby_RevenantArmy_Menu_Team_Attributed" )
		}
	}
}

void function RTKRevArmyCharSelect_OnAnimFinished( rtk_behavior self, string animName )
{
	rtk_behavior modeInfoAnim = self.PropGetBehavior( "modeInfoAnim" )

	if (animName == "IntroBannerAnimIn" && modeInfoAnim != null)
		if ( RTKAnimator_HasAnimation( modeInfoAnim, "IntroBannerAnimOut" ) )
			RTKAnimator_PlayAnimation( modeInfoAnim, "IntroBannerAnimOut" )

	if (animName == "IntroBannerAnimOut" && modeInfoAnim != null)
	if ( RTKAnimator_HasAnimation( modeInfoAnim, "InfoAnimation" ) )
		RTKAnimator_PlayAnimation( modeInfoAnim, "InfoAnimation" )
}

