package a3d.materials
{

	/**
	 * Enumeration class for defining which lighting types affects the specific material
	 * lighting component (diffuse and specular). This can be useful if, for example, you
	 * want to use light probes for diffuse global lighting, but want specular lights from
	 * traditional light sources without those affecting the diffuse light.
	 *
	 * @see a3d.materials.ColorMaterial.diffuseLightSources
	 * @see a3d.materials.ColorMaterial.specularLightSources
	 * @see a3d.materials.TextureMaterial.diffuseLightSources
	 * @see a3d.materials.TextureMaterial.specularLightSources
	*/
	class LightSources
	{
		/**
		 * Defines normal lights are to be used as the source for the lighting
		 * component.
		*/
		public static inline var LIGHTS:UInt = 0x01;

		/**
		 * Defines that global lighting probes are to be used as the source for the
		 * lighting component.
		*/
		public static inline var PROBES:UInt = 0x02;

		/**
		 * Defines that both normal and global lighting probes  are to be used as the
		 * source for the lighting component.
		*/
		public static inline var ALL:UInt = 0x03;
	}
}
