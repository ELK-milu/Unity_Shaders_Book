using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomGaussianBlur : CustomPostEffectsBase
{
	public Shader GaussianBlurShader;
	private Material m_gaussianBlurMaterial;
	public Material BaseMaterial
	{
		get
		{
			m_gaussianBlurMaterial = CheckShaderAndCreateMaterial(GaussianBlurShader, m_gaussianBlurMaterial);
			return m_gaussianBlurMaterial;
		}
	}
	[Range(0.2f, 3.0f)]
	public float BlurSize = 0.6f;
	private RenderTexture buffer0;
	private RenderTexture buffer1;

	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null)
		{
			int rtW = source.width;
			int rtH = source.height;

			BaseMaterial.SetFloat("_BlurSize", BlurSize);
			// 先渲染到buffer0
			buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			Graphics.Blit(source, buffer0,BaseMaterial,0);
			// 再渲染到buffer1
			buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
			Graphics.Blit(buffer0, buffer1, BaseMaterial, 1);
			// 最后渲染到屏幕
			Graphics.Blit(buffer1, destination);

			RenderTexture.ReleaseTemporary(buffer0);
			RenderTexture.ReleaseTemporary(buffer1);
		} else {
			Graphics.Blit(source, destination);
		}
	}

}
