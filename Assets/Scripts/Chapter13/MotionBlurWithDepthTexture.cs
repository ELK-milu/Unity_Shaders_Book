using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
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
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_BlurSize", blurSize);

			// 每帧开始渲染时将上一次获取的vp矩阵作为上一帧的vp矩阵传入shader
			material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			// 当前帧的vp矩阵再计算
			Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
			// 获取当前帧的vp矩阵的逆矩阵
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			// 当前帧的vp矩阵的逆矩阵传入shader
			material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			// 在传入结束后将当前帧获取的vp矩阵作为下次渲染的prevVP矩阵
			previousViewProjectionMatrix = currentViewProjectionMatrix;

			// 我算是知道为什么要在C#里计算矩阵了，比shader中计算方便太多
			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
