package com.ideaskill.as3globe.map 
{
	import com.ideaskill.as3globe.Location;
	import flash.geom.Point;

	/**
	 * Mercator projection.
	 * @see http://en.wikipedia.org/wiki/Mercator_projection
	 */
	public class MercatorProjection implements IProjection
	{
		private var _latitudeLimit:Number = 85.05113;
		/**
		 * Latitude limit, in degrees.
		 * @default 85.05113 degrees (Google, Microsoft and Yahoo maps use this limit)
		 * @see http://en.wikipedia.org/wiki/Mercator_projection#Uses
		 */
		public function get latitudeLimit ():Number { return _latitudeLimit; }
		public function set latitudeLimit (v:Number):void { if (v > 0) _latitudeLimit = v; }

		/**
		 * @inheritDoc
		 */
		public function project (location:Location):Point {
			var phi:Number = -location.latitude * 0.01745329252; // = pi / 180
			var y10:Number = Math.log (Math.tan (phi) + 1 / Math.cos (phi));

			phi = _latitudeLimit * 0.01745329252;
			var y10Limit:Number = Math.log (Math.tan (phi) + 1 / Math.cos (phi));

			return new Point (0.5 + location.longitude / 360.0, 0.5 * (1 + y10 / y10Limit));
		}
	}
}