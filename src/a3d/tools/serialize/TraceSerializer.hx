package a3d.tools.serialize
{
	import flash.geom.Vector3D;

	
	import a3d.math.Quaternion;

	

	/**
	 * TraceSerializer is a concrete Serializer that will output its results to trace().  It has user settable tabSize and separator vars.
	 *
	 * @see a3d.tools.serialize.Serialize
	 */
	class TraceSerializer extends SerializerBase
	{
		private var _indent:UInt = 0;
		public var separator:String = ": ";
		public var tabSize:UInt = 2;

		/**
		 * Creates a new TraceSerializer object.
		 */
		public function TraceSerializer()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override public function beginObject(className:String, instanceName:String):Void
		{
			writeString(className, instanceName);
			_indent += tabSize;
		}

		/**
			 * @inheritDoc
		 */
		override public function writeInt(name:String, value:Int):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeUint(name:String, value:UInt):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeBool(name:String, value:Bool):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeString(name:String, value:String):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeVector3D(name:String, value:Vector3D):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeTransform(name:String, value:Vector<Float>):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;

				var matrixIndent:UInt = outputString.length;

				for (var i:UInt = 0; i < value.length; i++)
				{
					outputString += value[i];
					if ((i < (value.length - 1)) && (((i + 1) % 4) == 0))
					{
						outputString += "\n";
						for (var j:UInt = 0; j < matrixIndent; j++)
						{
							outputString += " ";
						}
					}
					else
					{
						outputString += " ";
					}
				}
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function writeQuaternion(name:String, value:Quaternion):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value)
			{
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}

		/**
		 * @inheritDoc
		 */
		override public function endObject():Void
		{
			_indent -= tabSize;
		}

		private function _indentString():String
		{
			var indentString:String = "";
			for (var i:UInt = 0; i < _indent; i++)
			{
				indentString += " ";
			}
			return indentString;
		}
	}
}
