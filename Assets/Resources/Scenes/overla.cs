using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class overla : MonoBehaviour
{
    public BoxCollider2D bc2d;
    public ContactFilter2D cf2d;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        List<Collider2D> res = new List<Collider2D>();
        if (bc2d.OverlapCollider(cf2d, res) >0)
        {
            foreach (Collider2D r in res)
            {
                //print(r.name + ", " + bc2d.name);
                //if (r.name == bc2d.name)
                //{

                //    continue;
                //}
                print("ok");
            }

        }

    }
}
