global function MpWeaponLifelineBatonPrimary_Init

global function OnWeaponActivate_weapon_lifeline_baton_primary
global function OnWeaponDeactivate_weapon_lifeline_baton_primary







void function MpWeaponLifelineBatonPrimary_Init()
{
	





}

void function OnWeaponActivate_weapon_lifeline_baton_primary( entity weapon )
{
	entity player = weapon.GetWeaponOwner()
	string meleeSkinName = MeleeSkin_GetSkinNameFromPlayer( player )

	if ( meleeSkinName == "baton" )
	{
		
	}







}

void function OnWeaponDeactivate_weapon_lifeline_baton_primary( entity weapon )
{
	entity player = weapon.GetWeaponOwner()
	string meleeSkinName = MeleeSkin_GetSkinNameFromPlayer( player )

	if ( meleeSkinName == "baton" )
	{
		
	}







}

