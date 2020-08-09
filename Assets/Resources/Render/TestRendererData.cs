using UnityEngine.Rendering.Universal;
using System;
using UnityEngine.Rendering;
using UnityEngine.Scripting.APIUpdating;
using UnityEngine.Serialization;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif

namespace UnityEngine.Experimental.Rendering.Universal
{
    [Serializable, ReloadGroup, ExcludeFromPreset]
    [MovedFrom("UnityEngine.Experimental.Rendering.LWRP")]
    public class TestRendererData : ScriptableRendererData
    {

        [SerializeField, Reload("Runtime/Data/PostProcessData.asset")]
        PostProcessData m_PostProcessData = null;
        internal PostProcessData postProcessData => m_PostProcessData;

        protected override ScriptableRenderer Create()
        {
#if UNITY_EDITOR
            if (!Application.isPlaying)
            {
                ResourceReloader.TryReloadAllNullIn(this, UniversalRenderPipelineAsset.packagePath);
                ResourceReloader.TryReloadAllNullIn(m_PostProcessData, UniversalRenderPipelineAsset.packagePath);
            }
#endif
            return new TestRenderer(this);
        }

#if UNITY_EDITOR
        internal static void Create2DRendererData(Action<TestRendererData> onCreatedCallback)
        {
            var instance = CreateInstance<CreateTestRendererDataAsset>();
            instance.onCreated += onCreatedCallback;
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, instance, "New Test Renderer Data.asset", null, null);
        }

        class CreateTestRendererDataAsset : EndNameEditAction
        {
            public event Action<TestRendererData> onCreated;

            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var instance = CreateInstance<TestRendererData>();
                instance.OnCreate();
                AssetDatabase.CreateAsset(instance, pathName);
                Selection.activeObject = instance;

                onCreated(instance);
            }
        }

        void OnCreate()
        {

        }

        protected override void OnEnable()
        {
            base.OnEnable();

            // Provide a list of suggested texture property names to Sprite Editor via EditorPrefs.
            const string suggestedNamesKey = "SecondarySpriteTexturePropertyNames";
            const string maskTex = "_MaskTex";
            const string normalMap = "_NormalMap";
            string suggestedNamesPrefs = EditorPrefs.GetString(suggestedNamesKey);

            if (string.IsNullOrEmpty(suggestedNamesPrefs))
                EditorPrefs.SetString(suggestedNamesKey, maskTex + "," + normalMap);
            else
            {
                if (!suggestedNamesPrefs.Contains(maskTex))
                    suggestedNamesPrefs += ("," + maskTex);

                if (!suggestedNamesPrefs.Contains(normalMap))
                    suggestedNamesPrefs += ("," + normalMap);

                EditorPrefs.SetString(suggestedNamesKey, suggestedNamesPrefs);
            }

            ResourceReloader.TryReloadAllNullIn(this, UniversalRenderPipelineAsset.packagePath);
            ResourceReloader.TryReloadAllNullIn(m_PostProcessData, UniversalRenderPipelineAsset.packagePath);
        }

        //internal override Material GetDefaultMaterial(DefaultMaterialType materialType)
        //{
        //    if (materialType == DefaultMaterialType.Sprite || materialType == DefaultMaterialType.Particle)
        //    {
        //        if (m_DefaultMaterialType == Renderer2DDefaultMaterialType.Lit)
        //            return m_DefaultLitMaterial;
        //        else if (m_DefaultMaterialType == Renderer2DDefaultMaterialType.Unlit)
        //            return m_DefaultUnlitMaterial;
        //        else
        //            return m_DefaultCustomMaterial;
        //    }

        //    return null;
        //}


        //internal override Shader GetDefaultShader()
        //{
        //    return Shader.Find("Universal Render Pipeline/2D/Sprite-Lit-Default");
        //}
#endif
    }
}