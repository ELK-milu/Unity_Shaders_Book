using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralTextureGenerationCopy : MonoBehaviour {
	public Material material = null;

	#region 材质属性
	// SetProperty可以使得面板上的修改也会被属性set到
	[SerializeField, SetProperty("textureWidth")]
	// 纹理大小通常是2的整幂次
	private int m_textureWidth = 512;
	public int textureWidth {
		get {
			return m_textureWidth;
		}
		set {
			m_textureWidth = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("backgroundColor")]
	private Color m_backgroundColor = Color.white;
	public Color backgroundColor {
		get {
			return m_backgroundColor;
		}
		set {
			m_backgroundColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("circleColor")]
	private Color m_circleColor = Color.yellow;
	public Color circleColor {
		get {
			return m_circleColor;
		}
		set {
			m_circleColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("blurFactor")]
	private float m_blurFactor = 2.0f;
	public float blurFactor {
		get {
			return m_blurFactor;
		}
		set {
			m_blurFactor = value;
			_UpdateMaterial();
		}
	}
	#endregion
	private Texture2D m_generatedTexture = null;

	// Use this for initialization
	void Start () {
		if (material == null) {
			Renderer renderer = gameObject.GetComponent<Renderer>();
			if (renderer == null) {
				Debug.LogWarning("Cannot find a renderer.");
				return;
			}

			material = renderer.sharedMaterial;
		}

		_UpdateMaterial();
	}

	// 该函数用于根据Set生成新纹理并应用到Shader的MainTex属性上
	private void _UpdateMaterial() {
		if (material != null) {
			m_generatedTexture = _GenerateProceduralTexture();
			material.SetTexture("_MainTex", m_generatedTexture);
		}
	}
	
	// 混合颜色函数
	private Color _MixColor(Color color0, Color color1, float mixFactor) {
		Color mixColor = Color.white;
		mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
		mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
		mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
		mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
		return mixColor;
	}

	private Texture2D _GenerateProceduralTexture() {
		Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

		// 定义圆点间的间距
		float circleInterval = textureWidth / 4.0f;
		// 定义圆的半径
		float radius = textureWidth / 10.0f;
		// 定义模糊系数
		float edgeBlur = 1.0f / blurFactor;

		// 逐像素绘制
		for (int w = 0; w < textureWidth; w++) {
			for (int h = 0; h < textureWidth; h++) {
				// 初始化背景颜色像素
				Color pixel = backgroundColor;

				// 依次画圆
				for (int i = 0; i < 3; i++) {
					for (int j = 0; j < 3; j++) {
						// 计算圆心坐标
						Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

						// 计算当前像素与圆的距离 = 圆心与像素的欧氏距离 - 半径
						float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

						// 进行边缘模糊
						Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

						// 与边缘颜色再进行颜色混合
						pixel = _MixColor(pixel, color, color.a);
					}
				}

				proceduralTexture.SetPixel(w, h, pixel);
			}
		}

		proceduralTexture.Apply();

		return proceduralTexture;
	}
}
