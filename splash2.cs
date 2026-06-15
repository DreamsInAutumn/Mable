using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

public class ImageViewer : Form
{
    [STAThread]
    public static void Main(string[] args)
    {
        if (args.Length < 2)
        {
            MessageBox.Show(
                "Usage: splash.exe <image.jpg> <command_file.txt>\n\nExample:\n  splash.exe photo.jpg splash.txt",
                "ImageViewer",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            );
            return;
        }

        string imagePath = args[0];
        string cmdFile = args[1];

        if (!File.Exists(imagePath))
        {
            MessageBox.Show(
                "File not found:\n" + imagePath,
                "ImageViewer Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            );
            return;
        }

        // Always clear the file on startup
        try
        {
            File.WriteAllText(cmdFile, "");
        }
        catch
        {
            // Ignore if locked
        }

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new ImageViewer(imagePath, cmdFile));
    }

    private Image _image;
    private Timer _pollTimer;
    private string _cmdFile;
    private bool _isDisplayed = false;

    public ImageViewer(string imagePath, string cmdFile)
    {
        _cmdFile = cmdFile;
        _image = Image.FromFile(imagePath);

        this.FormBorderStyle = FormBorderStyle.None;
        this.TopMost          = true;
        this.StartPosition    = FormStartPosition.CenterScreen;
        this.BackColor        = Color.Black;
        this.DoubleBuffered   = true;

        this.Opacity = 0;
        this.ShowInTaskbar = false;

        Rectangle screen = Screen.PrimaryScreen.WorkingArea;
        int w = Math.Min(_image.Width,  screen.Width);
        int h = Math.Min(_image.Height, screen.Height);
        this.ClientSize = new Size(w, h);

        this.KeyPreview = true;
        this.KeyDown   += (s, e) => { if (e.KeyCode == Keys.Escape) this.Close(); };
        this.MouseClick += (s, e) => this.Close();

        _pollTimer = new Timer();
        _pollTimer.Interval = 100;
        _pollTimer.Tick += CheckCommandFile;
        _pollTimer.Start();
    }

    private void CheckCommandFile(object sender, EventArgs e)
    {
        bool shouldClose = false;

        try
        {
            using (var fs = new FileStream(_cmdFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var sr = new StreamReader(fs))
            {
                string cmd = sr.ReadToEnd().Trim().ToLower();

                if (cmd == "quit")
                {
                    shouldClose = true;
                }
                else if (cmd == "display" && !_isDisplayed)
                {
                    _isDisplayed = true;
                    this.Opacity = 1;
                    this.ShowInTaskbar = true;
                }
            }
        }
        catch
        {
            // Ignore temporary file-lock exceptions
        }

        // Close after the file lock is released
        if (shouldClose)
        {
            this.Close();
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (_image == null) return;

        Graphics g   = e.Graphics;
        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;

        float scaleX = (float)ClientSize.Width  / _image.Width;
        float scaleY = (float)ClientSize.Height / _image.Height;
        float scale  = Math.Min(scaleX, scaleY);

        int dw = (int)(_image.Width  * scale);
        int dh = (int)(_image.Height * scale);
        int dx = (ClientSize.Width  - dw) / 2;
        int dy = (ClientSize.Height - dh) / 2;

        g.DrawImage(_image, dx, dy, dw, dh);
    }

    protected override void OnFormClosed(FormClosedEventArgs e)
    {
        try
        {
            if (File.Exists(_cmdFile))
            {
                File.Delete(_cmdFile);
            }
        }
        catch 
        { 
            // Failsafe
        }
        
        base.OnFormClosed(e);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _pollTimer?.Dispose();
            _image?.Dispose();
        }
        base.Dispose(disposing);
    }
}