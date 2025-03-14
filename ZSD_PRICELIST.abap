*&---------------------------------------------------------------------*
*& Report ZSD_PRICELIST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_pricelist.
TABLES:mara.


DATA: o_alv       TYPE REF TO cl_gui_alv_grid,
      gt_fieldcat TYPE lvc_t_fcat.


CONSTANTS: gc_auart TYPE vbak-auart VALUE 'Z001',
           gc_vkorg TYPE vbak-vkorg VALUE '1000',
           gc_vtweg TYPE vbak-vtweg VALUE '10',
           gc_spart TYPE vbak-spart VALUE '10',
           gc_PSTYV TYPE vbap-pstyv VALUE 'TAN',
           gc_FKARA TYPE vbak-fkara VALUE 'FX',
           gc_WERKS TYPE vbap-werks VALUE 'S001'.


DATA: lt_komfkgn TYPE STANDARD TABLE OF komfkgn,
      lt_komfkko TYPE STANDARD TABLE OF komv,
      lt_t683s   TYPE STANDARD TABLE OF t683s,
      lt_komfk   TYPE STANDARD TABLE OF komfk,
      lt_komv    TYPE STANDARD TABLE OF komv,
      lt_thead   TYPE STANDARD TABLE OF theadvb,
      lt_vbfs    TYPE STANDARD TABLE OF vbfs,
      lt_vbpa    TYPE STANDARD TABLE OF vbpavb,
      lt_vbrk    TYPE STANDARD TABLE OF vbrkvb,
      lt_vbrp    TYPE STANDARD TABLE OF vbrpvb,
      lt_vbss    TYPE STANDARD TABLE OF vbss,
      lt_netpr   TYPE STANDARD TABLE OF vbrpvb,
      ld_vbsk    TYPE vbsk,
      address    TYPE kna1,
      trvog      TYPE c,
      lf_kvorg   TYPE komk-kvorg VALUE '08',
      ld_vtweg   TYPE vbco7-vtweg.


DATA: gt_alv TYPE STANDARD TABLE OF ZSD_St_PRICELIST.
SELECTION-SCREEN BEGIN OF BLOCK p01 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_kunnr TYPE kna1-kunnr OBLIGATORY.
  SELECT-OPTIONS: s_matnr FOR mara-matnr.
  SELECTION-SCREEN:SKIP 1.
  PARAMETERS: p_split AS CHECKBOX USER-COMMAND ucm,
              p_nrow  TYPE i DEFAULT '5000'.

SELECTION-SCREEN END OF BLOCK p01 .

INITIALIZATION.
  PERFORM screen.

AT SELECTION-SCREEN OUTPUT.
  PERFORM screen.

START-OF-SELECTION.

  PERFORM read_data.
  IF sy-batch = abap_true.
    PERFORM send.
  ENDIF.
  PERFORM open_alv.
*&---------------------------------------------------------------------*
*& Form read_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_data .
  DATA:lv_vgbel TYPE vbap-vgbel.

  SELECT SINGLE vtwku
  FROM tvta
  INTO ld_vtweg
  WHERE vkorg = gc_vkorg
  AND   vtweg = gc_VTWEG
  AND   spart = gc_SPART.



  SELECT *
    FROM zcdspricel
    INTO TABLE @DATA(lt_material)
  WHERE productnr IN @s_matnr
  ORDER BY productnr.

  lv_vgbel = sy-uzeit.
  lv_vgbel+6(4) = '9999'.

  lt_komfkgn = VALUE #(
  FOR list IN lt_material (
  mandt   = sy-mandt
  auart   = gc_auart
  vkorg   = gc_vkorg
  vtweg   = gc_vtweg
  spart   = gc_spart
  fkdat   = sy-datum
  kunag   = p_kunnr
  pstyv   = gc_pstyv
  kwmeng  = COND #( WHEN list-aumng <= 0 THEN 1 ELSE list-aumng  )
  werks   = gc_werks
  vgbel   = lv_vgbel
  fkara   = gc_fkara
  taxm1   = '1'
  taxk1   = '1'
  matnr   = list-productnr
  vgpos   = sy-tabix  " Indice automatico del ciclo
  )
  ).

  gt_alv = CORRESPONDING #( lt_material MAPPING group = prdha ).

  CALL FUNCTION 'GN_INVOICE_CREATE'
    EXPORTING
      vbsk_i            = ld_vbsk
      id_kvorg          = lf_kvorg
      id_no_dialog      = abap_true
      i_without_refresh = abap_true
      id_no_enqueue     = abap_true
      invoice_date      = sy-datum
      pricing_date      = sy-datum
    IMPORTING
      vbsk_e            = ld_vbsk
    TABLES
      xkomfk            = lt_komfk
      xkomfkgn          = lt_komfkgn
      xkomfkko          = lt_komfkko
      xkomv             = lt_komv
      xthead            = lt_thead
      xvbfs             = lt_vbfs
      xvbpa             = lt_vbpa
      xvbrk             = lt_vbrk
      xvbrp             = lt_vbrp
      xvbss             = lt_vbss.

  SORT lt_vbrp BY matnr.
  LOOP AT lt_vbrp INTO DATA(ls_vbrp).
    READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<alv>) WITH KEY productnr = ls_vbrp-matnr
    BINARY SEARCH.
    CHECK sy-subrc = 0.
    <alv>-forprice = ls_vbrp-netwr.
    <alv>-vatcode = ls_vbrp-mwsk1.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form open_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM open_alv .
  CALL SCREEN 100.
ENDFORM.

INCLUDE zsd_pricelist_cl01.
*&---------------------------------------------------------------------*
*& Form screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM screen .
  LOOP AT SCREEN.
    IF screen-name CS 'P_NROW'.
      screen-active = COND #( WHEN p_split IS INITIAL THEN '0' ELSE '1' ).
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.
