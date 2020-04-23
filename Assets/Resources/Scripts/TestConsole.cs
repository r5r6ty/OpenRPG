using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TestConsole : MonoBehaviour
{
    //public GameObject s;
    public Text t;

    // Start is called before the first frame update
    void Start()
    {
        Application.logMessageReceived += HandleLog;
    }

    // Update is called once per frame
    void Update()
    {

    }

    void OnDisable()
    {
        Application.logMessageReceived -= HandleLog;
    }

    void OnDestroy()
    {
        Application.logMessageReceived -= HandleLog;
    }

    void OnGUI()
    {
        //if (GUILayout.Button("Debug Log: " + (s.activeSelf ? "NO" : "OFF"), GUILayout.Width(120), GUILayout.Height(30)))
        //{
        //    s.SetActive(s.activeSelf ? false : true);
        //}
        if (GUILayout.Button("Clear", GUILayout.Width(60), GUILayout.Height(30)))
        {
            t.text = "";
        }
        if (GUI.Button(new Rect(Screen.width - 60, 0, 60, 30), Time.timeScale == 0 ? "Play" : "Pause"))
        {
            Time.timeScale = Time.timeScale == 0 ? 1 : 0;
        }
    }

    void HandleLog(string message, string stackTrace, LogType type)
    {
        //if (Application.isEditor)
        //    return;
        if (type == LogType.Exception || type == LogType.Error)
        {
            CreateMessage(type.ToString() + ":" + message + "\n stack: " + stackTrace);
            Time.timeScale = 0;
            Application.logMessageReceived -= HandleLog;
        }
        else if (type == LogType.Log)
        {
            CreateMessage(message);
        }

        //System.IO.StreamWriter writer;
        //System.IO.FileInfo file = new System.IO.FileInfo(Application.dataPath + "/log.txt");
        //if (!file.Exists)
        //{
        //    writer = file.CreateText();
        //}
        //else
        //{
        //    writer = file.AppendText();
        //}
        //writer.WriteLine(message);
        //writer.Flush();
        //writer.Dispose();
        //writer.Close();
    }

    void CreateMessage(string txt)
    {
        t.text += txt + "\n";
    }

    private static void HandleLog2(string message, string stackTrace, LogType type)
    {
        if (type == LogType.Exception || type == LogType.Error)
        {
            System.Console.WriteLine(type.ToString() + ":" + message + "\n stack: " + stackTrace);
            Time.timeScale = 0;
            Application.logMessageReceived -= HandleLog2;
        }
        else if (type == LogType.Log)
        {
            System.Console.WriteLine(message);
        }
    }

    public static void Start2()
    {
        Application.logMessageReceived += HandleLog2;
    }
}