using System;
using System.IO;
using System.Configuration;
using System.Globalization;

  /// <summary>
   /// This Class Contains Methods for A Simple Text File Logging Routine
   /// </summary>

   public class WriteLog
   {
      protected static StreamWriter Log;
      protected string strLogFile;

      public WriteLog()
      {
         // Constructor

      }

      public void SetFileName(string strLogFile_1)
      {
         Open(strLogFile_1);
      }

      ~WriteLog()
      {
         // Destructor
         Close();
      }

      /// <summary>
      /// Create a new StreamWriter.
      /// </summary>
      protected void Open(string strLogFile_1)
      {
         // Opens the Log File

         // Get the Name of the Log File  
         strLogFile = strLogFile_1;

         // Set Up a StreamWriter
         Log = new StreamWriter(strLogFile);
      }

      /// <summary>
      /// Method to Purge the Log File
      /// </summary>
      public void Purge()
      {
         // Purges the Log File
         try
         {
            // Log Is Open, Close It
            Close();

            if (File.Exists(strLogFile))
               File.Delete(strLogFile);

            // Re-Open It
            Open(strLogFile);
         }
         catch (Exception)
         {
            // MessageBox.Show("Unable to Purge Log File" + e.Message);
         }
      }

      /// <summary>
      /// Write a message to the log.
      /// </summary>
      /// <param name="message">The message to be written.</param>

      public void Write(string message)
      {
         // Writes a message to the log file

         // Get Date/Time
         DateTime dt = DateTime.Now;
         String date = dt.ToString("G", DateTimeFormatInfo.InvariantInfo);

         // Write Date/Time + Message
         Log.WriteLine(String.Concat(date, " : ", message));

         Log.Flush();
      }

      /// <summary>
      /// Close the log file.
      /// </summary>

      protected void Close()
      {
         try
         {
            Log.Close();
         }
         catch (Exception)
         {
         }
      }
   }
 
