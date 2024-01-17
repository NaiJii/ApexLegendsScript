global function RTKImageCrossfader_SetImage
global function RTKImageCrossfader_FadeNewImage
global function RTKImageCrossfader_FadeScrollNewImage

global struct RTKImageCrossfader_Properties
{
	rtk_behavior animator
	rtk_behavior imageBottom
	rtk_behavior imageTop
}

void function RTKImageCrossfader_SetImage( rtk_behavior self, asset imageAsset )
{
	rtk_behavior ornull imageBottom = self.PropGetBehavior( "imageBottom" )
	rtk_behavior ornull imageTop = self.PropGetBehavior( "imageTop" )

	if ( imageBottom != null )
	{
		expect rtk_behavior( imageBottom )
		imageBottom.PropSetAssetPath( "assetPath", imageAsset )
	}

	if ( imageTop != null )
	{
		expect rtk_behavior( imageTop )
		imageTop.PropSetAssetPath( "assetPath", imageAsset )
		imageTop.PropSetFloat( "alpha", 0 )
	}
}


void function RTKImageCrossfader_FadeNewImage( rtk_behavior self, asset imageAsset, float duration = 0.5 )
{
	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator == null )
		return

	expect rtk_behavior( animator )
	string animName = imageAsset != $"" ? "FadeIn" : "FadeOut"

	RTKImageCrossfader_SwapImage( self, imageAsset )
	RTKAnim_SetAnimationDuration( animator, animName, duration )
	RTKAnimator_PlayAnimation( animator, animName )
}


void function RTKImageCrossfader_FadeScrollNewImage( rtk_behavior self, asset imageAsset, float duration = 0.5, bool scrollDown = true )
{
	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator == null )
		return

	expect rtk_behavior( animator )
	string animName = imageAsset != $"" ? ( scrollDown ? "FadeInDown" : "FadeInUp" ) : "FadeOut"

	RTKImageCrossfader_SwapImage( self, imageAsset )
	RTKAnim_SetAnimationDuration( animator, animName, duration )
	RTKAnimator_PlayAnimation( animator, animName )
}

void function RTKImageCrossfader_SwapImage( rtk_behavior self, asset imageAsset )
{
	rtk_behavior ornull imageBottom = self.PropGetBehavior( "imageBottom" )
	rtk_behavior ornull imageTop = self.PropGetBehavior( "imageTop" )
	if ( imageBottom == null || imageTop == null )
		return

	expect rtk_behavior( imageBottom )
	expect rtk_behavior( imageTop )

	asset imageAssetOld = imageTop.PropGetAssetPath( "assetPath" )
	imageBottom.PropSetAssetPath( "assetPath", imageAssetOld )
	imageTop.PropSetAssetPath( "assetPath", imageAsset )
}
