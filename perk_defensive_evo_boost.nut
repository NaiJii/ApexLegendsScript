global function Perk_DefensiveEvoBoost_Init








const float BOOST_RANGE = 15 * METERS_TO_INCHES
const float BOOST_RANGE_SQR = BOOST_RANGE * BOOST_RANGE
const float BOOST_MULTIPLIER = 2.0
const asset BOOST_IMAGE = $"rui/menu/character_select/utility/util_role_defense"

struct
{



} file

void function Perk_DefensiveEvoBoost_Init()
{
	if ( GetCurrentPlaylistVarBool( "disable_perk_defensive_evo_boost", true ) )
		return

	PerkInfo defensiveEvoBoost
	defensiveEvoBoost.perkId          = ePerkIndex.DEFENSIVE_EVO_BOOST






	Perks_RegisterClassPerk( defensiveEvoBoost )




}
















































































































