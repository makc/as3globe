package com.ideaskill.as3globe.map 
{
	import com.ideaskill.as3globe.Location;
	import flash.geom.Point;

	/**
	* Transformation model of projection.
	*/
	public interface IProjection 
	{
		/**
		 * Latitude limit, in degrees.
		 * Some projections map poles to infinity; for these projections,
		 * latitudeLimit should return positive number less than 90 degrees.
		 */
		function get latitudeLimit ():Number;

		/**
		 * Function that maps geographic location into texture UV space.
		 * @param location Geographic location.
		 * @return Point with U coordinate in x and V in y.
		 */
		function project (location:Location):Point;
	}
}