/*  Copyright (C) 1996-1997  Robert "BOby" Siska

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

//// Constants
float 		PORTAL_ATTACK		= 0.5;
float		PORTAL_REFIRE		= 0.2;
float		PORTAL_BUFFER		= 0.9;
float		PORTAL_KICK		= 150;
float 		PORTAL_RANGE		= 120;

float       MAX_VEL         = 1000;

float		CUBE_LIFTED		= 2;
float		CUBE_DROPPED		= 3;

//// Functions
void()		      PortalImpulses;
void(entity p)	  PortalErase;
void()		      Portal1Touch;
void()		      Portal2Touch;
void()		      PortalDeathTouch;
void(entity org)  PortalTeleportEffect;
void()		      PortalFire;
void()		      GripFire;
void()		      PortalUpdate;
void()		      player_run;
void()		      PortalCubeThink;
void(entity own, entity hit, vector org, vector plane) T_PortalSpawn;
vector(entity p)  portal_clip_player;
void()            UpdateWeapon;


//// Global variables
// Entities
entity          portal1_entity;
entity          portal2_entity;
// Counters
float 		portal_global;
float		portal1_exist;
float		portal2_exist;
float		portal_mode; //1 = deathmatch, 0 = cooperative
.entity 	lastport;
.float 		nextportcolour;
.entity		cube;
.float		nextthink1;
.float		grip_dist;

//// Gun animation frames
$frame grip1 grip2 grip3 grip4 grip5 grip6
void()	player_grip1 = [$grip1, player_grip2] {self.weaponframe=16;self.nextthink = time + 0.03;};
void()  player_grip2 = [$grip2, player_grip3] {self.weaponframe=17;self.nextthink = time + 0.03;};
void()  player_grip3 = [$grip3, player_grip4] {self.weaponframe=18;GripFire();};
void()  player_grip4 = [$grip4, player_grip5] {self.weaponframe=19;self.nextthink = time + 0.03;};
void()  player_grip5 = [$grip5, player_run] {self.weaponframe=20;self.nextthink = time + 0.03;};

void()  player_portal1 =
{
if(self.weaponframe == 3)
{
PortalFire();
}
if(self.weaponframe == 14)
{
self.weaponframe = 1;
return;
}
self.weaponframe = self.weaponframe + 1;
self.think = player_portal1;
self.nextthink = time + 0.05;
}

  //////////////
 //// Main Code
//////////////
void() null_die = {};
void() PortalInit = {
	self.cube = spawn();
	self.cube.cnt = 0;

    portal_global = 0;
    portal1_exist = 0;
    portal2_exist = 0;
    
    portal_mode = 1; //1 = deathmatch, 0 = cooperative
};
vector(vector ang) portal_direction = {
	// Returns angle of the object which bears portal
	return trace_plane_normal;
};

vector(vector org) portal_face = {
	// Returns facing for the portal
	local vector v;
	v = trace_plane_normal;
	v_z = v_z * -1;
	return vectoangles(v);
};

vector(entity p) portal_clip_player = {
	// Returns coordinates where the teleported object appears
	local vector org;
	org = p.origin;

	makevectors(p.angles);
	org = org + v_forward*48;
	return org;
};

void() PortalImpulses = {
	local entity tmp;

	if (self.impulse == 98) {// Close portals
	 if (self.weapon == IT_PORTAL_GUN) {
      if (portal_mode == 1) {
       if (self.lastport) {
	        PortalErase(self.lastport);
			PortalErase(self.lastport.enemy);
			self.lastport = world;
	   }
	  } else // portal_mode == 0
      {
        PortalErase(portal1_entity);
		PortalErase(portal2_entity);
	  }
	 }
    }

	if (self.impulse == 99) { // sheath portal gun
		self.items = self.items | IT_PORTAL_GUN;
		self.weapon = IT_PORTAL_GUN;
		UpdateWeapon();
	}
	if (self.impulse == 97) { // Toggle deathmatch/cooperative mode
		if (portal_mode == 0) {
			PortalErase(portal1_entity);
			PortalErase(portal2_entity);
			portal_mode = 1; // set to deathmatch mode
			bprint("portal_gun: Deathmatch mode set.\n");
		} else {
			if (self.lastport) {
				PortalErase(self.lastport);
				if (self.lastport.enemy)
					PortalErase(self.lastport.enemy);
				self.lastport = world;
			}
			portal_mode = 0; // set to cooperative mode
			bprint("portal_gun: Cooperative mode set.\n");
		}
	}
	if (self.impulse == 96) { // Force blue portal
		if (self.weapon == IT_PORTAL_GUN) {
		 if (portal_mode == 1) {
			 if (self.nextportcolour != 0) {
			  self.nextportcolour = 0;
			  tmp = self.lastport.enemy;
                          PortalErase(self.lastport);
			  self.lastport = tmp;
			 }
			 player_portal1();
		 } else {
			portal_global = 0;
			player_portal1();
		 }
		}
	}
	if (self.impulse == 95) { // Force red portal
		if (self.weapon == IT_PORTAL_GUN) {
		 if (portal_mode == 1) {
			 if (self.nextportcolour != 1) {
			  self.nextportcolour = 1;
			  tmp = self.lastport.enemy;
                          PortalErase(self.lastport);
			  self.lastport = tmp;
			 }
			 player_portal1();
		 } else {
			portal_global = 1;
			player_portal1();
		 }
		}
	}
	if (self.impulse == 94) { // Fire grip
		if (self.weapon == IT_PORTAL_GUN)
		if (self.cube.cnt == 0) 
		{
			player_grip1();
		} 
		else
		{
		 
		 self.cube.cnt = 0; // self.cube is vacant
		 self.cube.enemy.nextthink = self.cube.nextthink1;
		 self.cube.enemy.think = self.cube.think;
		 self.cube.enemy.touch = self.cube.touch;
		 self.cube.enemy.flags = (self.cube.enemy.flags | FL_ONGROUND) - FL_ONGROUND;
		 self.cube.enemy.solid = SOLID_SLIDEBOX;
		 self.cube.enemy.owner = world;
		 makevectors(self.v_angle);
		 self.cube.enemy.velocity = v_forward*100+ v_up*25;
		 self.aiment = world;

			// recompute turret direction
			if( self.cube.enemy.classname == "turret" )
			{
				self.cube.enemy.ideal_yaw = self.cube.enemy.angles * '0 1 0';
				if( self.cube.enemy.trigger_field )
				{
					self.cube.enemy.trigger_field.angles = self.cube.enemy.angles;
					setorigin(self.cube.enemy.trigger_field, self.cube.enemy.origin);
				}
			}
			remove( self.cube );
		}
	}
	if (self.impulse == 94) { // Fire grip
		if (self.weapon == 0)
		if (self.cube.cnt == 0) {
			player_grip1();
		} else 
		{
		 self.cube.cnt = 0; // self.cube is vacant
		 self.cube.enemy.nextthink = self.cube.nextthink1;
		 self.cube.enemy.think = self.cube.think;
		 self.cube.enemy.touch = self.cube.touch;
		 self.cube.enemy.flags = (self.cube.enemy.flags | FL_ONGROUND) - FL_ONGROUND;
		 self.cube.enemy.solid = SOLID_SLIDEBOX;
		 self.cube.enemy.owner = world;
		 makevectors(self.v_angle);
		 self.cube.enemy.velocity = v_forward*10 + v_up*10;
		 self.aiment = world;
		 remove( self.cube );
		}
	}
};

void() T_PortalFlashTouch = {
	local vector src;
	local vector dst;
	local vector dir;

        // Portals touching handler
	if( other == self.owner )
                return;
                
	if( pointcontents( self.origin ) == CONTENT_SKY )
	{
                remove( self );
                return;
	}       

	dir = normalize( self.velocity );
	src = self.origin + dir * -8;
	dst = self.origin + dir * 8;

	traceline( src, dst, TRUE, self );

	if( trace_fraction != 1 )
	{
		if( trace_ent.classname == "hardlight" ) //portal can penetrate hard light, you can't
		{
			traceline( trace_endpos, dst, TRUE, trace_ent );

			if( trace_fraction != 1 )
				T_PortalSpawn( self.owner, trace_ent, trace_endpos, trace_plane_normal );
		}
		else
		{
			T_PortalSpawn( self.owner, trace_ent, trace_endpos, trace_plane_normal );
		}
	}

	// Explosion
	self.origin = self.origin - 8 * dir;
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_TELEPORT);
	WriteCoord(MSG_BROADCAST, self.origin_x);
	WriteCoord(MSG_BROADCAST, self.origin_y);
	WriteCoord(MSG_BROADCAST, self.origin_z);
	remove(self);
};

void() PortalFire = 
{
	local entity portal_flash;

	self.punchangle_x = -2;

	portal_flash = spawn();
	portal_flash.owner = self;
	portal_flash.movetype = MOVETYPE_FLY;
	portal_flash.solid = SOLID_BBOX;

	makevectors(self.v_angle);

	portal_flash.velocity = v_forward;
	portal_flash.velocity = portal_flash.velocity * 2500;
	portal_flash.angles = vectoangles( v_forward );
	portal_flash.touch = T_PortalFlashTouch;

	portal_flash.nextthink = time + 5;
	portal_flash.think = SUB_Remove;

	sound(self,CHAN_WEAPON,"portal/fire.wav",1,ATTN_NORM);

	setmodel( portal_flash, "progs/portal_flash.mdl" );
	setsize( portal_flash, VEC_ORIGIN, VEC_ORIGIN );
	setorigin(portal_flash, self.origin + v_forward * 8 + '0 0 16');

	self.attack_finished = time + PORTAL_ATTACK;
};

void() GripFire = {
	// Finds the entity
	local entity e;
	local vector where;
	local float dist,found,i;

	
	found = FALSE;
	i = 25;
	
	makevectors(self.v_angle);
	
	while ((found == FALSE) && (i != 125)) {
		where = self.origin + v_forward*i;
		e = findradius(where,30+(i/2));
		while ((e != world) && (found == FALSE)) {
			if (visible(e))
			if (infront(e))
			if ((e.movetype == MOVETYPE_TOSS) || (e.classname == "cube")) {
				dist = vlen(e.origin - (self.origin + self.view_ofs));
				found = TRUE;
				break;
			}
			if (found == FALSE)
				e = e.chain;
		}
		i = i + 25;
	}

	// e is first found entity
	if (found == FALSE) return;
	if (e == world) return;
	if (dist < 48 || dist > 128) return; // too close or too far 
	if (self.cube.cnt != 0) return; // already carrying item

	if (e.owner.classname == "player")
	{ // item is carried by someone
		e.owner.cube.cnt = 0;
		e.owner.cube.enemy.nextthink = e.owner.cube.nextthink1;
		e.owner.cube.enemy.think = e.owner.cube.think;
		e.owner.cube.enemy.flags = (e.owner.cube.enemy.flags | FL_ONGROUND) - FL_ONGROUND;
//		bprint(e.owner.classname);
	}
	
	//nice little electric bolt
	if(self.weapon == IT_PORTAL_GUN)
	{
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity(MSG_BROADCAST, self);
	WriteCoord(MSG_BROADCAST,self.origin_x);
	WriteCoord(MSG_BROADCAST,self.origin_y);
	WriteCoord(MSG_BROADCAST,self.origin_z+30);
	WriteCoord(MSG_BROADCAST,e.origin_x);
	WriteCoord(MSG_BROADCAST,e.origin_y);
	WriteCoord(MSG_BROADCAST,e.origin_z+16);
	}
	self.cube = spawn();
	self.cube.owner = e.owner;
	self.cube.think = e.think;
	self.cube.nextthink1 = e.nextthink;
	self.cube.touch = e.touch;
	self.cube.cnt = CUBE_LIFTED;
	self.cube.enemy = e;
		
	e.owner = self;
	e.cnt = CUBE_LIFTED;
	e.solid = SOLID_NOT;
	e.think = PortalCubeThink;
	e.nextthink = 0.01; // considering constant JIFFY
	e.touch = SUB_Null;
	e.grip_dist = dist;
	self.aiment = e;		// g-cont. tell engine about picked cube
	e.oldorigin = e.origin;	// setup the last valid origin
};

//TODO:  some checking if there is enough space to spawn would be great!
//FIXME: this function has large portion of code "duplicated", but...not really ;)
void(entity own, entity hit, vector org, vector plane) T_PortalSpawn = {
    // Spawns portals
    local entity p,e;

//    bprint(hit.classname);
//    bprint("\n");
    
    //portal-proof entities
    if ( (hit.classname == "portalproof") || (hit.classname == "door") || (hit.classname == "hardlight2") || (hit.classname == "pellet") )
    {
        //spawn just to remove it (in fancy way)
        p = spawn();
        p.fixangle = 1;
        plane_z = -1*plane_z;
        p.angles = vectoangles(plane);
        setorigin (p, org);
        PortalErase(p);
        return;
    }
       
    if (portal_mode == 1) { // deathmatch mode
       p = spawn();
       p.owner = own;
       p.movetype = MOVETYPE_NONE;
       p.solid = SOLID_TRIGGER;
       p.classname = "portal";
       p.fixangle = 1;
    		
       plane_z = -1*plane_z;
       p.angles = vectoangles(plane);
       p.punchangle = trace_plane_normal;
		
            p.touch = PortalDeathTouch;
    		p.frags = time - 1;
    		p.nextthink = time + 0.1;
    		p.think = PortalUpdate;
		
            p.movetarget = hit;
    		p.oldorigin = hit.origin;

    		if (own.lastport) {
    			p.enemy = own.lastport;
    			PortalErase(p.enemy.enemy);
    			p.enemy.enemy = p;
    		}
    		own.lastport = p;
		
    		if (own.nextportcolour) {
    			setmodel(p,"progs/portal2.bsp");
    			own.nextportcolour = 0;
    		} else {
    			setmodel(p,"progs/portal1.bsp");
    			own.nextportcolour = 1;
    		}
    //		setsize(p,p.mins,p.maxs);
    		setorigin(p,org);
		
    		// Wake entities near the portal gates
    		e = findradius(p.origin, PORTAL_RANGE);
    		while (e != world) {
    			if (e.classname == "cube" || (e.movetype == MOVETYPE_TOSS))
    			if (e != own) {
    				setorigin(e,e.origin + '0 0 10');
	    			e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
    			}
    			e = e.chain;
    		}
    		e = findradius(p.enemy.origin, PORTAL_RANGE);
    		while (e != world) {
    			if (e.classname == "cube" || (e.movetype == MOVETYPE_TOSS))
	    		if (e != own) {
    				setorigin(e,e.origin + '0 0 10');
    				e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
    			}
    			e = e.chain;
    		}
	    	
            return;
	}
	// cooperative mode
	if (portal_global == 0) { // Blue portal
        if (portal1_exist == 1) { // Delete if exists somewhere else
            PortalErase(portal1_entity);
            portal1_exist = 0;
        }

        portal1_entity = spawn();
		portal1_entity.owner = own;
		portal1_entity.movetype = MOVETYPE_NONE;
		portal1_entity.solid = SOLID_TRIGGER;
		portal1_entity.classname = "portal1";
		portal1_entity.fixangle = 1;
		plane_z = -1*plane_z;
		portal1_entity.angles = vectoangles(plane);
		portal1_entity.punchangle = trace_plane_normal;
		portal1_entity.touch = Portal1Touch;
		portal1_entity.frags = time - 0.1;
		portal1_entity.nextthink = time + 0.1;
		portal1_entity.think = PortalUpdate;
		portal1_entity.movetarget = hit;
		portal1_entity.oldorigin = hit.origin;
//		portal1_entity.effects = EF_DIMLIGHT; // glowing
		
		setmodel(portal1_entity, "progs/portal1.bsp");
//		setsize(portal1_entity,VEC_HULL_MIN,VEC_HULL_MAX);
		setorigin(portal1_entity,org);

                
		portal1_entity.frame = 4;

                portal1_exist = 1;
                portal_global = 1;

		// Wake the entities near the portal gates
		e = findradius(portal1_entity.origin, PORTAL_RANGE);
		while (e != world) {
			if (e.movetype == MOVETYPE_TOSS)
			if (e != own) {
				setorigin(e,e.origin + '0 0 10');
				e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
			}
			e = e.chain;
			
		}
		e = findradius(portal2_entity.origin, PORTAL_RANGE);
		while (e != world) {
			if (e.movetype == MOVETYPE_TOSS)
			if (e != own) {
				setorigin(e,e.origin + '0 0 10');
				e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
			}
			e = e.chain;
			
		}
        } else if (portal_global == 1) { // Yellow portal
		if (portal2_exist == 1) {
                        PortalErase(portal2_entity);
                        portal2_exist = 0;
                }       
                portal2_entity = spawn();
		portal2_entity.owner = own;
		portal2_entity.movetype = MOVETYPE_NONE;
		portal2_entity.solid = SOLID_TRIGGER;
		portal2_entity.classname = "portal2";
		portal2_entity.fixangle = 1;
        plane_z = -1*plane_z;
		portal2_entity.angles = vectoangles(plane);
		portal2_entity.punchangle = trace_plane_normal;
                portal2_entity.touch = Portal2Touch;
		portal2_entity.frags = time - 0.1;
		portal2_entity.nextthink = time + 0.1;
		portal2_entity.think = PortalUpdate;
		portal2_entity.movetarget = hit;
		portal2_entity.oldorigin = hit.origin;
//		portal2_entity.effects = EF_DIMLIGHT;
		
		setmodel(portal2_entity, "progs/portal2.bsp");
//		setsize(portal2_entity,);
		setorigin(portal2_entity,org);

                
		portal2_entity.frame = 4;

                portal2_exist = 1;
                portal_global = 0;

		e = findradius(portal1_entity.origin, PORTAL_RANGE);
		while (e != world) {
			if (e.movetype == MOVETYPE_TOSS)
			if (e != own) {
				setorigin(e,e.origin + '0 0 0');
				e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
			}
			e = e.chain;
		}
		e = findradius(portal2_entity.origin, PORTAL_RANGE);
		while (e != world) {
			if (e.movetype == MOVETYPE_TOSS)
			if (e != own) {
				setorigin(e,e.origin + '0 0 0');
				e.flags = (e.flags | FL_ONGROUND) - FL_ONGROUND;
			}
			e = e.chain;
		}

        }
};

void(entity org) PortalTeleportEffect = {
        // Spawns teleport fog
	local entity s;
	
	makevectors(org.angles);
	s = spawn();
        s.origin = org.origin + v_forward*50;
        s.nextthink = time + 0.2;
	s.think = SUB_Remove;

        sound(s, CHAN_WEAPON, "portal/use.wav", 1, ATTN_NORM);

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_TELEPORT);
        WriteCoord(MSG_BROADCAST, s.origin_x);
        WriteCoord(MSG_BROADCAST, s.origin_y);
        WriteCoord(MSG_BROADCAST, s.origin_z);
};

void(entity org) PortalEraseEffect = {
        // Spawns teleport fog
        local entity s;
	
	//can't find why it is on '0 0 0' sometimes...
        //possible bug
        if (org.origin == '0 0 0') return;

        makevectors(org.angles);
	s = spawn();
        s.origin = org.origin + v_forward*50;
        s.nextthink = time + 0.2;
	s.think = SUB_Remove;

        sound(s, CHAN_WEAPON, "portal/close.wav", 1, ATTN_NORM);

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_TELEPORT);
        WriteCoord(MSG_BROADCAST, s.origin_x);
        WriteCoord(MSG_BROADCAST, s.origin_y);
        WriteCoord(MSG_BROADCAST, s.origin_z);
};


void(entity p) PortalErase = {
	// Erases given portal
	local entity t;
        local float play;
	if (!p) return;
	play=0;
	if (portal_mode == 1) { //dm mode
		t = self;
		self = p;
		PortalEraseEffect(p);

		remove(self);
		self = t;
		return;
	}
	//coop mode
        if (p.classname=="portal1") {
		portal1_exist = 0;
	} else if (p.classname=="portal2") {
		portal2_exist = 0;
	}

//        t = self;
//        self = p;
        PortalEraseEffect(p);
        remove(p);
//        self = t;
};

void() PortalUpdate = {
	// What do portal gates think (nothing)
	self.nextthink = time + 0.1;
};

void() SUB_teleport = {
	// Safe setorigin (for use in handler functions)
	setorigin(self,self.origin);
	self.nextthink = self.nextthink1;
	self.think = self.think1;
};

void() Portal1Touch = {
	// Handles touch with Blue portal
	local float vel;
	local vector org;
	local vector oldvelocity;
	
	if (portal2_exist==0) return;
	if (self.frags > time) return;

	vel = vlen(other.velocity) + PORTAL_KICK;
	oldvelocity = other.velocity;
			
	org=portal_clip_player(portal2_entity);

	// just setorigin can't be used in touch function 
    // (quakec theory, 1st semester :)
	other.origin = org;
	other.nextthink1 = other.nextthink;
	other.nextthink = time + 0.1;
	other.think1 = other.think;
	other.think = SUB_teleport;

	PortalTeleportEffect(self);
	PortalTeleportEffect(portal2_entity);

	self.frags = time + PORTAL_REFIRE;
	portal2_entity.frags = time + PORTAL_REFIRE;

    if (other.classname == "player")
    {
        other.fixangle = 1;
        other.velocity = vel * portal2_entity.punchangle * PORTAL_BUFFER;
        if ((other.velocity_x == 0) && (other.velocity_y == 0))
        {
            other.fixangle = 0;
        }
        other.angles_x = 0;
    	other.angles_y = vectoyaw(other.velocity);
    	other.angles_z = 0;
    	other.v_angle_z = 0;
    } else
    {
        other.velocity = vel * portal2_entity.punchangle * PORTAL_BUFFER;
    }
    other.flags = (other.flags | FL_ONGROUND) - FL_ONGROUND;
};

void() Portal2Touch = {
	// Handles touch with Yellow portal
	local float vel;
	local vector org;
	local vector oldvelocity;

	if (portal1_exist==0) return;
	if (self.frags > time) return;
	
	vel = vlen(other.velocity) + PORTAL_KICK;
	oldvelocity = other.velocity;

    self.frags = time + PORTAL_REFIRE;
    self.enemy.frags = time + PORTAL_REFIRE;
		
	org = portal_clip_player(portal1_entity);
		
	other.origin = org;
	other.nextthink1 = other.nextthink;
	other.nextthink = time + 0.1;
	other.think1 = other.think;
	other.think = SUB_teleport;
	
	PortalTeleportEffect(self);	
	PortalTeleportEffect(portal1_entity);

	if (other.classname == "player")
    {
        other.fixangle = 1;
        other.velocity = vel * portal1_entity.punchangle * PORTAL_BUFFER;
        if ((other.velocity_x == 0) && (other.velocity_y == 0)) {
                other.fixangle = 0;
        }
        other.angles_x = 0;
        other.angles_y = vectoyaw(other.velocity);
    	other.angles_z = 0;
    	other.v_angle_z = 0;
    } else
    {
        other.velocity = vel * portal1_entity.punchangle * PORTAL_BUFFER;
    }
    other.flags = (other.flags | FL_ONGROUND) - FL_ONGROUND;
};

void() PortalDeathTouch = {
	// Handles touches in deathmatch mode
    //FIXME: cube bug on z_plane portals (solved?)
	local float vel;
	local vector org;
	local vector oldvelocity;

	if (!self.enemy) return;
	if (self.frags > time) return;
    if (other.frags > time) return;

    vel = vlen(other.velocity) + PORTAL_KICK;
    oldvelocity = other.velocity;

	self.frags = time + PORTAL_REFIRE;
	self.enemy.frags = time + PORTAL_REFIRE;

	org = portal_clip_player(self.enemy);

	other.origin = org;
	other.nextthink1 = other.nextthink;
	other.nextthink = time + 0.1;
	other.think1 = other.think;
	other.think = SUB_teleport;
 
    PortalTeleportEffect(self);
	PortalTeleportEffect(self.enemy);

    if (other.classname == "player")
    {
        other.fixangle = 1;
        other.velocity = vel * self.enemy.punchangle * PORTAL_BUFFER;
    	if ((other.velocity_x == 0) && (other.velocity_y == 0))
    	{
            other.fixangle = 0;
	    }
        other.angles_x = 0;
      	other.angles_y = vectoyaw(other.velocity);
       	other.angles_z = 0;
       	other.v_angle_z = 0;
    } else
    {
        other.velocity = vel * self.enemy.punchangle * PORTAL_BUFFER;
    }
    other.flags = (other.flags | FL_ONGROUND) - FL_ONGROUND;
};

void() PortalCubeThink = {
	local vector src,org;
	local entity e;
	self.nextthink = time + 0.01;
	
 	e = self.owner;
        
	if( self.cnt == CUBE_DROPPED )
	{
		// g-cont. probably dead code
		self.solid = SOLID_SLIDEBOX;
		self.owner.aiment = world;
		return;
	}

	makevectors( e.v_angle );
	src = e.origin + e.view_ofs;
	tracebox( src, self.mins, self.maxs, src + v_forward * self.grip_dist, FALSE, self );
	org = trace_endpos;

	setorigin( self, org );

	// make sure what position is valid
	self.owner = world;	// clear owner for collide with him
	tracebox( org, self.mins, self.maxs, org, FALSE, self );
	self.owner = e; // restore owner

	if( trace_startsolid || trace_allsolid )
	{
		// bah, cube is blocked by player or somewhat
		// return to old valid position
		setorigin( self, self.oldorigin );
		return;
	}

	e = self.owner;
	makevectors(e.angles);
	self.angles = e.angles;
	self.angles_x = 0;
	self.angles_z = 0;	// g-cont. only YAW rotation is allowed

	setorigin( self, org );
	self.oldorigin = org; // member last valid position
};		 