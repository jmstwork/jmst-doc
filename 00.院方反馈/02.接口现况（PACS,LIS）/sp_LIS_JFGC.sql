USE [interface]
GO

/****** Object:  StoredProcedure [dbo].[sp_LIS_JFGC]    Script Date: 03/08/2017 16:25:37 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[sp_LIS_JFGC]   ---�Ʒѹ���
@APPLY_ID varchar(50), --in�����뵥����¼
@NO int  , -- in�� ���
@return_code int output,  --out:��������� 0���ɹ� 1:���ɹ� 
@return_message varchar(100) output --out: ������Ϣ
as
declare @p_TYPE varchar(50), --���� ,
        @PA_ID varchar(50),--����ID��
	   @REFER_NO Bigint,--����ҽ��Ψһ��Ӧ��
		@ll_fyje decimal (18,2),
		@num  int,
		@ls_bl  varchar(50),
		@FYH varchar(50)
insert into lis_jf_log(apply_id,xh,sj)
values(@APPLY_ID,@NO,getdate())
declare @jcks varchar(4),@rylsh varchar(20),@status INT ,@zxhs   varchar(100),@mxid int,@count int,@yzmc varchar(100),@brxm varchar(20),@fyrq datetime
select @jcks ='HY'
select @count = 0
select @num = count(*) from lis_lab_sheet where APPLY_ID=@APPLY_ID
if @num = 1 
	begin 
		select @p_TYPE=TYPE,@PA_ID=PA_ID , @REFER_NO=REFER_NO from lis_lab_sheet where APPLY_ID=@APPLY_ID--I��סԺ  E������
		if @p_type = 'I' or @p_type = 'i'
			begin

               SELECT @status=status, @mxid=mx_id FROM lis_lab_item  where APPLY_ID=@APPLY_ID  and no=@NO
				IF @status=3 
					begin
						set @return_code  = 1 
						set @return_message = '�Ѿ��Ƿ�!'
						return
					end
                 else
                    begin   
						select @rylsh=rylsh ,@brxm=brxm from JMHIS..bdbr  where brbl=@PA_ID
						---select @count=count(*) from aa..bdyp where ys_1_1=@mxid
						DECLARE @brch   varchar(20),@OPDM   varchar(20),@FYKS   varchar(20),@rec1 decimal(18,0),@zsl decimal(18,0)
						select @ls_bl=brbl,@ll_fyje =zje,@FYH=FYH,@zxhs=ZXHS,@BRCH=brch,@OPDM=OPDM,@FYKS=FYKS,@REC1=rec1,@zsl=zsl,@fyrq=fyrq  from JMHIS..bdyp  where ys_1_1=@mxid

						select @yzmc=ys_1_9 from bs_ysgzz..ys01014 where ys_1_1=@mxid
					    if @yzmc is null 
							begin
								set @return_code  = 1
								set @return_message = @brxm+'����Ŀ�Ѿ���ҽ��ɾ��,�������ҽ���ͻ�ʿ��ϵ,�����ش��鵥���ߵ�סԺ����¼�շ�'
								return
							end	
						if	@ls_bl= '' 
							begin
								set @return_code  = 1
								set @return_message = @brxm+'��'+@yzmc+'û���䵽��ʿ����վ�򱻻�ʿɾ����,�������ҽ���ͻ�ʿ��ϵ,�����ش����ߵ�סԺ����¼�շ�'
								return
							end	
						--�ײ͵�ϸ��ҩƷ�Ѿ���ͣ��
						select @count= count(a.id) from jmhis..bfzywh a,JMHIS..bffy b ,JMHIS..bdyp where 		ys_1_1=@mxid  and a.py=b.py and a.dm=@fyh and (b.sybz=4)
						if(@count>0)
						begin
							set @return_code  = 1  
							set @return_message = '�Ʒ�ʧ��,�ײ͵�ϸ��ҩƷ�Ѿ���ͣ��'
							return
						end
						---------------
						IF SUBSTRING(@FYH,1,2)='TL'  
							insert into JMHIS..bdFY (brbl,brxm,brch,fyh,dj,fysl,fyje,opdm,fyks,fyrq,rec1,mc,xmlb,codejoin,fylb,rylsh,jgts,zxrq,sflb,zfbl,yplb,ysdm)
							select brbl,brxm,brch,b.py,b.bzdj,c.sl,b.bzdj*c.sl,opdm,fyks,GETDATE(),rec1,b.mc,@jcks,b.codejoin,b.badx,@rylsh,1,getdate(),b.sflb,b.dj1,b.yplb,e.��Ա���
							from JMHIS..bdyp a left outer join JMHIS..mz_ry e on a.ysdm=e.ref_javaid,JMHIS..bffy  b ,JMHIS..bfzywh c
							where a.fyh=c.dm and a.ys_1_1=@mxid 
							and c.py = b.py and ( b.SYBZ is null or b.SYBZ<>'4') 
							and a.fyrq is null 
						ELSE
							insert into JMHIS..bdFY (brbl,brxm,brch,fyh,dj,fysl,fyje,opdm,fyks,fyrq,rec1,mc,xmlb,codejoin,fylb,rylsh,jgts,zxrq,sflb,zfbl,yplb,ysdm)
							select brbl,brxm,brch,b.py,b.bzdj,A.Zsl,B.bzdj*A.Zsl,opdm,fyks,GETDATE(),rec1,a.mc,@jcks,b.codejoin,b.badx,@rylsh,1,getdate(),b.sflb,b.dj1,b.yplb,(select e.��Ա��� from jmhis..mz_ry e where e.ref_javaid=a.ysdm) as ysdm
							from JMHIS..bdyp a , JMHIS..bffy  b 
							where a.fyh=b.py and a.ys_1_1=@mxid  
							and ( b.SYBZ is null or b.SYBZ<>'4') 
							and a.fyrq is null	 
							
						if @fyrq is not null insert into lis_jf_log(apply_id,xh,sj) 		values(@APPLY_ID,@NO,@fyrq)
    
						update JMHIS..bdyp set fyrq=getdate(),jyqrbz=3,jydh=@APPLY_ID where  ys_1_1=@mxid and fyrq is null --,zxrq=getdate() ,shbz=1---tcxh=@REFER_NO and 
						update JMHIS..bdbr   set brye=isnull(brye,0) -isnull(@ll_fyje,0)   where brbl=@ls_bl
						update lis_lab_item set status=3 where APPLY_ID=@APPLY_ID and No=@NO
						update BS_YSGZZ..YS01014 SET YS_1_22=@zxhs,YS_1_23=3  WHERE  ys_1_1=@mxid  --,YS_1_33=getdate() 
						select @return_code =0
                    end   
			end 
			if @p_type = 'O'--O������
				begin
					update lis_lab_item set status=3 where APPLY_ID=@APPLY_ID and No=@NO
					select @return_code =0
					return
				end
			if @p_type = 'T'--O�����
				begin
					select @return_code =0
					return
				end
			if @p_type <> 'I' and @p_type <> 'O' and @p_type <> 'T'
				begin
					set @return_code  = 1
					set @return_message = '@p_type���ʹ���!'
					return
				end
   end
else
	begin
			set @return_code =1
			set @return_message= '��������뵥����¼��!'
			return
	end












GO


