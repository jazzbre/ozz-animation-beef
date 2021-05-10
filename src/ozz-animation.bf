using System;

namespace Ozz
{
	typealias Float4x4 = float[16];
	typealias OzzSoaTransform = void;
	typealias OzzSkeleton = void;
	typealias OzzAnimation = void;

	public class Skeleton
	{
		public OzzSkeleton* Handle { get; private set; }

		public int SoaJointCount => ozzanimation_Skeleton_GetSoaJointsCount(Handle);
		public int JointCount => ozzanimation_Skeleton_GetJointCount(Handle);
		public OzzSoaTransform* JointBindPose => ozzanimation_Skeleton_GetJointBindPose(Handle);

		public this(void* data, int dataSize)
		{
			Handle = ozzanimation_CreateSkeleton(data, (uint32)dataSize);
		}

		public ~this()
		{
			if (Handle != null)
			{
				ozzanimation_Skeleton_Destroy(Handle);
				Handle = null;
			}
		}

		public int GetJointParent(int index)
		{
			return (int)ozzanimation_Skeleton_GetJointParent(Handle, (int32)index);
		}

		public StringView GetJointName(int index)
		{
			return StringView(ozzanimation_Skeleton_GetJointName(Handle, (int32)index));
		}

		[CLink] private static extern OzzSkeleton* ozzanimation_CreateSkeleton(void* data, uint32 dataSize);
		[CLink] private static extern void ozzanimation_Skeleton_Destroy(OzzSkeleton* skeleton);
		[CLink] private static extern int32 ozzanimation_Skeleton_GetSoaJointsCount(OzzSkeleton* skeleton);
		[CLink] private static extern int32 ozzanimation_Skeleton_GetJointCount(OzzSkeleton* skeleton);
		[CLink] private static extern OzzSoaTransform* ozzanimation_Skeleton_GetJointBindPose(OzzSkeleton* skeleton);
		[CLink] private static extern int32 ozzanimation_Skeleton_GetJointParent(OzzSkeleton* skeleton, int32 index);
		[CLink] private static extern char8* ozzanimation_Skeleton_GetJointName(OzzSkeleton* skeleton, int32 index);
	}

	public class Animation
	{
		public OzzAnimation* Handle { get; private set; }

		public float Duration => ozzanimation_Animation_GetDuration(Handle);
		public int SoaTrackCount => (int)ozzanimation_Animation_GetSoaTrackCount(Handle);
		public int TrackCount => (int)ozzanimation_Animation_GetTrackCount(Handle);
		public StringView Name => StringView(ozzanimation_Animation_GetName(Handle));

		public this(void* data, int dataSize)
		{
			Handle = ozzanimation_CreateAnimation(data, (uint32)dataSize);
		}

		public ~this()
		{
			if (Handle != null)
			{
				ozzanimation_Animation_Destroy(Handle);
				Handle = null;
			}
		}

		[CLink] private static extern OzzAnimation* ozzanimation_CreateAnimation(void* data, uint32 dataSize);
		[CLink] private static extern void ozzanimation_Animation_Destroy(OzzAnimation* animation);
		[CLink] private static extern float ozzanimation_Animation_GetDuration(OzzAnimation* animation);
		[CLink] private static extern int32 ozzanimation_Animation_GetSoaTrackCount(OzzAnimation* animation);
		[CLink] private static extern int32 ozzanimation_Animation_GetTrackCount(OzzAnimation* animation);
		[CLink] private static extern char8* ozzanimation_Animation_GetName(OzzAnimation* animation);
	}

	public class SamplingJob
	{
		typealias OzzSamplingJob = void;
		OzzSamplingJob* handle = null;

		public this(int maxJointCount, int maxLayerTransformCount)
		{
			handle = ozzanimation_SamplingJob_Create((int32)maxJointCount, (int32)maxLayerTransformCount);
		}

		public ~this()
		{
			if (handle != null)
			{
				ozzanimation_SamplingJob_Destroy(handle);
				handle = null;
			}
		}

		public OzzSoaTransform* Run(Animation animation, float time, int layerTransformIndex)
		{
			return ozzanimation_SamplingJob_Run(handle, animation.Handle, time, (int32)layerTransformIndex);
		}

		[CLink] private static extern OzzSamplingJob* ozzanimation_SamplingJob_Create(int32 maxJointCount, int32 maxLayerTransformCount);
		[CLink] private static extern void ozzanimation_SamplingJob_Destroy(OzzSamplingJob* job);
		[CLink] private static extern OzzSoaTransform* ozzanimation_SamplingJob_Run(OzzSamplingJob* job, OzzAnimation* animation, float time, int layerTransformIndex);
	}

	class BlendingJob
	{
		typealias OzzBlendingJob = void;
		OzzBlendingJob* handle = null;

		public this(int maxJointCount, int maxLayerCount, int maxAdditiveLayerCount)
		{
			handle = ozzanimation_BlendingJob_Create((int32)maxJointCount, (int32)maxLayerCount, (int32)maxAdditiveLayerCount);
		}

		public ~this()
		{
			if (handle != null)
			{
				ozzanimation_BlendingJob_Destroy(handle);
				handle = null;
			}
		}

		public void SetSkeleton(Skeleton skeleton)
		{
			ozzanimation_BlendingJob_SetSkeleton(handle, skeleton.Handle);
		}

		public void ClearLayers()
		{
			ozzanimation_BlendingJob_ClearLayers(handle);
		}

		public void AddLayer(OzzSoaTransform* transforms, float weight)
		{
			ozzanimation_BlendingJob_AddLayer(handle, transforms, weight);
		}

		public void AddAdditiveLayer(OzzSoaTransform* transforms, float weight)
		{
			ozzanimation_BlendingJob_AddAdditiveLayer(handle, transforms, weight);
		}

		public bool Validate()
		{
			return ozzanimation_BlendingJob_Validate(handle);
		}

		public OzzSoaTransform* Run()
		{
			return ozzanimation_BlendingJob_Run(handle);
		}

		[CLink] private static extern BlendingJob* ozzanimation_BlendingJob_Create(int32 maxJointCount, int32 maxLayerCount, int32 maxAdditiveLayerCount);
		[CLink] private static extern void ozzanimation_BlendingJob_Destroy(OzzBlendingJob* job);
		[CLink] private static extern bool ozzanimation_BlendingJob_Validate(OzzBlendingJob* job);
		[CLink] private static extern OzzSoaTransform* ozzanimation_BlendingJob_Run(OzzBlendingJob* job);
		[CLink] private static extern void ozzanimation_BlendingJob_SetSkeleton(OzzBlendingJob* job, OzzSkeleton* skeleton);
		[CLink] private static extern void ozzanimation_BlendingJob_ClearLayers(OzzBlendingJob* job);
		[CLink] private static extern void ozzanimation_BlendingJob_AddLayer(OzzBlendingJob* job, OzzSoaTransform* transforms, float weight);
		[CLink] private static extern void ozzanimation_BlendingJob_AddAdditiveLayer(OzzBlendingJob* job, OzzSoaTransform* transforms, float weight);
	}

	class LocalToModelJob
	{
		typealias OzzLocalToModelJob = void;
		OzzLocalToModelJob* handle = null;

		public this(int maxJointCount)
		{
			handle = ozzanimation_LocalToModelJob_Create((int32)maxJointCount);
		}

		public ~this()
		{
			if (handle != null)
			{
				ozzanimation_LocalToModelJob_Destroy(handle);
				handle = null;
			}
		}

		public void SetInput(Skeleton skeleton, OzzSoaTransform* input)
		{
			ozzanimation_LocalToModelJob_SetInput(handle, skeleton.Handle, input);
		}

		public Float4x4* Run(int startIndex = 0, int endIndex = -1)
		{
			return ozzanimation_LocalToModelJob_Run(handle, (int32)startIndex, (int32)endIndex);
		}

		[CLink] private static extern OzzLocalToModelJob* ozzanimation_LocalToModelJob_Create(int maxJointCount);
		[CLink] private static extern void ozzanimation_LocalToModelJob_Destroy(OzzLocalToModelJob* job);
		[CLink] private static extern void ozzanimation_LocalToModelJob_SetInput(OzzLocalToModelJob* job, OzzSkeleton* skeleton, OzzSoaTransform* input);
		[CLink] private static extern Float4x4* ozzanimation_LocalToModelJob_Run(OzzLocalToModelJob* job, int32 startIndex, int32 endIndex);
	}
}
