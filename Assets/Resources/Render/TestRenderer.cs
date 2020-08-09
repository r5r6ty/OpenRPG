using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experimental.Rendering.Universal
{
    internal class TestRenderer : ScriptableRenderer
    {
        public TestRenderer(TestRendererData data) : base(data)
        {

        }

        public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
        {

        }
    }
}