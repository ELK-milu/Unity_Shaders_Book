using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomBloom : CustomPostEffectsBase
{
	public Shader BloomShader;
	private Material m_bloomMaterial;
	public Material BaseMaterial
	{
		get
		{
			m_bloomMaterial = CheckShaderAndCreateMaterial(BloomShader, m_bloomMaterial);
			return m_bloomMaterial;
		}
	}
	private RenderTexture buffer0;
	private RenderTexture buffer1;

	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

	// 判断照明区域的亮度阈值
	[Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;
	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null)
		{
			BaseMaterial.SetFloat("_LuminanceThreshold", luminanceThreshold);
			int rtW = source.width;
			int rtH = source.height;

			buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			#region Pass0 : 提取较亮区域
			// buffer0此时存储亮区
			Graphics.Blit(source, buffer0, BaseMaterial, 0);
			#endregion

			#region Pass1 : 垂直模糊
			// buffer1此时存储亮区垂直模糊效果
			BaseMaterial.SetFloat("_BlurSize", 1.0f + 1 * blurSpread);
			buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
			Graphics.Blit(buffer0, buffer1, BaseMaterial, 1);
			RenderTexture.ReleaseTemporary(buffer0);
			buffer0 = buffer1;
			#endregion

			#region Pass2 : 水平模糊
			// buffer1此时存储亮区垂直 + 水平模糊效果
			buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
			Graphics.Blit(buffer0, buffer1, BaseMaterial, 2);
			RenderTexture.ReleaseTemporary(buffer0);
			buffer0 = buffer1;
			#endregion


			#region Pass3 : 混合两张图像
			// buffer0为处理后画面，并用pass3和原画面混合
			BaseMaterial.SetTexture ("_Bloom", buffer0);  
			Graphics.Blit(source,destination,BaseMaterial,3);
			RenderTexture.ReleaseTemporary(buffer0);
			#endregion
		}
		else
		{
			Graphics.Blit(source,destination);
		}
	}
}
