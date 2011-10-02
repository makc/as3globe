package com.ideaskill.as3globe 
{
	/**
	* Transformation model of two-axis gimbal.
	*/
	internal class Gimbal 
	{
		private var lat:Number;
		private var clat:Number, slat:Number;
		private var lon:Number;
		private var clon:Number, slon:Number;
		private var slatslon:Number, slatclon:Number, clatslon:Number, clatclon:Number;

		internal function get location ():Location {
			var loc:Location = new Location;
			loc.latitude = + lat * 57.295779513; // = 180 / pi
			loc.longitude = lon * 57.295779513;
			return loc;
		}

		internal function set location (loc:Location):void {
			lat = ( + loc.latitude) * 0.01745329252; // = pi / 180
			lon = (loc.longitude) * 0.01745329252;

			clat = Math.cos (lat); slat = Math.sin (lat);
			clon = Math.cos (lon); slon = Math.sin (lon);

			slatslon = slat * slon; slatclon = slat * clon;
			clatslon = clat * slon; clatclon = clat * clon;
		}

		internal function transform (v:Vertex):void {
			//	x1 = x0 cos lon + z0 sin lon
			//	y1 = y0
			//	z1 = z0 cos lon - x0 sin lon

			//	x2 = x1
			//	y2 = y1 cos lat - z1 sin lat
			//	z2 = z1 cos lat + y1 sin lat

			//	combined:
			//	x2 = x0 cos lon + z0 sin lon
			//	y2 = y0 cos lat + x0 sin lat sin lon - z0 sin lat cos lon
			//	z2 = y0 sin lat - x0 cos lat sin lon + z0 cos lat cos lon

			v.tx = v.x * clon + v.z * slon;
			v.ty = v.y * clat + v.x * slatslon - v.z * slatclon;
			v.tz = v.y * slat - v.x * clatslon + v.z * clatclon;
		}

		/*public function toString ():String {
			return clon.toPrecision(3) + "\t" + "0.0" + "\t" + slon.toPrecision(3) + "\n" +
				slatslon.toPrecision(3) + "\t" + clat.toPrecision(3) + "\t" + ( -slatclon).toPrecision(3) + "\n" +
				( -clatslon).toPrecision(3) + "\t" + slat.toPrecision(3) + "\t" +clatclon.toPrecision(3) + "\n";
		}*/

		internal function invTransform (v:Vertex):void {
			// for rotation, inversion = transposition
			v.x = clon * v.tx + slatslon * v.ty - clatslon * v.tz;
			v.y = clat * v.ty + slat * v.tz;
			v.z = slon * v.tx - slatclon * v.ty + clatclon * v.tz;
		}
	}
}