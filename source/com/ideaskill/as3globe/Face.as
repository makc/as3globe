package com.ideaskill.as3globe {
	import flash.geom.Point;

	/**
	* Face.
	*/
	internal class Face {
		internal var vx0:Vertex;
		internal var vx1:Vertex;
		internal var vx2:Vertex;
		internal var uv0:Point;
		internal var uv1:Point;
		internal var uv2:Point;

		internal function compute (w:Number, h:Number):void {
			// stuff for texture mapping
			u0 = uv0.x * w; v0 = uv0.y * h;
			u1 = uv1.x * w; v1 = uv1.y * h;
			u2 = uv2.x * w; v2 = uv2.y * h;
			v1_v2 = v1 - v2; v2_v0 = v2 - v0; v0_v1 = v0 - v1;
			den = 1.0 / (v1_v2 * u0 + v2_v0 * u1 + v0_v1 * u2);
			v1_v2d = v1_v2 * den;
			v2_v0d = v2_v0 * den;
			v0_v1d = v0_v1 * den;
			u1_u0d = (u1 - u0) * den;
			u0_u2d = (u0 - u2) * den;
			u2_u1d = (u2 - u1) * den;
			u1v2_u2v1d = (u1 * v2 - u2 * v1) * den;
			u2v0_u0v2d = (u2 * v0 - u0 * v2) * den;
			u0v1_u1v0d = (u0 * v1 - u1 * v0) * den;
		}

		// fast texture mapping variables
		internal var u0:Number;
		internal var v0:Number;
		internal var u1:Number;
		internal var v1:Number;
		internal var u2:Number;
		internal var v2:Number;
		internal var v1_v2:Number;
		internal var v2_v0:Number;
		internal var v0_v1:Number;
		internal var den:Number;
		internal var v1_v2d:Number;
		internal var v2_v0d:Number;
		internal var v0_v1d:Number;
		internal var u1_u0d:Number;
		internal var u0_u2d:Number;
		internal var u2_u1d:Number;
		internal var u1v2_u2v1d:Number;
		internal var u2v0_u0v2d:Number;
		internal var u0v1_u1v0d:Number;
	}
}