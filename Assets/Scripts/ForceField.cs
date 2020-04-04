// author: Marcus Xie
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForceField : MonoBehaviour
{
    private Material mat;
    public float waveTime = 0.4f;
    private Coroutine coro;
    private bool flag = false;

    void Start()
    {
        mat = GetComponent<Renderer>().material;
        mat.SetFloat("_WaveScale", 0.0f);
        flag = false;
    }

    void OnCollisionEnter(Collision colli)
    {
        ContactPoint contact = colli.contacts[0];
        Vector3 pos = contact.point;
        mat.SetVector("_CollisionPos", pos);
        // if it gets hit while the previous wave is still going on, stop the previous wave
        if(flag)
            StopCoroutine(coro);
        coro = StartCoroutine(OneShotOfWave());
        flag = true;
    }

    IEnumerator OneShotOfWave()
    {
        float i = 0f;
        float rate = 1f / waveTime;
        while (i < 1f)
        {
            i += Time.deltaTime * rate;
            mat.SetFloat("_WaveScale", 1.0f - i);
            yield return 0;
        }
        mat.SetFloat("_WaveScale", 0.0f);
    }
}
