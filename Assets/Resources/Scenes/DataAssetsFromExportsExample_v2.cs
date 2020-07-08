using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Spine.Unity.Examples {
	public class DataAssetsFromExportsExample_v2 : MonoBehaviour {

		//public TextAsset skeletonJson;
		public TextAsset atlasText;
		//public Texture2D[] textures;
		//public Material materialPropertySource;

		AtlasAsset runtimeAtlasAsset;
		SkeletonDataAsset runtimeSkeletonDataAsset;
		SkeletonAnimation runtimeSkeletonAnimation;

		Bone bone;

		void CreateRuntimeAssetsAndGameObject () {
			// 1. Create the AtlasAsset (needs atlas text asset and textures, and materials/shader);
			// 2. Create SkeletonDataAsset (needs json or binary asset file, and an AtlasAsset)
			// 3. Create SkeletonAnimation (needs a valid SkeletonDataAsset)

			Texture2D[] textures = new Texture2D[1];

			textures[0] = new Texture2D(0, 0, TextureFormat.RGBA32, false, false);

			textures[0].filterMode = FilterMode.Point;
			byte[] bytes = File.ReadAllBytes("D:/unityproject/OpenRPG/Assets/Resources/Scenes/girl/girl.png");
			textures[0].LoadImage(bytes);
			textures[0].name = "girl";

			Material materialPropertySource = new Material(Shader.Find("Spine/Skeleton"));

			runtimeAtlasAsset = AtlasAsset.CreateRuntimeInstance(new TextAsset(File.ReadAllText("D:/unityproject/OpenRPG/Assets/Resources/Scenes/girl/girl.atlas.txt")), textures, materialPropertySource, true);
			runtimeSkeletonDataAsset = SkeletonDataAsset.CreateRuntimeInstance(new TextAsset(File.ReadAllText("D:/unityproject/OpenRPG/Assets/Resources/Scenes/girl/girl.json")), runtimeAtlasAsset, true);
		}

		void Start () {
			CreateRuntimeAssetsAndGameObject();
			runtimeSkeletonDataAsset.GetSkeletonData(false); // preload.
			//yield return new WaitForSeconds(0.5f);

			runtimeSkeletonAnimation = SkeletonAnimation.NewSkeletonAnimationGameObject(runtimeSkeletonDataAsset);

			bone = runtimeSkeletonAnimation.Skeleton.FindBone("crosshair");

			print(bone.Data.Name);
			print(bone.scaleX);
			print(bone.scaleY);

			// Extra Stuff
			runtimeSkeletonAnimation.Initialize(false);
			//runtimeSkeletonAnimation.Skeleton.SetSkin("base");
			runtimeSkeletonAnimation.Skeleton.SetSlotsToSetupPose();
			runtimeSkeletonAnimation.AnimationState.SetAnimation(0, "aimR", true);
			runtimeSkeletonAnimation.GetComponent<MeshRenderer>().sortingOrder = 10;
			runtimeSkeletonAnimation.transform.Translate(Vector3.down * 2);

		}

        void Update()
        {
			var mousePosition = Input.mousePosition;
			var worldMousePosition = Camera.main.ScreenToWorldPoint(mousePosition);
			var skeletonSpacePoint = runtimeSkeletonAnimation.transform.InverseTransformPoint(worldMousePosition);
			if (runtimeSkeletonAnimation.Skeleton.FlipX) skeletonSpacePoint.x *= -1;
			bone.SetPosition(skeletonSpacePoint);
		}
    }

}
