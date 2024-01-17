globalize_all_functions

int function RTKMutator_GetIntAt( rtk_array input, int p0 )
{
	return RTKArray_GetInt( input, p0 )
}

int function RTKMutator_GetFirstInt( rtk_array input )
{
	return RTKArray_GetInt( input, 0 )
}

int function RTKMutator_GetLastInt( rtk_array input )
{
	return RTKArray_GetInt( input, RTKArray_GetCount( input ) - 1 )
}

string function RTKMutator_PickStringFrom( int input, rtk_array p0 )
{
	if ( 0 <= input && input < RTKArray_GetCount( p0 )  )
		return RTKArray_GetString( p0, input )
	return ""
}

int function RTKMutator_PickIntFrom( int input, rtk_array p0 )
{
	if ( 0 <= input && input < RTKArray_GetCount( p0 )  )
		return RTKArray_GetInt( p0, input )
	return 0
}

float function RTKMutator_PickFloatFrom( int input, rtk_array p0 )
{
	if ( 0 <= input && input < RTKArray_GetCount( p0 )  )
		return RTKArray_GetFloat( p0, input )
	return 0.0
}

vector function RTKMutator_PickFloat2From( int input, rtk_array p0 )
{
	if ( 0 <= input && input < RTKArray_GetCount( p0 )  )
		return RTKArray_GetFloat2( p0, input )
	return <0, 0, 0>
}

vector function RTKMutator_PickFloat3From( int input, rtk_array p0 )
{
	if ( 0 <= input && input < RTKArray_GetCount( p0 )  )
		return RTKArray_GetFloat3( p0, input )
	return <0, 0, 0>
}
