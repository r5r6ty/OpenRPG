using Spine.Unity;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Spine.Unity
{
    public class LAtlasAsset : AtlasAsset
    {
		public static new AtlasAsset CreateRuntimeInstance(TextAsset atlasText, Texture2D[] textures, Material materialPropertySource, bool initialize)
		{
			// Get atlas page names.
			string atlasString = atlasText.text;
			atlasString = atlasString.Replace("\r", "");
			string[] atlasLines = atlasString.Split('\n');
			var pages = new List<string>();
			for (int i = 0; i < atlasLines.Length - 1; i++)
			{
				if (atlasLines[i].Trim().Length == 0)
					pages.Add(atlasLines[i + 1].Trim().Replace(".png", ""));
			}

			// Populate Materials[] by matching texture names with page names.
			var materials = new Material[pages.Count];
			for (int i = 0, n = pages.Count; i < n; i++)
			{
				Material mat = null;

				// Search for a match.
				string pageName = pages[i];
				for (int j = 0, m = textures.Length; j < m; j++)
				{
					if (string.Equals(pageName, textures[j].name, System.StringComparison.OrdinalIgnoreCase))
					{
						// Match found.
						mat = new Material(materialPropertySource);
						mat.mainTexture = textures[j];
						break;
					}
				}

				if (mat != null)
					materials[i] = mat;
				else
					throw new ArgumentException("Could not find matching atlas page in the texture array.");
			}

			// Create AtlasAsset normally
			return CreateRuntimeInstance(atlasText, materials, initialize);
		}
	}
}

public class spinetest : MonoBehaviour
{
    public TextAsset skeletonJson;
    public TextAsset atlasText;
    public Texture2D[] textures;
    public Material materialPropertySource;

	AtlasAsset runtimeAtlasAsset;
	SkeletonDataAsset runtimeSkeletonDataAsset;
    SkeletonAnimation runtimeSkeletonAnimation;

    // Start is called before the first frame update
    void Start()
    {
        runtimeAtlasAsset = AtlasAsset.CreateRuntimeInstance(atlasText, textures, materialPropertySource, true);
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
