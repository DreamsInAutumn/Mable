using System;
using System.Drawing;
using System.Drawing.Imaging;
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
                "Usage: splash.exe <image.jpg/gif> <command_file.txt> [speed_multiplier]\n\nExample:\n  splash.exe animation.gif splash.txt 1.5",
                "ImageViewer",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            );
            return;
        }

        string imagePath = args[0];
        string cmdFile = args[1];
        double speed = 1.0;

        if (args.Length >= 3)
        {
            if (!double.TryParse(args[2], System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out speed) || speed <= 0)
            {
                speed = 1.0;
            }
        }

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
        Application.Run(new ImageViewer(imagePath, cmdFile, speed));
    }

    private Image _image;
    private Timer _pollTimer;
    private Timer _gifTimer;
    private string _cmdFile;
    private bool _isDisplayed = false;

    private bool _isAnimated = false;
    private int _frameCount = 1;
    private int _currentFrame = 0;
    private int[] _frameDelays;

    public ImageViewer(string imagePath, string cmdFile, double speed)
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

        InitializeAnimation(speed);

        _pollTimer = new Timer();
        _pollTimer.Interval = 100;
        _pollTimer.Tick += CheckCommandFile;
        _pollTimer.Start();
    }

    private void InitializeAnimation(double speed)
    {
        try
        {
            Guid[] dimensionGuids = _image.FrameDimensionsList;
            if (dimensionGuids.Length > 0)
            {
                FrameDimension dimension = new FrameDimension(dimensionGuids[0]);
                _frameCount = _image.GetFrameCount(dimension);

                if (_frameCount > 1)
                {
                    _isAnimated = true;
                    _frameDelays = new int[_frameCount];

                    PropertyItem item = null;
                    try
                    {
                        item = _image.GetPropertyItem(0x5100);
                    }
                    catch
                    {
                        // Fallback if metadata is missing
                    }

                    for (int i = 0; i < _frameCount; i++)
                    {
                        int delay = 100;

                        if (item != null && item.Value.Length >= (i + 1) * 4)
                        {
                            int rawDelay = BitConverter.ToInt32(item.Value, i * 4);
                            if (rawDelay > 0)
                            {
                                delay = rawDelay * 10;
                            }
                        }

                        int adjustedDelay = (int)(delay / speed);
                        _frameDelays[i] = Math.Max(10, adjustedDelay);
                    }

                    _gifTimer = new Timer();
                    _gifTimer.Interval = _frameDelays[0];
                    _gifTimer.Tick += AdvanceFrame;
                    _gifTimer.Start();
                }
            }
        }
        catch
        {
            _isAnimated = false;
        }
    }

    private void AdvanceFrame(object sender, EventArgs e)
    {
        if (!_isAnimated) return;

        _gifTimer.Stop();

        if (_currentFrame >= _frameCount - 1)
        {
            return;
        }

        _currentFrame++;

        try
        {
            _image.SelectActiveFrame(FrameDimension.Time, _currentFrame);
            this.Invalidate();
        }
        catch
        {
            // Failsafe for frame selection errors
        }

        if (_currentFrame < _frameCount - 1)
        {
            _gifTimer.Interval = _frameDelays[_currentFrame];
            _gifTimer.Start();
        }
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

        if (shouldClose)
        {
            this.Close();
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (_image == null) return;

        Graphics g = e.Graphics;
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
            _gifTimer?.Dispose();
            _image?.Dispose();
        }
        base.Dispose(disposing);
    }
}