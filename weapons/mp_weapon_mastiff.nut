global function OnWeaponPrimaryAttack_weapon_mastiff
global function OnWeaponActivate_weapon_mastiff
global function OnWeaponDeactivate_weapon_mastiff
global function OnProjectileCollision_weapon_mastiff







const int MASTIFF_BLAST_PATTERN_LEN = 8
struct {
	float[2][MASTIFF_BLAST_PATTERN_LEN] boltOffsets = [
		[0.0, 1.2], 
		[0.0, 0.15], 
		[0.0, 0.3], 
		[0.0, 0.6], 
		[0.0, -0.3], 
		[0.0, -0.6], 
		[0.0, -1.2], 
		[0.0, -0.15], 
	]

	









} file

var function OnWeaponPrimaryAttack_weapon_mastiff( entity weapon, WeaponPrimaryAttackParams attackParams )
{




	return FireMastiff( attackParams, true, weapon )
}








int function FireMastiff( WeaponPrimaryAttackParams attackParams, bool playerFired, entity weapon )
{
	float patternScale = 1.0
	if ( playerFired )
	{
		
		entity owner             = weapon.GetWeaponOwner()
		float maxAdsPatternScale = expect float( weapon.GetWeaponInfoFileKeyField( "blast_pattern_ads_scale" ) )
		patternScale *= Graph( owner.GetZoomFrac(), 0.0, 1.0, 1.0, maxAdsPatternScale )
	}
	else
	{
		patternScale = weapon.GetWeaponSettingFloat( eWeaponVar.blast_pattern_npc_scale )
	}

	float speedScale  = 1.0
	bool ignoreSpread = true
	weapon.FireWeapon_Default( attackParams.pos, attackParams.dir, speedScale, patternScale, ignoreSpread )

	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_per_shot )
}


void function OnWeaponActivate_weapon_mastiff( entity weapon )
{



}


void function OnWeaponDeactivate_weapon_mastiff( entity weapon )
{



}


void function OnProjectileCollision_weapon_mastiff( entity projectile, vector pos, vector normal, entity hitEnt, int hitBox, bool isCritical, bool isPassthrough )
{



}
