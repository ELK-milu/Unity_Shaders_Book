using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CustomPostEffectsBase : MonoBehaviour {
	private bool m_CheckSupportAddition = false;
	// 相较于书中的案例，加入了一些虚方法，子类调用更灵活，甚至直接获取基类再调用同名方法即可
	protected virtual void Start() {
		CheckResources();
	}

	#region 屏幕后处理
	protected virtual void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		throw new NotImplementedException("Virtual Method \"OnRenderImage\" which extends by BaseClass [CustomPostEffectsBase] is not Implemented!!!");
	}
	#endregion
	#region 资源可用性检查
	// 检查shader可用性，并检查该材质是否使用了该shader，若通过检查则返回该材质，否则创建一个新材质
	protected Material CheckShaderAndCreateMaterial (Shader shader, Material material) {
		if (shader == null) return null;
		if (shader.isSupported && material && material.shader == shader) return material;
		if (!shader.isSupported) {
			return null;
		}
		else {
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else
				return null;
		}
	}
	#endregion
	#region 后处理可用性检查
	protected void CheckResources() 
	{
		if (!CheckSupport()) NotSupproted();
	}

	protected void NotSupproted()
	{
		enabled = false;
		throw new Exception("PostProgress is not supported!");
	}

	protected virtual bool SupportAddition() 
	{
		//与 ，有0出0，任意不支持则false
		m_CheckSupportAddition = SystemInfo.supportsImageEffects && SystemInfo.supportsRenderTextures;
		return m_CheckSupportAddition;
	}
	protected bool CheckSupport() 
	{
		if (!SupportAddition()) {
			Debug.LogWarning("This platform doesn't support image effects or render textures");
			return false;
		}
		return true;
	}
	#endregion

}
