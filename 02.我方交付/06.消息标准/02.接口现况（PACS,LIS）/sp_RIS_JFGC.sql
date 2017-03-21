USE [interface]
GO

/****** Object:  StoredProcedure [dbo].[sp_RIS_JFGC]    Script Date: 03/08/2017 15:40:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_RIS_JFGC]   ---计费过程
@APPLY_ID varchar(50), --in：医嘱唯一对应号
@return_code int output,  --out:返回序号码 0：成功 1:不成功 
@return_message varchar(100) output --out: 错误信息

as
declare @p_TYPE varchar(50), --类型 ,
        @ZSL decimal (18,2), @TCXH decimal (18,2),@YS_1_1 decimal (18,2),
		@ll_fyje decimal (18,2),		
		@num1 int,
		@num  int,
		@ls_bl  varchar(50),
		@FYH varchar(50),
		@fyrq datetime,
		@stopNo int -- 停用细项数量
declare @jcks varchar(4),@rylsh varchar(20),@status INT ,@SHBZ INT ,@zxhs   varchar(100)
select @jcks ='FS'

select @p_TYPE=ys_1_2 from bs_ysgzz..ys01060 where ys_1_3=@APPLY_ID
if @p_TYPE='2'
begin
	SELECT @num = count(*)  FROM JMHIS..BDYP WHERE TCXH=@APPLY_ID
	if @num = 0 
	begin
		set @return_code  = 1
		set @return_message = '不能记费,医生工作站未将全部医嘱传输到病区,请通知相关医生和护士,将不能计费的医嘱重传或者到住院处补录费用!'
		insert into JMHIS..tmp_fs values (@APPLY_ID,@return_code,@return_message)
		return
	end
	SELECT   @num =COUNT(FYH)   FROM JMHIS..BDYP WHERE TCXH=@APPLY_ID AND FYH  IN (SELECT PY FROM JMHIS..BFFY WHERE PY=JMHIS..BDYP.FYH)
	if @num = 0 
	begin
		set @return_code  = 1
		set @return_message = '不能记费!套餐编码不在bfzywh中,请通知管理员查找原因!'
	   insert into JMHIS..tmp_fs values (@APPLY_ID,@return_code,@return_message)
		return
	end
	if @num >= 1 
		begin  
		 DECLARE CUR_SORTtc CURSOR FOR    SELECT TCXH,FYH,ZSL,SHBZ,YS_1_1,brbl,ZSL,ZXHS,zxrq FROM JMHIS..BDYP WHERE TCXH=@APPLY_ID   
				OPEN    CUR_SORTtc 
				FETCH  CUR_SORTtc  INTO @TCXH,@FYH,@ZSL,@SHBZ,@YS_1_1,@ls_bl,@ZSL ,@zxhs,@fyrq
				WHILE(@@FETCH_STATUS=0)
				BEGIN
					select @rylsh=rylsh from JMHIS..bdbr  where brbl=@ls_bl

					IF @fyrq  is not null
						begin
							set @return_code  = 2  --已经计费标志与计费不成功使用不同标志
							set @return_message = '已经记费!'
							insert into JMHIS..tmp_fs  values (@APPLY_ID,@return_code,@return_message)
							 CLOSE cur_sorTtc
							 DEALLOCATE cur_sorTtc
							return
						end
					 else
					   begin  
							IF SUBSTRING(@FYH,1,2)='TL'  
							   BEGIN
									select @stopNo= count(a.id) from JMHIS..bfzywh a,JMHIS..bffy b where a.py=b.py and a.dm=@fyh and (b.sybz=4)
									if(@stopNo>0)
										begin
											set @return_code  = 1  
											set @return_message = '计费失败,套餐的细项药品已经被停用'
											insert into JMHIS..tmp_fs  values (@APPLY_ID,@return_code,@return_message)									
											 CLOSE cur_sorTtc
											 DEALLOCATE cur_sorTtc
											return
										end
									else
										begin
			   								insert into JMHIS..bdFY (dw,brbl,brxm,brch,fyh,dj,fysl,fyje,opdm,fyks,fyrq,rec1,gg,mc,zjm,jcks,jx,sflb,codejoin,xmlb,fylb,yplb,rylsh,jgts,zxrq,xh,ysdm,yf,jl,cs)
												select '1',brbl,brxm,brch,b.py,b.bzdj,c.sl,b.bzdj*c.sl,opdm,fyks,GETDATE(),rec1,b.gg,b.mc,b.zjm,@jcks,jx,sflb,b.codejoin,b.xmlb,fylb,b.dj1,@rylsh,1,getdate(),a.xh,a.ysdm,a.yf,a.jl,a.cs from JMHIS..bdyp a ,JMHIS..bffy  b ,JMHIS..bfzywh c
         										where a.fyh=c.dm and a.ys_1_1=@ys_1_1  and c.py = b.py and ( b.SYBZ is null or b.SYBZ<>'4') and a.fyrq is null 
											SELECT 	@ll_fyje=SUM(b.bzdj*c.sl) FROM JMHIS..bffy  b ,JMHIS..bfzywh c 
         									where c.dm=@fyh and c.py = b.py and ( b.SYBZ is null or b.SYBZ<>'4') 
										end
								  update JMHIS..bdyp set fyrq=getdate(),jyqrbz=2,jydh=@APPLY_ID where YS_1_1=@YS_1_1 --shbz=1, zxrq=getdate() ,--20161109 syz
								END  
							ELSE
							  BEGIN
								insert into JMHIS..bdFY (dw,brbl,brxm,brch,fyh,dj,fysl,fyje,opdm,fyks,fyrq,rec1,gg,mc,zjm,jcks,jx,sflb,codejoin,xmlb,fylb,yplb,rylsh,jgts,zxrq,xh,ysdm,yf,jl,cs)
									select '1',brbl,brxm,brch,b.py,b.bzdj,A.YCSL*A.YTCS,B.bzdj*A.YCSL*A.YTCS,opdm,fyks,GETDATE(),rec1,b.gg,b.mc,b.zjm,@jcks,jx,sflb,b.codejoin,b.xmlb,fylb,b.dj1,@rylsh,1,getdate(),a.xh,a.ysdm,a.yf,a.jl,a.cs from JMHIS..bdyp a ,JMHIS..bffy  b 
         							where a.fyh=b.py and a.ys_1_1=@ys_1_1 and a.tcxh=@APPLY_ID  and ( b.SYBZ is null or b.SYBZ<>'4')  and a.fyrq is null 										
								 SELECT 	@ll_fyje=SUM(B.bzdj*A.Zsl) from JMHIS..bdyp a ,JMHIS..bffy  b 
         								where a.fyh=b.py and a.ys_1_1=@ys_1_1  and ( b.SYBZ is null or b.SYBZ<>'4')
								update JMHIS..bdyp set fyrq=getdate(),jyqrbz=2,jydh=@APPLY_ID where    ys_1_1=@ys_1_1--fdh 2014.0630  zxrq=getdate() ,shbz=1, 
								END
				 
							update JMHIS..bdbr set brye=isnull(brye,0) -isnull(@ll_fyje,0)   where brbl=@ls_bl
							update BS_YSGZZ..YS01014 SET YS_1_22=@zxhs,YS_1_23=3 ,YS_1_33=getdate()  WHERE  YS_1_1=@YS_1_1   
							update bs_ysgzz..ys01060 set ys_1_40 = 1,YS_1_37=1 where ys_1_3 = @APPLY_ID  ----更新检查单的计费状态
							--select @return_code =0
						end
					  FETCH  CUR_SORTtc  INTO @TCXH,@FYH,@ZSL,@SHBZ,@YS_1_1,@ls_bl,@ZSL ,@zxhs,@fyrq
				END
				CLOSE cur_sorTtc
				DEALLOCATE cur_sorTtc
				select @return_code =0
				insert into JMHIS..tmp_fs values (@APPLY_ID,@return_code,@return_message)
		END 	
	else
			begin
				set @return_code =1
				set @return_message= '错误的申请单主记录号!'
				return
			end
end 
if @p_TYPE='1'
begin
	update bs_ysgzz..ys01060 set ys_1_40 = 1 where ys_1_3 = @APPLY_ID  ----更新检查单的计费状态
end














GO


