package a3d.animators.utils;

import a3d.animators.data.JointPose;
import a3d.animators.data.SkeletonPose;
import a3d.animators.nodes.SkeletonClipNode;
import flash.errors.Error;
import flash.geom.Matrix3D;
import flash.geom.Orientation3D;
import flash.geom.Vector3D;
import flash.Vector;



class SkeletonUtils
{
	public static function generateDifferenceClip(source:SkeletonClipNode, referencePose:SkeletonPose):SkeletonClipNode
	{
		var diff:SkeletonClipNode = new SkeletonClipNode();
		var numFrames:Int = source.frames.length;
		for (i in 0...numFrames)
			diff.addFrame(generateDifferencePose(source.frames[i], referencePose), source.durations[i]);

		return diff;
	}

	public static function generateDifferencePose(source:SkeletonPose, reference:SkeletonPose):SkeletonPose
	{
		if (source.numJointPoses != reference.numJointPoses)
		{
			throw new Error("joint counts don't match!");
		}

		var numJoints:Int = source.numJointPoses;
		var diff:SkeletonPose = new SkeletonPose();
		var srcPose:JointPose;
		var refPose:JointPose;
		var diffPose:JointPose;
		var mtx:Matrix3D = new Matrix3D();
		var tempMtx:Matrix3D = new Matrix3D();
		var vec:Vector<Vector3D>;

		for (i in 0...numJoints)
		{
			srcPose = source.jointPoses[i];
			refPose = reference.jointPoses[i];
			diffPose = new JointPose();
			diff.jointPoses[i] = diffPose;
			diffPose.name = srcPose.name;

			refPose.toMatrix3D(mtx);
			mtx.invert();
			mtx.append(srcPose.toMatrix3D(tempMtx));
			vec = mtx.decompose(Orientation3D.QUATERNION);
			diffPose.translation.copyFrom(vec[0]);
			diffPose.orientation.x = vec[1].x;
			diffPose.orientation.y = vec[1].y;
			diffPose.orientation.z = vec[1].z;
			diffPose.orientation.w = vec[1].w;
		}

		return diff;
	}
}
