using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public RenderTexture m_rtTarget = null;
    public Material m_raymaracherMaterial = null;
    //public Camera m_thisCamera = null;

    private void Awake()
    {
        m_rtTarget = new RenderTexture(Screen.width, Screen.height, 0);
        m_rtTarget.Create();
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Camera m_thisCamera = Camera.current;
        m_raymaracherMaterial.SetMatrix("_FrustumCornersES", GetFrustumCorners(m_thisCamera));
        m_raymaracherMaterial.SetMatrix("_CameraInvViewMatrix", m_thisCamera.cameraToWorldMatrix);
        m_raymaracherMaterial.SetVector("_CameraWS", m_thisCamera.transform.position);

        this.CustomGraphicsBlit(source, destination, m_raymaracherMaterial);
        //this.CustomGraphicsBlit(source, m_rtTarget, m_raymaracherMaterial);
        //Graphics.Blit(m_rtTarget, destination);
    }

    private void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial)
    {
        RenderTexture.active = dest;

        fxMaterial.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        fxMaterial.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }
}
