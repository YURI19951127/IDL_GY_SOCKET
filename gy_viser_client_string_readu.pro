pro GY_VISER_CLIENT_string_readu
  compile_opt hidden
  Error = 0
  catch,Error
  If (Error ne 0) then Begin
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
  socket,clientlun,'192.168.0.198',9002,READ_TIMEOUT=3.,error=a,connect_timeout=3.,write_timeout=3.,width=200;,/rawio
  json = '{"Requuest":"Read"}'
  ;json_EX='{"Requuest": "Set","ExposureTime": 1000}'
  if a eq 0 then begin
    i = 'C:\Users\dell\Desktop\GY_VISER_socket.txt'
    get_lun,file
    openu,file,i,error=a,width=200 
    if a ne 0 then openw,file,i,error=a,width=200
    if a eq 0 then begin
      ;json = {Requuest:"Read"}
      ;json=JSON_SERIALIZE(json)
      ;print,json
      i = systime(1)      
      writeu,clientlun,json;json_EX;JSON_SERIALIZE(json)           
      bigbuffer = bytarr(32768)
      length = 0l
      a = bigbuffer
      repeat begin
        readu,clientlun,bigbuffer,transfer_count = TC
;        if (TC ne 0) then begin
          a[length] = bigbuffer[0:TC - 1]
          length += TC 
          a = [a,bigbuffer]
;          if (length lt bigbuffer.length) then begin
;            a = bytarr(bigbuffer.length - length)
;          endif
;         while TC NE 32768 do begin
;           a[length] = bigbuffer[0:TC - 1]
;           length += TC
;           a = [a,bigbuffer]
;         endwhile
         
;        endif
      endrep until (size(a,/n_elements) gt 1980000l)
      ;print,a
      ;print,string(a),size(a),i
      
      writeu,file,a
      ;printf,file,a
      i-=systime(1)
      ;print,a
      print,-1/i             
    endif
    close,file,/force
    free_lun,file,/force
  endif
  close,clientlun,/force
  free_lun,clientlun,/force
end

;pro GY_viser_clientlun_stop,clientlun=clientlun
;  compile_opt hidden
;  close,clientlun,/force
;  free_lun,clientlun,/force
;  return
;end