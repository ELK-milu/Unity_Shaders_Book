using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomMotionBlurWithDepthTexture : CustomPostEffectsBase
{
	public Shader BlurShader;
	private Material m_blurMaterial;
	public Material BaseMaterial
	{
		get
		{
			m_blurMaterial = CheckShaderAndCreateMaterial(BlurShader, m_blurMaterial);
			return m_blurMaterial;
		}
	}
	private Camera myCamera;
	public Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}
	[Range(0.0f, 1.0f)]
	public float blurSize = 0.5f;
	private Matrix4x4 previousViewProjectionMatrix;

	
	void OnEnable() {
		// 获取深度值
		camera.depthTextureMode |= DepthTextureMode.Depth;

		// 当开启时计算当前帧的vp矩阵
		previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
	}
	override protected void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
		if (BaseMaterial != null) {
			BaseMaterial.SetFloat("_BlurSize", blurSize);

			// 每帧开始渲染时将上一次获取的vp矩阵作为上一帧的vp矩阵传入shader
			BaseMaterial.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			// 当前帧的vp矩阵再计算
			Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
			// 获取当前帧的vp矩阵的逆矩阵
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			// 当前帧的vp矩阵的逆矩阵传入shader
			BaseMaterial.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			// 在传入结束后将当前帧获取的vp矩阵作为下次渲染的prevVP矩阵
			previousViewProjectionMatrix = currentViewProjectionMatrix;

			// 我算是知道为什么要在C#里计算矩阵了，比shader中计算方便太多
			Graphics.Blit (source, destination, BaseMaterial);
		} else {
			Graphics.Blit(source, destination);
		}
	}
}
