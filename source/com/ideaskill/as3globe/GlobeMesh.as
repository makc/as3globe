package com.ideaskill.as3globe {
	import com.ideaskill.as3globe.map.IProjection;
	import flash.geom.Point;
	
	/**
	* Globe mesh.
	*/
	internal class GlobeMesh {

		/**
		 * Squared accuracy of floating point match.
		 */
		internal static const SQ_ACCURACY:Number = 1e-9;

		/**
		 * Mesh constructor.
		 * @param	N The number of triangles along globe equator.
		 * @throws	RangeError N must not be too small.
		 */
		public function GlobeMesh (N:int, map:IProjection) {
			verticesMap = []; uvsMap = [];

			// a number of rows in one hemisphere
			var m:Number = N * map.latitudeLimit / (180 * Math.sqrt (3));
			if (m < 1) throw new RangeError ("N is too small for this map" +
				((N > 3) ? "" : " (try N > 3)"));
			var M:int = int(m) + 1;

			// compute vertical compression coefficient k:
			// 1 + k + k^2 + ... + k^int(m) = m
			var k:Number, sum:Number, ka:Number = 0.1, kb:Number = 1.1,
				err:Number = Math.sqrt (SQ_ACCURACY);
			while (kb - ka > err) {
				k = 0.3 * ka + 0.7 * kb;
				sum = 1; for (var p:int = 1; p < M; p++) sum += Math.pow (k, p);
				if (sum > m) kb = k; else ka = k;				
			}

			// create mesh
			faces = []; vertices = []; uvs = [];

			var lat_base:Number = 0;
			var lat_step:Number = 180 * Math.sqrt (3) / N;

			for (var i:int = 0; i < M; i++) {

				var dj:Number = (i % 2) * 0.5;

				for (var j:int = 0; j < N; j++) {

					// create vertices
					var locA:Location = (j > 0) ? locD : new Location (
						lat_base,
						360 * (j + dj) / N - 180);

					var locB:Location = (j > 0) ? locC : new Location (
						(i < M - 1) ? (lat_base + lat_step) : map.latitudeLimit,
						360 * (j + dj + 0.5) / N - 180);

					var locC:Location = new Location (
						(i < M - 1) ? (lat_base + lat_step) : map.latitudeLimit,
						360 * (j + dj + 1.5) / N - 180);

					var locD:Location = new Location (
						lat_base,
						360 * (j + dj + 1) / N - 180);

					var locE:Location = (j > 0) ? locH : new Location (
						-lat_base,
						360 * (j + dj) / N - 180);

					var locF:Location = (j > 0) ? locG : new Location (
						(i < M - 1) ? -(lat_base + lat_step) : -map.latitudeLimit,
						360 * (j + dj + 0.5) / N - 180);

					var locG:Location = new Location (
						(i < M - 1) ? -(lat_base + lat_step) : -map.latitudeLimit,
						360 * (j + dj + 1.5) / N - 180);

					var locH:Location = new Location (
						-lat_base,
						360 * (j + dj + 1) / N - 180);


					var vA:Vertex = (j > 0) ? vD : getVertex (locA);
					var uvA:Point = (j > 0) ? uvD : getUV (locA, map);

					var vB:Vertex = (j > 0) ? ((vC != null) ? vC : vB) : getVertex (locB, false);
					var uvB:Point = ((j > 0) && (uvC != null)) ? uvC : getUV (locB, map, false);

					var vC:Vertex = null;
					var uvC:Point = null;

					var vD:Vertex = getVertex (locD);
					var uvD:Point = getUV (locD, map);

					var vE:Vertex = (j > 0) ? vH : getVertex (locE);
					var uvE:Point = (j > 0) ? uvH : getUV (locE, map);

					var vF:Vertex = (j > 0) ? ((vG != null) ? vG : vF) : getVertex (locF, false);
					var uvF:Point = ((j > 0) && (uvG != null)) ? uvG : getUV (locF, map, false);

					var vG:Vertex = null;
					var uvG:Point = null;

					var vH:Vertex = getVertex (locH);
					var uvH:Point = getUV (locH, map);

					// create /\ faces
					var fABD:Face = new Face;
					fABD.vx0 = vA; fABD.uv0 = uvA;
					fABD.vx1 = vB; fABD.uv1 = uvB;
					fABD.vx2 = vD; fABD.uv2 = uvD;
					faces.push (fABD);

					var fFEH:Face = new Face;
					fFEH.vx0 = vF; fFEH.uv0 = uvF;
					fFEH.vx1 = vE; fFEH.uv1 = uvE;
					fFEH.vx2 = vH; fFEH.uv2 = uvH;
					faces.push (fFEH);

					// create \/ faces (these need C and G vertices)
					if ((i < M - 1) || (map.latitudeLimit < 90)) {
						vC = getVertex (locC);
						uvC = getUV (locC, map, false);

						vG = getVertex (locG);
						uvG = getUV (locG, map, false);

						var fDBC:Face = new Face;
						fDBC.vx0 = vD; fDBC.uv0 = uvD;
						fDBC.vx1 = vB; fDBC.uv1 = uvB;
						fDBC.vx2 = vC; fDBC.uv2 = uvC;
						faces.push (fDBC);

						var fFHG:Face = new Face;
						fFHG.vx0 = vF; fFHG.uv0 = uvF;
						fFHG.vx1 = vH; fFHG.uv1 = uvH;
						fFHG.vx2 = vG; fFHG.uv2 = uvG;
						faces.push (fFHG);
					}
				}

				lat_base += lat_step;
				lat_step *= k;
			}

			verticesMap = null; uvsMap = null;

			//trace (vertices.length, 0.6 * N * N);
		}

		internal var faces:Array, vertices:Array, uvs:Array;

		internal var verticesMap:Array, uvsMap:Array;
		internal function getLocationHash (loc:Location):int {
			var cos:Number = 1 - loc.latitude * loc.latitude / 8100;
			return (loc.longitude * cos + 36 * (loc.latitude + 90)) / 10;
		}

		internal function getVertex (loc:Location, search:Boolean = true):Vertex {
			var v:Vertex, w:Vertex = new Vertex; w.location = loc;
			// find existing vertex
			var hash:int = getLocationHash (loc);
			var vmap:Array = verticesMap [hash];
			if (vmap) {
				if (search)
				for each (v in vmap) {
					if ((v.x - w.x) * (v.x - w.x) + (v.y - w.y) * (v.y - w.y) + (v.z - w.z) * (v.z - w.z) < SQ_ACCURACY) {
						return v;
					}
				}
			} else {
				verticesMap [hash] = vmap = [];
			}
			// none found
			vertices.push (w); vmap.push (w); return w;
		}

		internal function getUV (loc:Location, map:IProjection, search:Boolean = true):Point {
			var p:Point, proj:Point = map.project (loc);
			// find existing uv
			var hash:int = getLocationHash (loc);
			var umap:Array = uvsMap [hash];
			if (umap) {
				if (search)
				for each (p in umap) {
					if ((p.x - proj.x) * (p.x - proj.x) + (p.y - proj.y) * (p.y - proj.y) < SQ_ACCURACY) {
						return p;
					}
				}
			} else {
				uvsMap [hash] = umap = [];
			}
			// none found
			uvs.push (proj); umap.push (proj); return proj;
		}

		internal function release ():void {
			// release stuff
			faces.length = 0; faces = null;
			vertices.length = 0; vertices = null;
			uvs.length = 0; uvs = null;
		}

		internal function toString ():String {
			var n:int = 6;
			var ase:String =
				"*3DSMAX_ASCIIEXPORT 200\n" +
				"*COMMENT \"Created with as3globe ver " + Globe.VERSION + "\"\n" +
				"*GEOMOBJECT {\n" +
				"\t*NODE_NAME \"globe\"\n" +
				"\t*NODE_TM {\n" +
				"\t\t*NODE_NAME \"globe\"\n" +
				"\t\t*INHERIT_POS 0 0 0\n" +
				"\t\t*INHERIT_ROT 0 0 0\n" +
				"\t\t*INHERIT_SCL 0 0 0\n" +
				"\t\t*TM_ROW0 1.0000 0.0000 0.0000\n" +
				"\t\t*TM_ROW1 0.0000 1.0000 0.0000\n" +
				"\t\t*TM_ROW2 0.0000 0.0000 1.0000\n" +
				"\t\t*TM_ROW3 0.0000 0.0000 0.0000\n" +
				"\t\t*TM_POS 0.0000 0.0000 0.0000\n" +
				"\t\t*TM_ROTAXIS 0.0000 0.0000 0.0000\n" +
				"\t\t*TM_ROTANGLE 0.0000\n" +
				"\t\t*TM_SCALE 1.0000 1.0000 1.0000\n" +
				"\t\t*TM_SCALEAXIS 0.0000 0.0000 0.0000\n" +
				"\t\t*TM_SCALEAXISANG 0.0000\n" +
				"\t}\n" +
				"\t*MESH {\n" +
				"\t\t*TIMEVALUE 0\n" +
				"\t\t*MESH_NUMVERTEX " + vertices.length + "\n" +
				"\t\t*MESH_NUMFACES " + faces.length + "\n" +
				"\t\t*MESH_VERTEX_LIST {\n";

			var i:int;
			for (i = 0; i < vertices.length; i++) {
				var v:Vertex = Vertex (vertices [i]);
				ase += "\t\t\t*MESH_VERTEX " + i + " " + v.x.toFixed (n) + " " + v.y.toFixed (n) + " " + v.z.toFixed (n) + "\n";
			}

			ase +=
				"\t\t}\n" +
				"\t\t*MESH_FACE_LIST {\n";

			var f:Face;
			for (i = 0; i < faces.length; i++) {
				f = Face (faces [i]);
				ase += "\t\t\t*MESH_FACE " + i + ": A: " +
					vertices.indexOf (f.vx0) + " B: " +
					vertices.indexOf (f.vx1) + " C: " +
					vertices.indexOf (f.vx2) + " AB: 1 BC: 1 CA: 1 *MESH_SMOOTHING 1 *MESH_MTLID 0\n";
			}

			ase +=
				"\t\t}\n" +
				"\t\t*MESH_NUMTVERTEX " + uvs.length + "\n" +
				"\t\t*MESH_TVERTLIST {\n";

			for (i = 0; i < uvs.length; i++) {
				var p:Point = Point (uvs [i]);
				ase += "\t\t\t*MESH_TVERT " + i + " " + p.x.toFixed (n) + " " + p.y.toFixed (n) + " 0.0\n";
			}

			ase +=
				"\t\t}\n" +
				"\t\t*MESH_NUMTVFACES " + faces.length + "\n" +
				"\t\t*MESH_TFACELIST {\n";

			for (i = 0; i < faces.length; i++) {
				f = Face (faces [i]);
				ase += "\t\t\t*MESH_TFACE " + i + " " +
					uvs.indexOf (f.uv0) + " " + uvs.indexOf (f.uv1) + " " + uvs.indexOf (f.uv2) + "\n";
			}

			ase +=
				"\t\t}\n" +
				"\t}\n" +
				"\}\n";

			return ase;
		}
	}
}