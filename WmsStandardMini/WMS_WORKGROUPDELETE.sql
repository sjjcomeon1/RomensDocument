GO

/****** Object:  StoredProcedure [dbo].[WMS_WORKGROUPDELETE]    Script Date: 2020/11/18 10:21:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Proc [dbo].[WMS_WORKGROUPDELETE]
(
  @BillGuid VARCHAR(50) ,
  @BillTypeGuid VARCHAR(50),
  @OperatorGuid VARCHAR(50) ,
  @ReturnMsg varchar(200) OutPut,
  @ReturnValue int OutPut	-- 返回提示或错误信息  
)
AS
    Declare @ISFORBIDDEN Int;
BEGIN
   SELECT @ISFORBIDDEN = ISFORBIDDEN  FROM wms_Workgroup WHERE  GUID = @BillGuid;
   IF @ISFORBIDDEN = 0
   BEGIN
      Set @ReturnMsg = '该小组正在使用,不能删除!' ;
      Set @ReturnValue = -1 ;
      RETURN;
   END;
  
   Begin Tran
   Delete wms_Workgroup  WHERE GUID = @BillGuid and IsNull(ISFORBIDDEN,1)=1;
   Delete wms_Workgroupdetail WHERE WorkgroupGUID = @BillGuid;
   If @@Error<>0 
   Begin
	Select @ReturnMsg = '删除失败！'
	Goto SQLErr1
   End;
  -------------从人员表中删除
  Declare my_cursor Cursor Scroll For select workgroup,guid from OPERATORS where CharIndex( @BillGuid,WORKGROUP)>0
   Open my_cursor
   Declare @workgroup Varchar(50),@guid Varchar(50)
   Fetch Next From my_cursor Into @workgroup,@guid
   While @@FETCH_STATUS=0
   Begin
    DECLARE @workgroups varchar(500);
	Set @workgroups = ( STUFF ((SELECT ','+CH FROM ( select ch from  fsplit(@workgroup,',') where  ch<>@BillGuid ) A WHERE 1=1 FOR XML PATH('')),1,1,'')   )
	UPDATE  OPERATORS SET WORKGROUP = @workgroups WHERE guid=@guid;
	Fetch Next From my_cursor Into @workgroup,@guid;
   End
   Close my_cursor;
   DealLocate my_cursor;

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


