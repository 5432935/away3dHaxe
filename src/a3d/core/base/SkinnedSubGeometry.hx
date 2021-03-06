package a3d.core.base;

import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.utils.VertexFormatUtil;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.Vector;
import haxe.ds.IntMap;


/**
 * SkinnedSubGeometry provides a SubGeometry extension that contains data needed to skin vertices. In particular,
 * it provides joint indices and weights.
 * Important! Joint indices need to be pre-multiplied by 3, since they index the matrix array (and each matrix has 3 float4 elements)
 */
class SkinnedSubGeometry extends CompactSubGeometry
{
	/**
	 * If indices have been condensed, this will contain the original index for each condensed index.
	 */
	public var condensedIndexLookUp(get, null):Vector<UInt>;
	/**
	 * The amount of joints used when joint indices have been condensed.
	 */
	public var numCondensedJoints(get, null):Int;
	/**
	 * The animated vertex positions when set explicitly if the skinning transformations couldn't be performed on GPU.
	 */
	public var animatedData(get, null):Vector<Float>;
	/**
	 * The raw joint weights data.
	 */
	public var jointWeightsData(get,null):Vector<Float>;
	/**
	 * The raw joint index data.
	 */
	public var jointIndexData(get, null):Vector<Float>;
	
	private var _bufferFormat:Context3DVertexBufferFormat;
	private var _jointWeightsData:Vector<Float>;
	private var _jointIndexData:Vector<Float>;
	private var _animatedData:Vector<Float>; // used for cpu fallback
	private var _jointWeightsBuffer:Vector<VertexBuffer3D>;
	private var _jointIndexBuffer:Vector<VertexBuffer3D>;
	private var _jointWeightsInvalid:Vector<Bool>;
	private var _jointIndicesInvalid:Vector<Bool>;
	private var _jointWeightContext:Vector<Context3DProxy>;
	private var _jointIndexContext:Vector<Context3DProxy>;
	private var _jointsPerVertex:Int;

	private var _condensedJointIndexData:Vector<Float>;
	private var _condensedIndexLookUp:Vector<UInt>; // used for linking condensed indices to the real ones
	private var _numCondensedJoints:Int;


	/**
	 * Creates a new SkinnedSubGeometry object.
	 * @param jointsPerVertex The amount of joints that can be assigned per vertex.
	 */
	public function new(jointsPerVertex:Int)
	{
		super();
		_jointsPerVertex = jointsPerVertex;
		_bufferFormat = VertexFormatUtil.getVertexBufferFormat(_jointsPerVertex);
		
		_jointWeightsBuffer = new Vector<VertexBuffer3D>(A3d.MAX_NUM_STAGE3D);
		_jointIndexBuffer = new Vector<VertexBuffer3D>(A3d.MAX_NUM_STAGE3D);
		_jointWeightsInvalid = new Vector<Bool>(A3d.MAX_NUM_STAGE3D, true);
		_jointIndicesInvalid = new Vector<Bool>(A3d.MAX_NUM_STAGE3D, true);
		_jointWeightContext = new Vector<Context3DProxy>(A3d.MAX_NUM_STAGE3D);
		_jointIndexContext = new Vector<Context3DProxy>(A3d.MAX_NUM_STAGE3D);
	}

	public function updateAnimatedData(value:Vector<Float>):Void
	{
		_animatedData = value;
		invalidateBuffers(_vertexDataInvalid);
	}

	/**
	 * Assigns the attribute stream for joint weights
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
	public function activateJointWeightsBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;
		if (_jointWeightContext[contextIndex] != context || _jointWeightsBuffer[contextIndex] == null)
		{
			_jointWeightsBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
			_jointWeightContext[contextIndex] = context;
			_jointWeightsInvalid[contextIndex] = true;
		}
		if (_jointWeightsInvalid[contextIndex])
		{
			_jointWeightsBuffer[contextIndex].uploadFromVector(_jointWeightsData, 0, Std.int(_jointWeightsData.length / _jointsPerVertex));
			_jointWeightsInvalid[contextIndex] = false;
		}
		context.setVertexBufferAt(index, _jointWeightsBuffer[contextIndex], 0, _bufferFormat);
	}

	/**
	 * Assigns the attribute stream for joint indices
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
	public function activateJointIndexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_jointIndexContext[contextIndex] != context || 
			_jointIndexBuffer[contextIndex] == null)
		{
			_jointIndexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
			_jointIndexContext[contextIndex] = context;
			_jointIndicesInvalid[contextIndex] = true;
		}
		if (_jointIndicesInvalid[contextIndex])
		{
			_jointIndexBuffer[contextIndex].uploadFromVector(_numCondensedJoints > 0 ? _condensedJointIndexData : _jointIndexData, 0, Std.int(_jointIndexData.length / _jointsPerVertex));
			_jointIndicesInvalid[contextIndex] = false;
		}
		context.setVertexBufferAt(index, _jointIndexBuffer[contextIndex], 0, _bufferFormat);
	}

	override private function uploadData(contextIndex:Int):Void
	{
		if (_animatedData != null)
		{
			_activeBuffer.uploadFromVector(_animatedData, 0, _numVertices);
			_vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
		}
		else
			super.uploadData(contextIndex);
	}

	/**
	 * Clones the current object.
	 * @return An exact duplicate of the current object.
	 */
	override public function clone():ISubGeometry
	{
		var clone:SkinnedSubGeometry = new SkinnedSubGeometry(_jointsPerVertex);
		clone.updateData(_vertexData.concat());
		clone.updateIndexData(_indices.concat());
		clone.updateJointIndexData(_jointIndexData.concat());
		clone.updateJointWeightsData(_jointWeightsData.concat());
		clone._autoDeriveVertexNormals = _autoDeriveVertexNormals;
		clone._autoDeriveVertexTangents = _autoDeriveVertexTangents;
		clone._numCondensedJoints = _numCondensedJoints;
		clone._condensedIndexLookUp = _condensedIndexLookUp;
		clone._condensedJointIndexData = _condensedJointIndexData;
		return clone;
	}

	/**
	 * Cleans up any resources used by this object.
	 */
	override public function dispose():Void
	{
		super.dispose();
		disposeVertexBuffers(_jointWeightsBuffer);
		disposeVertexBuffers(_jointIndexBuffer);
	}

	/**
	 */
	public function condenseIndexData():Void
	{
		var len:Int = _jointIndexData.length;
		var oldIndex:Int;
		var newIndex:Int = 0;
		var dic:IntMap<Int> = new IntMap<Int>();

		_condensedJointIndexData = new Vector<Float>(len, true);
		_condensedIndexLookUp = new Vector<UInt>();

		for (i in 0...len)
		{
			oldIndex = Std.int(_jointIndexData[i]);

			// if we encounter a new index, assign it a new condensed index
			if (!dic.exists(oldIndex))
			{
				dic.set(oldIndex, newIndex);
				_condensedIndexLookUp[newIndex++] = oldIndex;
				_condensedIndexLookUp[newIndex++] = oldIndex + 1;
				_condensedIndexLookUp[newIndex++] = oldIndex + 2;
			}
			_condensedJointIndexData[i] = dic.get(oldIndex);
		}
		_numCondensedJoints = Std.int(newIndex / 3);

		invalidateBuffers(_jointIndicesInvalid);
	}
	
	private function get_condensedIndexLookUp():Vector<UInt>
	{
		return _condensedIndexLookUp;
	}

	
	private function get_numCondensedJoints():Int
	{
		return _numCondensedJoints;
	}

	
	private function get_animatedData():Vector<Float>
	{
		if (_animatedData != null)
			return _animatedData;
		return _vertexData.concat();
	}

	private function get_jointWeightsData():Vector<Float>
	{
		return _jointWeightsData;
	}

	public function updateJointWeightsData(value:Vector<Float>):Void
	{
		// invalidate condensed stuff
		_numCondensedJoints = 0;
		_condensedIndexLookUp = null;
		_condensedJointIndexData = null;

		_jointWeightsData = value;
		invalidateBuffers(_jointWeightsInvalid);
	}

	
	private function get_jointIndexData():Vector<Float>
	{
		return _jointIndexData;
	}

	public function updateJointIndexData(value:Vector<Float>):Void
	{
		_jointIndexData = value;
		invalidateBuffers(_jointIndicesInvalid);
	}
}
