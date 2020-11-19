create proc WMS_VESSELTYPEDELETE
(
	@BillGuid     varchar(100),                 -- 待删除的表单单据GUID
	@BillTypeGuid varchar(100),                 -- 待删除的表单GUID
	@OperatorGuid varchar(100),                 -- 当前操作人员GUID
 	@ReturnMsg    nvarchar(500) output,          -- 返回提示或错误信息
 	@ReturnValue    nvarchar(500) output          -- 返回提示或错误信息
) AS
Declare @temp int;
BEGIN
  BEGIN
    SELECT @temp = COUNT(1) FROM WMS_VESSEL WHERE VESSELTYPE = @BillGuid;
	IF @temp <> 0
	Begin
      Set @ReturnMsg = '该容器类型正在使用,不能删除!';
      Set @ReturnValue = -1;
      RETURN;
    End;
  END;

  BEGIN
    DELETE WMS_VESSELTYPE WHERE GUID = @BillGuid;
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
end;