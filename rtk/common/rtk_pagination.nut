global function RTKPagination_InitMetaData
global function RTKPagination_OnInitialize
global function RTKPagination_OnPreDraw
global function RTKPagination_OnDestroy
global function RTKPagination_GetCurrentPage
global function RTKPagination_GetTargetPage
global function RTKPagination_GoToPage

global struct RTKPagination_Properties
{
	rtk_panel 		container
	rtk_panel 		content

	rtk_behavior cursorInteract1Area
	rtk_behavior cursorInteract2Area

	rtk_behavior nextButton
	rtk_behavior prevButton
	rtk_panel paginationButtons
	rtk_behavior hintAnimator

	int pages
	int startPageIndex = 0

	float containerSizeOffset 

	array< string > pageNames = []

	bool vertical
	bool autoPagesByContainerContent
	bool useContentSizeAsTotalSize
	bool panelsAlwaysStartNewPages = false
	bool fillEmptySpace = true
	bool canWrap = false
	bool forceShowNav = false
	bool showNonInteractiveNavButtons = true
	bool supportShoulderButtonNav = false
	bool globalInput = false

	rtk_behavior animator
}

struct PrivateData
{
	int currentPageIndex = 0
	int nextPageIndex = 0

	bool firstDrawComplete = false

	void functionref( var button ) prevPageFunc
	void functionref( var button ) nextPageFunc
	array<int> keycodesPrev
	array<int> keycodesNext
}

global struct RTKPaginationPip
{
	bool isActive = false
	string name = ""
}

void function RTKPagination_InitMetaData( string behaviorType, string structType )
{
	RTKMetaData_SetAllowedBehaviorTypes( structType, "nextButton", [ "Button" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "prevButton", [ "Button" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "animator", [ "Animator" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "cursorInteract1Area", [ "CursorInteract" ] )
	RTKMetaData_SetAllowedBehaviorTypes( structType, "cursorInteract2Area", [ "CursorInteract" ] )
}

void function RTKPagination_OnInitialize( rtk_behavior self )
{
	rtk_behavior ornull nextButton = self.PropGetBehavior( "nextButton" )
	rtk_behavior ornull prevButton = self.PropGetBehavior( "prevButton" )

	rtk_behavior ornull cursorInteract1Area = self.PropGetBehavior( "cursorInteract1Area" )
	rtk_behavior ornull cursorInteract2Area = self.PropGetBehavior( "cursorInteract2Area" )

	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	rtk_panel ornull paginationButtons = self.PropGetPanel( "paginationButtons" )

	if ( nextButton != null )
	{
		expect rtk_behavior( nextButton )
		self.AutoSubscribe( nextButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			RTKPagination_NextPage( self )
		} )
	}

	if ( prevButton != null )
	{
		expect rtk_behavior( prevButton )
		self.AutoSubscribe( prevButton, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self ) {
			RTKPagination_PrevPage( self )
		} )
	}

	if ( animator != null )
	{
		expect rtk_behavior( animator )
		self.AutoSubscribe( animator, "onAnimationFinished", function ( rtk_behavior animator, string animName ) : ( self ) {
			RTKPagination_OnAnimFinished( self, animName )
		} )
	}

	if ( paginationButtons != null )
	{
		expect rtk_panel( paginationButtons )
		self.AutoSubscribe( paginationButtons, "onChildAdded", function ( rtk_panel newChild, int newChildIndex ) : ( self ) {
			array< rtk_behavior > buttonBehaviors = newChild.FindBehaviorsByTypeName( "Button" )
			foreach( button in buttonBehaviors )
			{
				self.AutoSubscribe( button, "onPressed", function( rtk_behavior button, int keycode, int prevState ) : ( self, newChildIndex ) {
					RTKPagination_GoToPage( self, newChildIndex )
				} )
			}
		} )
	}

	if ( self.PropGetBool( "globalInput" ) )
	{
		RTKPagination_RegisterGlobalInput( self )
	}
	else
	{
		RTKPagination_SetupCursorInteractArea( self, cursorInteract1Area )
		RTKPagination_SetupCursorInteractArea( self, cursorInteract2Area )
	}
}

void function RTKPagination_OnDestroy( rtk_behavior self )
{
	RTKPagination_ClearDataModel(self )

	if ( self.PropGetBool( "globalInput" ) )
	{
		RTKPagination_DeregisterGlobalInput( self )
	}
}

void function RTKPagination_OnPreDraw( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	if( !p.firstDrawComplete )
	{
		p.nextPageIndex = self.PropGetInt( "startPageIndex" )
		RTKPagination_SetPositionToPageNoAnim( self  )
		RTKPagination_RefreshPaginationButtons( self )
		p.firstDrawComplete = true
	}
}

void function RTKPagination_OnMouseWheeled( rtk_behavior self, float delta )
{
	if( IsControllerModeActive() && !self.PropGetBool( "vertical" ) )
		return

	if( delta > 0)
	{
		RTKPagination_PrevPage( self, true )
	}
	else if( delta < 0)
	{
		RTKPagination_NextPage( self, true )
	}
}

void function RTKPagination_OnKeyCodePressed( rtk_behavior self, int code )
{
	if( self.PropGetBool( "vertical" ) )
	{
		if( code == STICK2_DOWN || code == KEY_DOWN ) 
		{
			RTKPagination_NextPage( self, true )
		}
		else if( code == STICK2_UP || code == KEY_UP ) 
		{
			RTKPagination_PrevPage( self, true )
		}
	}
	else
	{
		if( code == STICK2_RIGHT || code == KEY_RIGHT || code == BUTTON_SHOULDER_RIGHT ) 
		{
			RTKPagination_NextPage( self, true )
		}
		else if( code == STICK2_LEFT  || code == KEY_LEFT || code == BUTTON_SHOULDER_LEFT ) 
		{
			RTKPagination_PrevPage( self, true )
		}
	}
}

void function RTKPagination_OnHoverEnter( rtk_behavior self, rtk_behavior area )
{
	bool showNav = RTKPagination_GetShowNav( self )
	if ( !showNav )
		return

	bool controlTypeIsActive = area.PropGetBool( IsControllerModeActive() ? "controllerEnabled" : "mouseEnabled" )
	if ( !controlTypeIsActive )
		return

	rtk_behavior animator = self.PropGetBehavior( "hintAnimator" )
	if( animator != null && RTKAnimator_HasAnimation( animator, "FadeIn" ) )
	{
		RTKAnimator_PlayAnimation( animator, "FadeIn" )
	}
}

void function RTKPagination_OnHoverLeave( rtk_behavior self, rtk_behavior area )
{
	bool showNav = RTKPagination_GetShowNav( self )
	if ( !showNav )
		return

	bool controlTypeIsActive = area.PropGetBool( IsControllerModeActive() ? "controllerEnabled" : "mouseEnabled" )
	if ( !controlTypeIsActive )
		return

	rtk_behavior animator = self.PropGetBehavior( "hintAnimator" )
	if( animator != null && RTKAnimator_HasAnimation( animator, "FadeOut" ) )
	{
		RTKAnimator_PlayAnimation( animator, "FadeOut" )
	}
}

void function RTKPagination_GoToPage( rtk_behavior self, int page )
{
	PrivateData p
	self.Private( p )

	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator != null )
	{
		if ( RTKAnimator_IsPlaying( expect rtk_behavior( animator ) ) )
			return
	}

	p.nextPageIndex = page
	RTKPagination_RefreshActivePage( self )
}

void function RTKPagination_NextPage( rtk_behavior self, bool emitSound = false )
{
	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator != null && RTKAnimator_IsPlaying( expect rtk_behavior( animator ) ) )
		return

	PrivateData p
	self.Private( p )

	int pageCount = RTKPagination_GetTotalPages( self  )
	bool canWrap = self.PropGetBool( "canWrap" )
	bool isLastPage = p.currentPageIndex + 1 >= pageCount

	if( !canWrap && isLastPage )
		return

	if( emitSound )
		EmitUISound( "UI_Menu_BattlePass_LevelTab" )

	
	p.nextPageIndex = isLastPage ? 0 : p.currentPageIndex + 1
	RTKPagination_RefreshActivePage( self )
}

void function RTKPagination_PrevPage( rtk_behavior self, bool emitSound = false )
{
	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator != null && RTKAnimator_IsPlaying( expect rtk_behavior( animator ) ) )
		return

	PrivateData p
	self.Private( p )

	int pageCount = RTKPagination_GetTotalPages( self  )
	bool canWrap = self.PropGetBool( "canWrap" )
	bool isFirstPage = p.currentPageIndex <= 0

	if( !canWrap && isFirstPage )
		return

	if( emitSound )
		EmitUISound( "UI_Menu_BattlePass_LevelTab" )

	
	p.nextPageIndex = isFirstPage ? pageCount - 1 : p.currentPageIndex - 1
	RTKPagination_RefreshActivePage( self )
}


void function RTKPagination_RefreshActivePage( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	if ( p.currentPageIndex < 0 )
		return

	rtk_behavior ornull animator = self.PropGetBehavior( "animator" )
	if ( animator != null && RTKAnimator_IsPlaying( expect rtk_behavior( animator ) ) )
		return

	expect rtk_behavior( animator )

	rtk_array animations  = animator.PropGetArray( "tweenAnimations" )
	int tweensCount = RTKArray_GetCount( animations )
	rtk_struct nextPageAnim = null

	for( int i = 0; i < tweensCount; i++ )
	{
		rtk_struct animation = RTKArray_GetStruct( animations, i )
		string name = RTKStruct_GetString( animation, "name" )

		if( name == "NextPage" )
		{
			nextPageAnim = animation
			break
		}
	}
	if( nextPageAnim != null )
	{
		rtk_array tweens = RTKStruct_GetArray( nextPageAnim, "tweens" )
		rtk_struct tween = RTKArray_GetStruct( tweens, 0 )

		RTKStruct_SetInt( tween, "startValue", RTKPagination_GetPagePosition( self, p.currentPageIndex ) )
		RTKStruct_SetInt( tween, "endValue", RTKPagination_GetPagePosition( self, p.nextPageIndex ) )

		RTKAnimator_PlayAnimation( animator, "NextPage" )
	}
	else 
		RTKPagination_SetPositionToPageNoAnim( self  )

	RTKPagination_UpdateCurrentPage( self )
	RTKPagination_RefreshPaginationButtons( self )
}

void function RTKPagination_RefreshPaginationButtons( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	rtk_panel ornull paginationButtons = self.PropGetPanel( "paginationButtons" )
	rtk_behavior ornull nextButton     = self.PropGetBehavior( "nextButton" )
	rtk_behavior ornull prevButton     = self.PropGetBehavior( "prevButton" )
	int pageCount                      = RTKPagination_GetTotalPages( self )
	bool canWrap                       = self.PropGetBool( "canWrap" )
	bool showNonInteractiveNavButtons  = self.PropGetBool( "showNonInteractiveNavButtons" )
	bool showNav                       = RTKPagination_GetShowNav( self )

	if( nextButton != null )
	{
		expect rtk_behavior( nextButton )
		bool interactive = canWrap || p.currentPageIndex + 1 < pageCount

		
		if ( nextButton.PropGetBool( "interactive" ) != interactive )
			nextButton.PropSetBool( "interactive", interactive )

		nextButton.GetPanel().SetVisible( showNav && ( showNonInteractiveNavButtons || interactive ) )
	}

	if( prevButton != null )
	{
		expect rtk_behavior( prevButton )
		bool interactive = canWrap || p.currentPageIndex > 0

		
		if ( prevButton.PropGetBool( "interactive" ) != interactive )
			prevButton.PropSetBool( "interactive", interactive )

		prevButton.GetPanel().SetVisible( showNav && ( showNonInteractiveNavButtons || interactive )  )
	}

	if ( paginationButtons != null )
	{
		expect rtk_panel( paginationButtons )
		paginationButtons.SetVisible( showNav )

		rtk_struct screenPagination = RTKDataModel_GetOrCreateEmptyStruct( RTK_MODELTYPE_MENUS, "pagination" )
		array< RTKPaginationPip > pips

		for( int i = 0; i < pageCount; i++ )
		{
			RTKPaginationPip pip
			pip.isActive = i == p.currentPageIndex
			rtk_array pageNames = self.PropGetArray( "pageNames" )
			if( RTKArray_GetCount( pageNames ) > i )
				pip.name = RTKArray_GetString( pageNames, i )

			pips.push( pip )
		}

		rtk_array paginationArray = RTKStruct_GetOrCreateScriptArrayOfStructs( screenPagination, string( self.GetInternalId() ), "RTKPaginationPip" )
		RTKArray_SetValue( paginationArray, pips )

		rtk_behavior ornull listBinder = paginationButtons.FindBehaviorByTypeName( "ListBinder" )

		if( listBinder == null )
			return

		expect rtk_behavior( listBinder )

		if( listBinder.PropGetString( "bindingPath" ) == "" )
		{
			listBinder.PropSetString( "bindingPath", RTKDataModelType_GetDataPath( RTK_MODELTYPE_MENUS, string( self.GetInternalId() ), true, [ "pagination" ] ) )
		}
	}

	if ( !showNav )
	{
		rtk_behavior animator = self.PropGetBehavior( "hintAnimator" )
		if( animator != null && RTKAnimator_HasAnimation( animator, "Hide" ) )
		{
			RTKAnimator_PlayAnimation( animator, "Hide" )
		}
	}
}

void function RTKPagination_ClearDataModel( rtk_behavior self  )
{
	rtk_struct screenPagination = RTKDataModelType_CreateStruct( RTK_MODELTYPE_MENUS, "pagination" )
	rtk_array paginationArray = RTKStruct_AddArrayOfStructsProperty( screenPagination, string( self.GetInternalId() ), "RTKPaginationPip" )
	RTKArray_SetValue( paginationArray, [] )
}

void function RTKPagination_SetPositionToPageNoAnim( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	rtk_panel ornull content = self.PropGetPanel( "content" )

	if( content != null )
	{
		expect rtk_panel( content )
		if( self.PropGetBool( "vertical" ) )
			content.SetPositionY( RTKPagination_GetPagePosition( self, p.nextPageIndex ) )
		else
			content.SetPositionX( RTKPagination_GetPagePosition( self, p.nextPageIndex ) )

		RTKPagination_UpdateCurrentPage( self )
	}
}

void function RTKPagination_OnAnimFinished( rtk_behavior self, string animName )
{
	RTKPagination_RefreshPaginationButtons( self )
}

void function RTKPagination_UpdateCurrentPage( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	p.currentPageIndex = p.nextPageIndex
	p.nextPageIndex = -1
}

float function RTKPagination_GetContainerSize( rtk_behavior self )
 {
	 rtk_panel ornull container = self.PropGetPanel( "container" )
	 if( container != null )
	 {
		 expect rtk_panel( container )

		 if( self.PropGetBool( "vertical" ) )
			 return container.GetHeight()
		 else
			 return container.GetWidth()
	 }

	 return 0
 }

float function RTKPagination_GetContentSize( rtk_behavior self )
{
	rtk_panel ornull content = self.PropGetPanel( "content" )
	if( content != null )
	{
		expect rtk_panel( content )

		if( self.PropGetBool( "vertical" ) )
			return content.GetHeight()
		else
			return content.GetWidth()
	}

	return 0
}

struct PaginationPositionData
{
	float offset
	int pages
}

PaginationPositionData function RTKPagination_GetDynamicPaginationPositionData( rtk_behavior self , int searchForPage = -1)
{
	float containerSizeOffset = self.PropGetFloat( "containerSizeOffset" )
	float containerSize = RTKPagination_GetContainerSize( self ) + containerSizeOffset
	bool panelsAlwaysStartNewPages = self.PropGetBool( "panelsAlwaysStartNewPages" )
	PaginationPositionData data

	if( panelsAlwaysStartNewPages )
	{
		array< float >  contentSizes = RTKPagination_GetContentSizes( self )
		float contentSpacing = RTKPagination_GetContentSpacing( self )
		float childContentUsedSpace      = 0
		int lastIndex                    = 0

		
		
		for ( int i = 0; i < contentSizes.len(); i++ )
		{
			if( searchForPage == data.pages )
				break

			if( i != lastIndex )
			{
				childContentUsedSpace = 0
			}
			int savedIndex = i

			float childContentSize = contentSizes[i] - childContentUsedSpace
			float remainingContainerSize

			if( i == lastIndex )
				remainingContainerSize = data.offset - ( containerSize * max( data.pages - 1, 0 ) )
			else
				remainingContainerSize = containerSize

			if( childContentSize > containerSize )
			{
				
				data.offset += containerSize
				data.pages++
				childContentUsedSpace += containerSize

				i-- 
			}
			else if( remainingContainerSize + childContentSize >= containerSize )
			{
				
				data.offset += childContentSize
				data.pages++

				childContentUsedSpace += min( containerSize, childContentSize )
			}
			else
			{
				
				data.offset += childContentSize + contentSpacing
				childContentUsedSpace = 0

				data.pages++
			}

			lastIndex = savedIndex
		}
	}
	else
	{
		
		
		float totalSize = RTK_Pagination_GetContentTotalSize( self ) + containerSizeOffset

		data.offset = ( searchForPage == -1 ) ? totalSize : containerSize * float( searchForPage )
		data.pages = ( searchForPage == -1 ) ? int( ceil( totalSize / containerSize ) ) : searchForPage
	}

	data.pages = int( max( data.pages, 0 ) )

	return data
}

float function RTK_Pagination_GetContentTotalSize( rtk_behavior self )
{
	if ( self.PropGetBool( "useContentSizeAsTotalSize" ) )
	{
		rtk_panel content = self.PropGetPanel( "content" )
		return self.PropGetBool( "vertical" ) ? content.GetHeight() : content.GetWidth()
	}

	array< float > contentSizes = RTKPagination_GetContentSizes( self )
	float spacing = RTKPagination_GetContentSpacing( self )
	float totalSize = 0
	for ( int i = 0; i < contentSizes.len(); i++ )
	{
		totalSize += ( i == 0 ) ? contentSizes[i] : contentSizes[i] + spacing
	}

	return totalSize
}

int function RTKPagination_GetTotalPages( rtk_behavior self )
{
	if( !self.PropGetBool( "autoPagesByContainerContent" ) )
		return self.PropGetInt( "pages" )

	PaginationPositionData data = RTKPagination_GetDynamicPaginationPositionData( self )
	return data.pages
}

int function RTKPagination_GetPagePosition( rtk_behavior self, int page )
{
	float contentSpacing = RTKPagination_GetContentSpacing( self )
	array< float >  contentSizes = RTKPagination_GetContentSizes( self )

	float contentSize = RTKPagination_GetContentSize( self )
	float containerSize = RTKPagination_GetContainerSize( self )

	rtk_panel ornull content = self.PropGetPanel( "content" )

	if( content != null )
	{
		expect rtk_panel( content )

		PaginationPositionData data = RTKPagination_GetDynamicPaginationPositionData( self, page )
		float maxOffset = -1 * ( self.PropGetBool( "fillEmptySpace" )? ( contentSize - containerSize ): contentSize )

		if( self.PropGetBool( "vertical" ) )
			return int( max( content.GetPivot().y * contentSize - data.offset, maxOffset ) )
		else
			return int( max( content.GetPivot().x * contentSize - data.offset, maxOffset ) )

	}

	return 0
}

array< float > function RTKPagination_GetContentSizes( rtk_behavior self )
{
	rtk_panel ornull content = self.PropGetPanel( "content" )
	array< float > sizes = []

	if( content != null )
	{
		expect rtk_panel( content )

		array< rtk_panel > children = content.GetChildren()
		foreach( panel in children )
		{
			if( self.PropGetBool( "vertical" ) )
				sizes.push( panel.GetHeight() )
			else
				sizes.push( panel.GetWidth() )
		}
	}

	return sizes
}

float function RTKPagination_GetContentSpacing( rtk_behavior self )
{
	rtk_panel ornull content = self.PropGetPanel( "content" )
	float spacing = 0
	if( content == null )
		return spacing

	expect rtk_panel( content )
	if( !content.HasLayoutBehavior() )
		return spacing

	rtk_behavior behavior = content.GetLayoutBehavior()
	if ( RTKStruct_HasProperty( behavior.GetProperties(), "spacing" ) )
	{
		spacing = behavior.PropGetFloat( "spacing" )
	}
	else if ( RTKStruct_HasProperty( behavior.GetProperties(), "slotSpacing" ) )
	{
		vector slotSpacing = RTKStruct_GetFloat2( behavior.GetProperties(), "slotSpacing" )
		spacing = self.PropGetBool( "vertical" ) ? slotSpacing.y : slotSpacing.x
	}

	return spacing
}

int function RTKPagination_GetCurrentPage( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	return p.currentPageIndex
}

int function RTKPagination_GetTargetPage( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	return p.nextPageIndex
}


bool function RTKPagination_GetShowNav( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	bool forceShowNav =  self.PropGetBool( "forceShowNav" )
	int pageCount = RTKPagination_GetTotalPages( self )

	return forceShowNav || pageCount > 1
}

void function RTKPagination_UpdateKeycodes( rtk_behavior self, rtk_behavior area )
{
	array< int > keycodes = [ KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, STICK2_LEFT, STICK2_RIGHT, STICK2_UP, STICK2_DOWN ]
	if ( self.PropGetBool( "supportShoulderButtonNav" ) )
	{
		keycodes.extend( [ BUTTON_SHOULDER_LEFT, BUTTON_SHOULDER_RIGHT ] )
	}
	rtk_array rtk_keycodes = area.PropGetArray( "keycodes" )

	RTKArray_SetValue( rtk_keycodes, keycodes )
}

void function RTKPagination_RegisterGlobalInput( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	array<int> keycodesPrev = [ MOUSE_WHEEL_UP ]
	array<int> keycodesNext = [ MOUSE_WHEEL_DOWN ]

	if ( self.PropGetBool( "vertical" ) )
	{
		keycodesPrev.extend( [ KEY_UP, STICK2_UP ] )
		keycodesNext.extend( [ KEY_DOWN, STICK2_DOWN ] )
	}
	else
	{
		keycodesPrev.extend( [ KEY_LEFT, STICK2_LEFT ] )
		keycodesNext.extend( [ KEY_RIGHT, STICK2_RIGHT ] )
	}

	if ( self.PropGetBool( "supportShoulderButtonNav" ) )
	{
		keycodesPrev.append( BUTTON_SHOULDER_LEFT )
		keycodesNext.append( BUTTON_SHOULDER_RIGHT )
	}

	p.keycodesPrev = keycodesPrev
	p.keycodesNext = keycodesNext
	p.prevPageFunc = void function( var button ) : ( self ) { RTKPagination_PrevPage( self, true ) }
	p.nextPageFunc = void function( var button ) : ( self ) { RTKPagination_NextPage( self, true ) }

	foreach( keycode in keycodesPrev )
	{
		RegisterButtonPressedCallback( keycode, p.prevPageFunc )
	}
	foreach( keycode in keycodesNext )
	{
		RegisterButtonPressedCallback( keycode, p.nextPageFunc )
	}

	rtk_behavior animator = self.PropGetBehavior( "hintAnimator" )
	if( animator != null && RTKAnimator_HasAnimation( animator, "FadeIn" ) )
	{
		RTKAnimator_PlayAnimation( animator, "FadeIn" )
	}
}

void function RTKPagination_DeregisterGlobalInput( rtk_behavior self )
{
	PrivateData p
	self.Private( p )

	foreach( keycode in p.keycodesPrev )
	{
		DeregisterButtonPressedCallback( keycode, p.prevPageFunc )
	}
	foreach( keycode in p.keycodesNext )
	{
		DeregisterButtonPressedCallback( keycode, p.nextPageFunc )
	}
}

void function RTKPagination_SetupCursorInteractArea( rtk_behavior self, rtk_behavior ornull area )
{
	if ( area != null )
	{
		expect rtk_behavior( area )

		RTKPagination_UpdateKeycodes( self, area )

		RTKCursorInteract_AutoSubscribeMouseWheeledListener( self, area,
			void function( float delta ) : ( self )
			{
				RTKPagination_OnMouseWheeled( self, delta )
			}
		)

		RTKCursorInteract_AutoSubscribeOnKeyCodePressedListener( self, area,
			void function( int code ) : ( self )
			{
				RTKPagination_OnKeyCodePressed( self, code )
			}
		)

		RTKCursorInteract_AutoSubscribeOnHoverEnterListener( self, area,
			void function() : ( self, area )
			{
				RTKPagination_OnHoverEnter( self, area )
			}
		)

		RTKCursorInteract_AutoSubscribeOnHoverLeaveListener( self, area,
			void function() : ( self, area )
			{
				RTKPagination_OnHoverLeave( self, area )
			}
		)
	}
}
