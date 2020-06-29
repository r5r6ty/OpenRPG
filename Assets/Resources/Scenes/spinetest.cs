using Spine.Unity;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class spinetest : MonoBehaviour
{
    public TextAsset skeletonJson;
    public TextAsset atlasText;
    public Texture2D[] textures;
    public Material materialPropertySource;

    SpineAtlasAsset runtimeAtlasAsset;
    SkeletonDataAsset runtimeSkeletonDataAsset;
    SkeletonAnimation runtimeSkeletonAnimation;

    // Start is called before the first frame update
    void Start()
    {
        runtimeAtlasAsset = SpineAtlasAsset.CreateRuntimeInstance(atlasText, textures, materialPropertySource, true);
        runtimeSkeletonDataAsset = SkeletonDataAsset.CreateRuntimeInstance(skeletonJson, runtimeAtlasAsset, true);

        runtimeSkeletonDataAsset.GetSkeletonData(false); // preload.


        runtimeSkeletonAnimation = SkeletonAnimation.NewSkeletonAnimationGameObject(runtimeSkeletonDataAsset);

        // Extra Stuff
        runtimeSkeletonAnimation.Initialize(false);
        runtimeSkeletonAnimation.Skeleton.SetSkin("base");
        runtimeSkeletonAnimation.Skeleton.SetSlotsToSetupPose();
        runtimeSkeletonAnimation.AnimationState.SetAnimation(0, "run", true);
        runtimeSkeletonAnimation.GetComponent<MeshRenderer>().sortingOrder = 10;
        runtimeSkeletonAnimation.transform.Translate(Vector3.down * 2);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
