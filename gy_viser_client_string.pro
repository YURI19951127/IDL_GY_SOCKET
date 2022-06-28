function GY_Viser_GetFilename,data,id=id
  ;根据viser原始数据data中的时间记录生成文件名；文件暂依旧例。今后将加入载荷名称等。
  ;data：原始数据文件，从中可提取时间信息。data可缺省，当不存在时，采用系统时间
  ;ID：viser的指定机器名称，如存在，文件名为：ID_旧例时间.txt
  compile_opt hidden
  cfg={data:'',id:0l}
  if n_elements(data) gt 0 then begin
    cfg.data=data[0]
    if n_elements(ID) gt 0 then begin
      cfg.id=id[0]
      file='ID'+'_'+data."time"+'.txt'
      return,file
    endif else begin
      file=data."time"+'.txt'
    endelse
  endif else begin
    file=systime()+'.txt'
    return,file
  endelse    
end

pro GY_Viser_SaveRawfile,data,file,error=error
  ;将viser的原始数据data,保存在文件file中
  ;data：对VISER读入的原始数据
  ;file:要保存的文件名，文件名的命名按旧例，路径自定义。文件名的时间信息来自于data及文件自身的时间
  ;error：返回保存情况,0表成功，其余为出错代码
  compile_opt hidden
  Error = 0
  catch,Error
  If Error ne 0 then Begin   
    print,!error_state.msg
    if n_elements(lun) eq 1 then begin
      close,lun,/force
      free_lun,lun,/force
    endif
    Return
  EndIf
  if n_elements(data) gt 0 then begin
    get_lun,lun
    openw,lun,file
    writeu,lun,data
    return,0
  endif else return,!error_state.msg    
end


function GY_Viser_Clinet_Open,host,port,READ_TIMEOUT=READ_TIMEOUT,WRITE_TIMEOUT=WRITE_TIMEOUT,CONNECT_TIMEOUT=CONNECT_TIMEOUT,rawio=rawio
  ;host,;port,_timeout等参数同GY_VISER_CLIENT_RUN，从GY_VISER.ini中可读入
  ;返回打开的CLENTLUN句柄。当负值时表出错
  compile_opt hidden
  cfg={host:'198.168.0.198',port:9002l,READ_TIMEOUT:0.01,WRITE_TIMEOUT:0.02,CONNECT_TIMEOUT:0.5,rawio:0b}
  if n_elements(host) gt 0 then cfg.host=host[0] else begin;'192.168.0.198'
    a=zyc_getsyspath('GY_Viser')+'GY_VISER.ini'
    a=zyc_sys_readconfigfile(a,cfg=cfg)
  endelse
  if n_elements(READ_TIMEOUT) gt 0 then cfg.READ_TIMEOUT=READ_TIMEOUT[0]
  if n_elements(WRITE_TIMEOUT) gt 0 then cfg.WRITE_TIMEOUT=WRITE_TIMEOUT[0];0.02
  if n_elements(CONNECT_TIMEOUT) gt 0 then cfg.CONNECT_TIMEOUT=CONNECT_TIMEOUT[0];0.5
  if n_elements(port) gt 0 then cfg.port=port[0];9002
  if n_elements(rawio) gt 0 then cfg.rawio=keyword_set(rawio)
  get_lun,clientlun
  socket,clientlun,cfg.host,cfg.port,error=a,/SWAP_IF_BIG_ENDIAN,READ_TIMEOUT=cfg.READ_TIMEOUT,WRITE_TIMEOUT=cfg.WRITE_TIMEOUT,CONNECT_TIMEOUT=cfg.CONNECT_TIMEOUT,rawio=cfg.rawio
  if a ne 0 then return clientlun=a
  return,clientlun
end


function GY_Viser_Client_GetData,ClientLun,save=save,path=path,shm=shm
  ;从指定的ClientLUN按协议读入VISER的原始数据。
  ;返回读入的原始数据。当读入败时返回－1
  ;ClientLun：打开的viser的socket句柄

  ;save：设置时同步按协议文件名写文件，否则只返回不写入,文件位置由path确定
  ;path: 设定的保存的位置，不设定时为缺省系统路径 zyc_getsyspath('GY_Viser_Client_GetData')
  ;shm：为虚拟内存，当指定时，也往此虚拟内存更新数据，数据结构同GY_VISER_VM.vs

  compile_opt hidden
  cfg = {save:'{"Requuest":"Read"}',path:'',shm:'',data:''}
  if n_elements(save) gt 0 then begin
    cfg.save=save[0]
    cfg.path=path[0]
    writeu,ClientLun,cfg.save
    readu,ClientLun,data
    if n_elements(data) gt 0 then begin
      openw,data,cfg.path+'\systime().txt'
      return,data
    endif else return,-1 
  endif else return,cfg.save
end


function GY_Viser_Client_Close,ClientLun
  ;关闭并清空打开的ClientLun句柄
  compile_opt hidden
  Error = 0
  catch,Error
  If Error ne 0 then Begin
    print,!error_state.msg
    if n_elements(ClientLun) eq 1 then begin
      close,ClientLun,/force
      free_lun,ClientLun,/force
    endif
    Return
  EndIf
  close,ClientLun,/force
  free_lun,ClientLun,/force
end





pro GY_VISER_CLIENT_RUN_EVENT,ev
  ;GY_VISER_CLIENT_RUN的事件响应
  compile_opt hidden
  
end

pro GY_VISER_CLIENT_RUN,ev,host=host,port=port,echo=echo,save=save,base=base
  ;启动一个采集VISER数据的独立进程。echo时带一个no_block的界面
  ;host,port,save:同GY_Viser_Client_GetData
  ;echo:带界面可作为控制响应。控制响应包括：启动，停止，退出；save的开关；ev.id发送的开关；状态显示(是否正常采集数据及超时设置),其他控制参数可从GY_Viser.ini的配制文件中获得
  ;当不带界面时，通过虚拟内存GY_VISER_vm.
  ;ev（可选）,作为菜单项启动时传入的菜单事件，当存正时，可通过ev.id发送采集到的数据信息
  ;base,当echo设置时，返回界面的id

  ;启动时自动开始采集数据
  ;GY_VISER.ini中的相关项（位置在缺省系统路径 zyc_getsyspath('GY_VISER_CLIENT_RUN')）：
  ;host=
  ;port=
  ;READ_TIMEOUT=
  ;WRITE_TIMEOUT=
  ;CONNECT_TIMEOUT=
  ;title =
  ;time_dif=


  ;启动后，即采生一个虚拟内存，将采集的数据按虚拟内存的方式保存，虚拟数据结构同GY_VISER_VM.vs，路径与GY_VISER.ini相同
  ;停止和退出操作有警告确认过程
  ;退出时，要退出虚拟内存映射和打开的socket clientLun
  compile_opt hidden
  if n_elements(echo) gt 0 then begin
    if n_elements(base) gt 0 then if base[0] gt 0 then begin
      if keyword_set(quit) then begin
        tmp={WIDGET_KILL_REQUEST,ID:0,TOP:base[0],HANDLER:base[0]}
        GY_VISER_CLIENT_RUN_event,tmp
        return
      endif
    endif
  endif
  
end

pro GY_VISER_CLIENT_Contral,base,stop=stop,quit=quit
  ;对带界面的base，进行外控
  ;base:GY_VISER_CLIENT_RUN中的base,可自动识别或传入
  ;stop:停止采集
  ;quit:退出
  compile_opt hidden
  
end







pro GY_VISER_CLIENT_string
  compile_opt hidden
  Error = 0
  catch,Error
  If Error ne 0 then Begin
    ;Catch, /Cancel
    ;Help, /Last_Message
    print,!error_state.msg
    if n_elements(clientlun) eq 1 then begin
      close,clientlun,/force
      free_lun,clientlun,/force
    endif
    if n_elements(file) eq 1 then begin
      close,file,/force
      free_lun,file,/force
    endif
    Return
  EndIf
  get_lun,clientlun
  socket,clientlun,'192.168.0.198',9002,error=a,/SWAP_IF_BIG_ENDIAN, READ_TIMEOUT=0.1,CONNECT_TIMEOUT =3,WRITE_TIMEOUT=0.2,/rawio
  json = '{"Requuest":"Read"}'
  if a eq 0 then begin
    i = 'C:\Users\ASD_18506\Desktop\GY_VISER_socket.txt'
    get_lun,file
    openu,file,i,error=a
    if a ne 0 then openw,file,i,error=a
    if a eq 0 then begin
      ;json = {Requuest:"Read"}
      ;json=JSON_SERIALIZE(json)
      ;print,json
      i = systime(1)
      writeu,clientlun,json;JSON_SERIALIZE(json)
      a =bytarr(327680ul)
      on_ioerror, eeee
      j=0
      repeat begin
        tmp=0
        readu,clientlun,a,TRANSFER_COUNT=b
        ;print,b
        ;if b eq 0 then print,string(a)
        writeu,file,a;,13b,10b
        tmp=1
        j++
        eeee:if tmp ne 1 then print,tmp,'aaaaaaa'
      endrep until  (tmp eq 0)
      i-=systime(1)
      print,-1/i,j

    endif else print,'File open error!'
    close,file,/force
    free_lun,file,/force
  endif else print,'Socket open error!'
  close,clientlun,/force
  free_lun,clientlun,/force
end