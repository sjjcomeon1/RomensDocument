
GO
/****** Object:  StoredProcedure [dbo].[WMS_GOODSPLACEEXECSORT]    Script Date: 11/19/2020 11:17:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE          [dbo].[WMS_GOODSPLACEEXECSORT]
    (
        @BillGuid varchar(50) ,
        @billTemplateGuid varchar(50) ,
        @ProType  varchar(50), -- 类型 1=> ;2=>> ;3=<; 4=<<;5=上移；6=下移；7=置顶;8=置底
        @SiteNum int ,-- 序号
        @OperatorGuid varchar(50),-- 当前操作人员GUID
        @ReturnMsg nvarchar(50) out,
        @ReturnValue int out
    )
    AS
    declare @count int;
    declare @Num int;
BEGIN
    select  @count = count(*)  from tt_selectguid where type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid;
    if (@count=0)
    Begin
          set @ReturnMsg = '无记录，操作失败！' ;
          set @ReturnValue = -1 ;
          RETURN;
    End;
    Begin Tran
         update  WMS_GOODSPLACESORT set iszt='' where MAINGUID=@billguid and BILLTEMPLATEGUID=@BILLTEMPLATEGUID;
         IF @ProType = '1'
             Begin
                 -----------1.先重新排序
                BEGIN
                    update WMS_GOODSPLACESORT set SORTNUMBER=ISNULL(SORTNUMBER,0)+ @COUNT where SORTNUMBER > ISNULL( @SiteNum,0) and BILLTEMPLATEGUID=@BILLTEMPLATEGUID and mainguid=@billguid ;
                    IF @@ERROR <> 0
                    Begin
                        set @ReturnMsg = '>移位更新排序出错';
                        GOTO SQLERR1;
                    end
                END;
                BEGIN
                    insert into WMS_GOODSPLACESORT(GUID,BILLTEMPLATEGUID,GOODSPLACEGUID,MAINGUID,SORTNUMBER,iszt)
                    SELECT NEWID(),@BILLTEMPLATEGUID,A.GUID,@BILLGUID,
                    A.DETAILNO+isnull(@SiteNum,0),'Y' FROM tt_selectguid A
                    LEFT JOIN (select guid ,GOODSPLACEGUID from WMS_GOODSPLACESORT where BILLTEMPLATEGUID=@BILLTEMPLATEGUID)B ON B.GOODSPLACEGUID=A.GUID
                    where A.type='WMS_GoodsPlaceSort' and A.operatorguid=@OperatorGuid AND B.GUID IS NULL ;
                    IF @@ERROR <> 0
                    Begin
                        Set @ReturnMsg = '>移位出错';
                        GOTO SQLERR1;
                    end

                END;

            End
        Else IF @ProType = '2'
        Begin
              -----------1.先重新排序
                BEGIN
                    UPDATE A SET  A.SORTNUMBER=isnull(SORTNUMBER,0)+@COUNT  FROM WMS_GOODSPLACESORT A INNER JOIN tt_selectguid B ON A.GOODSPLACEGUID = B.Guid
                    WHERE type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid AND A.BILLTEMPLATEGUID=@BILLTEMPLATEGUID AND A.SORTNUMBER> ISNULL(@SiteNum,0);
                    IF @@ERROR <> 0
                    Begin
                        set @ReturnMsg = '>>移位更新排序出错';
                        GOTO SQLERR1;
                    end
                END;
                      -----------2.插入新纪录
                BEGIN
                    insert into WMS_GOODSPLACESORT(GUID,BILLTEMPLATEGUID,GOODSPLACEGUID,MAINGUID,SORTNUMBER,iszt)
                    SELECT NEWID(),@BILLTEMPLATEGUID,A.GUID,@BILLGUID,A.DETAILNO + ISNULL(@SiteNum,0),'Y' FROM tt_selectguid A
                    LEFT JOIN  (select guid ,GOODSPLACEGUID from WMS_GOODSPLACESORT where BILLTEMPLATEGUID=@BILLTEMPLATEGUID) B ON B.GOODSPLACEGUID=A.GUID
                    where A.type='WMS_GoodsPlaceSort' and A.operatorguid=@OperatorGuid   AND B.GUID IS NULL ;
                    IF @@ERROR <> 0
                    Begin
                        Set @ReturnMsg = '>>移位出错';
                        GOTO SQLERR1;
                    end

                END;
        End
        Else IF @ProType = '3'
             Begin
                BEGIN
                    DELETE FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID AND GUID IN (SELECT GUID FROM  tt_selectguid where type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid);
                    IF @@ERROR <> 0
                    Begin
                        set @ReturnMsg = '<移位出错';
                        GOTO SQLERR1;
                    end
                END;
                -- 重新排序
                Begin
                UPDATE A SET a.SORTNUMBER=b.SORTID FROM  WMS_GOODSPLACESORT a INNER JOIN (SELECT guid,ROW_NUMBER() OVER(partition by Mainguid ORDER BY SORTNUMBER) AS SORTID  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID) B ON A.GUID = B.GUID
                 IF @@ERROR <> 0
                 Begin
                    SET @ReturnMsg = '<移位排序出错';
                    GOTO SQLERR1;
                 End
                End
            End
        Else IF @ProType = '4'
            Begin
                DELETE FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID;
                IF @@ERROR <> 0
                Begin
                 Set @ReturnMsg = '<<移位出错';
                 GOTO SQLERR1;
                End
            End
    -------------------------------*********移位***************----------------
        IF @ProType = '5'  ----------上移
            Begin
                --------1.更新选择行 以上的记录
                BEGIN
                    update WMS_GOODSPLACESORT set SORTNUMBER=ISNULL(SORTNUMBER,0) + @COUNT  where SORTNUMBER=ISNULL(@SiteNum,0)-1 and BILLTEMPLATEGUID = @BILLTEMPLATEGUID and mainguid=@billguid ;
                    IF @@ERROR <> 0
                    Begin
                    Set @ReturnMsg = '上移移位更新排序出错';
                    GOTO SQLERR1;
                    End
                END;
                --------------2.更新选择行的位置
                BEGIN
                    UPDATE A SET A.SORTNUMBER=ISNULL(SORTNUMBER,0) - 1 , iszt='Y' FROM WMS_GOODSPLACESORT A INNER JOIN  tt_selectguid B ON A.GUID = B.Guid WHERE  B.type='WMS_GoodsPlaceSort' and B.operatorguid=@OperatorGuid AND A.BILLTEMPLATEGUID=@BILLTEMPLATEGUID
                    IF @@ERROR <> 0
                    Begin
                    Set @ReturnMsg = '上移排序出错';
                    GOTO SQLERR1;
                    End
                End
                --------重新排序
                Begin
                  UPDATE A SET  a.SORTNUMBER=b.SORTID  FROM  WMS_GOODSPLACESORT a INNER JOIN (SELECT guid,row_number() over(partition by Mainguid  order by SORTNUMBER) AS SORTID  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID)  B ON A.GUID = B.GUID
                  IF @@ERROR <> 0
                  Begin
                    Set @ReturnMsg = '上移排序出错';
                    GOTO SQLERR1;
                  End
                End;
            End
        Else IF @ProType = '6' ------下移
            Begin
                --------1.更新选择行 以上的记录
                Begin
                    update WMS_GOODSPLACESORT set SORTNUMBER=isnull(SORTNUMBER,0) - @count where SORTNUMBER=IsNull(@SiteNum,0) + @count and BILLTEMPLATEGUID=@BILLTEMPLATEGUID and mainguid=@billguid;
                    If @@ERROR <> 0
                    Begin
                       Set @ReturnMsg = '下移移位更新排序出错';
                       GOTO SQLERR1;
                    end
                End
                --------------2.更新选择行的位置
                Begin
                    UPDATE A SET A.SORTNUMBER = ISNULL(SORTNUMBER,0) + 1 , iszt = 'Y' FROM WMS_GOODSPLACESORT A INNER JOIN tt_selectguid B ON A.GUID = B.Guid where type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid AND A.BILLTEMPLATEGUID=@BILLTEMPLATEGUID
                    IF @@ERROR <> 0
                    Begin
                     SET @ReturnMsg = '下移排序出错';
                     GOTO SQLERR1;
                    End
                END;
               --------重新排序
               Begin
                UPDATE A SET a.SORTNUMBER=b.SORTID FROM WMS_GOODSPLACESORT A INNER JOIN (SELECT guid,row_number() over(partition by Mainguid  order by SORTNUMBER) AS SORTID  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID) B ON A.GUID = B.GUID
                IF @@ERROR <> 0
                  Begin
                    Set @ReturnMsg = '下移排序出错';
                    GOTO SQLERR1;
                  End
               End;
          End;
        Else IF @ProType = '7'
            Begin
              SELECT @Num = count(*)  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid= @BILLGUID;
              ----------------先更新 选择的记录的 序号
                Begin
                    UPDATE A SET A.SORTNUMBER = ISNULL(SORTNUMBER,0) - @Num , iszt = 'Y'  FROM WMS_GOODSPLACESORT A INNER JOIN tt_selectguid B ON A.GUID = B.GUID where type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid  AND A.BILLTEMPLATEGUID = @BILLTEMPLATEGUID
                    IF @@ERROR <> 0
                    Begin
                        SET @ReturnMsg = '置顶移位更新排序出错';
                        GOTO SQLERR1;
                    End
                End;
                 --------重新排序
                Begin
                    UPDATE A SET A.SORTNUMBER=B.SORTID  FROM WMS_GOODSPLACESORT A INNER JOIN (SELECT guid,row_number() over(partition by Mainguid  order by SORTNUMBER) AS SORTID  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid=@BILLGUID) B ON A.GUID = B.GUID
                     IF @@ERROR <> 0
                     Begin
                      Set @ReturnMsg = '置顶排序出错';
                      GOTO SQLERR1;
                     End
                End;
            End
        Else IF @ProType = '8' --置底
            Begin
                 SELECT @Num = count(*)  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID = @BILLTEMPLATEGUID AND Mainguid = @BILLGUID;
                  ----------------先更新 选择的记录的 序号
                 BEGIN
                    UPDATE A SET A.SORTNUMBER=ISNULL(SORTNUMBER,0) + @Num , iszt = 'Y'  FROM WMS_GOODSPLACESORT A INNER JOIN  tt_selectguid B ON A.GUID = B.Guid where type='WMS_GoodsPlaceSort' and operatorguid=@OperatorGuid AND A.BILLTEMPLATEGUID=@BILLTEMPLATEGUID
                    IF @@ERROR <> 0
                    Begin
                       Set @ReturnMsg = '置底移位更新排序出错';
                       GOTO SQLERR1;
                    End
                END;
                     --------重新排序
                 Begin
                    UPDATE A SET a.SORTNUMBER=b.SORTID From  WMS_GOODSPLACESORT a INNER JOIN (SELECT guid,row_number() over(partition by Mainguid  order by SORTNUMBER) AS SORTID  FROM WMS_GOODSPLACESORT WHERE BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND Mainguid = @BILLGUID) B ON A.GUID = B.GUID
                    IF @@ERROR <> 0
                    Begin
                         Set @ReturnMsg = '置底排序出错';
                         GOTO SQLERR1;
                    End;
                End
            End
        IF @ProType <> '4'
            Begin
            -------------出库策略
                if(@billTemplateGuid='10051508008')
                Begin
                  UPDATE WMS_DownStrateGyDetail SET SELLOUTORDER = null WHERE MAINGUID=@BILLGUID;
                  BEGIN
                      UPDATE A SET A.SELLOUTORDER=B.SORTNUMBER  FROM WMS_DownStrateGyDetail A INNER JOIN WMS_GOODSPLACESORT B ON A.GOODSPLACEGUID = B.GOODSPLACEGUID WHERE B.BILLTEMPLATEGUID =@BILLTEMPLATEGUID AND B.Mainguid=@BILLGUID
                      IF @@ERROR <> 0
                      Begin
                          SET @ReturnMsg = '移位货位排序出错';
                          GOTO SQLERR1;
                      End
                  END;
                End;
            End
    COMMIT Tran ;
    set @RETURNMSG = ' ' ;
    set @RETURNVALUE = 0 ;
    Return ;
  SQLErr1:
    Rollback  transaction
    Set @ReturnValue = -1 ;
    Return;
END;
