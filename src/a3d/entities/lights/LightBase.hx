package a3d.entities.lights;

import a3d.core.base.IRenderable;
import a3d.core.partition.EntityNode;
import a3d.core.partition.LightNode;
import a3d.entities.Entity;
import a3d.errors.AbstractMethodError;
import a3d.events.LightEvent;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.shadowmaps.ShadowMapperBase;

import flash.geom.Matrix3D;



/**
 * LightBase provides an abstract base class for subtypes representing lights.
 */
class LightBase extends Entity
{
	private var _color:UInt = 0xffffff;
	private var _colorR:Float = 1;
	private var _colorG:Float = 1;
	private var _colorB:Float = 1;

	private var _ambientColor:UInt = 0xffffff;
	private var _ambient:Float = 0;
	public var ambientR:Float = 0;
	public var ambientG:Float = 0;
	public var ambientB:Float = 0;

	private var _specular:Float = 1;
	public var specularR:Float = 1;
	public var specularG:Float = 1;
	public var specularB:Float = 1;

	private var _diffuse:Float = 1;
	public var diffuseR:Float = 1;
	public var diffuseG:Float = 1;
	public var diffuseB:Float = 1;

	private var _castsShadows:Bool;

	private var _shadowMapper:ShadowMapperBase;


	/**
	 * Create a new LightBase object.
	 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
	 */
	public function new()
	{
		super();
	}

	private inline function get_castsShadows():Bool
	{
		return _castsShadows;
	}

	private inline function set_castsShadows(value:Bool):Void
	{
		if (_castsShadows == value)
			return;

		_castsShadows = value;

		if (value)
		{
			if (_shadowMapper == null)
				_shadowMapper = createShadowMapper();
			_shadowMapper.light = this;
		}
		else
		{
			_shadowMapper.dispose();
			_shadowMapper = null;
		}

		dispatchEvent(new LightEvent(LightEvent.CASTS_SHADOW_CHANGE));
	}

	private function createShadowMapper():ShadowMapperBase
	{
		throw new AbstractMethodError();
	}

	/**
	 * The specular emission strength of the light. Default value is <code>1</code>.
	 */
	private inline function get_specular():Float
	{
		return _specular;
	}


	private inline function set_specular(value:Float):Void
	{
		if (value < 0)
			value = 0;
		_specular = value;
		updateSpecular();
	}

	/**
	 * The diffuse emission strength of the light. Default value is <code>1</code>.
	 */
	private inline function get_diffuse():Float
	{
		return _diffuse;
	}

	private inline function set_diffuse(value:Float):Void
	{
		if (value < 0)
			value = 0;
		//else if (value > 1) value = 1;
		_diffuse = value;
		updateDiffuse();
	}

	/**
	 * The color of the light. Default value is <code>0xffffff</code>.
	 */
	private inline function get_color():UInt
	{
		return _color;
	}

	private inline function set_color(value:UInt):Void
	{
		_color = value;
		_colorR = ((_color >> 16) & 0xff) / 0xff;
		_colorG = ((_color >> 8) & 0xff) / 0xff;
		_colorB = (_color & 0xff) / 0xff;
		updateDiffuse();
		updateSpecular();
	}

	/**
	 * The ambient emission strength of the light. Default value is <code>0</code>.
	 */
	private inline function get_ambient():Float
	{
		return _ambient;
	}

	private inline function set_ambient(value:Float):Void
	{
		if (value < 0)
			value = 0;
		else if (value > 1)
			value = 1;
		_ambient = value;
		updateAmbient();
	}

	private inline function get_ambientColor():UInt
	{
		return _ambientColor;
	}

	/**
	 * The ambient emission colour of the light. Default value is <code>0xffffff</code>.
	 */
	private inline function set_ambientColor(value:UInt):Void
	{
		_ambientColor = value;
		updateAmbient();
	}

	private function updateAmbient():Void
	{
		ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient;
		ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient;
		ambientB = (_ambientColor & 0xff) / 0xff * _ambient;
	}

	/**
	 * Gets the optimal projection matrix to render a light-based depth map for a single object.
	 * @param renderable The IRenderable object to render to a depth map.
	 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
	 * @return A Matrix3D object containing the projection transformation.
	 */
	public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D
	{
		throw new AbstractMethodError();
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new LightNode(this);
	}

	/**
	 * @inheritDoc
	 */
	override private function get_assetType():String
	{
		return AssetType.LIGHT;
	}


	/**
	 * Updates the total specular components of the light.
	 */
	private function updateSpecular():Void
	{
		specularR = _colorR * _specular;
		specularG = _colorG * _specular;
		specularB = _colorB * _specular;
	}

	/**
	 * Updates the total diffuse components of the light.
	 */
	private function updateDiffuse():Void
	{
		diffuseR = _colorR * _diffuse;
		diffuseG = _colorG * _diffuse;
		diffuseB = _colorB * _diffuse;
	}

	private inline function get_shadowMapper():ShadowMapperBase
	{
		return _shadowMapper;
	}

	private inline function set_shadowMapper(value:ShadowMapperBase):Void
	{
		_shadowMapper = value;
		_shadowMapper.light = this;
	}
}
