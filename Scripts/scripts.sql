﻿USE [master]
GO
/****** Object:  Database [Luxottica]    Script Date: 7/13/2016 1:07:58 PM ******/
CREATE DATABASE [Luxottica]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Luxottica', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.MSSQLSERVER2012\MSSQL\DATA\Luxottica.mdf' , SIZE = 105472KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Luxottica_log', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.MSSQLSERVER2012\MSSQL\DATA\Luxottica_log.ldf' , SIZE = 427392KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [Luxottica] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Luxottica].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Luxottica] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Luxottica] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Luxottica] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Luxottica] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Luxottica] SET ARITHABORT OFF 
GO
ALTER DATABASE [Luxottica] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Luxottica] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Luxottica] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Luxottica] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Luxottica] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Luxottica] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Luxottica] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Luxottica] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Luxottica] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Luxottica] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Luxottica] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Luxottica] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Luxottica] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Luxottica] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Luxottica] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Luxottica] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Luxottica] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Luxottica] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Luxottica] SET RECOVERY FULL 
GO
ALTER DATABASE [Luxottica] SET  MULTI_USER 
GO
ALTER DATABASE [Luxottica] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Luxottica] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Luxottica] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Luxottica] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'Luxottica', N'ON'
GO
USE [Luxottica]
GO
/****** Object:  StoredProcedure [dbo].[sp_FailedSSIS_SendMail]    Script Date: 7/13/2016 1:07:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_FailedSSIS_SendMail]
         
          @CCEmail varchar(1000) = '',
          @minute int = null 
AS
SET NOCOUNT ON 
declare c4 cursor for 
select  id , event , computer , operator , source ,  
	executionid , starttime , endtime , message  ,FileName
from Temp_Fail where executionid 
in (select executionid from Temp_Fail where event = 'OnError' )
and starttime > dateadd(mi, -@minute, getdate()) order by executionid, id 
 
open c4
declare @id int, @event varchar(256), @computer varchar(256), 
	@operator varchar(256), @source varchar(256), 
	@executionid uniqueidentifier, @starttime datetime, @endtime datetime, 
	@message varchar(1024), @errormsg varchar(4000), @FileName nvarchar(500)
 
declare @startid int,  @endid int, @pre_id int, 
	@start_time datetime, @end_time datetime, @cmd varchar(8000)
declare @subject1 varchar(256)
declare @ival int
 
set @errormsg = ''
set @cmd = ''

-- get Toemail address
declare @ToEmail nvarchar(50)
set @ToEmail = (select distinct SUBSTRING([FileName],0,CHARINDEX('-',[FileName]))+'@dminc.in' as email
from Temp_Fail where executionid 
in (select executionid from Temp_Fail where event = 'OnError' )
and starttime > dateadd(mi, -@minute, getdate())  )


	 set @ival=0
fetch next from c4 into @id , @event , @computer , @operator , @source , 
	 @executionid , @starttime , @endtime , @message ,@FileName

print @ToEmail 
print 'before cursor1'
while @@fetch_status = 0
begin
print 'in cursor'
          if @ival=0
          begin 
                   set @endid = @id
                   set @end_time = @endtime
                   
                   SELECT @startid = t.id from Temp_Fail t --where t.executionid = @executionid and 
						--event = 'PackageStart' and message like 'Beginning of package execution.%'
                   SELECT @start_time = t.starttime from Temp_Fail t --where executionid = @executionid and 
						--event = 'PackageStart' and message like 'Beginning of package execution.%'
                   select @errormsg = @errormsg + message from Temp_Fail 
                   --t where t.id between @startid and 						@endid and t.executionid = @executionid
                   print @errormsg
                   
                   set @subject1 = 'SSIS Package ' + @source + ' Failed on ' + @@SERVERNAME
                   
                   select @cmd = @cmd + 'SQL Instance: ' + @@SERVERNAME + char(10)
                   select @cmd = @cmd + 'Package Name: ' + @source + char(10)
                   select @cmd = @cmd + 'File Name: ' + @FileName + char(10)
                   
                   select @cmd = @cmd + 'Job Originating Host: ' + @computer + char(10)
                   select @cmd = @cmd + 'Run As: ' + @operator + char(10)
                   select @cmd = @cmd + 'Start DT: ' + convert(varchar(30),@start_time,121) + char(10)
                   select @cmd = @cmd + 'End DT: ' + convert(varchar(30),@end_time,121) + char(10)
                   select @cmd = @cmd + 'Error Message: '+ char(10) + @errormsg 
                   
                   -----------------
                   
                    
                             --call sp to send email 
                             exec  msdb.dbo.sp_send_dbmail 
                             @recipients= @ToEmail,
                             @copy_recipients = @CCEmail,
                             @subject =  @subject1, 
                             @body_format ='TEXT',
                             @body = @cmd
                             
                             print @cmd
                             print @ToEmail
                             
                            
                  set  @ival = 1
          set @errormsg = ''             
          set @cmd = ''
          end
set @pre_id = @id
fetch next from c4 into @id , @event , @computer , @operator , @source ,  
	@executionid , @starttime , @endtime , @message ,@FileName
end
 
close c4
deallocate c4


GO
/****** Object:  StoredProcedure [dbo].[sp_successSSIS_SendMail]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_successSSIS_SendMail]
         
          @CCEmail varchar(1000) = '',
          @minute int = null 
AS
SET NOCOUNT ON 
declare c4 cursor for 
select  id , event , computer , operator , source ,  
	executionid , starttime , endtime , message  ,FileName
	--,Package_Name
from Temp_success where executionid 
in (select executionid from Temp_success  )
and starttime > dateadd(mi, -@minute, getdate()) order by executionid, id 
 
open c4
declare @id int, @event varchar(256), @computer varchar(256), 
	@operator varchar(256), @source varchar(256), 
	@executionid uniqueidentifier, @starttime datetime, @endtime datetime, 
	@message varchar(1024), @errormsg varchar(4000), @FileName nvarchar(500)
	--,@packagename varchar(256)
 
declare @startid int,  @endid int, @pre_id int, 
	@start_time datetime, @end_time datetime, @cmd varchar(8000)
declare @subject1 varchar(256)
declare @ival int
 
set @errormsg = ''
set @cmd = ''

-- get Toemail address
declare @ToEmail nvarchar(50)
set @ToEmail = (select distinct SUBSTRING([FileName],0,CHARINDEX('-',[FileName]))+'@dminc.in' as email
from Temp_success where executionid 
in (select executionid from Temp_success)
and starttime > dateadd(mi, -@minute, getdate())  )


	 set @ival=0
fetch next from c4 into @id , @event , @computer , @operator , @source , 
	 @executionid , @starttime , @endtime , @message ,@FileName
	 --,@packagename

print @ToEmail 
print 'before cursor1'
while @@fetch_status = 0
begin
print 'in cursor'
          if @ival=0
          begin 
                   set @endid = @id
                   set @end_time = @endtime
                   
                   SELECT @startid = t.id from Temp_success t --where t.executionid = @executionid and 
						--event = 'PackageStart' and message like 'Beginning of package execution.%'
                   SELECT @start_time = t.starttime from Temp_success t --where executionid = @executionid and 
						--event = 'PackageStart' and message like 'Beginning of package execution.%'
                   select @errormsg = @errormsg + message from Temp_success 
                   --t where t.id between @startid and 						@endid and t.executionid = @executionid
                   print @errormsg
                   
                   set @subject1 = 'SSIS Package ' + @source + ' completed ' + @@SERVERNAME
                   
                   select @cmd = @cmd + 'SQL Instance: ' + @@SERVERNAME + char(10)
                   select @cmd = @cmd + 'Package Name: ' + @source + char(10)
                   select @cmd = @cmd + 'File Name: ' + @FileName + char(10)
                   
                   select @cmd = @cmd + 'Job Originating Host: ' + @computer + char(10)
                   select @cmd = @cmd + 'Run As: ' + @operator + char(10)
                   select @cmd = @cmd + 'Start DT: ' + convert(varchar(30),@start_time,121) + char(10)
                   select @cmd = @cmd + 'End DT: ' + convert(varchar(30),@end_time,121) + char(10)
                   select @cmd = @cmd + 'Message: '+ char(10) + @errormsg 
                   
                    
                             --call sp to send email 
                             exec  msdb.dbo.sp_send_dbmail 
                             @recipients= @ToEmail,
                             @copy_recipients = @CCEmail,
                             @subject =  @subject1, 
                             @body_format ='TEXT',
                             @body = @cmd
                             
                             print @cmd
                             print @ToEmail
                             
                            
                  set  @ival = 1
          set @errormsg = ''             
          set @cmd = ''
          end
set @pre_id = @id
fetch next from c4 into @id , @event , @computer , @operator , @source ,  
	@executionid , @starttime , @endtime , @message ,@FileName
end
 
close c4
deallocate c4


GO
/****** Object:  Table [dbo].[cdc_states]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cdc_states](
	[name] [nvarchar](256) NOT NULL,
	[state] [nvarchar](256) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Destination]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Destination](
	[DoctorTabId] [nvarchar](255) NULL,
	[StoreID] [nvarchar](255) NULL,
	[OfficeType] [nvarchar](255) NULL,
	[FiscalWeek] [nvarchar](255) NULL,
	[NextEEScheduledLastYear] [nvarchar](255) NULL,
	[ConfirmedNextEE] [nvarchar](255) NULL,
	[NextEEScheduledLastYearRetained] [nvarchar](255) NULL,
	[CLNextEEScheduledLastYear] [nvarchar](255) NULL,
	[CLNextEERetained] [nvarchar](255) NULL,
	[ActualAvailableODCells] [nvarchar](255) NULL,
	[AppointedCells] [nvarchar](255) NULL,
	[SchedExamApptTotal] [nvarchar](255) NULL,
	[OfficeExams] [nvarchar](255) NULL,
	[OnlineExamsbyExamDate] [nvarchar](255) NULL,
	[CLExam] [nvarchar](255) NULL,
	[ScheduledEyeglassExam] [nvarchar](255) NULL,
	[OnlineCLExams] [nvarchar](255) NULL,
	[OnlineEyeglassExams] [nvarchar](255) NULL,
	[NewExam] [nvarchar](255) NULL,
	[ScheduledNPCL] [nvarchar](255) NULL,
	[ScheduledNPCLNW] [nvarchar](255) NULL,
	[ScheduledEPE] [nvarchar](255) NULL,
	[ScheduledEPCL] [nvarchar](255) NULL,
	[ScheduledEPCLNW] [nvarchar](255) NULL,
	[SameDayExams] [nvarchar](255) NULL,
	[SameDayExamsOnline] [nvarchar](255) NULL,
	[SameDayOnlineCL] [nvarchar](255) NULL,
	[ExamsCheckedIn] [nvarchar](255) NULL,
	[CLExamsCheckin] [nvarchar](255) NULL,
	[EyeExamsCheckedin] [nvarchar](255) NULL,
	[OnlineExamsCheckedin] [nvarchar](255) NULL,
	[ExamsCompleted] [nvarchar](255) NULL,
	[CLExamsComplete] [nvarchar](255) NULL,
	[EyeglassExamsComplete] [nvarchar](255) NULL,
	[ExamsNoShows] [nvarchar](255) NULL,
	[OnlineExamNoShow] [nvarchar](255) NULL,
	[OfficeNoShow] [nvarchar](255) NULL,
	[ExamsCancelled] [nvarchar](255) NULL,
	[OnlineExamCancelled] [nvarchar](255) NULL,
	[OfficeCancel] [nvarchar](255) NULL,
	[CLExamsCancelled] [nvarchar](255) NULL,
	[EyeglassExamsCancelled] [nvarchar](255) NULL,
	[TotalPatients] [nvarchar](255) NULL,
	[OnlineNewPatients] [nvarchar](255) NULL,
	[NextEECreatedforNextYear] [nvarchar](255) NULL,
	[CLNextEECreatedfornextyear] [nvarchar](255) NULL,
	[LoadedAt] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[File_processing]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[File_processing](
	[Package_Name] [varchar](100) NULL,
	[Execution_Date] [datetime] NULL,
	[FileName] [varchar](100) NULL,
	[Foldername] [varchar](100) NULL,
	[Status] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LC_CommoditySales]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LC_CommoditySales](
	[CommoditySalesId] [int] IDENTITY(1,1) NOT NULL,
	[StoreID] [int] NOT NULL,
	[FiscalWeek] [int] NOT NULL,
	[RetailUnits] [int] NULL,
	[NetSalesHome] [decimal](10, 2) NULL,
	[CompleteSun_RetailUnits] [int] NULL,
	[CompleteSun_NetSalesHome] [decimal](10, 2) NULL,
	[CompleteOphth_RetailUnits] [int] NULL,
	[CompleteOphth_NetSalesHome] [decimal](10, 2) NULL,
	[PlanoSun_RetailUnits] [int] NULL,
	[PlanoSun_NetSalesHome] [decimal](10, 2) NULL,
	[FrameOnlyOphth_RetailUnits] [int] NULL,
	[FrameOnlyOphth_NetSalesHome] [decimal](10, 2) NULL,
	[LensOnlySun_RetailUnits] [int] NULL,
	[LensOnlySun_NetSalesHome] [decimal](10, 2) NULL,
	[LensOnlyOphth_RetailUnits] [int] NULL,
	[LensOnlyOphth_NetSalesHome] [decimal](10, 2) NULL,
	[ContactLens_RetailUnits] [int] NULL,
	[ContactLens_NetSalesHome] [decimal](10, 2) NULL,
	[LoadedAt] [datetime] NULL,
 CONSTRAINT [PK_commoditysales] PRIMARY KEY NONCLUSTERED 
(
	[CommoditySalesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LC_DoctorTAB]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LC_DoctorTAB](
	[DoctorTABID] [int] IDENTITY(1,1) NOT NULL,
	[StoreID] [int] NOT NULL,
	[FiscalWeek] [int] NOT NULL,
	[OfficeType] [varchar](10) NULL,
	[NextEEScheduledLastYear] [int] NULL,
	[ConfirmedNextEE] [int] NULL,
	[NextEEScheduledLastYearRetained] [int] NULL,
	[CLNextEEScheduledLastYear] [int] NULL,
	[CLNextEERetained] [int] NULL,
	[ActualAvailableODCells] [int] NULL,
	[AppointedCells] [int] NULL,
	[SchedExamApptTotal] [int] NULL,
	[OfficeExams] [int] NULL,
	[OnlineExamsbyExamDate] [int] NULL,
	[CLExam] [int] NULL,
	[ScheduledEyeglassExam] [int] NULL,
	[OnlineCLExams] [int] NULL,
	[OnlineEyeglassExams] [int] NULL,
	[NewExam] [int] NULL,
	[SameDayExams] [int] NULL,
	[SameDayExamsOnline] [int] NULL,
	[SameDayOnlineCL] [int] NULL,
	[ExamsCheckedIn] [int] NULL,
	[CLExamsCheckin] [int] NULL,
	[EyeExamsCheckedin] [int] NULL,
	[OnlineExamsCheckedin] [int] NULL,
	[ExamsCompleted] [int] NULL,
	[CLExamsComplete] [int] NULL,
	[EyeglassExamsComplete] [int] NULL,
	[ExamsNoShows] [int] NULL,
	[OnlineExamNoShow] [int] NULL,
	[OfficeNoShow] [int] NULL,
	[ExamsCancelled] [int] NULL,
	[OnlineExamCancelled] [int] NULL,
	[OfficeCancel] [int] NULL,
	[CLExamsCancelled] [int] NULL,
	[EyeglassExamsCancelled] [int] NULL,
	[TotalPatientsCumulative] [int] NULL,
	[OnlineNewPatients] [int] NULL,
	[NextEECreatedforNextYear] [int] NULL,
	[CLNextEECreatedfornextyear] [int] NULL,
 CONSTRAINT [PK_LC_DoctorTAB] PRIMARY KEY NONCLUSTERED 
(
	[DoctorTABID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LC_StoreCharacteristics]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LC_StoreCharacteristics](
	[Store ] [float] NULL,
	[Brand] [nvarchar](255) NULL,
	[Concept] [nvarchar](255) NULL,
	[Store Name] [nvarchar](255) NULL,
	[Store Address1] [nvarchar](255) NULL,
	[Store Address2] [nvarchar](255) NULL,
	[CITY] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[ZIP] [nvarchar](255) NULL,
	[COUNTRY] [nvarchar](255) NULL,
	[Store Type] [nvarchar](255) NULL,
	[SF] [float] NULL,
	[Center Type] [nvarchar](255) NULL,
	[Center Rating] [float] NULL,
	[Updated RE Venue] [nvarchar](255) NULL,
	[Store Open Date] [datetime] NULL,
	[Landlord] [nvarchar](255) NULL,
	[LEASETYPE] [nvarchar](255) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[DMA] [nvarchar](255) NULL,
	[Latitude1] [float] NULL,
	[Longitude1] [float] NULL,
	[DMA1] [nvarchar](255) NULL,
	[2016] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LC_StoreSegmentation]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LC_StoreSegmentation](
	[StoreID] [int] NOT NULL,
	[StoreSegmentation] [nvarchar](255) NULL,
	[FiscalYear] [int] NOT NULL,
	[StoreSegmentationID] [nvarchar](255) NULL,
 CONSTRAINT [PK_storeseg] PRIMARY KEY NONCLUSTERED 
(
	[StoreID] ASC,
	[FiscalYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LC_StoreSegmentation_STAGE]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LC_StoreSegmentation_STAGE](
	[StoreID] [int] NOT NULL,
	[StoreSegmentation] [nvarchar](255) NULL,
	[FiscalYear] [int] NOT NULL,
	[StoreSegmentationID] [nvarchar](255) NULL,
 CONSTRAINT [PK_UserGroup] PRIMARY KEY NONCLUSTERED 
(
	[StoreID] ASC,
	[FiscalYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LC_Traffic]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LC_Traffic](
	[TrafficId] [int] IDENTITY(1,1) NOT NULL,
	[Storeid] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[Traffic] [int] NULL,
	[FiscalWeek] [int] NULL,
	[LoadedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TrafficId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[MstStoreSegmentation]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MstStoreSegmentation](
	[StoreSegmentationID] [float] NULL,
	[StoreSegmentation] [nvarchar](255) NULL,
	[ProductSegmentation] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[OLE DB Destination]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OLE DB Destination](
	[StoreSegmentationID] [float] NULL,
	[StoreSegmentation] [nvarchar](255) NULL,
	[ProductSegmentation] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SAMPLE]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SAMPLE](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EVENT] [varchar](50) NULL,
	[PACKAGENAME] [varchar](50) NULL,
	[RUNTIME] [datetime] NOT NULL,
	[MESSAGE] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SSIS_Logging_Details]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SSIS_Logging_Details](
	[Execution_Instance_GUID] [nvarchar](100) NULL,
	[Package_Name] [varchar](100) NULL,
	[Execution_Date] [datetime] NULL,
	[FileName] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Stage]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Stage](
	[__$start_lsn] [binary](10) NULL,
	[__$operation] [int] NULL,
	[__$update_mask] [binary](128) NULL,
	[Storeid] [float] NULL,
	[Brand] [nvarchar](255) NULL,
	[Concept] [nvarchar](255) NULL,
	[Store Name] [nvarchar](255) NULL,
	[Store Address1] [nvarchar](255) NULL,
	[Store Address2] [nvarchar](255) NULL,
	[CITY] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[ZIP] [nvarchar](255) NULL,
	[COUNTRY] [nvarchar](255) NULL,
	[Store Type] [nvarchar](255) NULL,
	[SF] [float] NULL,
	[Center Type] [nvarchar](255) NULL,
	[Center Rating] [float] NULL,
	[Updated RE Venue] [nvarchar](255) NULL,
	[Store Open Date] [date] NULL,
	[Landlord] [nvarchar](255) NULL,
	[LEASETYPE] [nvarchar](255) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[DMA] [nvarchar](255) NULL,
	[Latitude1] [float] NULL,
	[Longitude1] [float] NULL,
	[DMA1] [nvarchar](255) NULL,
	[2016] [nvarchar](255) NULL,
	[Status] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Temp_Fail]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Fail](
	[id] [int] NULL,
	[Package_Name] [nvarchar](100) NULL,
	[operator] [nvarchar](128) NOT NULL,
	[computer] [nvarchar](128) NOT NULL,
	[executionid] [nvarchar](100) NULL,
	[Package_Run_Start_DateTime] [datetime] NULL,
	[Source] [nvarchar](2000) NOT NULL,
	[Event] [sysname] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[starttime] [datetime] NOT NULL,
	[endtime] [datetime] NOT NULL,
	[FileName] [nvarchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Temp_success]    Script Date: 7/13/2016 1:07:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_success](
	[id] [int] NULL,
	[Package_Name] [nvarchar](100) NULL,
	[operator] [nvarchar](128) NOT NULL,
	[computer] [nvarchar](128) NOT NULL,
	[executionid] [nvarchar](100) NULL,
	[Package_Run_Start_DateTime] [datetime] NULL,
	[Source] [nvarchar](2000) NOT NULL,
	[Event] [sysname] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[starttime] [datetime] NOT NULL,
	[endtime] [datetime] NOT NULL,
	[FileName] [nvarchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [cdc_states_name]    Script Date: 7/13/2016 1:07:59 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [cdc_states_name] ON [dbo].[cdc_states]
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [Luxottica] SET  READ_WRITE 
GO
