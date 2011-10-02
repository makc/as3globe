package com.ideaskill.as3globe {
	import flash.display.DisplayObject;

	/**
	 * Basic custom marker interface.
	 */
	public interface IMarker {
		function getLocation():Location;
		function getObject():DisplayObject;
	}
}