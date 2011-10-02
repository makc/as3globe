package com.ideaskill.as3globe 
{
	/**
	* Location object represents geographic location.
	*/
	public class Location
	{
		/**
		* Latitude, in degrees.
		* @see http://en.wikipedia.org/wiki/Latitude#Geocentric_latitude
		*/
		public var latitude:Number;

		/**
		* Longitude, in degrees.
		* @see http://en.wikipedia.org/wiki/Longitude
		*/
		public var longitude:Number;

		/**
		* Altitude, in meters.
		*/
		public var altitude:Number;


		/**
		 * Constructor; allows you to set all the properties in one call.
		 */
		public function Location (lat:Number = 0, lon:Number = 0, alt:Number = 0) {
			latitude = lat; longitude = lon; altitude = alt;
		}


		/**
		* Mean radius of Earth, in meters. Altitudes are based on this value.
		* @see http://en.wikipedia.org/wiki/Earth_radius#Mean_radii
		*/
		public static const R:Number = 6.37101e6;
	}
}