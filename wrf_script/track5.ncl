;********************************************************
; Plot storm stracks from wrfout files.
;********************************************************
;
; JUN-18-2005 
; So-Young Ha (MMM/NCAR)
; SEP-01-2006
; Slightly modified by Mary Haley to add some extra comments.
; ===========================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"


begin

; DATES
  date = (/0906,0909,0912,0915,0918,0921,1000,1003,1006,1009,1012,1015,1018/)
  ndate = 13;dimsizes(date)

  sdate = sprinti("%4.0i",date)

; Experiment name (for legend)
  EXP = (/"EXP_I"/)                ; (/"EXP_I","EXP_II","EXP_III"/)
  nexp = dimsizes(EXP)

; To get lat/lon info.

  a = addfile("/media/liyuan3970/Data/demo4_run2/wrfout_d01_2019-08-09_06:00:00.nc","r")

  lat2d = a->XLAT(0,:,:)
  lon2d = a->XLONG(0,:,:)
  dimll = dimsizes(lat2d)
  nlat  = dimll(0)
  mlon  = dimll(1)

; Sea Level Pressure
  slp = wrf_user_getvar(a,"slp",-1)
  slp2d = slp
  ;printVarSummary(slp2d)
  dims = dimsizes(slp(0,:,:))

; Array for track
  time = new(ndate,string)
  imin = new(ndate,integer)
  jmin = new(ndate,integer)
  smin = new(ndate,integer)
  slp1d= new((/13,99*87/),float)

; =======
;  ndate
; =======

  nfs= 13;dimsizes(fs)


  do ifs=0,nfs-1

    
; We need to convert 2-D array to 1-D array to find the minima.
    slp1d(ifs,:)=ndtooned(slp2d(ifs,:,:))
    smin(ifs) = minind(slp1d(ifs,:))

; Convert the index for 1-D array back to the indeces for 2-D array.
    minij     = ind_resolve(ind(slp1d(ifs,:).eq.min(slp2d(ifs,:,:))),dims)
    imin(ifs) = minij(0,0)
    jmin(ifs) = minij(0,1)

;    print(time(ifs)+" : "+min(slp2d)+" ("+imin(ifs)+","+jmin(ifs)+")")
  end do
;

; Graphics section

  wks=gsn_open_wks("ps","track5")              ; Open PS file.
  gsn_define_colormap(wks,"BlGrYeOrReVi200")  ; Change color map.

  res                     = True
  res@gsnDraw             = False             ; Turn off draw.
  res@gsnFrame            = False             ; Turn off frame advance.
  res@gsnMaximize         = True              ; Maximize plot in frame.

  res@tiMainString = "Typhoon LiQiMa"       ; Main title

  WRF_map_c(a,res,0)                          ; Set up map resources
                                              ;    (plot options)
  plot = gsn_csm_map(wks,res)                 ; Create a map.

; Set up resources for polymarkers.
  gsres                = True
  gsres@gsMarkerIndex  = 16                  ; filled dot
  ;gsres@gsMarkerSizeF = 0.005               ; default - 0.007
  cols                  = (/5,160,40/)

; Set up resources for polylines.
  res_lines                      = True
  res_lines@gsLineThicknessF     = 3.           ; 3x as thick

  dot  = new(ndate,graphic)    ; Make sure each gsn_add_polyxxx call
  line = new(ndate,graphic)    ; is assigned to a unique variable.

; Loop through each date and add polylines to the plot.
  do i = 0,ndate-2
     res_lines@gsLineColor           = cols(0)
     xx=(/lon2d(imin(i),jmin(i)),lon2d(imin(i+1),jmin(i+1))/)
     yy=(/lat2d(imin(i),jmin(i)),lat2d(imin(i+1),jmin(i+1))/)
     line(i) = gsn_add_polyline(wks,plot,xx,yy,res_lines)
  end do

  lon1d = ndtooned(lon2d)
  lat1d = ndtooned(lat2d)

; Loop through each date and add polymarkers to the plot.
  do i = 0,ndate-1
     print("dot:"+lon1d(smin(i))+","+lat1d(smin(i)))
     gsres@gsMarkerColor  = cols(0)
     dot(i)=gsn_add_polymarker(wks,plot,lon1d(smin(i)),lat1d(smin(i)),gsres)
  end do

; Date (Legend)
  txres               = True
  txres@txFontHeightF = 0.015
  txres@txFontColor   = cols(0)

  txid1 = new(ndate,graphic)
; Loop through each date and draw a text string on the plot.
  do i = 0, ndate-1
     txres@txJust = "CenterRight"
     ix = smin(i) - 4
     print("Eye:"+ix)
     if(i.eq.1) then
        txres@txJust = "CenterLeft"
        ix = ix + 8
     end if
     txid1(i) = gsn_add_text(wks,plot,sdate(i),lon1d(ix),lat1d(ix),txres)
  end do

; Add marker and text for legend. (Or you can just use "pmLegend" instead.)
  txres@txJust = "CenterLeft"

  txid2 = new(nexp,graphic)
  pmid2 = new(nexp,graphic)
  ;do i = 0,nexp-1
  ;   gsres@gsMarkerColor  = cols(i)
  ;   txres@txFontColor    = cols(i)
  ;   ii = ((/129,119,109/))  ; ilat
  ;   jj = ((/110,110,110/))  ; jlon
  ;   ji = ii*mlon+jj         ; col x row
  ;   pmid2(i) = gsn_add_polymarker(wks,plot,lon1d(ji(i)),lat1d(ji(i)),gsres)
  ;   txid2(i) = gsn_add_text(wks,plot,EXP(i),lon1d(ji(i)+5),lat1d(ji(i)),txres)
  ;end do

  draw(plot)
  frame(wks)
end
