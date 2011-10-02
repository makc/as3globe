package com.ideaskill.as3globe.map 
{
	import com.ideaskill.as3globe.Location;
	import flash.geom.Point;

	/**
	 * Plate carré projection.
	 * @see http://en.wikipedia.org/wiki/Equirectangular_projection
	 */
	public class EquirectangularProjection implements IProjection
	{
		/**
		 * Latitude limit, in degrees.
		 * This projection has no latitude limit.
		 */
		public function get latitudeLimit ():Number { return 90; }

		/**
		 * @inheritDoc
		 */
		public function project (location:Location):Point {
			return new Point (0.5 + location.longitude / 360.0, 0.5 - location.latitude / 180.0);
		}
	}
}