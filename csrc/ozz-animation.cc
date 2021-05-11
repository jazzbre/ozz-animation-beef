#include "ozz-animation.h"
#include <ozz/base/io/archive.h>
#include <ozz/base/maths/soa_transform.h>
#include <ozz/base/maths/transform.h>
#include <ozz/animation/runtime/animation.h>
#include <ozz/animation/runtime/skeleton.h>
#include <ozz/animation/runtime/blending_job.h>
#include <ozz/animation/runtime/sampling_job.h>
#include <ozz/animation/runtime/local_to_model_job.h>
#include <vector>
#include <array>

// Skeleton
OZZAPI ozz::animation::Skeleton* ozzanimation_CreateSkeleton(void* data, uint32_t dataSize) {
    ozz::io::DirectMemoryStream stream((const uint8_t*)data, (size_t)dataSize);
    auto skeleton = new ozz::animation::Skeleton();
    ozz::io::IArchive archive(&stream);
    archive >> *skeleton;
    if (skeleton->num_joints() == 0) {
        delete skeleton;
        return nullptr;
    }
    return skeleton;
}

OZZAPI void ozzanimation_Skeleton_Destroy(ozz::animation::Skeleton* skeleton) {
    delete skeleton;
}

OZZAPI int ozzanimation_Skeleton_GetSoaJointsCount(ozz::animation::Skeleton* skeleton) {
    return skeleton->num_soa_joints();
}

OZZAPI int ozzanimation_Skeleton_GetJointCount(ozz::animation::Skeleton* skeleton) {
    return skeleton->num_joints();
}

OZZAPI const ozz::math::SoaTransform* ozzanimation_Skeleton_GetJointBindPose(ozz::animation::Skeleton* skeleton) {
    return skeleton->joint_bind_poses().begin();
}

OZZAPI const int ozzanimation_Skeleton_GetJointParent(ozz::animation::Skeleton* skeleton, int index) {
    return (int)skeleton->joint_parents()[index];
}

OZZAPI const char* ozzanimation_Skeleton_GetJointName(ozz::animation::Skeleton* skeleton, int index) {
    return skeleton->joint_names()[index];
}

// Animation
OZZAPI ozz::animation::Animation* ozzanimation_CreateAnimation(void* data, uint32_t dataSize) {
    ozz::io::DirectMemoryStream stream((const uint8_t*)data, (size_t)dataSize);
    auto animation = new ozz::animation::Animation();
    ozz::io::IArchive archive(&stream);
    archive >> *animation;
    if (animation->num_tracks() == 0) {
        delete animation;
        return nullptr;
    }
    return animation;
}

OZZAPI void ozzanimation_Animation_Destroy(ozz::animation::Animation* animation) {
    delete animation;
}

OZZAPI float ozzanimation_Animation_GetDuration(ozz::animation::Animation* animation) {
    return animation->duration();
}

OZZAPI int ozzanimation_Animation_GetSoaTrackCount(ozz::animation::Animation* animation) {
    return animation->num_soa_tracks();
}

OZZAPI int ozzanimation_Animation_GetTrackCount(ozz::animation::Animation* animation) {
    return animation->num_tracks();
}

OZZAPI const char* ozzanimation_Animation_GetName(ozz::animation::Animation* animation) {
    return animation->name();
}

// SamplingJob
class SamplingJob : public ozz::animation::SamplingJob {
public:
    SamplingJob(int maxJointCount, int maxLayerTransformCount) {
        auto maxSoaJointCount = (maxJointCount + 3) / 4;
        cache = new ozz::animation::SamplingCache(maxJointCount);
        for (int i = 0; i < maxLayerTransformCount; ++i) {
            layerTransforms.push_back({new ozz::math::SoaTransform[(size_t)maxSoaJointCount], (size_t)maxSoaJointCount});
        }
    }

    ~SamplingJob() {
        delete cache;
        for (auto& layerTransform : layerTransforms) {
            delete layerTransform.begin();
        }
    }

    ozz::span<ozz::math::SoaTransform> Run(int layerTransformIndex) {
        output = layerTransforms[layerTransformIndex];
        if (!ozz::animation::SamplingJob::Run()) {
            return {};
        }
        return output;
    }

private:
    std::vector<ozz::span<ozz::math::SoaTransform>> layerTransforms;
};

OZZAPI SamplingJob* ozzanimation_SamplingJob_Create(int maxJointCount, int maxLayerTransformCount) {
    return new SamplingJob(maxJointCount, maxLayerTransformCount);
}

OZZAPI void ozzanimation_SamplingJob_Destroy(SamplingJob* job) {
    delete job;
}

OZZAPI ozz::math::SoaTransform* ozzanimation_SamplingJob_Run(SamplingJob* job, ozz::animation::Animation* animation, float time, int layerTransformIndex) {
    job->animation = animation;
    job->ratio = time;
    return job->Run(layerTransformIndex).begin();
}

// BlendingJob
class BlendingJob : public ozz::animation::BlendingJob {
public:
    BlendingJob(int maxJointCount, int _maxLayerCount, int _maxAdditiveLayerCount)
        : maxLayerCount(_maxLayerCount)
        , maxAdditiveLayerCount(_maxAdditiveLayerCount) {
        auto maxSoaJointCount = (maxJointCount + 3) / 4;
        output = {new ozz::math::SoaTransform[(size_t)maxSoaJointCount], (size_t)maxSoaJointCount};
        activeLayers.reserve((size_t)maxLayerCount);
        activeAdditiveLayers.reserve((size_t)maxAdditiveLayerCount);
    }

    void SetSkeleton(ozz::animation::Skeleton* skeleton) {
        activeSoaJointCount = skeleton->num_soa_joints();
        bind_pose = skeleton->joint_bind_poses();
    }

    void ClearLayers() {
        activeLayers.clear();
        activeAdditiveLayers.clear();
    }

    bool AddLayer(ozz::math::SoaTransform* transforms, float weight) {
        if (activeLayers.size() == maxLayerCount) {
            return false;
        }
        Layer layer;
        layer.transform = {transforms, (size_t)activeSoaJointCount};
        layer.weight = weight;
        activeLayers.push_back(layer);
        return true;
    }

    bool AddAdditiveLayer(ozz::math::SoaTransform* transforms, float weight) {
        if (activeAdditiveLayers.size() == maxLayerCount) {
            return false;
        }
        Layer layer;
        layer.transform = {transforms, (size_t)activeSoaJointCount};
        layer.weight = weight;
        activeAdditiveLayers.push_back(layer);
        return true;
    }

    ozz::span<ozz::math::SoaTransform> Run() {
        if (activeLayers.size()) {
            layers = {&activeLayers[0], activeLayers.size()};
        } else {
            layers = {};
        }
        if (activeAdditiveLayers.size()) {
            additive_layers = {&activeAdditiveLayers[0], activeAdditiveLayers.size()};
        } else {
            additive_layers = {};
        }
        auto result = ozz::animation::BlendingJob::Run();
        if (!result) {
            return {};
        }
        return output;
    }

private:
    int activeSoaJointCount = 0;
    int maxLayerCount = 0;
    int maxAdditiveLayerCount = 0;

    int activeJointCount = 0;
    std::vector<Layer> activeLayers;
    std::vector<Layer> activeAdditiveLayers;
};

OZZAPI BlendingJob* ozzanimation_BlendingJob_Create(int maxJointCount, int maxLayerCount, int maxAdditiveLayerCount) {
    return new BlendingJob(maxJointCount, maxLayerCount, maxAdditiveLayerCount);
}

OZZAPI void ozzanimation_BlendingJob_Destroy(BlendingJob* job) {
    delete job;
}

OZZAPI ozz::math::SoaTransform* ozzanimation_BlendingJob_Run(BlendingJob* job) {
    return job->Run().begin();
}

OZZAPI void ozzanimation_BlendingJob_SetSkeleton(BlendingJob* job, ozz::animation::Skeleton* skeleton) {
    job->SetSkeleton(skeleton);
}

OZZAPI void ozzanimation_BlendingJob_ClearLayers(BlendingJob* job) {
    job->ClearLayers();
}

OZZAPI void ozzanimation_BlendingJob_AddLayer(BlendingJob* job, ozz::math::SoaTransform* transforms, float weight) {
    job->AddLayer(transforms, weight);
}

OZZAPI void ozzanimation_BlendingJob_AddAdditiveLayer(BlendingJob* job, ozz::math::SoaTransform* transforms, float weight) {
    job->AddAdditiveLayer(transforms, weight);
}

// LocalToModelJob
class LocalToModelJob : public ozz::animation::LocalToModelJob {
public:
    LocalToModelJob(int maxJointCount) {
        outputWorldMatrices.resize((size_t)maxJointCount);
    }

    void SetInput(ozz::animation::Skeleton* _skeleton, ozz::math::SoaTransform* _input) {
        skeleton = _skeleton;
        input = {_input, (size_t)skeleton->num_soa_joints()};
        output = {&outputWorldMatrices[0], (size_t)skeleton->num_joints()};
    }

    ozz::span<ozz::math::Float4x4> Run(int startIndex, int endIndex) {
        from = startIndex;
        to = endIndex == -1 ? ozz::animation::Skeleton::kMaxJoints : endIndex;
        if (!ozz::animation::LocalToModelJob::Run()) {
            return {};
        }
        return output;
    }

private:
    std::vector<ozz::math::Float4x4> outputWorldMatrices;
};

OZZAPI LocalToModelJob* ozzanimation_LocalToModelJob_Create(int maxJointCount) {
    return new LocalToModelJob(maxJointCount);
}

OZZAPI void ozzanimation_LocalToModelJob_Destroy(LocalToModelJob* job) {
    delete job;
}

OZZAPI void ozzanimation_LocalToModelJob_SetInput(LocalToModelJob* job, ozz::animation::Skeleton* skeleton, ozz::math::SoaTransform* input) {
    job->SetInput(skeleton, input);
}

OZZAPI ozz::math::Float4x4* ozzanimation_LocalToModelJob_Run(LocalToModelJob* job, int startIndex, int endIndex) {
    return job->Run(startIndex, endIndex).begin();
}