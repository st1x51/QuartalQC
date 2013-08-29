//buttonuse
.void() th_use;
.float capenabled;
void() use_ent = 
{
	local entity oldself;
	if (trace_ent.th_use)
	{
		oldself = self;
		other = self;
		self = trace_ent;
		self.th_use();
		self = oldself;
	}
};
void() use_cmd = 
{
	local vector source;
	local vector org;
	makevectors(self.v_angle);
	source = self.origin + '0 0 16';
	traceline(source, source + v_forward * 70, 0, self);
	if (trace_fraction == 1)
	{
		return;
	}
	org = trace_endpos - v_forward * 4;
	if (trace_ent)
	{
				if (trace_ent.capenabled == 1)
				{
					if (self.capenabled == 1)
					{
						return;
					}
					self.frame = 384;
				}
				else
				{
					if (trace_ent.classname == "player" && trace_ent.capenabled == 0)
					{
						return;
					}
					else
					{
						if (trace_ent.classname == "player" && self.capenabled == 1)
						{
							return;
						}
					}
				}
		use_ent();
	}
};