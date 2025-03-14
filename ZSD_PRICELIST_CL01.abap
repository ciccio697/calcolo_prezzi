*----------------------------------------------------------------------*
***INCLUDE ZSD_PRICELIST_CL01.
*----------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.
  PUBLIC SECTION.

    METHODS:
      user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
      toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive.


ENDCLASS.

CLASS lcl_handle_events IMPLEMENTATION.

  METHOD user_command.
    PERFORM user_command USING e_ucomm.

  ENDMETHOD.                    "user_command

  METHOD toolbar.
    PERFORM toolbar USING e_object.
  ENDMETHOD.                    "toolbar

ENDCLASS.
*&---------------------------------------------------------------------*
*& Form user_command
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM user_command  USING    u_ucomm.


  CASE u_ucomm.
    WHEN 'SEND'.
      PERFORM send.
    WHEN '%EX' OR 'RW' OR 'BACK' .
      SET SCREEN 0.
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM toolbar  USING    cl_object TYPE REF TO cl_alv_event_toolbar_set.
  DATA ls_toolbar TYPE stb_button.

  CLEAR ls_toolbar.

  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'SEND' TO ls_toolbar-function.
  MOVE space TO ls_toolbar-disabled.
  MOVE icon_next_step TO ls_toolbar-icon.
  MOVE TEXT-002 TO ls_toolbar-quickinfo.
  MOVE TEXT-002 TO ls_toolbar-text.
  APPEND ls_toolbar TO cl_object->mt_toolbar .

ENDFORM.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET TITLEBAR 'TITLE01'.
  PERFORM alv.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Form exclude_from_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- lt_ex_toolbar
*&---------------------------------------------------------------------*
FORM exclude_from_toolbar CHANGING j_toolbar TYPE ui_functions.

  DATA: ls_ex TYPE ui_func.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_delete_row.
  APPEND ls_ex TO j_toolbar.
  ls_ex = cl_gui_alv_grid=>mc_fc_loc_insert_row.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_copy_row.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_append_row.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_undo.
  APPEND ls_ex TO j_toolbar.


  ls_ex = cl_gui_alv_grid=>mc_fc_loc_paste.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_cut.
  APPEND ls_ex TO j_toolbar.

  ls_ex = cl_gui_alv_grid=>mc_fc_loc_copy.
  APPEND ls_ex TO j_toolbar.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM alv .
  DATA: ol_objevent   TYPE REF TO lcl_handle_events,
        ls_layo       TYPE lvc_s_layo,
        lt_ex_toolbar TYPE ui_functions,
        ls_variant    TYPE disvariant.


  ls_variant-report = sy-repid.
  ls_variant-username = sy-uname.

  ls_layo-zebra =
  ls_layo-cwidth_opt = abap_true.

*  ls_layo-sel_mode    = 'A'.

  PERFORM get_fcat TABLES gt_fieldcat.

  PERFORM exclude_from_toolbar CHANGING lt_ex_toolbar.

  IF o_alv IS NOT BOUND.


    CREATE OBJECT o_alv
      EXPORTING
        i_parent = cl_gui_container=>screen0.

    CREATE OBJECT ol_objevent.
    IF ol_objevent IS BOUND.
      SET HANDLER ol_objevent->toolbar FOR o_alv.
      SET HANDLER ol_objevent->user_command FOR o_alv.
    ENDIF.

    o_alv->set_table_for_first_display(
    EXPORTING
      i_save                       = 'A'
      is_layout                    = ls_layo
      it_toolbar_excluding         = lt_ex_toolbar
      is_variant                   = ls_variant
    CHANGING
      it_outtab                     = gt_alv
      it_fieldcatalog               = gt_fieldcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4 ).

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ELSE.
    o_alv->refresh_table_display( ).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> gt_fieldcat
*&---------------------------------------------------------------------*
FORM get_fcat  TABLES   t_fcat STRUCTURE lvc_s_fcat.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_bypassing_buffer     = abap_true
      i_structure_name       = 'ZSD_ST_PRICELIST'
    CHANGING
      ct_fieldcat            = t_fcat[]
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  PERFORM user_command USING sy-ucomm.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form send
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM send .
  DATA(ol_send) = NEW zpr_co_sc_0056price_list_async(  ).
  DATA: lo_async_proxy TYPE REF TO if_wsprotocol_async_messaging,
        ls_input       TYPE zpr_mt_req_price_list,
        lv_csend       TYPE i.

  ls_input-mt_req_price_list-partner = p_kunnr.
  ls_input-mt_req_price_list-filename = |LIST_{ p_kunnr ALPHA = OUT }.csv|.
  ls_input-mt_req_price_list-idservice = |BS_{ sy-sysid }_{ sy-mandt }/SC_0056PriceList_Async|.

  IF p_split IS INITIAL.
    ls_input-mt_req_price_list-pricelistdetail = CORRESPONDING #( gt_alv ).
    TRY.
        ol_send->execute( input =  ls_input ).
      CATCH cx_ai_system_fault. " Communication Error

    ENDTRY.
  ELSE.
    lo_async_proxy  ?=  ol_send->get_protocol( if_wsprotocol=>async_messaging ).
    lo_async_proxy->set_serialization_context( |{ p_kunnr }| ).

    DATA(lt_temp) = gt_alv.
    WHILE lt_temp IS NOT INITIAL.
      REFRESH: ls_input-mt_req_price_list-pricelistdetail.
      LOOP AT lt_temp INTO DATA(ls_alv) FROM 1 TO p_nrow.
        APPEND INITIAL LINE TO ls_input-mt_req_price_list-pricelistdetail ASSIGNING FIELD-SYMBOL(<list>).
        <list> = CORRESPONDING #( ls_alv ).
      ENDLOOP.
      DELETE lt_temp FROM 1 TO p_nrow.
      TRY.
          ol_send->execute( input =  ls_input ).
        CATCH cx_ai_system_fault. " Communication Error

      ENDTRY.
    ENDWHILE.

  ENDIF.


  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = abap_true.


  MESSAGE s208(cms).
ENDFORM.
