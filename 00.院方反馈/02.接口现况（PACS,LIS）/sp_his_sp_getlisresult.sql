USE [lis]
GO

/****** Object:  StoredProcedure [dbo].[sp_his_sp_getlisresult]    Script Date: 03/08/2017 16:24:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE proc[dbo].[sp_his_sp_getlisresult]
@hsp_no VARCHAR(20),---病人id号
 @da_id VARCHAR(50), ---即Apply_ID：No格式

--
@report_person varchar(20),----发报告的人
@returncode int output,
@returnmsg VARCHAR(100)output
AS
BEGIN 
	if len(@da_id)<12
		begin
			set @returncode=1
			set @returnmsg='@da_id的长度不能小于12位'
		end

	 select @returncode = 0,@returnmsg = ''
	declare @APPLY_ID varchar(12)--申请单号
	declare @NO int--序号
	declare @type int--类型 1门诊 2住院 3体检
	declare @HY_ResultMain_Id bigint
	declare @HY_ResultDetail_id bigint--明细表id
	declare @is_new int
	declare @item_code int--化验类别代码
	declare @item_name varchar(50)--化验类别名称
	--序号
	declare @his_code varchar(15),
		@report_code int,
		@report_name varchar(60),
		@refer_range  varchar(50),
		@result varchar(255),
		@unit varchar(10),
		@Status varchar(3),
		@examine_person varchar(50),
		@pa_name varchar(20),
		@PatExt2 varchar(50),
		@reviewerindex int
	declare @testIndex int
	select @testIndex=testIndex from DBVIP.climis.dbo.h_finance where HIS=@da_id
	set @APPLY_ID=substring(@da_id,1,charindex(':',@da_id)-1)

	print @da_id+'@da_id'
	set @NO=cast(substring(@da_id,charindex(':',@da_id)+1,4) as int)
	
	select @type=dbo.convertType(type),@item_code=b.item_code,@item_name=b.item_name,@pa_name=a.pa_name from  lis..lis_lab_sheet a ,lis..lis_lab_item b  where  a.apply_id=b.apply_id and a.apply_id=@APPLY_ID and no=@NO
	print '@APPLY_ID='+@APPLY_ID	
--Apply_ID varchar(12),NO int,patient_type int,patient_id varchar(10),report_person varchar(36))
	select @HY_ResultMain_Id=id from aa..HY_ResultMain where apply_id=@APPLY_ID and no=@NO
	if @HY_ResultMain_Id is null
	begin
		insert into aa..HY_ResultMain(Apply_ID,NO,patient_type,patient_id,report_person,exam_time,item_code,item_name,pa_name)
			values(@APPLY_ID,@NO,@type,@hsp_no,@report_person,getdate(),@item_code,@item_name,@pa_name);
		select @HY_ResultMain_Id=@@Identity
		set @is_new=1
	end
	print @HY_ResultMain_Id
	declare select_detail cursor for 
	select
		t.Standard  , --本报告中维一
		t.code , 
		t.name , 
		v.reviewnotes , 
		.dbo.StrFormat(v.nvalue, v.svalue, t.presion) ,
		t.units , v.Status ,o.name,p.reviewerindex-- p.PatExt3  
	from 
		DBVIP.climis.dbo.h_finance h 
		left join DBVIP.climis.dbo.oldvalue v on h.ndate=v.ndate and h.specimenno=v.specimenno 
		left join DBVIP.climis.dbo.b_test t on v.testindex=t.code
		left join DBVIP.climis.dbo.oldspecimen p on v.ndate=p.ndate and v.specimenno=p.specimenno
        left join DBVIP.climis.dbo.operator o on o.code=p.patExt3
	where  h.his = @da_id and 
		((t.code in (select testindex from DBVIP.climis.dbo.b_testprofile where profiletestindex=@testIndex)) or (t.code=@testIndex))
		and dbo.StrFormat(v.nvalue, v.svalue, t.presion)<>''
	order by t.PrtOrder
	
	open select_detail
	fetch next from select_detail into @his_code,@report_code ,@report_name,@refer_range ,@result,@unit,@Status,@examine_person,@reviewerindex
	while @@fetch_status=0
	begin
		select @PatExt2=name  from DBVIP.climis.dbo.operator where code=@reviewerindex
		if @is_new=1 --如果是新增，则直接增加
		insert into aa..HY_ResultDetail(main_id,his_code,report_code ,report_name,refer_range ,result,unit,Status,examine_person,PatExt2)
			values(@HY_ResultMain_Id,@his_code,@report_code ,@report_name,@refer_range ,@result,@unit,@Status,@examine_person,@PatExt2)
		else
			begin
				select @HY_ResultDetail_id=id from aa..HY_ResultDetail where main_id=@HY_ResultMain_Id and his_code=@his_code
				if	 @HY_ResultDetail_id is null
					insert into aa..HY_ResultDetail(main_id,his_code,report_code ,report_name,refer_range ,result,unit,Status,examine_person,PatExt2)
						values(@HY_ResultMain_Id,@his_code,@report_code ,@report_name,@refer_range ,@result,@unit,@Status,@examine_person,@PatExt2)
				else
					update aa..HY_ResultDetail set main_id=@HY_ResultMain_Id,his_code=@his_code,report_code=@report_code,report_name=@report_name,refer_range=@refer_range ,result=@result,unit=@unit,Status=@Status,examine_person=@examine_person where id=@HY_ResultDetail_id
			end
		fetch next from select_detail into @his_code,@report_code ,@report_name,@refer_range ,@result,@unit,@Status,@examine_person,@reviewerindex
	end
	close select_detail
	deallocate select_detail
		print @type
	
	 set @returncode=0
	 set @returnmsg='保存成功'
end



GO


