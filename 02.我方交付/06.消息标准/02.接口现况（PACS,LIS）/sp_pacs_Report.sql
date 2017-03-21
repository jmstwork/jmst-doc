USE [interface]
GO

/****** Object:  StoredProcedure [dbo].[sp_pacs_Report]    Script Date: 03/08/2017 15:42:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE      proc[dbo].[sp_pacs_Report]
@ID VARCHAR(20),---检查的申请单号
@report_person varchar(20),----发报告的人
@ret_code int output,
@ret_message VARCHAR(100)output
AS
BEGIN 
	 set @ret_code=2
	 set @ret_message='报告成功'
	update BS_YSGZZ..YS01060 SET YS_1_35 = @report_person ,YS_1_37 = 2 WHERE  YS_1_1=@ID  ---将检查单状态更新成报告的状态2
	insert into JMHIS..tmp_fs values (@ID,@ret_code,@ret_message)       ---将信息保存到aa的tmp_fs中 
end

GO


