USE [interface]
GO

/****** Object:  StoredProcedure [dbo].[sp_pacs_Report]    Script Date: 03/08/2017 15:42:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE      proc[dbo].[sp_pacs_Report]
@ID VARCHAR(20),---�������뵥��
@report_person varchar(20),----���������
@ret_code int output,
@ret_message VARCHAR(100)output
AS
BEGIN 
	 set @ret_code=2
	 set @ret_message='����ɹ�'
	update BS_YSGZZ..YS01060 SET YS_1_35 = @report_person ,YS_1_37 = 2 WHERE  YS_1_1=@ID  ---����鵥״̬���³ɱ����״̬2
	insert into JMHIS..tmp_fs values (@ID,@ret_code,@ret_message)       ---����Ϣ���浽aa��tmp_fs�� 
end

GO


