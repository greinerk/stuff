//////////////////////////////////////////////////////////////////////////////
// SchemaGenerator
//
//     This Program Generates Schema For Views, Procs, UDFs, Tables, Roles, Etc.
//     Across A SQL Instance and Databases.  Uses SMO in SQL 2005.
//     
//     Requirements:  Visual Studio Studio 2005 [Database Engine: SQL Server 2005]
//    
//     History
//     -------
//
//     Version     Date      Author     Change
//     ---------------------------------------
//     1           3.24.06   J. Jakob   Created
//////////////////////////////////////////////////////////////////////////////

using System;
using System.Collections;
using System.Text;
using Microsoft.SqlServer.Management.Smo;
using System.Data;
using System.Collections.Specialized;  // For StringCollection
using System.IO;
using System.Data.SqlClient;
using System.Globalization;

namespace DBASchemaGenerator
{
   class Program
   {
      protected const string zTABLES     = "TABLES";           // T-SQL Tables
      protected const string zPROCEDURES = "PROCEDURES";       // T-SQL Stored Procedures
      protected const string zVIEWS      = "VIEWS";            // T-SQL Views
      protected const string zFUNCTIONS  = "FUNCTIONS";        // T-SQL UDFs
      protected const string zROLES      = "ROLES";            // Database Roles
      protected const string zDATABASE   = "DATABASE";         // Entire Database Schema

      // BASEPATH: The Base Path File Spec. Is In the "App.Config" Configuration File
      //  NOTE: You will need to add A Project Reference to "System.configuration"
      //        or You'll Get An Error Here!
      protected static string glBASEPATH
          = System.Configuration.ConfigurationManager.AppSettings["zBASEPATH"];

      // The Log File
      protected static WriteLog LOG = new WriteLog();

      static void Main(string[] args)
      {
         // This is the Main Program Logic

         // Initialize, and Get the SQL Instance We Need to Process
         string strSQLInstance = Initialize(args);

         // Valid Instance?
         if (strSQLInstance != "")
         {
            // YES -- Go Collect the Schema!
            CollectSchema(strSQLInstance);
         }
      }

      protected static void CollectSchema(string strSQLInstance)
      {
         // Collects the Schema For the [strSQLInstance] SQL Instance

         ////////////////////////////////////////////////////////////
         // First Try to Connect to the Server for this Instance...
         ////////////////////////////////////////////////////////////
         Server theServer = null;
         bool bConnectedOK = ConnectToSQLInstance(ref theServer, strSQLInstance);

         // If We Were We Able to Connect to the Server, Continue...
         if (bConnectedOK)
         {
            ///////////////////////////////////////
            // For Each Database On the Instance...
            ///////////////////////////////////////
            foreach (Database db in theServer.Databases)
            {
               // We Skip System Databases, [pubs], [Northwind], And Other Databases
               //    That We Don't Care About!!!
               if (! db.IsSystemObject
               && db.Name != "pubs"
               && db.Name != "Northwind")
               {
                  // Show the Name of the Database
                  WriteStatus(false, ">> DATABASE: " + db.Name);

                  // Build the Full Path for the Output.  
                  //   We Replace the "\" In SQL Named Instances With "~", Since Our File-System
                  //   Doesn't Allow Directory Names With the "\" Character In Them!
                  string strFullPath = glBASEPATH + @"\"
                                     + strSQLInstance.Replace(@"\", "~") + @"\"
                                     + db.Name;

                  // Script Out Tables to Individual Files
                  ScriptTablesInDB(theServer, db, strFullPath + @"\" + zTABLES);

                  // Script Out User-Defined Functions to Individual Files 
                  ScriptFunctionsInDB(theServer, db, strFullPath + @"\" + zFUNCTIONS);

                  // Script Out Views to Individual Files 
                  ScriptViewsInDB(theServer, db, strFullPath + @"\" + zVIEWS);

                  // Script Out Stored Procedures to Individual Files  
                  ScriptProcsInDB(theServer, db, strFullPath + @"\" + zPROCEDURES);

                  // Script Out Roles to Individual Files 
                  ScriptRolesInDB(theServer, db, strFullPath + @"\" + zROLES);                 
               }
            }
         }
      }

      protected static bool ConnectToSQLInstance(ref Server theServer, string strDBMSInstanceName)
      {
         //
         // We Use SQL DMO to Try to Create a Server Connection [theServer] 
         //    for a Given SQL Instance...
         //

         // Tell User What We Are Doing
         WriteStatus(false, "Attempting Connection: " + strDBMSInstanceName);

         int ErrorCount = 0;
         try
         {
            // Create A Server Instance
            theServer = new Server(strDBMSInstanceName);

            // DEBUG -- TRY THIS TO SPEED THINGS UP
            // theServer.SetDefaultInitFields(true);
            theServer.SetDefaultInitFields(typeof(Table), true);  // For Tables, Try Loading All Defaults

         }
         catch (Exception e)
         {
            // We Were Unable to Create the Instance
            ErrorCount++;

            WriteStatus(false, "**** ERROR: Unable to Create Server Instance: " + strDBMSInstanceName
                  + "\r\nERROR: " + e.Message);
         }

         if (ErrorCount == 0)
         {
            // Tell User What We're Doing...
            try
            {
               WriteStatus(false, "Querying SQL Version for: " + strDBMSInstanceName
               + " [" + theServer.Information.VersionString + "]");
            }
            catch (Exception e)
            {
               // We Were Unable to Query Version Number
               ErrorCount++;

               WriteStatus(false, "**** ERROR: Unable to Query Version Number: " + strDBMSInstanceName
                     + "\r\nERROR: " + e.Message);
            }
         }

         // Return Status Of Connection
         return ((ErrorCount == 0) ? true : false);
      }

      static int ScriptTablesInDB(Server theServer, Database db, string strScriptFileDir)
      {
         //
         // This Function Scripts Out All Tables in Database [db] on SQL Server Instance
         //    [theServer] to a File in the [strScriptFileDir] Directory
         //    Returns "0" if No Errors

         int ErrorCount = 0;

         // Create the Target Directory Where the Script Files Go, If Necessary
         if (Directory.Exists(strScriptFileDir) == false)
            Directory.CreateDirectory(strScriptFileDir);

         // Define a Scripter object and set the required scripting options.
         Scripter scrp = new Scripter(theServer);

         scrp.Options.ContinueScriptingOnError = true;
         scrp.Options.IncludeHeaders = true;
         scrp.Options.NoIdentities = false;
         scrp.Options.DriAll = true;
         scrp.Options.Indexes = true;
         scrp.Options.Triggers = true;
         scrp.Options.Permissions = true;
         scrp.Options.Default = true;
         scrp.Options.FullTextCatalogs = true;
         scrp.Options.FullTextIndexes = true;

         // Overwrite Any Existing File
         scrp.Options.AppendToFile = false;

         try
         {
            Urn[] urn = new Urn[1];

            // For Each Table In the Database... 
            foreach (Table t in db.Tables)
            {
               // Get the Table Name            
               string strTableName = t.Name;

               // We Exclude "sys" and "dt" tables
               if (strTableName.IndexOf("dt") != 0 && strTableName.IndexOf("sys") != 0)
               {
                  // Identify This Table
                  WriteStatus(false, "--  TABLE: " + strTableName);

                  // Set the Script File Name
                  scrp.Options.FileName = strScriptFileDir + @"\" + strTableName + ".SQL";

                  // Script Out This Table...                    
                  urn[0] = t.Urn;
                  StringCollection sc = scrp.Script(urn);

                  //// And Display It                  
                  // foreach (string s in sc)
                  //    WriteStatus(false, s);

               }   // if 
            }      // foreach
         }         // try

         catch (Exception e)
         {
            WriteStatus(false, "**** ERROR: [ScriptTablesInDB]: " + e.Message);
            ErrorCount++;
         }

         // Return the Error Count 
         return ErrorCount;
      }

      static int ScriptProcsInDB(Server theServer, Database db, string strScriptFileDir)
      {
         //
         // This Function Scripts Out All Procedures in Database [db] on SQL Server Instance
         //    [theServer] to a File in the [strScriptFileDir] Directory
         //
         int ErrorCount = 0;

         // Create the Target Directory Where the Script Files Go, If Necessary
         if (Directory.Exists(strScriptFileDir) == false)
            Directory.CreateDirectory(strScriptFileDir);

         // Define a Scripter object and set the required scripting options.
         Scripter scrp = new Scripter(theServer);
         scrp.Options.Permissions = true;
         scrp.Options.ContinueScriptingOnError = true;
         scrp.Options.IncludeHeaders = true;

         // Overwrite Any Existing File
         scrp.Options.AppendToFile = false;

         // For Each Procedure In the Database... 
         Urn[] urn = new Urn[1];
         foreach (StoredProcedure sp in db.StoredProcedures)
         {
            // Get the Procedure Name            
            string strProcName = sp.Name;

            // We Exclude "dt_" Procedures and Microsoft Procedures
            if (strProcName.IndexOf("dt_") != 0 && strProcName.IndexOf("sp_MS") != 0)
            {
               // Identify This Procedure
               WriteStatus(false, "--  PROCEDURE: " + strProcName);

               // Set the Script File Name
               scrp.Options.FileName = strScriptFileDir + @"\" + strProcName + ".SQL";

               // Script Out This Procedure... [This Runs SLOW!]
               urn[0] = sp.Urn;
               StringCollection sc = scrp.Script(urn);

               //// And Display It
               //foreach (string s in sc)
               //   WriteStatus(false, s);

            }
         }

         // Return Number of Errors
         return ErrorCount;
      }


      static int ScriptViewsInDB(Server theServer, Database db, string strScriptFileDir)
      {
         //
         // This Function Scripts Out All Views in Database [db] on SQL Server Instance
         //    [theServer] to a File in the [strScriptFileDir] Directory
         //

         int ErrorCount = 0;

         // Create the Target Directory Where the Script Files Go, If Necessary
         if (Directory.Exists(strScriptFileDir) == false)
            Directory.CreateDirectory(strScriptFileDir);

         // Define a Scripter object and set the required scripting options.
         Scripter scrp = new Scripter(theServer);

         scrp.Options.Permissions = true;
         scrp.Options.ContinueScriptingOnError = true;
         scrp.Options.IncludeHeaders = true;

         // Overwrite Any Existing File
         scrp.Options.AppendToFile = false;

         // For Each View In the Database... 
         Urn[] urn = new Urn[1];
         foreach (View v in db.Views)
         {
            // Get the View Name            
            string strViewName = v.Name;

            // We Exclude "sys..." System Views and "syncobj_" views!
            if (strViewName.IndexOf("sys") != 0 && strViewName.IndexOf("syncobj_") != 0)
            {
               // Identify This View
               WriteStatus(false, "--  VIEW: " + strViewName);

               // Set the Script File Name
               scrp.Options.FileName = strScriptFileDir + @"\" + strViewName + ".SQL";

               // Script Out This View... [This Runs SLOW!]
               urn[0] = v.Urn;
               StringCollection sc = scrp.Script(urn);

               //// And Display It
               //foreach (string s in sc)
               //   WriteStatus(false, s);

            }
         }

         // Return Number of Errors
         return ErrorCount;

      }

      static int ScriptFunctionsInDB(Server theServer, Database db, string strScriptFileDir)
      {
         //
         // This Function Scripts Out All UDFs in Database [db] on SQL Server Instance
         //    [theServer] to a File in the [strScriptFileDir] Directory
         //

         int ErrorCount = 0;

         // Create the Target Directory Where the Script Files Go, If Necessary
         if (Directory.Exists(strScriptFileDir) == false)
            Directory.CreateDirectory(strScriptFileDir);


         // Define a Scripter object and set the required scripting options.
         Scripter scrp = new Scripter(theServer);

         scrp.Options.Permissions = true;
         scrp.Options.ContinueScriptingOnError = true;
         scrp.Options.IncludeHeaders = true;

         // Overwrite Any Existing File
         scrp.Options.AppendToFile = false;

         // For Each UDF In the Database... 
         Urn[] urn = new Urn[1];
         foreach (UserDefinedFunction udf in db.UserDefinedFunctions)
         {
            // Get the UDF Name            
            string strFunctionName = udf.Name;

            // Identify This UDF
            WriteStatus(false, "--  FUNCTION: " + strFunctionName);

            // Set the Script File Name
            scrp.Options.FileName = strScriptFileDir + @"\" + strFunctionName + ".SQL";

            // Script Out This UDF... [This Runs SLOW!]
            urn[0] = udf.Urn;
            StringCollection sc = scrp.Script(urn);

            //// And Display It
            //foreach (string s in sc)
            //   WriteStatus(false, s);

         }

         // Return Number of Errors
         return ErrorCount;

      }

      static int ScriptRolesInDB(Server theServer, Database db, string strScriptFileDir)
      {
         //
         // This Function Scripts Out All Roles in Database [db] on SQL Server Instance
         //    [theServer] to a File in the [strScriptFileDir] Directory
         //

         int ErrorCount = 0;

         // Create the Target Directory Where the Script Files Go, If Necessary
         if (Directory.Exists(strScriptFileDir) == false)
            Directory.CreateDirectory(strScriptFileDir);

         // Define a Scripter object and set the required scripting options.
         Scripter scrp = new Scripter(theServer);
         scrp.Options.Permissions = true;

         // For Each Role In the Database... 
         Urn[] urn = new Urn[1];
         foreach (DatabaseRole dr in db.Roles)
         {
            // Get the Role Name            
            string strRoleName = dr.Name;

            // Identify This Role
            WriteStatus(false, "--  ROLE: " + strRoleName);

            // Set the Script File Name
            scrp.Options.FileName = strScriptFileDir + @"\" + strRoleName + ".SQL";

            // Script Out This Role... [This Runs SLOW!]
            urn[0] = dr.Urn;
            StringCollection sc1 = scrp.Script(urn);

            // We Want to List Members Of this Role
            StringCollection sc2 = dr.EnumMembers();

            // Open Output File Manually, And Write Out The Data We Need Manually
            StreamWriter TheFile = new StreamWriter(scrp.Options.FileName);

            // Write the Role Declaration
            foreach (string s in sc1)
            {
               // Write This String
               TheFile.WriteLine("\r\n\r\n--Role: " + strRoleName + "\r\n" + s);
            }

            // Show Role Members
            TheFile.WriteLine("GO\r\n\r\n--Role Members: ");
            foreach (string s in sc2)
            {
               // Write This String
               TheFile.WriteLine(s);
            }

            // Close File
            TheFile.Flush();
            TheFile.Close();

         }

         // Return Number of Errors
         return ErrorCount;

      }

      protected static void WriteStatus(bool bPurgeLogFile, string strStatus)
      {
         // Updates the Status [Writes a String to a Log File and to the Console]

         // Purge Log File, if Appropriate
         if (bPurgeLogFile)
            LOG.Purge();

         // Write to Log File
         LOG.Write(strStatus);

         // Write to Console
         Console.WriteLine(strStatus);
      }

      protected static string Initialize(string[] args)
      {
         // Initializes for the Run

         // Grab the Log File Name from the Configuration File
         string strLogFileName = 
            System.Configuration.ConfigurationManager.AppSettings["zLOG_FILE"];

         // Set Up the Logging
         LOG.SetFileName(strLogFileName);

         // We Purge the Log File and Start A New Run
         WriteStatus(true, "**** STARTING RUN ******");

         // Get the SQL Instance That the User Passed In -- 
         //   It Is the First Program Argument -- args[0]
         string strSQLInstance = "";
         if (args.Length == 1)
            strSQLInstance = (string)args[0];
         else
         {
            // User Had Invalid Syntax On the Command-Line!
            WriteStatus(false, "Command-Line Syntax Error!  Expected Format:\r\n\r\n  SchemaCollector <SQL Instance Name>");
            return "";
         }

         // Return the SQL Instance Name that We Will Process!
         return strSQLInstance;
      }
   }
}
