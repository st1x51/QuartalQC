void() UpdateWeapon;
void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
};
/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float	oldz;

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
	if (!droptofloor(0,0))
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

void() weapon_touch =
{
	if (!(other.flags & FL_CLIENT))
		return;
	
	if (self.classname == "weapon_portalgun")
	{
		other.weapon = IT_PORTAL_GUN;	
		other.weaponmodel = "progs/v_portal.mdl";	
	}
	else
		objerror ("weapon_touch: unknown classname");

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch == 1)
		self.nextthink = time + 30;
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

/*QUAKED weapon_portalgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_portalgun =
{
	precache_model ("progs/g_portal.mdl");
	setmodel (self, "progs/g_portal.mdl");
	self.weapon = IT_PORTAL_GUN;
	self.netname = "PortalGun";
	self.touch = weapon_touch;
	setsize (self, '0 0 0', '32 32 32');
	StartItem ();
}; 