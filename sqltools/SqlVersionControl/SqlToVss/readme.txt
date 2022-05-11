Good article by MVP Hilary Cotter on version control, including his VSSAgent code. As he explains in the article, his code has four parts:

* A batch file, which contains a list of the SQL Servers to put under version control 
* A VBScript file that extracts the schema and tags the objects 
* The run log that he e-mails back to himself 
* The change log that he e-mails back to himself

http://searchsqlserver.techtarget.com/tip/1,289483,sid87_gci1093178,00.html.


===================================================================================================================================

Like the weather, SQL developers and database administrators talk about version control, but most of
them don't do anything about it. Version control means managing the versions of the objects created
and deployed in their SQL Server environments. Typically, this involves developers and DBAs
checking scripts including object creation scripts into Visual Source Safe (VSS), or a similar version
control software, when they create them and then checking them out and back in again when they
make modifications.
Several benefits come with establishing version control:
1. Control of the versions of objects that are deployed in the various environments
2. Database object recovery
3. Change tracking -- detection of new or deleted objects
4. Difference tracking -- detection of what has changed in an object
5. History and rationale of object changes
6. Labeling of a version of database objects to build upgrade scripts
7. Simplified troubleshooting process by knowing exactly what has changed; and the ability to roll
back changes to prior versions of the objects
The problem with SQL Server version control is that the tool of choice that most SQL developers and
DBAs use to build their database objects is Query Analyzer. Query Analyzer does not have Visual
Source Safe Integration built into it. In SQL 2005, SQL Server Management Studio is integrated with
Visual Source Safe, so a developer using SQL Server Management Studio can check his objects in
and out of Visual Source Safe.
Ken Henderson's book, The Guru's Guide to SQL Server Stored Procedures, XML, and HTML, shows
how to integrate Query Analyzer with Visual Source Safe, but it still requires SQL developers to
rigorously check the objects they are modifying in and out through Query Analyzer using a few simple
keystrokes.
There are commercially available tools that will integrate an IDE (like Enterprise Manager or SQL
2005 Server Management Studio) with Visual Source Safe. Query Google or MSN Search for SQL IDE
Visual Source Safe for a list of such products.
The advantages of using an IDE that integrates with Visual Source Safe (or another version control
software product) are:
1. The SQL developer or DBA controls what is archived in Visual Source Safe. (Test objects will
not be stored in VSS unless the developer checks them in for backup purposes.)
2. Units of code can all be checked in at once, as opposed to mismatched versions, which may
not work together.
3. Units of code will have been tested by the SQL developer.
4. Most version control software forces the SQL developer who checks in the code to explain why
the code was modified. This raises the visibility of problems with the code and greatly assists
with the debugging process. It also raises the visibility of SQL developers who are not
following the software development processes you have created in-house. Following the
processes is critical for the success of large development projects.
5. All installations in the test, QA, release and production environments can be generated from a
single source -- the version control software. This reduces the logistical burden of maintaining
the build scripts, and it prevents errors.
6. It allows for ticket tracking of modifications.
(This list is courtesy of SQL Server MVP Erland Sommarskog. Any errors in this list are solely my own,
any gems you may find in this list are completely Erland's.)
In well-disciplined shops there are well-established protocols and procedures for checking objects in
and out of the company's version control software. DBAs and developers rigorously check the objects
they will be modifying in and out of Visual Source Safe or other version control software.
I have not had the luxury of working for an institution that has such protocols and procedures or, for
the most part, even enterprise-level version control software. So I have had to deal with DBAs and
SQL developers begging me to restore their databases to recover an earlier version of a stored
procedure, view or function. For larger databases, that can be a lengthy process. Frequently the SQL
developer has been working in a development environment that is not backed up, and recovering
these objects is not possible.
In such undisciplined environments, I implement a nightly batch job that connects to all SQL Servers
in the environment, scripts out all database objects and then pushes the modified objects into Visual
Source Safe.

In Visual Source Safe, I can easily retrieve a previous version of an object. I can also label groups of
objects so that I can generate an installation script for a set of objects for a specific version. For
instance, I can label all objects Release to Manufacturing (RTM), then a group of objects later down
the road as SP1, and so on. Within Source Safe, I can check out all objects labeled SP1 and generate
a script to distribute to my customers.
The nightly batch job also keeps a run log of error messages generated during the run for debugging
purposes. I can use this run log to improve my scripts by fixing the errors or working around particular
problems that cause my script to fail.
I also generate a log of what has changed in the environments. Then I can evaluate the code that is
going into the test, QA, release or production environments to determine whether:
1. the changes are authorized, and the authorized changes are deployed (not something
different)
2. the changes follow best security, naming, and coding conventions
All objects are tagged with extended properties, which include versioning information. With this
versioning information I can query an environment and ensure that all objects are at a specific version
and then detect which objects belong to a different version.
At the completion of the nightly job, I e-mail the logs to myself for evaluation.
The logs and the version control information provide high visibility to what has changed in your
environments, and they allow you to proactively react to what will be deployed in the environments
downstream. The most compelling reason for implementing such a version control process, in my
opinion, is to have a repository of all the stored procedures in my environment so I can run scripts
against the repository to check for poor coding practices. I use slightly modified scripts that I obtain
from Linchi Shea's Real World SQL Server Administration with Perl to do this checking. I check for
cursor use, temp table creation, object references without an owner name and other poor coding
practices. A database that scores high for bad coding practices will be evaluated in greater depth.
Here is a short description of how this code works.
There are several parts to this VSS agent:
A batch file, which contains a list of the SQL Servers I want to put under version control
A VBScript file, which contains the code I use to extract the schema and tag the objects in the
SQL Server databases that I bring under version control with version control tags
The run log that I e-mail back to myself
The change log that I e-mail back to myself
I use blat to e-mail these logs to myself because the security policy in most of the companies I work
in prevent using SQL Mail or installing SMTP on their SQL Servers.
I schedule a job to run via SQL Scheduler. It runs an operating system command, which is a batch file
that looks like this:
C:
Cd\vssagent
Vssagent.vbs Server1
Vssagent.vbs Server2
Vssagent.vbs Server3
where Server1, Server2 and Server3 are SQL Servers in my environment that I want to bring under
version control. Modify your batch file to include the names of your SQL Servers.
In my VSSagent script I start off with several constants that define where my file system repository is --
and the path, account and password for Visual Source Safe.
CONST VSSPath="c:\Program Files\Microsoft Visual Studio\common\vss\srcsafe.ini"
CONST VSSAdminAccount="admin"
CONST VSSAdminAccountPassword=""
CONST FileRepositoryPath="C:\VSS"
You will have to modify this for your particular environments. The run log will be placed in your
FileRepositoryPath and will be called RunLogMM-DD-YYYY.log. The Difference log will be called
DifferenceLogMM-DD-YYYY.log.log and will also be placed in the FileRepositoryPath.
This script will create project paths in VSS and file system paths for each server in the file system. By
default the project path in VSS will be in the root of your VSS database. SQL Server Instances have the
in their name replaced with an underscore. For instance, a SQL Server Instance called
SQLServerInstanceName would be called SQLServer_InstanceName in the file system. That is
because we use separate subdirectories for each SQL server and its databases in the file system,
and an instance name would be recognized as a database of a SQL Server.
The script will then connect with user databases, check to see if that database is under source
in VSS. It will then enumerate the objects, add them to VSS if they are not under source control, check
the changes if there have been changes and note that a difference has been detected for this object
for that SQL Server in that database. It also tags each object with version control information using
extended properties, which allows us to use the system function fn_listextendedproperty to determine
which objects are at what version in our database.
Please find in the attached script the VSSAgent code. Feel free to modify it to implement your own
version control for SQL Server objects.
Hilary Cotter has been involved in IT for more than 20 years as a Web and database consultant.
Microsoft first awarded Cotter the Microsoft SQL Server MVP award in 2001. Cotter received his
bachelor of applied science degree in mechanical engineering from the University of Toronto and
subsequently studied both economics at the University of Calgary and computer science at UC
Berkeley. He is the author of a book on SQL Server transactional replication and is currently working
on books on merge replication and Microsoft search technologies.