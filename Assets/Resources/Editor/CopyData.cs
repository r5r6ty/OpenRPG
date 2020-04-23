using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using UnityEditor;
using UnityEngine;

public static class CopyData
{
    [MenuItem("OpenRPG/CopyDataAndRun", false, 1)]
    public static void CopyData_Run()
    {
        CopyDirectory(Application.dataPath + @"\StreamingAssets\", @"D:\uppp\OpenRPG\OpenRPG_Data\StreamingAssets\", true);

        try
        {
            //var process2 = new Process
            //{
            //    StartInfo =
            //    {
            //        FileName = "cmd.exe",
            //        //Arguments = "/k" + cmd,
            //        CreateNoWindow = false,
            //    }
            //};
            //try
            //{
            //    process2.Start();
            //    process2.WaitForExit();

            //}
            //catch (Exception e)
            //{
            //    UnityEngine.Debug.Log(e.Message);
            //}
            //finally
            //{
            //    process2.Close();
            //}

            //Process process = new Process();
            //process.StartInfo.FileName = @"D:\uppp\OpenRPG\OpenRPG.exe";
            //process.StartInfo.UseShellExecute = false;
            //process.StartInfo.CreateNoWindow = true;
            //process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            ////process.StartInfo.Arguments = param0 + " " + param1 + " " + param2;
            //process.EnableRaisingEvents = true;
            //process.Start();
            //process.WaitForExit();
            //UnityEngine.Debug.Log("Close OpenRPG.exe");
            //int ExitCode = process.ExitCode;
            //print(ExitCode);

            Application.OpenURL(@"D:\uppp\OpenRPG\OpenRPG.exe");
        }
        catch (Exception e)
        {
            UnityEngine.Debug.LogError(e.Message);
        }
    }

    private static bool CopyDirectory(string SourcePath, string DestinationPath, bool overwriteexisting)
    {
        bool ret;
        try
        {
            SourcePath = SourcePath.EndsWith(@"\") ? SourcePath : SourcePath + @"\";
            DestinationPath = DestinationPath.EndsWith(@"\") ? DestinationPath : DestinationPath + @"\";

            if (Directory.Exists(SourcePath))
            {
                if (Directory.Exists(DestinationPath) == false)
                    Directory.CreateDirectory(DestinationPath);

                foreach (string fls in Directory.GetFiles(SourcePath))
                {
                    FileInfo flinfo = new FileInfo(fls);
                    if (flinfo.Extension != ".meta")
                        flinfo.CopyTo(DestinationPath + flinfo.Name, overwriteexisting);
                }
                foreach (string drs in Directory.GetDirectories(SourcePath))
                {
                    DirectoryInfo drinfo = new DirectoryInfo(drs);
                    if (CopyDirectory(drs, DestinationPath + drinfo.Name, overwriteexisting) == false)
                        ret = false;
                }
            }
            ret = true;
        }
        catch (Exception ex)
        {
            UnityEngine.Debug.LogError(ex.Message);
            ret = false;
        }
        return ret;
    }
}
