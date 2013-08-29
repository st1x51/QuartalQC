
float (entity targ) crouchcheck =
{

makevectors (self.v_angle);
tracebox (self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.origin + '0 0 16', FALSE, self); 

if (trace_fraction == 1)            //hits nothing go ahead
	return TRUE;

if (!trace_ent.takedamage)      //hits world or nondamagable object
	return FALSE;

	return FALSE;

};

void() crouch_on =
{

if ((self.crouch == 0) && (!self.velocity_z)) //crouch down
{
setsize (self, '-16 -16 -8', '16 16 8');
self.crouch = 1;
self.view_ofs = '0 0 14';
}
else if (self.crouch == 1 && (!self.velocity_z) && (crouchcheck(self)))
{
setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
self.crouch = 0;
self.origin_z = self.origin_z + 16;
self.view_ofs = '0 0 22';
}
};