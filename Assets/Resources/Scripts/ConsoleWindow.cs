using UnityEngine;
using System;
using System.Collections;
using System.Runtime.InteropServices;
using System.IO;

namespace ConsoleTestWindows
{
	/// <summary>
	/// Creates a console window that actually works in Unity
	/// You should add a script that redirects output using Console.Write to write to it.
	/// </summary>
	public class ConsoleWindow
	{
		TextWriter oldOutput = null;

		public bool Initialize()
		{
#if UNITY_EDITOR
			return false;
#endif
			//
			// Attach to any existing consoles we have
			// failing that, create a new one.
			//
			if (!AttachConsole(0x0ffffffff))
			{
				AllocConsole();
			}

			oldOutput = Console.Out;

			try
			{
				IntPtr stdHandle = GetStdHandle(STD_OUTPUT_HANDLE);
				Microsoft.Win32.SafeHandles.SafeFileHandle safeFileHandle = new Microsoft.Win32.SafeHandles.SafeFileHandle(stdHandle, true);
				FileStream fileStream = new FileStream(safeFileHandle, FileAccess.Write);
				System.Text.Encoding encoding = System.Text.Encoding.ASCII;
				StreamWriter standardOutput = new StreamWriter(fileStream, encoding);
				standardOutput.AutoFlush = true;
				Console.SetOut(standardOutput);
				return true;
			}
			catch (System.Exception e)
			{
				Debug.Log("Couldn't redirect output: " + e.Message);
				oldOutput = null;
				return false;
			}
		}

		public void Shutdown()
		{
			if (oldOutput != null)
			{
				Console.SetOut(oldOutput);
				FreeConsole();
			}
		}

		public void SetTitle(string strName)
		{
			Debug.Log("this is debug log");
			SetConsoleTitle(strName);
		}

		private const int STD_OUTPUT_HANDLE = -11;

		[DllImport("kernel32.dll", SetLastError = true)]
		static extern bool AttachConsole(uint dwProcessId);

		[DllImport("kernel32.dll", SetLastError = true)]
		static extern bool AllocConsole();

		[DllImport("kernel32.dll", SetLastError = true)]
		static extern bool FreeConsole();

		[DllImport("kernel32.dll", EntryPoint = "GetStdHandle", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
		private static extern IntPtr GetStdHandle(int nStdHandle);

		[DllImport("kernel32.dll")]
		static extern bool SetConsoleTitle(string lpConsoleTitle);
	}
}