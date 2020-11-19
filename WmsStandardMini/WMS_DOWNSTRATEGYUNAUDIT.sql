
GO

/****** Object:  StoredProcedure [dbo].[WMS_DOWNSTRATEGYUNAUDIT]    Script Date: 2020/11/18 10:34:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Proc[dbo].[WMS_DOWNSTRATEGYUNAUDIT] 
(
    @BillGuid varchar(50),
	@BillTypeGuid varchar(50),
	@OperatorGuid varchar(50),
	@ReturnMsg nvarchar(50) output,
	@ReturnValue int output
)

AS
Declare @INFO Varchar(500);
Begin
  --数据有效检测
  Select @Info = Case When IsNull(a.ISAUDITING,0) = 0 Then '当前单据未审核,不允许反审核！'End 
  FROM WMS_DOWNSTRATEGY A
  WHERE A.guid = @BillGuid;

  IF IsNull(@Info,'')<> ''
   Begin
	Set @ReturnMsg = @Info;
	Set @ReturnValue = -1;
	Return;
   End
  Begin Tran
  UPDATE WMS_DOWNSTRATEGY
         SET IsAuditing = 0,
             AuditingDate = '',
             AuditingGuid = ''
  WHERE Guid = @BillGuid;

  If @@Error<>0 
	Begin
	 Set @ReturnMsg = '审核发生异常'
	 Goto SQLErr1
	End
  Commit Tran
	SET @ReturnMsg=''
	SET @ReturnValue=0
	Return;
	SQLErr1:
	RollBack Transaction
	Set @ReturnValue=-1
	Return;
END;
GO


