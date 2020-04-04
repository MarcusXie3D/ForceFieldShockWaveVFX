// author: Marcus Xie
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProjectileMove : MonoBehaviour
{
    public float speed;
    // controls how many projectiles are generated in 1 sec, which takes effect in SpawnProjectiles.cs
    public float fireRate;
    public GameObject muzzlePrefab;
    public GameObject hitPrefab;

    // Start() is provoked every time a projectile comes out
    void Start()
    {
        if (muzzlePrefab != null)
        {
            // when a projectile comes out, generate a muzzle on its starting point
            var muzzleVFX = Instantiate(muzzlePrefab, transform.position, Quaternion.identity);
            // align the muzzle with the projectile
            muzzleVFX.transform.forward = transform.forward;
            var psMuzzle = muzzleVFX.GetComponent<ParticleSystem>();
            // the muzzle only flashes one time, and lasts one period (duration) of its particle system
            // after the duration, it needs to be destroyed
            if (psMuzzle != null)
                Destroy(muzzleVFX, psMuzzle.main.duration);
            else
            {
                var psChild = muzzleVFX.transform.GetChild(0).GetComponent<ParticleSystem>();
                Destroy(muzzleVFX, psChild.main.duration);
            }
        }
    }

    void Update()
    {
        if (speed != 0)
        {
            transform.position += transform.forward * (speed * Time.deltaTime);
        }
        else
            Debug.Log("Speed is not set yet");
    }

    void OnCollisionEnter(Collision co)
    {
        speed = 0f;

        ContactPoint contact = co.contacts[0];
        Quaternion rot = Quaternion.FromToRotation(Vector3.up, contact.normal);
        Vector3 pos = contact.point;

        GameObject theObj = co.gameObject;

        if (hitPrefab != null && !theObj.gameObject.tag.Equals("ForceField"))
        {
            // generate a hit effect where the surface was hit by the projectile
            // align the hit effect with the normal of the surface
            var hitVFX = Instantiate(hitPrefab, pos, rot);
            var psHit = hitVFX.GetComponent<ParticleSystem>();
            // the hit effect only flashes one time, and lasts one period (duration) of its particle system
            // after the duration, it needs to be destroyed
            if (psHit != null)
                Destroy(hitVFX, psHit.main.duration);
            else
            {
                var psChild = hitVFX.transform.GetChild(0).GetComponent<ParticleSystem>();
                Destroy(hitVFX, psChild.main.duration);
            }
        }

        Destroy(gameObject);
    }
}
