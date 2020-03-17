using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestCollider2D : MonoBehaviour
{
    public CircleCollider2D c;

    public BoxCollider2D d;

    // Start is called before the first frame update
    void Start()
    {
        print(c.bounds.center);
        print(c.bounds.size);
        print(c.bounds.extents);
        print(c.bounds.max);
        print(c.bounds.min);
    }

    // Update is called once per frame
    void Update()
    {
        if(c.bounds.Intersects(d.bounds))
        {
            print("aaaaaaaaaaaaaa");
        }
    }
}
