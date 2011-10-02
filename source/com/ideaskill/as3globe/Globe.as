package com.ideaskill.as3globe {
	import com.ideaskill.as3globe.map.EquirectangularProjection;
	import com.ideaskill.as3globe.map.IProjection;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * Globe component class.
	 */
	public class Globe extends Sprite {

		// vars in order of creation ----------------------------------------------------
		private var _smooth:Boolean;
		private var _quality:uint;
		private var _projection:IProjection;
		private var _mesh:GlobeMesh;
		private var _texture:BitmapData;
		private var _textureReference:*;
		private var _textureIsManaged:Boolean;
		private var _p:Number;
		private var _pRoot:Number;
		private var _R:Number;
		private var _pR:Number;
		private var _gimbal:Gimbal;
		private var _surface:Sprite;
		private var _renderMatrix:Matrix;
		private var _children:Array;
		private var _childrenDepth:Array;


		// properties -------------------------------------------------------------------

		/**
		 * Nearest-neighbor or bilinear texture sampling.
		 * @default true
		 */
		public function get smoothTexture ():Boolean { return _smooth; }
		public function set smoothTexture (v:Boolean):void {
			_smooth = v; render ();
		}


		/**
		 * Quality of mesh. This is the number of triangles along the equator.
		 * Approximate corresponding number of visible triangles, or total number
		 * of mesh vertices, is ~0.6·quality².
		 * @default 30
		 */
		[Inspectable (name="Quality", type="Number", defaultValue="30")]
		public function get quality ():uint { return _quality; }
		public function set quality (v:uint):void {
			_quality = Math.max (v, 7); rebuildMesh ();
		}


		/**
		 * Map projection. This could be either one of packaged projections,
		 * or your custom projection class. Globe mesh is optimized for Plate
		 * carré projection (default).
		 * @see com.ideaskill.as3globe.map.EquirectangularProjection
		 * @see com.ideaskill.as3globe.map.MercatorProjection
		 */
		public function get projection ():IProjection { return _projection; }
		public function set projection (v:IProjection):void {
			_projection = v; rebuildMesh ();
		}


		/**
		 * Map texture. You can set texture to IBitmapDrawable or
		 * linkage class name of IBitmapDrawable, however, unless
		 * you set texture to BitmapData, internal managed BitmapData
		 * instance is created and used as a texture instead.
		 * @see flash.display.IBitmapDrawable
		 */
		[Inspectable (name="Texture", type="String", defaultValue="")]
		public function get texture ():* { return _textureReference; }
		public function set texture (v:*):void {
			if (v != null) {
				if (v is String) {
					// try to interpret this as a class name
					try {
						var Asset:Class = getDefinitionByName (String (v)) as Class;
						var asset:IBitmapDrawable = (new Asset) as IBitmapDrawable;
						if (asset == null) {
							// not IBitmapDrawable - create default texture, if none present
							if (_texture == null) {
								_texture = makeDefaultTexture ();
								_textureReference = v;
								_textureIsManaged = true; updateMesh (); render ();
							}
						} else {
							if (asset is BitmapData) {
								// use asset as managed texture
								releaseTexture ();
								_texture = BitmapData (asset);
								_textureReference = v;
								_textureIsManaged = true; updateMesh (); render ();
							} else {
								// this is DisplayObject - make managed texture from it
								releaseTexture ();
								_texture = makeTextureFromDisplayObject (DisplayObject (asset));
								_textureReference = v;
								_textureIsManaged = true; updateMesh (); render ();
							}
						}
					} catch (e:ReferenceError) {
						// incomprehensible string - create default texture, if none present
						if (_texture == null) {
							_texture = makeDefaultTexture ();
							_textureReference = v;
							_textureIsManaged = true; updateMesh (); render ();
						}
					}
				} else if (v is IBitmapDrawable) {
					if (v is BitmapData) {
						// the only case when texture is NOT managed
						releaseTexture ();
						_texture = BitmapData (v);
						_textureReference = v;
						_textureIsManaged = false; updateMesh (); render ();
					} else {
						// this is DisplayObject - make managed texture from it
						releaseTexture ();
						_texture = makeTextureFromDisplayObject (DisplayObject (v));
						_textureReference = v;
						_textureIsManaged = true; updateMesh (); render ();
					}
				}
			}
		}


		/**
		 * Perspective. Valid values start at zero (orthographic projection),
		 * with positive values adding perspective distortion.
		 * @default 0.5
		 */
		[Inspectable (name="Perspective", type="Number", defaultValue="0.5")]
		public function get perspective ():Number { return 1e2 * (1 -_p) / _p; }
		public function set perspective (v:Number):void {
			if (!(v < 0)) {
				_p = 1e2 / (1e2 + v); _pRoot = Math.sqrt (1 - _p * _p); _pR = _p * _R; render ();
			}
		}


		/**
		 * Globe radius, in pixels.
		 * @default 100
		 */
		[Inspectable (name="Radius", type="Number", defaultValue="100")]
		public function get radius ():Number { return _R; }
		public function set radius (v:Number):void {
			if (v > 0) {
				_R = v; _pR = _p * _R; render ();
			}
		}

		// constructor (defaults) -------------------------------------------------------


		/**
		 * Constructor.
		 */
		public function Globe () {
			// set default state through properties
			smoothTexture = true;
			quality = 30;
			projection = new EquirectangularProjection;
			texture = "";
			perspective = 0.5;
			radius = 100;

			// set other important privates
			_gimbal = new Gimbal;
			_gimbal.location = new Location (50.45, 30.52);

			_surface = new Sprite; addChild (_surface);
			_renderMatrix = new Matrix;

			_children = [ { /* reserved for _surface */ } ];
			_childrenDepth = [ 1.0 ];

			// render
			render ();
		}


		/**
		 * Version string.
		 * Version string format is major version dot minor version dot bugfix release number.
		 */
		public static const VERSION:String = "1.01.00";


		// privates ---------------------------------------------------------------------


		private function get isLivePreview ():Boolean {
			return (parent != null) && (getQualifiedClassName (parent) == "fl.livepreview::LivePreviewParent");
		}

		/**
		 * @private for live preview only (doesn't work so far)
		 */
		public function setSize (w:Number, h:Number):void {
			if (isLivePreview) {
				radius = Math.max (0, Math.min (w, h) * 0.5);
			}
		}

		private function makeDefaultTexture ():BitmapData {
			var bd:BitmapData = new BitmapData (64, 32, false, 0xC0C0C0);
			var rle:Array = [
				  85,  7,  147, 10,  162,  2,  176,  4,  196,  1,  198,  1,  200,  6,  207,  5,  214,  6,  228,  2,
				 233,  1,  236, 17,  254,  3,  259, 14,  275,  1,  279,  2,  290, 30,  324,  1,  327,  8,  338,  2,
				 353,  2,  356, 23,  380,  1,  393, 13,  414,  2,  417, 24,  444,  1,  458, 11,  479, 27,  522, 10,
				 543,  2,  546,  3,  551,  1,  554, 14,  586,  9,  607,  1,  613,  4,  618, 13,  632,  1,  652,  6,
				 670,  5,  676,  1,  678, 15,  716,  3,  733, 12,  748,  9,  781,  3,  797, 13,  813,  2,  817,  3,
				 846,  3,  861, 11,  877,  2,  881,  2,  885,  1,  913,  4,  926, 11,  949,  1,  978,  5,  994,  6,
				1010,  1, 1012,  1, 1041,  7, 1058,  5,	1074,  4, 1079,  2, 1106,  8, 1122,  5, 1145,  1, 1170,  7,
				1186,  5, 1207,  1, 1235,  6, 1250,  4,	1256,  1, 1269,  5, 1300,  4, 1315,  3, 1332,  7, 1364,  3,
				1379,  2, 1396,  7, 1427,  3, 1465,  2,	1491,  2, 1555,  1, 1619,  1, 1812,  1, 1825, 11, 1837, 16,
				1863, 13, 1884, 33, 1924, 15, 1944, 38,	1984, 64
			];
			for (var i:int = 0; i < rle.length; i += 2)
				for (var j:int = 0; j < rle [i + 1]; j++)
					bd.setPixel ((rle [i] + j) % 64, (rle [i] + j) / 64, 0x404040);
			return bd;
		}

		private function makeTextureFromDisplayObject (dobj:DisplayObject):BitmapData {
			var rect:Rectangle = dobj.getBounds (dobj);
			var bd:BitmapData = new BitmapData (Math.ceil (rect.width), Math.ceil (rect.height), true, 0);
			bd.draw (dobj, new Matrix (1, 0, 0, 1, -Math.floor (rect.x), -Math.floor (rect.y)), null, null, null, true);
			return bd;
		}

		private function rebuildMesh ():void {
			if ((_quality > 0) && (_projection != null)) {
				// ok to rebuild
				if (_mesh != null)
					_mesh.release ();
				_mesh = new GlobeMesh (_quality, _projection); updateMesh (); render ();
			}
		}

		private function updateMesh ():void {
			if ((_mesh != null) && (_texture != null)) {
				// ok to update
				var w:int = _texture.width
				var h:int = _texture.height;
				for each (var f:Face in _mesh.faces) f.compute (w, h);
			}
		}

		private function releaseTexture ():void {
			if ((_texture != null) && _textureIsManaged) {
				_texture.dispose (); _texture = null;
			}
		}

		private function projectVertex (v:Vertex):void {
			var zoom:Number = _pR / (1 + v.tz * _pRoot);
			v.sx = v.tx * zoom;
			v.sy = v.ty * zoom;
		}

		private function sortChildren ():Number {
			var i:int, j:int;
			var o:DisplayObject;
			var v:Vertex = new Vertex;
			var zc:Number = 1 / Math.max (_pRoot, 1e-3); // camera at 0, 0, -zc
			var d1:Number = (zc * zc - 1) / zc; // camera-to-surface-edge distance along z, d1:d0 = d0:zc, d0^2 + 1^2 = zc^2

			for (i = 1; i < _children.length; i++) {
				var marker:IMarker = _children [i];
				v.location = marker.getLocation ();

				// normalized distance to camera
				// < 1 is in front of globe, > 1 is behind
				_gimbal.transform (v);
				_childrenDepth [i] = (zc + v.tz) / d1;

				// btw, place in 2D
				projectVertex (v);
				o = marker.getObject (); o.x = v.sx; o.y = v.sy;
			}

			// sort markers and surface
			var indices:Array = _childrenDepth.sort (Array.NUMERIC | Array.DESCENDING | Array.RETURNINDEXEDARRAY);

			// sort display list
			for (i = 0; i < _children.length; i++) {
				// new pos: i, old pos: indices [i]
				j = indices [i];
				o = (j > 0) ? IMarker (_children [j]).getObject () : _surface;
				setChildIndex (o, i);
			}

			indices.length = 0;
			indices = null;

			// tz of edge
			return d1 - zc;
		}

		// various public methods -------------------------------------------------------

		/**
		 * Adds custom marker.
		 */
		public function addMarker (marker:IMarker):void {
			addChild (marker.getObject ());

			_children.push (marker); _childrenDepth.push (0);

			sortChildren ();
		}

		/**
		 * Removes custom marker.
		 */
		public function removeMarker (marker:IMarker):void {
			var o:DisplayObject = marker.getObject ();
			if (o.parent == this) {
				removeChild (o);
			}

			var i:int = _children.indexOf (marker);
			if (i > -1) {
				_children.splice (i, 1); _childrenDepth.splice (i, 1);
			}
		}

		/**
		 * Calculates screen coordinates of location.
		 */
		public function loc2xy (loc:Location):Point {
			var v:Vertex = new Vertex; v.location = loc;
			_gimbal.transform (v); projectVertex (v);
			return new Point (v.sx, v.sy);
		}

		/**
		 * Calculates closest location from screen coordinates.
		 */
		public function xy2loc (p:Point, altitude:Number = 0):Location {
			var t:Number;
			var v:Vertex = new Vertex;
			// ray elements
			var _pRootPositive:Number = Math.max (_pRoot, 1e-3);
			var zf:Number = (_pR - 1) / _pRootPositive; // p.x, p.y, zf
			var zc:Number = - 1 / _pRootPositive; // 0, 0, zc
			// normalized ray direction vector
			var dd:Number = Math.sqrt (p.x * p.x + p.y * p.y + (zf - zc) * (zf - zc));
			var dx:Number = p.x / dd;
			var dy:Number = p.y / dd;
			var dz:Number = (zf - zc) / dd;
			// intersect with required sphere at the origin
			var r2:Number = 1 + altitude / Location.R; r2 *= r2;
			// http://devmaster.net/wiki/Ray-sphere_intersection
			var B:Number = dz * zc;
			var C:Number = zc * zc - r2;
			var D:Number = B * B - C;
			if (D < 0) {
				// find tangent sphere
				// http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
				t = -B;
			} else {
				// ray hits required sphere
				t = -B -Math.sqrt (D);
			}

			v.tx = dx * t;
			v.ty = dy * t;
			v.tz = dz * t + zc;

			_gimbal.invTransform (v);
			return v.location;
		}

		/**
		 * Makes specified location to face the camera.
		 * @param	loc	Location to look at.
		 * @param	p Desired screen coordinates of specified location.
		 * If you specify this constraint, be aware that it will not
		 * always be possible to satisfy it (locations near poles have
		 * less freedom than locations near equator).
		 */
		public function lookAt (loc:Location, p:Point = null):void {
			_gimbal.location = loc;
			if (p != null) {

				// TODO better algo!!
				var candidates:Array = [
					_gimbal.location,
					new Location (-60, -120), new Location (-60,   0), new Location (-60, +120),
					new Location (  0,  -60), new Location (  0, 180), new Location (  0,  +60),
					new Location (+60, -120), new Location (+60,   0), new Location (+60, +120)
				];

				var best_err:Number = Number.MAX_VALUE, best_i:int = 0;
				for (var i:int = 0; i < candidates.length; i++) {

					// for each candidate, perform 9 steps of simple IK
					var k:Number = 1;
					var center:Location = candidates [i];
					for (var n:int = 0; n < 9; n++, k *= 0.9) {
						var real:Location = xy2loc (p);
						center.latitude += k * (0.1 * (int (10 * (loc.latitude - real.latitude)) % 3600));
						center.longitude += k * (0.1 * (int (10 * (loc.longitude - real.longitude)) % 3600));
						_gimbal.location = center;
					}

					// estimate error
					var locAt:Point = loc2xy (loc);
					var err:Number = Point.distance (locAt, p);
					if (best_err > err) {
						best_err = err; best_i = i;
					}
				}

				_gimbal.location = candidates [best_i];
			}
			render ();
		}

		/**
		 * Exports globe mesh in ASE format.
		 * @see http://www.solosnake.com/main/ase.htm
		 */
		public function getMeshASE ():String { return _mesh.toString (); }

		/**
		 * Returns surface sprite. Use to wire mouse events handlers or apply special effects.
		 */
		public function getSurface ():Sprite { return _surface; }

		/**
		 * Renders the globe. Use to enforce rendering, for example with animated textures.
		 */
		public function render ():void {
			// can render?
			if (_renderMatrix != null) {

				// smoothing threshold heuristic
				var z3:Number = sortChildren () - 0.6 - 1.46 * _pRoot;

				// process mesh vertices
				var v:Vertex;
				for each (v in _mesh.vertices) {
					_gimbal.transform (v); projectVertex (v);
				}

				// draw mesh faces
				var f:Face, w:Number;
				var x0:Number, y0:Number, x1:Number, y1:Number, x2:Number, y2:Number, avgz:Number;
				var g:Graphics = _surface.graphics; g.clear ();// g.lineStyle (0, 0x7FFF);
				for each (f in _mesh.faces) {
					avgz = 0;
					x0 = (v = f.vx0).sx; y0 = v.sy; avgz += v.tz;
					x1 = (v = f.vx1).sx; y1 = v.sy; avgz += v.tz;
					x2 = (v = f.vx2).sx; y2 = v.sy; avgz += v.tz;
					// calculate face winding
					w = x0 * y1 - x1 * y0 +
						x1 * y2 - x2 * y1 +
						x2 * y0 - x0 * y2;
					if (w > 0) {
						// safe to render the face
						_renderMatrix.a = f.v0_v1d * x2 + f.v2_v0d * x1 + f.v1_v2d * x0;
						_renderMatrix.b = f.v0_v1d * y2 + f.v2_v0d * y1 + f.v1_v2d * y0;
						_renderMatrix.c = f.u1_u0d * x2 + f.u0_u2d * x1 + f.u2_u1d * x0;
						_renderMatrix.d = f.u1_u0d * y2 + f.u0_u2d * y1 + f.u2_u1d * y0;
						_renderMatrix.tx = f.u1v2_u2v1d * x0 + f.u2v0_u0v2d * x1 + f.u0v1_u1v0d * x2;
						_renderMatrix.ty = f.u1v2_u2v1d * y0 + f.u2v0_u0v2d * y1 + f.u0v1_u1v0d * y2;
						g.beginBitmapFill (_texture, _renderMatrix, true, _smooth && (avgz < z3));
						g.moveTo (x0, y0); g.lineTo (x1, y1); g.lineTo (x2, y2);
						g.endFill ();
					}
				}
			}
		}
	}
}