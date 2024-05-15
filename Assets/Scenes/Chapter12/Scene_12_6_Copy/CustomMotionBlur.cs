using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomMotionBlur : CustomPostEffectsBase
{
	public Shader MotionBlurShader;
	private Material m_motionBlurMaterial = null;
	public Material BaseMaterial {  
		get {
			m_motionBlurMaterial = CheckShaderAndCreateMaterial(MotionBlurShader, m_motionBlurMaterial);
			return m_motionBlurMaterial;
		}  
	}
	
	[Range(0.0f, 0.9f)]
	public float BlurAmount = 0.5f;
	
	// 用于保存上一帧渲染结果的RT
	private RenderTexture m_accumulationTexture;

	//为了在开启后重新叠加图像(避免关闭脚本之前的画面错误叠加)需要摧毁RT
	private void OnDisable()
	{
		DestroyImmediate(m_accumulationTexture);
	}

	// 检查保存渲染结果的RT是否可用（为空且尺寸与画面帧相符）
	bool IsAccumulationTextureAvailable(RenderTexture source)
	{
		return (m_accumulationTexture == null 
		       || m_accumulationTexture.width != source.width 
		       || m_accumulationTexture.height != source.height);
	}
	
	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null)
		{
			if (IsAccumulationTextureAvailable(source))
			{
				// 若不可用则重建RT并渲染
				DestroyImmediate(m_accumulationTexture);
				m_accumulationTexture =new RenderTexture(source.width, source.height, 0);
				m_accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
				Graphics.Blit(source, m_accumulationTexture);
			}
			//通常在对目标RT再次渲染时，需要先清除之前渲染的内容(例如ReleaseTemporary或者DiscardContents)
			//调用下面函数后则不会对未清除内容的RT再渲染时报错(新版本已弃用该函数)
			m_accumulationTexture.MarkRestoreExpected();

			BaseMaterial.SetFloat("_BlurAmount", 1.0f - BlurAmount);

			// 将当前帧画面和之前累加的画面进行shader处理
			Graphics.Blit (source, m_accumulationTexture, BaseMaterial);
			// 最后渲染到目标帧
			Graphics.Blit (m_accumulationTexture, destination);
		}
		else
		{
			Graphics.Blit(source,destination);
		}
	}

}
