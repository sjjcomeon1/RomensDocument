GO
/****** Object:  StoredProcedure [dbo].[WMS_WORKGROUPAUDITING]    Script Date: 2020/11/18 10:29:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE          [dbo].[WMS_WORKGROUPAUDITING]
(
	@BillGuid varchar(50),			--单据内码
	@BillTypeGuid varchar(50),		--单据类型
	@OperatorGuid varchar(50),		--操作人员内码
	@AuditingDate Datetime,			--审核日期
	@ReturnMsg varchar(200) OutPut,	--返回提示信息，成功执行，返回空值；否则返回提示信息
	@ReturnValue int OutPut			--返回值，成功执行，返回0；否则返回非零值
)
AS
Declare @count int;
BEGIN
   set @count = 0;
   select @count = count(*) from wms_Workgroup WHERE  GUID = @BillGuid and ISNULL(IsAuditing,0)=1;
   If @count>0
   Begin
    Set @ReturnMsg = '单据已经审核！' ;
    Set @ReturnValue = -1 ;
    Return;
   End;

   Begin Tran
   Update wms_Workgroup  Set ISAUDITING=1,AUDITINGGUID=@Operatorguid,AUDITINGDATE=convert(varchar(10),getdate(),23)
   WHERE GUID = @BillGuid and IsNull(IsAuditing,0)=0;
   If @@Error<>0
	Begin
		Select @ReturnMsg = '审核失败！'
		Goto SQLErr1
	End

   --------------更新人员

   Declare m_cursor Cursor Scroll For Select workgroup,guid from operators where CHARINDEX(@BillGuid, WORKGROUP)>0
   Open m_cursor
   Declare @workgroup Varchar(50),@guid Varchar(50)
   Fetch Next From m_cursor Into @workgroup,@guid
   While @@FETCH_STATUS=0
   Begin
      DECLARE @workgroups varchar(500);
	  Set @workgroups = ( STUFF((SELECT ','+CH FROM ( select ch from  fsplit(@workgroup,',') where  ch <> @BillGuid ) A WHERE 1=1 FOR XML PATH('')),1,1,'')   )
	    UPDATE OPERATORS SET WORKGROUP = @workgroups Where guid = @guid;
	Fetch Next From m_cursor Into @workgroup,@guid
   End
   Close m_cursor
   DealLocate m_cursor;


   Declare my_cursor Cursor Scroll For select employeeguid from WMS_WORKGROUPDETAIL where WORKGROUPGUID = @BillGuid
   Open my_cursor
   Declare @employeeguid Varchar(50)
   Fetch Next From my_cursor Into @employeeguid
   While @@FETCH_STATUS=0
   Begin
        select @count = count(1) from operators a where a.guid=@employeeguid and  ISNULL(a.WORKGROUP,'')= '';
		If @count=1
		Begin
			UPDATE  operators SET WORKGROUP=@BillGuid where guid=@employeeguid;
		End
        Else
		Begin
            UPDATE  operators  SET WORKGROUP = WORKGROUP + ',' + @BillGuid WHERE guid = @employeeguid;
        End
	Fetch Next From my_cursor Into @employeeguid;
   End
   Close my_cursor;
   DealLocate my_cursor;
   If @@Error<>0
	Begin
	Select @ReturnMsg = '更新作业组失败！'
	Goto SQLErr1
	End
-- 	UPDATE A SET A.WORKGROUP=CASE WHEN len(Isnull(A.WORKGROUP,'')) > 0 THEN A.WORKGROUP + ',' + @BILLGUID ELSE @BILLGUID END  from WMS_EMPLOYEE A INNER JOIN WMS_WORKGROUPDETAIL B ON B.EMPLOYEEGUID =A.GUID AND WORKGROUPGUID = @BILLGUID
-- 	If @@Error<>0
-- 	Begin
-- 		Select @ReturnMsg = '更新！'
-- 		Goto SQLErr1
-- 	End
	Commit Tran
	SET @ReturnMsg=''
	SET @ReturnValue=0
	Return;
	SQLErr1:
	RollBack Transaction
	Set @ReturnValue=-1
	Return;
	END;