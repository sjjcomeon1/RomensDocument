GO

/****** Object:  StoredProcedure [dbo].[WMS_VESSELDELETE]    Script Date: 2020/11/18 10:17:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WMS_VESSELDELETE] 
(
	@BillGuid     varchar(100),                 -- 待删除的表单单据GUID
	@BillTypeGuid varchar(100),                 -- 待删除的表单GUID
	@OperatorGuid varchar(100),                 -- 当前操作人员GUID
 	@ReturnMsg    nvarchar(500) output,          -- 返回提示或错误信息
 	@ReturnValue    nvarchar(500) output          -- 返回提示或错误信息
  ) 
  AS
  Declare @temp int;
  Set @temp = 0;
BEGIN
    SELECT @temp = COUNT(1)  FROM WMS_VESSEL  WHERE GUID = @BillGuid  AND ISNULL(ISSTATUS, 1) <> 1;
    IF @temp <> 0 
	Begin
      Set @ReturnMsg = '该容器不是空闲状态,不能删除!';
      Set @ReturnValue = -1;
      RETURN;
    End;
    Begin Tran
	DELETE WMS_VESSEL WHERE GUID = @BillGuid;
    IF @@Error<>0 
	Begin
		Select @ReturnMsg='删除失败!'
		GoTo SQLErr1
    End
	Commit Tran
	Set @ReturnMsg='删除成功!'
	Set @ReturnValue=0
	Return
    SQLErr1:
	RollBack Transaction
	Set @ReturnValue=-1
	Return
END;
GO


