using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Windows.Forms;

/// <summary>
/// Cowboy-head icon launcher for Windows Explorer / taskbar.
/// Mirrors Play Cowboy Trail.bat: unpack engine, refresh assets, start the game.
/// Compiles with .NET Framework csc (see tools/build_play_launcher.bat).
/// </summary>
internal static class Program
{
	[STAThread]
	private static void Main()
	{
		try
		{
			string root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
			Directory.SetCurrentDirectory(root);

			string engine = Path.Combine(root, "godot", "Godot_v4.4.1-stable_win64.exe");
			string engineZip = Path.Combine(root, "godot", "Godot_v4.4.1-stable_win64.exe.zip");
			string stampFile = Path.Combine(root, "content_version.txt");
			string cacheStamp = Path.Combine(root, ".godot", "cowboy_trail_content_version.txt");

			if (!File.Exists(engine))
			{
				if (!File.Exists(engineZip))
				{
					Fail("Could not find the bundled Godot engine zip in the godot folder.");
					return;
				}
				string godotFolder = Path.Combine(root, "godot");
				Directory.CreateDirectory(godotFolder);
				// .NET Framework ZipFile has no overwrite flag — clear colliding exe first.
				if (File.Exists(engine))
				{
					try { File.Delete(engine); } catch { }
				}
				ZipFile.ExtractToDirectory(engineZip, godotFolder);
			}
			if (!File.Exists(engine))
			{
				Fail("Could not unpack Godot. Keep the godot folder next to this launcher.");
				return;
			}

			bool needImport = !Directory.Exists(Path.Combine(root, ".godot"))
				|| !File.Exists(stampFile)
				|| !File.Exists(cacheStamp)
				|| !FileContentsEqual(stampFile, cacheStamp);

			if (needImport)
			{
				string godotDir = Path.Combine(root, ".godot");
				if (Directory.Exists(godotDir))
				{
					try { Directory.Delete(godotDir, true); } catch { }
				}
				int import = Run(engine, "--headless --path \"" + root + "\" --import", root);
				if (import != 0)
				{
					Fail("Could not import the game (exit " + import + ").");
					return;
				}
				Directory.CreateDirectory(Path.Combine(root, ".godot"));
				if (File.Exists(stampFile))
				{
					File.Copy(stampFile, cacheStamp, true);
				}
			}

			Process.Start(new ProcessStartInfo
			{
				FileName = engine,
				Arguments = "--path \"" + root + "\"",
				WorkingDirectory = root,
				UseShellExecute = true
			});
		}
		catch (Exception ex)
		{
			Fail(ex.Message);
		}
	}

	private static int Run(string fileName, string args, string workDir)
	{
		ProcessStartInfo info = new ProcessStartInfo
		{
			FileName = fileName,
			Arguments = args,
			WorkingDirectory = workDir,
			UseShellExecute = false,
			CreateNoWindow = true
		};
		Process p = Process.Start(info);
		if (p == null) return -1;
		p.WaitForExit();
		return p.ExitCode;
	}

	private static bool FileContentsEqual(string a, string b)
	{
		byte[] ba = File.ReadAllBytes(a);
		byte[] bb = File.ReadAllBytes(b);
		if (ba.Length != bb.Length) return false;
		for (int i = 0; i < ba.Length; i++)
		{
			if (ba[i] != bb[i]) return false;
		}
		return true;
	}

	private static void Fail(string message)
	{
		MessageBox.Show(message, "Cowboy Trail", MessageBoxButtons.OK, MessageBoxIcon.Error);
	}
}
