function OutputData2= Poisson_image_editing(inputData00,DataMask00, inputData10,BoundryType)
%%%输入参数inputData0、DataMask0和inputData1，均为uint8类型，输入也为uint8型
%%%输入参数也可均为double型，则输出也为double型
[nh,nw,b]=size(inputData00);
inputData0=zeros(nh+2,nw+2,b)-1;inputData0(2:end-1,2:end-1,:)=inputData00;
inputData1=zeros(nh+2,nw+2,b)-1;inputData1(2:end-1,2:end-1,:)=inputData10;
% if(BoundryType~=1)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%若是基于像素调整边界，则不扩充
DataMask0=imfilter(DataMask00, [0,1,0;1,1,1;0,1,0]);%扩充操作：mask往外扩充1
% end
DataMask0(DataMask0>0)=1;
DataMask=zeros(nh+2,nw+2,1)-1;DataMask(2:end-1,2:end-1,:)=DataMask0;
DataMask0=zeros(nh+2,nw+2,1)-1;DataMask0(2:end-1,2:end-1,:)=DataMask00;
[Array_H,Array_W]=find(DataMask>0);%需替换像素的位置信息---按照一列一列的顺序、从上到下来的
%%构造系数矩阵DiagA
%找出位于边界的像素点，系数矩阵对应行为1
%%%稀疏矩阵构造
% DiagA=eye(length(Array_H));
DiagA_i=zeros(1,length(Array_H));
DiagA_j=zeros(1,length(Array_H));
DiagA_v=ones(1,length(Array_H));
%建立DiagA和[Array_H,Array_W]的坐标对应关系
ArrayWH_index=zeros(max(Array_H),max(Array_W));
for i=1:length(Array_W)
    ArrayWH_index(Array_H(i),Array_W(i))=i;
end
%找出位于内部的像素点,修改矩阵对应行
%%构造系数矩阵MatB，计算散度 inputData1(1:3,1:3,3) OutputData1([1,103],3)
OutputData=imfilter(double(inputData1), [0,1,0;1,-4,1;0,1,0]);%-OutputData--------------------------------------
num_nozeros=1;%稀疏矩阵中非0的个数
for i=1:length(Array_W)
    if ( DataMask0(Array_H(i),Array_W(i))>0)%%未知点
      if( DataMask(Array_H(i)-1,Array_W(i))>0 && DataMask(Array_H(i)+1,Array_W(i))>0 && DataMask(Array_H(i),Array_W(i)-1)>0 && DataMask(Array_H(i),Array_W(i)+1)>0 )
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i; DiagA_v(num_nozeros)=-4; num_nozeros=num_nozeros+1;  
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i-1; DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=ArrayWH_index(Array_H(i),Array_W(i)-1); DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=ArrayWH_index(Array_H(i),Array_W(i)+1); DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i+1; DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
      else %%在边界的情况
          s=0;ls=0;
          if(DataMask(Array_H(i)-1,Array_W(i))>0)
              DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i-1; DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
              s=s+DiagA_v(num_nozeros-1);
              ls=ls+inputData1(Array_H(i)-1,Array_W(i),:)*DiagA_v(num_nozeros-1);
          end
          if(DataMask(Array_H(i),Array_W(i)-1)>0)
              DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=ArrayWH_index(Array_H(i),Array_W(i)-1); DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1; 
              s=s+DiagA_v(num_nozeros-1);
              ls=ls+inputData1(Array_H(i),Array_W(i)-1,:)*DiagA_v(num_nozeros-1);
          end
          if(DataMask(Array_H(i),Array_W(i)+1)>0)   
              DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=ArrayWH_index(Array_H(i),Array_W(i)+1); DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
              s=s+DiagA_v(num_nozeros-1);
              ls=ls+inputData1(Array_H(i),Array_W(i)+1,:)*DiagA_v(num_nozeros-1);
          end
          if(DataMask(Array_H(i)+1,Array_W(i))>0)
              DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i+1; DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
              s=s+DiagA_v(num_nozeros-1);
              ls=ls+inputData1(Array_H(i)+1,Array_W(i),:)*DiagA_v(num_nozeros-1);
          end
          DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i; DiagA_v(num_nozeros)=-s; num_nozeros=num_nozeros+1;
          OutputData(Array_H(i),Array_W(i),:)=ls-s*inputData1(Array_H(i),Array_W(i),:);
      end      
    else %%已知点
        DiagA_i(num_nozeros)=i; DiagA_j(num_nozeros)=i; DiagA_v(num_nozeros)=1; num_nozeros=num_nozeros+1;
        OutputData(Array_H(i),Array_W(i),:)=inputData0(Array_H(i),Array_W(i),:);
    end
end
DiagA=sparse(DiagA_i,DiagA_j,DiagA_v);
clear ArrayWH_index DiagA_i DiagA_j DiagA_v;
DataMask=repmat(DataMask,1,1,b);
OutputData1=OutputData(DataMask>0);
clear DataMask0 OutputData inputData1
OutputData1=reshape(OutputData1,length(OutputData1)/b,b);
OutputData1=double(OutputData1);
for ib=1:b
    setup = struct('type','ilutp','droptol',1e-6);
    [L,U] = ilu(sparse(DiagA),setup);
    OutputData1(:,ib)=bicgstab(DiagA,OutputData1(:,ib),1e-4,100,L,U);
end
OutputData2=inputData0;
OutputData2(DataMask>0)=abs(OutputData1);
OutputData2=OutputData2(2:end-1,2:end-1,:);
OutputData2=uint8(OutputData2);
end 
