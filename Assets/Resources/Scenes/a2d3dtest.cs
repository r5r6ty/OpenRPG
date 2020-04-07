using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class a2d3dtest : MonoBehaviour
{

    public LineRenderer lr;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        //RaycastHit result;
        //if (Physics.Raycast(ray, out result, 15))
        //{
        //    lr.SetPosition(0, ray.origin);
        //    lr.SetPosition(1, result.point);
        //}
        //else
        //{
        //    lr.SetPosition(0, ray.origin);
        //    lr.SetPosition(1, ray.origin + ray.direction * 15);
        //}

        RaycastHit2D result = Physics2D.GetRayIntersection(ray, 15);

        if (result.collider != null)
        {
            print(result.collider.bounds.size);
            lr.SetPosition(0, ray.origin);
            lr.SetPosition(1, new Vector3(result.point.x, result.point.y, result.collider.transform.position.z));
        }
        else
        {
            lr.SetPosition(0, ray.origin);
            lr.SetPosition(1, ray.origin + ray.direction * 15);
        }
    }
}
