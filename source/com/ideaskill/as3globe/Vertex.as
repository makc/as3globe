package com.ideaskill.as3globe 
{
	/**
	* Vertex.
	*/
	internal class Vertex 
	{
		internal function set location (loc:Location):void {
			// colatitude
			var phi:Number = +(90 - loc.latitude) * 0.01745329252;
			// azimuthal angle
			var the:Number = +(180 - loc.longitude) * 0.01745329252;
			// normalized radius
			var r:Number = 1 + loc.altitude / Location.R;
			// translate into XYZ coordinates
			x = r * Math.sin (the) * Math.sin (phi);
			y = r * Math.cos (phi) * -1;
			z = r * Math.cos (the) * Math.sin (phi);
		}

		internal function get location ():Location {
			var loc:Location = new Location;
			var r:Number = Math.sqrt (x * x + y * y + z * z);
			var phi:Number = Math.acos (-1 * y / r); // 0 to pi
			var the:Number = Math.atan2 (x, z); // -pi to +pi
			loc.altitude = (r - 1) * Location.R;
			loc.latitude = +(90 - phi * 57.295779513);
			loc.longitude = +(180 - the * 57.295779513);
			return loc;
		}

		internal var x:Number;
		internal var y:Number;
		internal var z:Number;

		internal var tx:Number;
		internal var ty:Number;
		internal var tz:Number;

		internal var sx:Number;
		internal var sy:Number;
	}

}