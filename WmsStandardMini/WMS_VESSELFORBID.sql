GO
/****** Object:  StoredProcedure [dbo].[WMS_VESSELFORBID]    Script Date: 2020/11/19 10:30:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc  [dbo].[WMS_VESSELFORBID] 
(
	@BillGuid nvarchar(100),             	-- 表单单据GUID
    @BillTypeGuid nvarchar(100),		--单据类型
	@OperatorGuid nvarchar(100),     	--当前操作人员GUID
	@ReturnMsg nvarchar(500) output,   	--返回提示或错误信息
	@ReturnValue smallint output          --返回提示或错误信息
) AS
 DECLARE @ISFORBIDDEN INT;
BEGIN
  Select  @ISFORBIDDEN = ISNULL(ISSTATUS,0) From WMS_VESSEL Where GUID = @BillGuid;
  IF @ISFORBIDDEN = 0
    Begin
      Set @ReturnMsg  = '该容器已经禁用';
      Set @ReturnValue = -1;
      RETURN;
    END;
  IF @ISFORBIDDEN = 2
    Begin
      Set @ReturnMsg ='该容器正在使用,不允许禁用';
      Set @ReturnValue = -1;
      RETURN;
    END;
  Begin Tran
    Update WMS_VESSEL Set ISSTATUS = 0  WHERE GUID = @BillGuid and IsNull(ISSTATUS, 0) != 0;
	If @@ERROR<>0
	Begin 
		set @ReturnMsg='禁用失败!'; 		
		set @ReturnValue=2;
		rollback;
		return 2;
	End 
  Commit
  Set @ReturnMsg=''; 		
  Set @ReturnValue=0;
  Return;
 End