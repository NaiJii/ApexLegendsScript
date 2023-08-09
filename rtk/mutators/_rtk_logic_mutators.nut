globalize_all_functions


bool function RTKMutator_Not( bool input )
{
	return !input
}

bool function RTKMutator_Equal( float input, float other )
{
	return fabs( input - other ) < FLT_EPSILON
}

bool function RTKMutator_NotEqual( float input, float other )
{
	return !RTKMutator_Equal( input, other )
}

bool function RTKMutator_StrEqual( string input, string other )
{
	return  input == other
}

bool function RTKMutator_StrNotEqual( string  input, string other )
{
	return !RTKMutator_StrEqual( input, other )
}

bool function RTKMutator_GreaterThan( float input, float other )
{
	return input > other
}

bool function RTKMutator_GreaterThanOrEqual( float input, float other )
{
	return input >= other
}

bool function RTKMutator_LessThan( float input, float other )
{
	return input < other
}

bool function RTKMutator_LessThanOrEqual( float input, float other )
{
	return input <= other
}

bool function RTKMutator_CompareStrings( string option0, string option1 )
{
	return option0 == option1
}

bool function RTKMutator_InRangeExclusive( float input, float lowerBound, float upperBound )
{
	float realMin = min( lowerBound, upperBound )
	float realMax = max( lowerBound, upperBound )
	return input > realMin && input < realMax
}

bool function RTKMutator_InRangeInclusive( float input, float lowerBound, float upperBound )
{
	float realMin = min( lowerBound, upperBound )
	float realMax = max( lowerBound, upperBound )
	return input >= realMin && input <= realMax
}

bool function RTKMutator_And( bool input , bool arg1 )
{
	return input && arg1
}

bool function RTKMutator_Or( bool input , bool arg1 )
{
	return input || arg1
}

vector function RTKMutator_IfTrueSwapColour( vector input , bool shouldSwap, vector newColour )
{
	return shouldSwap ? newColour : input
}

vector function RTKMutator_IfFalseSwapColour( vector input , bool shouldSwap, vector newColour )
{
	return shouldSwap ? input : newColour
}

string function RTKMutator_IfTrueSwapString( string input , bool shouldSwap, string newString )
{
	return shouldSwap ? newString : input
}

string function RTKMutator_IfFalseSwapString( string input , bool shouldSwap, string newString )
{
	return shouldSwap ? input : newString
}
