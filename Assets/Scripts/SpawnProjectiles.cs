// author: Marcus Xie
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpawnProjectiles : MonoBehaviour
{
    // where the projectile is initially generated
    public GameObject firePoint;
    // prefab of the projectile
    public List<GameObject> vfx = new List<GameObject> ();

    private GameObject effectToSpawn;
    private float timeToFire = 0f;

    void Start()
    {
        effectToSpawn = vfx[0];
    }

    void Update()
    {
        // generate projectiles when mouse is pressed. only allow <fireRate> shots within 1 second
        if (Input.GetMouseButton(0) && Time.time >= timeToFire)
        {
            timeToFire = Time.time + 1f / effectToSpawn.GetComponent<ProjectileMove>().fireRate;
            SpawnVFX();
        }
    }

    void SpawnVFX()
    {
        GameObject vfx;
        if (firePoint != null)
        {
            // generate a projectile at the fire point
            vfx = Instantiate(effectToSpawn, firePoint.transform.position, Quaternion.identity);
            // and align it with the fire point
            vfx.transform.forward = firePoint.transform.forward;
        }
        else
            Debug.Log("Fire Point is not assigned");
    }
}
