using System;
using System.Collections;
using System.IO;
using Ozz;

namespace example
{
	class Program
	{
		public static int Main()
		{
			// Load skeleton
			var readData = scope List<uint8>();
			switch (File.ReadAll("../submodules/ozz-animation/media/bin/pab_skeleton.ozz ", readData)) {
			case .Err(let err):
				return 1;
			default:
			}
			var skeleton = scope Skeleton(readData.Ptr, readData.Count);
			if (skeleton == null)
			{
				return 1;
			}
			Console.WriteLine(scope $"Skeleton loaded, SoaJointCount:{skeleton.SoaJointCount}, JointCount:{skeleton.JointCount}");
			// Load animation 1
			readData.Clear();
			switch (File.ReadAll("../submodules/ozz-animation/media/bin/pab_run.ozz ", readData)) {
			case .Err(let err):
				return 1;
			default:
			}
			var animation1 = scope Animation(readData.Ptr, readData.Count);
			if (animation1 == null)
			{
				return 1;
			}
			Console.WriteLine(scope $"Animation1 loaded, Duration:{animation1.Duration}, Name:{animation1.Name}");
			// Load animation 2
			readData.Clear();
			switch (File.ReadAll("../submodules/ozz-animation/media/bin/pab_jog.ozz ", readData)) {
			case .Err(let err):
				return 1;
			default:
			}
			var animation2 = scope Animation(readData.Ptr, readData.Count);
			if (animation2 == null)
			{
				return 1;
			}
			Console.WriteLine(scope $"Animation2 loaded, Duration:{animation2.Duration}, Name:{animation2.Name}");
			// Sample two animations
			var samplingJob = scope SamplingJob(512, 32);
			var transforms1 = samplingJob.Run(animation1, 0.5f, 0);
			if (transforms1 == null)
			{
				return 1;
			}
			var transforms2 = samplingJob.Run(animation2, 0.5f, 1);
			if (transforms1 == null)
			{
				return 1;
			}
			// Blend two animations
			var blendingJob = scope BlendingJob(512, 24, 8);
			blendingJob.SetSkeleton(skeleton);
			blendingJob.ClearLayers();
			blendingJob.AddLayer(transforms1, 0.5f);
			blendingJob.AddLayer(transforms2, 0.5f);
			var blendedTransforms = blendingJob.Run();
			if (blendedTransforms == null)
			{
				return 1;
			}
			// Get model matrices
			var localToModelJob = scope LocalToModelJob(512);
			localToModelJob.SetInput(skeleton, blendedTransforms);
			var modelMatrices = localToModelJob.Run();
			if (modelMatrices == null)
			{
				return 1;
			}
			Console.WriteLine("ALL OK!");
			for (int i = 0; i < skeleton.JointCount; ++i)
			{
				Console.WriteLine(scope $"#{i} {skeleton.GetJointName(i)} ({modelMatrices[i][12]}, {modelMatrices[i][13]}, {modelMatrices[i][14]})");
			}
			return 0;
		}
	}
}
