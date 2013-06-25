package a3d.materials.methods;


class MethodVO
{
	public var vertexData:Vector<Float>;
	public var fragmentData:Vector<Float>;

	// public register indices
	public var texturesIndex:Int;
	public var secondaryTexturesIndex:Int; // sometimes needed for composites
	public var vertexConstantsIndex:Int;
	public var secondaryVertexConstantsIndex:Int; // sometimes needed for composites
	public var fragmentConstantsIndex:Int;
	public var secondaryFragmentConstantsIndex:Int; // sometimes needed for composites

	public var useMipmapping:Bool;
	public var useSmoothTextures:Bool;
	public var repeatTextures:Bool;

	// internal stuff for the material to know before assembling code
	public var needsProjection:Bool;
	public var needsView:Bool;
	public var needsNormals:Bool;
	public var needsTangents:Bool;
	public var needsUV:Bool;
	public var needsSecondaryUV:Bool;
	public var needsGlobalVertexPos:Bool;
	public var needsGlobalFragmentPos:Bool;

	public var numLights:Int;
	public var useLightFallOff:Bool = true;

	public function new()
	{

	}

	public function reset():Void
	{
		texturesIndex = -1;
		vertexConstantsIndex = -1;
		fragmentConstantsIndex = -1;

		useMipmapping = true;
		useSmoothTextures = true;
		repeatTextures = false;

		needsProjection = false;
		needsView = false;
		needsNormals = false;
		needsTangents = false;
		needsUV = false;
		needsSecondaryUV = false;
		needsGlobalVertexPos = false;
		needsGlobalFragmentPos = false;

		numLights = 0;
		useLightFallOff = true;
	}
}
