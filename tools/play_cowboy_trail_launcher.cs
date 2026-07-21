using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Media;
using System.Threading;
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
		LoadingForm loading = null;
		SoundPlayer loadingMusic = null;
		try
		{
			string root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
			Directory.SetCurrentDirectory(root);

			// This launcher runs the game from the project files next to it, so it must
			// stay inside the Cowboy Trail folder. If it was copied out on its own, the
			// game files are missing — explain that instead of failing on the engine.
			if (!File.Exists(Path.Combine(root, "project.godot")))
			{
				Fail("The Cowboy Trail game files were not found next to this launcher.\n\n"
					+ "Keep \"Play Cowboy Trail.exe\" inside the Cowboy Trail folder.\n\n"
					+ "To play from anywhere, build the portable game with create_exe.bat and copy CowboyTrail.exe instead.");
				return;
			}
			Application.EnableVisualStyles();
			loading = new LoadingForm(root);
			loading.Show();
			Application.DoEvents();
			string musicPath = Path.Combine(root, "assets", "audio", "cheerful_cowboy_trail.wav");
			if (File.Exists(musicPath))
			{
				try
				{
					loadingMusic = new SoundPlayer(musicPath);
					loadingMusic.PlayLooping();
				}
				catch { }
			}

			string engine = Path.Combine(root, "godot", "Godot_v4.4.1-stable_win64.exe");
			string engineZip = Path.Combine(root, "godot", "Godot_v4.4.1-stable_win64.exe.zip");
			string stampFile = Path.Combine(root, "content_version.txt");
			string cacheStamp = Path.Combine(root, ".godot", "cowboy_trail_content_version.txt");

			if (!File.Exists(engine))
			{
				loading.SetStatus("Unpacking the saddle bags...");
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
				loading.SetStatus("Painting the Wild West...");
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

			loading.SetStatus("Starting the trail...");
			Application.DoEvents();
			Process.Start(new ProcessStartInfo
			{
				FileName = engine,
				Arguments = "--path \"" + root + "\"",
				WorkingDirectory = root,
				UseShellExecute = true
			});
			Thread.Sleep(250);
		}
		catch (Exception ex)
		{
			Fail(ex.Message);
		}
		finally
		{
			if (loadingMusic != null)
			{
				try { loadingMusic.Stop(); } catch { }
				loadingMusic.Dispose();
			}
			if (loading != null)
			{
				loading.Close();
				loading.Dispose();
			}
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
		while (!p.HasExited)
		{
			Application.DoEvents();
			Thread.Sleep(40);
		}
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

internal sealed class LoadingForm : Form
{
	private readonly Label status;

	internal LoadingForm(string root)
	{
		Text = "Cowboy Trail";
		FormBorderStyle = FormBorderStyle.FixedDialog;
		StartPosition = FormStartPosition.CenterScreen;
		ClientSize = new Size(620, 300);
		BackColor = Color.FromArgb(237, 151, 67);
		ControlBox = false;
		ShowInTaskbar = true;
		var title = new Label
		{
			Text = "COWBOY TRAIL",
			Font = new Font(FontFamily.GenericSerif, 30, FontStyle.Bold),
			ForeColor = Color.FromArgb(85, 35, 12),
			TextAlign = ContentAlignment.MiddleCenter,
			Bounds = new Rectangle(20, 38, 580, 70)
		};
		Controls.Add(title);
		status = new Label
		{
			Text = "Saddling up...",
			Font = new Font(FontFamily.GenericSansSerif, 17, FontStyle.Bold),
			ForeColor = Color.FromArgb(105, 48, 18),
			TextAlign = ContentAlignment.MiddleCenter,
			Bounds = new Rectangle(20, 185, 580, 55)
		};
		Controls.Add(status);
		string iconPath = Path.Combine(root, "icon.png");
		if (File.Exists(iconPath))
		{
			try
			{
				var picture = new PictureBox
				{
					Image = Image.FromFile(iconPath),
					SizeMode = PictureBoxSizeMode.Zoom,
					Bounds = new Rectangle(270, 105, 80, 80)
				};
				Controls.Add(picture);
				picture.BringToFront();
			}
			catch { }
		}
	}

	internal void SetStatus(string text)
	{
		status.Text = text;
		Application.DoEvents();
	}
}
