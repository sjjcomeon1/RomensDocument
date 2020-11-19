GO

/****** Object:  StoredProcedure [dbo].[WMS_VESSELUNFORBID]    Script Date: 2020/11/19 10:30:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create proc [dbo].[WMS_VESSELUNFORBID] 
(
	@BillGuid nvarchar(100),             	-- 表单单据GUID
    @BillTypeGuid nvarchar(100),		--单据类型
	@OperatorGuid nvarchar(100),     	--当前操作人员GUID
	@ReturnMsg nvarchar(500) output,   	--返回提示或错误信息
	@ReturnValue smallint output          --返回提示或错误信息
) AS

DECLARE @ISFORBIDDEN INT;
BEGIN

  SELECT @ISFORBIDDEN = ISSTATUS FROM WMS_VESSEL WHERE GUID = @BillGuid;
  IF @ISFORBIDDEN != 0
	BEGIN
		Set @ReturnMsg   = '该容器不是禁用状态,不允许启用!';
		Set @ReturnValue = -1;
		RETURN;
	END;
	Begin Tran
    Update WMS_VESSEL Set ISSTATUS = 1 WHERE GUID = @BillGuid and ISNULL(ISSTATUS, 0) = 0;
	If @@ERROR<>0
		Begin 
			Set @ReturnMsg='启用失败!';		
			Set @ReturnValue=2;
			Rollback
			Return 2
		End 
  Commit
  Set @ReturnMsg='';		
  Set @ReturnValue=0;
  return
END;
GO


