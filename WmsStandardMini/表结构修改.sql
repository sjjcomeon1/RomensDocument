--操作人员表
ALTER TABLE OPERATORS ADD WORKGROUP VARCHAR(500);
alter table operators add UUID VARCHAR(50);

-- 仓库调拨总库明细
ALTER TABLE CKDBDZKMX ADD DCKH VARCHAR(50);
ALTER TABLE CKDBDZKMX ADD DRKH VARCHAR(50);
ALTER TABLE CKDBDZKMX ADD ISCONFIRM BIT;
ALTER TABLE CKDBDZKMX ADD DBQRBZ BIT


-- 盘点表增加字段
ALTER TABLE STOCKTAKINGDETAIL ADD PDYBH VARCHAR(50);
ALTER TABLE STOCKTAKINGDETAIL ADD ISSTOCKTAKING INT;

-- 修改FAHUO 字段类型
ALTER TABLE FAHUO ALTER COLUMN WMSISEXPORT VARCHAR(50);
ALTER TABLE FAHUO ALTER COLUMN WMSRECORDSTATUS VARCHAR(50);

-- 修改FHDZK 字段类型
ALTER TABLE FHDZK ALTER COLUMN WMSISEXPORT VARCHAR(50);
ALTER TABLE FHDZK ALTER COLUMN WMSRECORDSTATUS VARCHAR(50);

-- FAHUOHEAD |FHDZKHEAD 增加字段
ALTER TABLE FAHUOHEAD ADD WMSEXPORTMSG  VARCHAR(500);
ALTER TABLE FHDZKHEAD ADD WMSEXPORTMSG  VARCHAR(500)；
