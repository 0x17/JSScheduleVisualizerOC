using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UpdateOnChange
{
    class Program
    {
        private static DateTime lastUpdate = DateTime.MinValue;

        static void Main(string[] args)
        {
            var filters = NotifyFilters.CreationTime | NotifyFilters.LastWrite;
            var watcher = new FileSystemWatcher { Path=".", NotifyFilter = filters, IncludeSubdirectories = false, EnableRaisingEvents = true, Filter = "modelcli.gms" };
            watcher.Changed += OnChanged;
            Console.ReadKey();
        }

        private static void OnChanged(object sender, FileSystemEventArgs e)
        {
            if ((DateTime.Now - lastUpdate).Seconds > 5)
            {
                Console.WriteLine(e.Name);
                Console.WriteLine(e.FullPath);
                Console.WriteLine(e.ChangeType);
                Console.WriteLine("File modified, rerun update.bat...");
                ExecuteCommand("update");
                lastUpdate = DateTime.Now;
            }

            
        }

        static void ExecuteCommand(string command)
        {
            ProcessStartInfo processInfo;
            Process process;
            processInfo = new ProcessStartInfo(/*"cmd.exe"*/ "sh", "/c " + command);
            processInfo.CreateNoWindow = true;
            processInfo.UseShellExecute = true;
            processInfo.RedirectStandardError = false;
            processInfo.RedirectStandardOutput = false;
            process = Process.Start(processInfo);
            process.WaitForExit();
            process.Close();
        }
    }
}
