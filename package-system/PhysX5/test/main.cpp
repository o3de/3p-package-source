/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */

#include <PxPhysicsAPI.h>

#ifndef PX_PHYSX_STATIC_LIB
#error Expected static PhysX SDK definitions from the package
#endif

int main()
{
    physx::PxDefaultAllocator allocator;
    physx::PxDefaultErrorCallback errorCallback;
    auto* foundation = PxCreateFoundation(PX_PHYSICS_VERSION, allocator, errorCallback);
    if (!foundation)
    {
        return 1;
    }

    auto* physics = PxCreatePhysics(PX_PHYSICS_VERSION, *foundation, physx::PxTolerancesScale());
    if (!physics)
    {
        return 2;
    }

    const physx::PxVec3 vertices[] =
    {
        physx::PxVec3(0, 0, 0),
        physx::PxVec3(1, 0, 0),
        physx::PxVec3(0, 0, 1)
    };
    const physx::PxU32 indices[] = {0, 1, 2};

    physx::PxTriangleMeshDesc meshDesc;
    meshDesc.points.count = 3;
    meshDesc.points.stride = sizeof(physx::PxVec3);
    meshDesc.points.data = vertices;
    meshDesc.triangles.count = 1;
    meshDesc.triangles.stride = sizeof(indices);
    meshDesc.triangles.data = indices;

    const physx::PxCookingParams cookingParams(physics->getTolerancesScale());
    physx::PxDefaultMemoryOutputStream cookedMesh;
    if (!PxCookTriangleMesh(cookingParams, meshDesc, cookedMesh))
    {
        return 3;
    }

    auto* dispatcher = physx::PxDefaultCpuDispatcherCreate(1);
    physx::PxSceneDesc sceneDesc(physics->getTolerancesScale());
    sceneDesc.cpuDispatcher = dispatcher;
    sceneDesc.filterShader = physx::PxDefaultSimulationFilterShader;

    auto* scene = physics->createScene(sceneDesc);
    if (!scene)
    {
        return 4;
    }

    scene->simulate(1.0f / 60.0f);
    scene->fetchResults(true);

    scene->release();
    dispatcher->release();
    physics->release();
    foundation->release();
    return 0;
}
