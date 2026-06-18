using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

class IniReader
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetPrivateProfileString(
        string lpAppName,
        string lpKeyName,
        string lpDefault,
        StringBuilder lpReturnedString,
        uint nSize,
        string lpFileName);

    // Overload to retrieve all keys in a section by passing null for lpKeyName
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetPrivateProfileString(
        string lpAppName,
        string lpKeyName,
        IntPtr lpDefault,
        byte[] lpReturnedString,
        uint nSize,
        string lpFileName);

    static int Main(string[] args)
    {
        if (args.Length < 3)
        {
            Console.Error.WriteLine("Error: Missing arguments.");
            Console.Error.WriteLine("Usage: IniReader.exe <path_to_ini> <section> <key>");
            return 1; // Invalid Arguments
        }

        string iniPath = Path.GetFullPath(args[0]);
        string section = args[1];
        string key = args[2];

        // 1. Verify file existence
        if (!File.Exists(iniPath))
        {
            Console.Error.WriteLine("Error: File not found: " + iniPath);
            return 2; // File Not Found
        }

        // 2. Verify section existence
        if (!SectionExists(section, iniPath))
        {
            Console.Error.WriteLine("Error: Section [" + section + "] not found.");
            return 3; // Section Not Found
        }

        // 3. Verify key existence and retrieve value
        // We use a unique Guid string as the default value to detect missing keys
        string sentinelDefault = "KEY_NOT_FOUND_" + Guid.NewGuid().ToString();
        StringBuilder buffer = new StringBuilder(2048);
        
        GetPrivateProfileString(section, key, sentinelDefault, buffer, (uint)buffer.Capacity, iniPath);
        string result = buffer.ToString();

        if (result == sentinelDefault)
        {
            Console.Error.WriteLine("Error: Key '" + key + "' not found in section [" + section + "].");
            return 4; // Key Not Found
        }

        // Output the value to stdout and exit successfully
        Console.Write(result);
        return 0;
    }

    private static bool SectionExists(string section, string filePath)
    {
        // Passing null for lpKeyName returns all keys in the section as null-terminated strings
        byte[] buffer = new byte[32768];
        uint bytesRead = GetPrivateProfileString(section, null, IntPtr.Zero, buffer, (uint)buffer.Length, filePath);
        
        // If the section doesn't exist, the API returns 0 (or 1-2 bytes of noise/nulls depending on OS)
        return bytesRead > 0;
    }
}