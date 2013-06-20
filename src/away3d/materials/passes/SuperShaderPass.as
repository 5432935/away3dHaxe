package away3d.materials.passes
{
	import flash.display3D.Context3D;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;


	import away3d.entities.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.lights.DirectionalLight;
	import away3d.entities.lights.LightProbe;
	import away3d.entities.lights.PointLight;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.ShaderCompiler;
	import away3d.materials.compilation.SuperShaderCompiler;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVOSet;



	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */

	public class SuperShaderPass extends CompiledPass
	{
		private var _includeCasters:Boolean = true;
		private var _ignoreLights:Boolean;

		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function SuperShaderPass(material:MaterialBase)
		{
			super(material);
			_needFragmentAnimation = true;
		}

		override protected function createCompiler(profile:String):ShaderCompiler
		{
			return new SuperShaderCompiler(profile);
		}

		public function get includeCasters():Boolean
		{
			return _includeCasters;
		}

		public function set includeCasters(value:Boolean):void
		{
			if (_includeCasters == value)
				return;
			_includeCasters = value;
			invalidateShaderProgram();
		}

		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform():ColorTransform
		{
			return _methodSetup.colorTransformMethod ? _methodSetup.colorTransformMethod.colorTransform : null;
		}

		public function set colorTransform(value:ColorTransform):void
		{
			if (value)
			{
				colorTransformMethod ||= new ColorTransformMethod();
				_methodSetup.colorTransformMethod.colorTransform = value;
			}
			else if (!value)
			{
				if (_methodSetup.colorTransformMethod)
					colorTransformMethod = null;
				colorTransformMethod = _methodSetup.colorTransformMethod = null;
			}
		}

		public function get colorTransformMethod():ColorTransformMethod
		{
			return _methodSetup.colorTransformMethod;
		}

		public function set colorTransformMethod(value:ColorTransformMethod):void
		{
			_methodSetup.colorTransformMethod = value;
		}

		/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		 */
		public function addMethod(method:EffectMethodBase):void
		{
			_methodSetup.addMethod(method);
		}

		public function get numMethods():int
		{
			return _methodSetup.numMethods;
		}

		public function hasMethod(method:EffectMethodBase):Boolean
		{
			return _methodSetup.hasMethod(method);
		}

		public function getMethodAt(index:int):EffectMethodBase
		{
			return _methodSetup.getMethodAt(index);
		}

		/**
		 * Adds a shading method to the end of a shader, at the specified index amongst
		 * the methods in that section of the shader. Note that shading methods can not
		 * be reused across materials.
		 */
		public function addMethodAt(method:EffectMethodBase, index:int):void
		{
			_methodSetup.addMethodAt(method, index);
		}

		public function removeMethod(method:EffectMethodBase):void
		{
			_methodSetup.removeMethod(method);
		}

		override protected function updateLights():void
		{
//			super.updateLights();
			if (_lightPicker && !_ignoreLights)
			{
				_numPointLights = _lightPicker.numPointLights;
				_numDirectionalLights = _lightPicker.numDirectionalLights;
				_numLightProbes = _lightPicker.numLightProbes;

				if (_includeCasters)
				{
					_numPointLights += _lightPicker.numCastingPointLights;
					_numDirectionalLights += _lightPicker.numCastingDirectionalLights;
				}
			}
			else
			{
				_numPointLights = 0;
				_numDirectionalLights = 0;
				_numLightProbes = 0;
			}

			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(stage3DProxy, camera);

			if (_methodSetup.colorTransformMethod)
				_methodSetup.colorTransformMethod.activate(_methodSetup.colorTransformMethodVO, stage3DProxy);

			var methods:Vector.<MethodVOSet> = _methodSetup.methods;
			var len:uint = methods.length;
			for (var i:int = 0; i < len; ++i)
			{
				var mset:MethodVOSet = methods[i];
				mset.method.activate(mset.data, stage3DProxy);
			}

			if (_cameraPositionIndex >= 0)
			{
				var pos:Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function deactivate(stage3DProxy:Stage3DProxy):void
		{
			super.deactivate(stage3DProxy);

			if (_methodSetup.colorTransformMethod)
				_methodSetup.colorTransformMethod.deactivate(_methodSetup.colorTransformMethodVO, stage3DProxy);

			var mset:MethodVOSet;
			var methods:Vector.<MethodVOSet> = _methodSetup.methods;
			var len:uint = methods.length;
			for (var i:uint = 0; i < len; ++i)
			{
				mset = methods[i];
				mset.method.deactivate(mset.data, stage3DProxy);
			}
		}

		override protected function addPassesFromMethods():void
		{
			super.addPassesFromMethods();

			if (_methodSetup.colorTransformMethod)
				addPasses(_methodSetup.colorTransformMethod.passes);

			var methods:Vector.<MethodVOSet> = _methodSetup.methods;
			for (var i:uint = 0; i < methods.length; ++i)
				addPasses(methods[i].method.passes);
		}

		private function usesProbesForSpecular():Boolean
		{
			return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
		}

		private function usesProbesForDiffuse():Boolean
		{
			return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
		}

		override protected function updateMethodConstants():void
		{
			super.updateMethodConstants();
			if (_methodSetup.colorTransformMethod)
				_methodSetup.colorTransformMethod.initConstants(_methodSetup.colorTransformMethodVO);

			var methods:Vector.<MethodVOSet> = _methodSetup.methods;
			var len:uint = methods.length;
			for (var i:uint = 0; i < len; ++i)
			{
				methods[i].method.initConstants(methods[i].data);
			}
		}

		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		override protected function updateLightConstants():void
		{
			// first dirs, then points
			var dirLight:DirectionalLight;
			var pointLight:PointLight;
			var i:uint, k:uint;
			var len:int;
			var dirPos:Vector3D;
			var total:uint = 0;
			var numLightTypes:uint = _includeCasters ? 2 : 1;

			k = _lightFragmentConstantIndex;

			for (var cast:int = 0; cast < numLightTypes; ++cast)
			{
				var dirLights:Vector.<DirectionalLight> = cast ? _lightPicker.castingDirectionalLights : _lightPicker.directionalLights;
				len = dirLights.length;
				total += len;

				for (i = 0; i < len; ++i)
				{
					dirLight = dirLights[i];
					dirPos = dirLight.sceneDirection;

					_ambientLightR += dirLight.ambientR;
					_ambientLightG += dirLight.ambientG;
					_ambientLightB += dirLight.ambientB;

					_fragmentConstantData[k++] = -dirPos.x;
					_fragmentConstantData[k++] = -dirPos.y;
					_fragmentConstantData[k++] = -dirPos.z;
					_fragmentConstantData[k++] = 1;

					_fragmentConstantData[k++] = dirLight.diffuseR;
					_fragmentConstantData[k++] = dirLight.diffuseG;
					_fragmentConstantData[k++] = dirLight.diffuseB;
					_fragmentConstantData[k++] = 1;

					_fragmentConstantData[k++] = dirLight.specularR;
					_fragmentConstantData[k++] = dirLight.specularG;
					_fragmentConstantData[k++] = dirLight.specularB;
					_fragmentConstantData[k++] = 1;
				}
			}

			// more directional supported than currently picked, need to clamp all to 0
			if (_numDirectionalLights > total)
			{
				i = k + (_numDirectionalLights - total) * 12;
				while (k < i)
					_fragmentConstantData[k++] = 0;
			}

			total = 0;
			for (cast = 0; cast < numLightTypes; ++cast)
			{
				var pointLights:Vector.<PointLight> = cast ? _lightPicker.castingPointLights : _lightPicker.pointLights;
				len = pointLights.length;
				for (i = 0; i < len; ++i)
				{
					pointLight = pointLights[i];
					dirPos = pointLight.scenePosition;

					_ambientLightR += pointLight.ambientR;
					_ambientLightG += pointLight.ambientG;
					_ambientLightB += pointLight.ambientB;

					_fragmentConstantData[k++] = dirPos.x;
					_fragmentConstantData[k++] = dirPos.y;
					_fragmentConstantData[k++] = dirPos.z;
					_fragmentConstantData[k++] = 1;

					_fragmentConstantData[k++] = pointLight.diffuseR;
					_fragmentConstantData[k++] = pointLight.diffuseG;
					_fragmentConstantData[k++] = pointLight.diffuseB;
					_fragmentConstantData[k++] = pointLight.radius * pointLight.radius;

					_fragmentConstantData[k++] = pointLight.specularR;
					_fragmentConstantData[k++] = pointLight.specularG;
					_fragmentConstantData[k++] = pointLight.specularB;
					_fragmentConstantData[k++] = pointLight.fallOffFactor;
				}
			}

			// more directional supported than currently picked, need to clamp all to 0
			if (_numPointLights > total)
			{
				i = k + (total - _numPointLights) * 12;
				for (; k < i; ++k)
					_fragmentConstantData[k] = 0;
			}
		}

		override protected function updateProbes(stage3DProxy:Stage3DProxy):void
		{
			var probe:LightProbe;
			var lightProbes:Vector.<LightProbe> = _lightPicker.lightProbes;
			var weights:Vector.<Number> = _lightPicker.lightProbeWeights;
			var len:int = lightProbes.length;
			var addDiff:Boolean = usesProbesForDiffuse();
			var addSpec:Boolean = Boolean(_methodSetup.specularMethod && usesProbesForSpecular());
			var context:Context3D = stage3DProxy.context3D;

			if (!(addDiff || addSpec))
				return;

			for (var i:uint = 0; i < len; ++i)
			{
				probe = lightProbes[i];

				if (addDiff)
					context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
				if (addSpec)
					context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
			}

			_fragmentConstantData[_probeWeightsIndex] = weights[0];
			_fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
			_fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
			_fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
		}

		public function set ignoreLights(ignoreLights:Boolean):void
		{
			_ignoreLights = ignoreLights;
		}

		public function get ignoreLights():Boolean
		{
			return _ignoreLights;
		}
	}
}
