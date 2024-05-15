using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class CustomBrightnessSaturationAndContrast : CustomPostEffectsBase
{
	public Shader BriSatConShader;
	private Material m_briSatConMaterial;
	public Material BaseMaterial 
	{
		get 
		{
			m_briSatConMaterial = CheckShaderAndCreateMaterial(BriSatConShader, m_briSatConMaterial);
			return m_briSatConMaterial;
		}
	}
	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;
	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;
	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;

	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null)
		{
			BaseMaterial.SetFloat("_Brightness",brightness);
			BaseMaterial.SetFloat("_Saturation",saturation);
			BaseMaterial.SetFloat("_Contrast",contrast);
			
			Graphics.Blit(source,destination,BaseMaterial);
		}
		else
		{
			Graphics.Blit(source,destination);
		}
	}
}
