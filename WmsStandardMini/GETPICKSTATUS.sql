
GO

/****** Object:  UserDefinedFunction [dbo].[GETPICKSTATUS]    Script Date: 2020/11/19 14:47:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[GETPICKSTATUS]
(
  @BillNo varchar(50),
  @BoxNo varchar(50)
)
-- 返回值说明： 0 未拣货 1 正在拣货 2 拣货完成
returns varchar(2)
AS
BEGIN
    declare @pick_count decimal(18,2);
    declare @vessel_status varchar(50);
    declare @row_count decimal(18,2);

  SELECT @pick_count = count(1)   FROM FAHUO A INNER JOIN  WMS_VESSEL B ON WMSRECORDSTATUS = B.CODE WHERE ISSTATUS = 2 AND A.LSH = @BillNo;
  --M200908466  20200902001
  IF @pick_count <= 0
  Begin
	     return 0;
  End

 SELECT @row_count =COUNT(1)   FROM FAHUO WHERE WMSRECORDSTATUS = @BoxNo AND LSH = @BillNo;
 SELECT @pick_count = count(1) FROM FAHUO WHERE WMSRECORDSTATUS = @BoxNo AND LSH = @BillNo and WMSEXECSTATUS = 1;
  IF @pick_count >0
    Begin
          return 1;
    END;

  SELECT @pick_count = count(1)   FROM FAHUO WHERE WMSRECORDSTATUS = @BoxNo AND LSH = @BillNo and WMSEXECSTATUS = 2;
  IF  @pick_count >0 and @pick_count = @row_count
    BEGIN
      Return 2;
    END;
  return 0;
END;
GO


