void() tur_aim;
void() tur_launch;
void() tur_run;
void() start_monster_tur;
/*
Some stuff here
*/
void() spike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};
/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};
void() superspike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};
void() Laser_Touch =
{
	local vector org;
	
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
	org = self.origin - 8*normalize(self.velocity);

	if (other.health)
	{
		SpawnBlood (org, self.velocity*0.2, 15);
		T_Damage (other, self, self.owner, 15);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
	
	remove(self);	
};
void(vector org, vector vec) LaunchLaser =
{
//	local	vector	vec;
	sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
	vec = normalize(vec);
	
	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		

	setorigin (newmis, org);

	newmis.velocity = vec * 600;
	newmis.angles = vectoangles(newmis.velocity);

	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.touch = Laser_Touch;
};
/*
==============================================================================

TURRET
Can be used in teamplay as base defense, or as a normal SP monster.

==============================================================================
*/
void() checkground =           // UNNECESSARY?
{
  if (!(self.flags & FL_ONGROUND))
    return;

  if (self.groundentity.solid != SOLID_BSP)
  {
    self.flags = self.flags - (self.flags & FL_ONGROUND);
    return;
  }
};

float() turfindtarget =
{
  local entity e;
  local float r, mr;

  self.oldenemy = self.enemy;

  
  if (self.enemy)  // If has enemy, check if other people are closer
    mr = vlen(self.enemy.origin - self.origin);
  else
    mr = 1000;

  e = find(world,classname, "player");
  while (e)
  {
    if (e.health > 0) // Fastest checks first...
    {
      if (e.team != self.team || teamplay == 0)
      {
        if (visible(e) && infront(e))
        {
          r = vlen(e.origin - self.origin);
          if (r<mr)
          {
            mr = r;
            self.enemy = e;
          }
        }
      }
    }
    e = find (e, classname , "player");
  }

  if (self.enemy != self.oldenemy)  // Found a player to kill
    return TRUE;

  return FALSE;
};

void() tur_stand =
{
  checkground();

  setorigin(self.trigger_field, self.origin);

//  if (!self.flags&FL_ONGROUND)  // Check if nothing below!
//    T_Damage(self, world, world, 1000);
  if (!turfindtarget ())
  {
    self.enemy = world;
    tur_aim();
  }
  else
  {
    self.think = tur_run ;
    self.nextthink = time + 0.01;
    return;
  }
  self.think = tur_stand;
  self.nextthink = time + 0.01;
};

void() tur_walk =          // needed - NOT! :)
{
  self.think = tur_stand;
  self.nextthink = time + 0.1;
};

void() tur_run =
{
  setorigin(self.trigger_field, self.origin);
  
  checkground();
	if (!infront(self.enemy))
		self.enemy = world;
  if (!visible(self.enemy))
    self.enemy = world;
  if (self.enemy.health < 1)
    self.enemy = world;
  turfindtarget();
  if (!self.enemy)
  {
    self.think = self.th_stand;
    self.nextthink = time + 0.01;
    return;
  }
  tur_aim ();

  self.think = tur_run;
  self.nextthink = time + 0.01;
};

void() tur_death =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

  self.trigger_field.think = SUB_Remove;  // Remove the gun barrels
  self.trigger_field.nextthink = time + 0.1;
  if (!deathmatch)  // If SP mode, no respawn
    remove(self);
  else     // In DM, do respawn
  {
    setmodel(self, "");
    self.takedamage = 0;
    self.think = start_monster_tur;
    self.nextthink = time + self.wait;
//dprint("gonna resp\n");
  }
};

void() tur_die =
{
  // check for gib -- bio-mechanics ?-)
	
    
    if (self.health < -90)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		//gibs here
	}

self.solid = SOLID_NOT;
  tur_death();
};

void() tur_aim =
{
  local vector dir, vtemp, org;
  local float dist;

  setorigin(self.trigger_field,self.origin);//sync
	if (infront(self.enemy) == 0)
		self.enemy =world;
  if (self.enemy == world) // If no enemy, go to default position
    org = self.origin + self.movedir;
  else  // Dangerous iterating leading routine :)
  {
    org = self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5;
    // Notice it shoots to middle of size, not to origin. Can be opted out
    // if needed... Players rarely have origin outside their body. :)

    vtemp = org + self.enemy.velocity * self.speed;
    dist = vlen (vtemp - self.origin);
    dist = dist / 300;
    self.speed = dist;
    org = org + self.enemy.velocity * dist;
  }

  // Turn the gun
  dir = vectoangles (org - self.origin);

  vtemp = '0 0 0';
  vtemp_y = dir_y - self.angles_y;
  vtemp_x = dir_x - self.trigger_field.angles_x;
  dir = '0 0 0';
  if (vtemp_x < 0) vtemp_x = vtemp_x + 360;
  if (vtemp_x > 180) vtemp_x = vtemp_x - 360;
  if (vtemp_y < 0) vtemp_y = vtemp_y + 360;
  if (vtemp_y > 180) vtemp_y = vtemp_y - 360;
  dir = vtemp;
  if (dir_x < -10)  //  Turn 10 degrees per 0.1 sec.
    dir_x = -10;
  if (dir_x > 10)
    dir_x = 10;
  if (dir_y < -10)
    dir_y = -10;
  if (dir_y > 10)
    dir_y = 10;

	// g-cont. disabled by request
/*
	self.trigger_field.angles_x = anglemod(self.trigger_field.angles_x + dir_x);
	self.angles_y = anglemod(self.angles_y + dir_y);
	self.trigger_field.angles_y = self.angles_y;
*/
  
  if (self.enemy)
  {
    dir = self.trigger_field.angles;
    dir_x = 0 - dir_x;
    makevectors(dir);
    dir = normalize(org - self.origin);
    if (dir * v_forward > 0.97)  // roughly pointing at the target
    {
      if (time > self.attack_finished)
      {
        traceline(self.origin, org, TRUE, world);
        if (trace_fraction == 1 && dist <= 2)   // max. 2 seconds range
          self.th_missile (); 
      }
    }
  }
};

void() tur_launch =
{
  if (!self.ammo_cells)
    return;
  //self.ammo_cells = self.ammo_cells - 1;
	/*
  v1 = self.trigger_field.angles;
  v1_x = 0 - v1_x;
  makevectors (v1);
	//makevectors (self.enemy.angles);	
	v1 = (self.enemy.origin - self.origin);
	*/
  	local vector org;

	self.effects = self.effects | EF_MUZZLEFLASH;
	makevectors (self.angles);
	if(self.enemy.crouch == 0)
	org = self.origin + v_forward * 30 + '0 0 16'; 
	else
	org = self.origin + v_forward * 30 + '0 0 6';
	//LaunchLaser(org, self.enemy.origin - self.origin);
  
  if (self.spawnflags & 2)
  {
	sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
	if (self.ammo_cells & 1)
		LaunchLaser(org, self.enemy.origin - self.origin);
	else
		LaunchLaser(org, self.enemy.origin - self.origin);
	self.attack_finished = time + 0.2;
  }
  else
  {
	sound (self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM);
	if (self.ammo_cells & 1)
		launch_spike(org, self.enemy.origin - self.origin);
	else
		launch_spike(org, self.enemy.origin - self.origin);

	newmis.touch = superspike_touch;
	newmis.velocity = 1200 * normalize(self.enemy.origin - self.origin);
	self.attack_finished = time + 0.2;
  }
};

//=================================================================

void() start_monster_tur =
{
  bprint("turret's mind active\n");
  local entity stemp;

/*  if (deathmatch > 0)   // People won't like it in regular DM, right?
    if (self.team == 0 || teamplay == 0)
    {
//dprint("fukk!\n");
      remove(self);
      return;
    }
*/

  self.solid = SOLID_SLIDEBOX;
  self.movetype = MOVETYPE_TOSS;
  self.health = self.max_health;
  setmodel (self, "progs/aagtb.mdl");
  setsize (self, '-16 -16 -20', '16 16 16');

  self.th_stand = tur_stand;
  self.th_walk = tur_walk;
  self.th_run = tur_run;
  self.th_die = tur_die;
  self.th_missile = tur_launch;

  setorigin(self, self.oldorigin);
  droptofloor(0,0);
	self.takedamage = DAMAGE_AIM;


	self.ideal_yaw = self.angles * '0 1 0';
	self.view_ofs = '0 0 1';
	self.use = monster_use;
	
	self.flags = self.flags | FL_ONGROUND;

  stemp = spawn(); 
  stemp.owner = self;
  stemp.takedamage = DAMAGE_NO;
  self.trigger_field = stemp;
  stemp.angles = self.angles;
  setorigin(stemp, self.origin);
  self.ammo_cells = self.aflag;

  self.th_stand ();
};

/*QUAKED monster_tur (1 0 0) (-16 -16 -20) (16 16 16) Ambush Laser
Shoots people by spikes and lasers. 99% effective leading routine.
Health and ammo_cells can be set in map file, wait == respawn time.
*/
void() monster_tur =
{
  local vector v1;

  precache_model ("progs/aagtb.mdl");

  if (self.spawnflags & 2)
  {
		precache_model2 ("progs/laser.mdl");
		
		precache_sound2 ("enforcer/enfire.wav");
		precache_sound2 ("enforcer/enfstop.wav");
  }
  else
  {
		precache_sound ("weapons/spike2.wav");
  }

  if (!deathmatch)
    total_monsters = total_monsters + 1;
  self.oldorigin = self.origin;
  if (!self.health)  
    self.health = 100;
  self.max_health = self.health;
  v1 = self.angles_y * '0 1 0' + '-20 0 0';
  makevectors (v1);
  self.movedir = v_forward;
  self.classname = "turret";

  if (!self.ammo_cells)
    self.ammo_cells = 5000;
  self.aflag = self.ammo_cells;

  if (!self.wait)
    self.wait = 30;

  self.think = start_monster_tur;
  self.nextthink = time + 0.1;
}; 