class ZCL_UNIX_STATIC definition
  public
  final
  create public .

*"* public components of class ZCL_UNIX_STATIC
*"* do not include other source files here!!!
public section.
  type-pools ABAP .

  class-methods RUN
    importing
      !I_COMMAND type SIMPLE
      !I_PARAMS type SIMPLE optional
      !I_RFC type ABAP_BOOL default ABAP_TRUE
    returning
      value(ET_RESULT) type STRINGTAB
    raising
      ZCX_GENERIC .
  class-methods LIST
    importing
      !I_PATH type DATA
    returning
      value(ET_RESULT) type STRINGTAB
    raising
      ZCX_GENERIC .
  class-methods COPY
    importing
      !I_FROM type DATA
      !I_TO type DATA
    raising
      ZCX_GENERIC .
  class-methods DELETE
    importing
      !I_PATH type DATA
    returning
      value(ET_RESULT) type STRINGTAB
    raising
      ZCX_GENERIC .
  class-methods IS_FILE_EXIST
    importing
      !I_PATH type STRING
    returning
      value(E_EXIST) type ABAP_BOOL
    raising
      ZCX_GENERIC .
  class-methods IS_DIRECTORY_EXIST
    importing
      !I_PATH type SIMPLE
    returning
      value(E_EXIST) type ABAP_BOOL
    raising
      ZCX_GENERIC .
  class-methods CREATE_DIRECTORY
    importing
      !I_PATH type SIMPLE
    raising
      ZCX_GENERIC .
  class-methods DELETE_DIRECTORY
    importing
      !I_PATH type DATA
    raising
      ZCX_GENERIC .
  class-methods CHMOD
    importing
      !I_PATH type SIMPLE
      !I_RECURSIVE type ABAP_BOOL default ABAP_TRUE
      !I_OWNER type C default '7'
      !I_GROUP type C default '7'
      !I_ANYBODY type C default '7'
    raising
      ZCX_GENERIC .
  protected section.
*"* protected components of class ZATMCL_UNIX_STATIC
*"* do not include other source files here!!!
private section.

*"* private components of class ZCL_UNIX_STATIC
*"* do not include other source files here!!!
  class-data DEST type RFCDEST value 'NONE' ##NO_TEXT.
ENDCLASS.



CLASS ZCL_UNIX_STATIC IMPLEMENTATION.


  method chmod.

    data l_permissions(3).
    concatenate i_owner i_group i_anybody into l_permissions.

    data l_params type string.
    concatenate '-R' l_permissions i_path into l_params separated by space.

    run(
      i_command = 'chmod'
      i_params  = l_params ).

  endmethod.


  method copy.

    data l_params type string.
    concatenate i_from i_to into l_params separated by space.

    run(
      i_command = 'cp'
      i_params  = l_params ).

  endmethod.


  method create_directory.

    data l_params type string.
    concatenate '-p' i_path into l_params separated by space.

    run(
      i_command = 'mkdir'
      i_params  = l_params ).

  endmethod.


  method delete.

    run(
      i_command = 'rm'
      i_params  = i_path ).

  endmethod.


  method delete_directory.

    data l_params type string.
    concatenate '-r' i_path into l_params separated by space.

    run(
      i_command = 'rm'
      i_params  = l_params ).

  endmethod.


  method is_directory_exist.

    data l_params type string.
    concatenate '-d' i_path into l_params separated by space.

    data lt_result type stringtab.
    lt_result =
      run(
        i_command = 'test'
        i_params  = l_params ).

    if lt_result is initial.
      e_exist = abap_true.
    endif.

  endmethod.


  method is_file_exist.

    data l_params type string.
    concatenate '-f' i_path into l_params separated by space.

    data lt_result type stringtab.
    lt_result =
      run(
        i_command = 'test'
        i_params  = l_params ).

    if lt_result is initial.
      e_exist = abap_true.
    endif.

  endmethod.


  method list.

    data l_params type string.
    concatenate '-la' i_path into l_params separated by space.

    et_result =
      run(
        i_command = 'ls'
        i_params  = l_params ).

  endmethod.


  method run.

    if i_rfc eq abap_true.

      data l_rfc_command type string.
      l_rfc_command = i_command.

      data l_rfc_params type string.
      l_rfc_params = i_params.

      data lt_messages type zimessages.
      call function 'Z_SRM_UNIX_RUN' destination dest
        exporting
          i_command   = l_rfc_command
          i_params    = l_rfc_params
        importing
          et_result   = et_result
          et_messages = lt_messages.

      loop at lt_messages transporting no fields
        where msgty ca 'EAX'.
        zcx_generic=>raise( it_messages = lt_messages ).
      endloop.

    else.

      data l_extprog type btcxpgpgm.
      l_extprog = i_command.

      data l_params type btcxpgpar.
      l_params = i_params.

      data l_strtstat type btcxpgstat.
      data l_xpgid type btcxpgid.
      data l_convid type gwy_struct-convid.
      data l_exitstat type btcxpgstat.
      data l_exitcode type btcxpgexit.
      data l_last_proc type wpinfo-wp_pid.
      data l_last_host type rfchost.
      data l_last_proc_num type wpinfo-wp_no.
      data lt_log type table of btcxpglog.
      call function 'SXPG_STEP_XPG_START'
        exporting
          extprog             = l_extprog
          params              = l_params
          stdincntl           = 'R'
          stdoutcntl          = 'M'
          stderrcntl          = 'M'
          tracecntl           = '0'
          termcntl            = 'C'
        importing
          strtstat            = l_strtstat
          xpgid               = l_xpgid
          convid              = l_convid
          exitstat            = l_exitstat
          exitcode            = l_exitcode
          last_proc           = l_last_proc
          last_host           = l_last_host
          last_proc_num       = l_last_proc_num
        tables
          log                 = lt_log
        exceptions
          communication_error = 1
          system_error        = 2
          unknown_error       = 3
          cannot_get_rfc_dest = 4
          job_update_failed   = 5
          job_does_not_exist  = 6
          program_start_error = 7
          no_permission       = 8
          others              = 9.
      if sy-subrc ne 0.
        zcx_generic=>raise( ).
      endif.

***  data lt_result type table of text255.
***  call 'SYSTEM'
***    id 'COMMAND' field  l_command
***    id 'TAB'     field  lt_result.
***  if sy-subrc ne 0.
***    message e091 with l_command into dummy.
***    zcx_generic=>raise( ).
***  endif.

      zcl_abap_static=>list2list(
        exporting it_data = lt_log
        importing et_data = et_result ).

    endif.

  endmethod.
ENDCLASS.
