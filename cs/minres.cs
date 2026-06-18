using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

// WindowState.exe Minimize   -> minimizes the current foreground window
// WindowState.exe Restore    -> restores any WindowsTerminal / WindowsTerminalPreview window
//
// Compile on Linux targeting Windows (no console window pops up, matching the
// original "> nul 2>&1" hidden behavior):
//   mcs -target:winexe -out:WindowState.exe -r:System.dll WindowState.cs
//
// Run on Windows:
//   WindowState.exe Minimize
//   WindowState.exe Restore

class WindowState
{
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    private const int SW_MINIMIZE = 6;
    private const int SW_RESTORE = 9;

    private static readonly string[] TerminalProcessNames =
    {
        "WindowsTerminal",
        "WindowsTerminalPreview"
    };

    static int Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.Error.WriteLine("Usage: WindowState.exe [Minimize|Restore]");
            return 1;
        }

        switch (args[0].ToLowerInvariant())
        {
            case "minimize":
                MinimizeForegroundWindow();
                break;

            case "restore":
                RestoreTerminalWindows();
                break;

            default:
                Console.Error.WriteLine("Unknown argument: " + args[0]);
                Console.Error.WriteLine("Expected 'Minimize' or 'Restore'.");
                return 1;
        }

        return 0;
    }

    private static void MinimizeForegroundWindow()
    {
        IntPtr hWnd = GetForegroundWindow();
        if (hWnd != IntPtr.Zero)
        {
            ShowWindow(hWnd, SW_MINIMIZE);
        }
    }

    private static void RestoreTerminalWindows()
    {
        foreach (string name in TerminalProcessNames)
        {
            Process[] procs;
            try
            {
                procs = Process.GetProcessesByName(name);
            }
            catch
            {
                continue;
            }

            foreach (Process proc in procs)
            {
                try
                {
                    if (proc.MainWindowHandle != IntPtr.Zero)
                    {
                        ShowWindow(proc.MainWindowHandle, SW_RESTORE);
                    }
                }
                catch
                {
                    // Ignore inaccessible/exited processes
                }
                finally
                {
                    proc.Dispose();
                }
            }
        }
    }
}