using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomEdgeDetection : CustomPostEffectsBase
{
	public Shader EdgeDectecShader;
	private Material m_edgeDectecShader;
	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;

	public Color edgeColor = Color.black;
	
	public Color backgroundColor = Color.white;
	public Material BaseMaterial
	{
		get
		{
			m_edgeDectecShader = CheckShaderAndCreateMaterial(EdgeDectecShader, m_edgeDectecShader);
			return m_edgeDectecShader;
		}
	}
	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null)
		{
			BaseMaterial.SetFloat("_EdgeOnly", edgesOnly);
			BaseMaterial.SetColor("_EdgeColor", edgeColor);
			BaseMaterial.SetColor("_BackgroundColor", backgroundColor);
			Graphics.Blit(source,destination,BaseMaterial);
		}
		else
		{
			Graphics.Blit(source,destination);
		}
	}
}
