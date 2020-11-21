CLASS test_mime_repository_api DEFINITION
      FINAL
      FOR TESTING
      RISK LEVEL HARMLESS
      DURATION MEDIUM.
  PRIVATE SECTION.
    CONSTANTS:
      gc_path_to_tested_folder TYPE string VALUE `/sap/bc/bsp/sap/public/zmime_repo_test`,
      gc_dev_package           TYPE devclass VALUE `$MIME_REPO_TEST`.
    DATA:
      mime_repository TYPE REF TO if_mr_api.

    METHODS:
      delete_all_files_in_folder,
      create_new_file IMPORTING file_name    TYPE clike
                                file_content TYPE clike,
      setup,
      teardown,
      setup_2,
      teardown_1,
      setup_3,
      setup_1,
      test_missed_folder FOR TESTING,
      test_folder_existence FOR TESTING,
      test_put_method_as_create FOR TESTING RAISING cx_static_check,
      test_get_method_as_read FOR TESTING RAISING cx_static_check,
      test_delete_method FOR TESTING RAISING cx_static_check,
      test_put_method_as_update FOR TESTING RAISING cx_static_check,
      test_file_list_method FOR TESTING RAISING cx_static_check,
      test_properties_method FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS test_mime_repository_api IMPLEMENTATION.
  METHOD delete_all_files_in_folder.
    DATA: files TYPE string_table.

    " Get list of files in the folder
    mime_repository->file_list( EXPORTING i_url = `.`
                                          i_check_authority = abap_false
                                IMPORTING e_files = files
                                EXCEPTIONS error_occured = 1
                                           is_not_folder = 2
                                           not_found = 3
                                           parameter_missing = 4
                                           permission_failure = 5
                                           OTHERS = 6
                              ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).

    DATA: file_size TYPE i.
    FIELD-SYMBOLS: <file> LIKE LINE OF files.

    " Delete each file in the folder
    LOOP AT files ASSIGNING <file>.
      mime_repository->delete( EXPORTING i_url = <file>
                                         i_check_authority = abap_false
                                         i_suppress_dialogs = abap_false
                               EXCEPTIONS  parameter_missing = 1
                                           error_occured = 2
                                           cancelled = 3
                                           permission_failure = 4
                                           not_found = 5
                                           OTHERS = 6
                             ).
*      cl_abap_unit_assert=>assert_subrc( exp = 0
*                                         act = sy-subrc ).
    ENDLOOP.
  ENDMETHOD.

  METHOD create_new_file.
    DATA: file_content_hex TYPE xstring.

    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = file_content
      IMPORTING
        buffer = file_content_hex.

    mime_repository->put( EXPORTING i_url = file_name
                                    i_content = file_content_hex
                                    i_dev_package = gc_dev_package
                                    i_check_authority = abap_false
                                    i_suppress_dialogs = abap_true
                                    i_suppress_package_dialog = abap_true
                          EXCEPTIONS cancelled = 1
                                     data_inconsistency = 2
                                     error_occured = 3
                                     is_folder = 4
                                     new_loio_already_exists = 5
                                     parameter_missing = 6
                                     permission_failure = 7
                                     OTHERS = 8 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
  ENDMETHOD.

  METHOD setup.
    mime_repository = cl_mime_repository_api=>if_mr_api~get_api( i_prefix = gc_path_to_tested_folder ).
    cl_abap_unit_assert=>assert_bound( mime_repository ).
  ENDMETHOD.

  METHOD teardown.
    FREE mime_repository.
  ENDMETHOD.

  METHOD test_missed_folder.
    DATA:
      files TYPE string_table.

    mime_repository->file_list( EXPORTING i_url = gc_path_to_tested_folder && sy-datum && sy-uzeit
                                i_check_authority = abap_false
                                IMPORTING e_files = files
                                EXCEPTIONS not_found = 1
                                           OTHERS = 2 ).
    cl_abap_unit_assert=>assert_subrc( exp = 1
                                       act = sy-subrc ).
  ENDMETHOD.

  METHOD test_folder_existence.
    DATA:
      is_folder TYPE abap_bool.

    mime_repository->get( EXPORTING i_url = `.`
                                    i_check_authority = abap_false
                          IMPORTING e_is_folder = is_folder
                          EXCEPTIONS not_found = 1
                                     OTHERS = 2 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
    cl_abap_unit_assert=>assert_true( is_folder ).
  ENDMETHOD.

  METHOD test_put_method_as_create.
    setup_1( ).

    DATA: file_content         TYPE string,
          encoded_file_content TYPE xstring.

    file_content = '12345'.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = file_content
      IMPORTING
        buffer = encoded_file_content.

    mime_repository->put( EXPORTING i_url = `testFile1.js`
                                    i_content = encoded_file_content
                                    i_check_authority = abap_false
                                    i_dev_package = gc_dev_package
                                    i_suppress_dialogs = abap_true
                                    i_suppress_package_dialog = abap_true
                          EXCEPTIONS cancelled = 1
                                     data_inconsistency = 2
                                     error_occured = 3
                                     is_folder = 4
                                     new_loio_already_exists = 5
                                     parameter_missing = 6
                                     permission_failure = 7
                                     OTHERS = 8 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).

    teardown_1( ).
  ENDMETHOD.

  METHOD test_get_method_as_read.
    setup_2( ).

    " Read existing file.
    DATA: file_content         TYPE xstring,
          decoded_file_content TYPE string.

    mime_repository->get( EXPORTING i_url = `testFile1.js`
                                    i_check_authority = abap_false
                          IMPORTING  e_content = file_content
                         EXCEPTIONS  parameter_missing = 1
                                     error_occured = 2
                                     not_found = 3
                                     permission_failure = 4
                                     OTHERS = 5 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
    CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING'
      EXPORTING
        im_xstring = file_content
      IMPORTING
        ex_string  = decoded_file_content.
    cl_abap_unit_assert=>assert_equals( exp = `12345`
                                        act = decoded_file_content ).

    teardown_1( ).
  ENDMETHOD.

  METHOD test_delete_method.
    setup_2( ).

    " Delete existing file
    mime_repository->delete( EXPORTING i_url = `testFile1.js`
                                         i_check_authority = abap_false
                                         i_suppress_dialogs = abap_false
                               EXCEPTIONS  parameter_missing = 1
                                           error_occured = 2
                                           cancelled = 3
                                           permission_failure = 4
                                           not_found = 5
                                           OTHERS = 6
                             ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).

    " Test existence of the file
    mime_repository->get( EXPORTING i_url = `testFile1.js`
                                    i_check_authority = abap_false
                         EXCEPTIONS  parameter_missing = 1
                                     error_occured = 2
                                     not_found = 3
                                     permission_failure = 4
                                     OTHERS = 5 ).
    cl_abap_unit_assert=>assert_subrc( exp = 3
                                       act = sy-subrc ).

    teardown_1( ).
  ENDMETHOD.

  METHOD test_put_method_as_update.
    setup_2( ).

    " Update file with new content.
    create_new_file( file_name = `testFile2.js`
                     file_content = `123456` ).

    " Compare content of files.
    DATA: file_content         TYPE xstring,
          decoded_file_content TYPE string.
    mime_repository->get( EXPORTING i_url = `testFile2.js`
                                    i_check_authority = abap_false
                          IMPORTING e_content = file_content
                          EXCEPTIONS parameter_missing = 1
                                     error_occured = 2
                                     not_found = 3
                                     permission_failure = 4
                                     OTHERS = 5 ).
    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
    CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING'
      EXPORTING
        im_xstring = file_content
      IMPORTING
        ex_string  = decoded_file_content.
    cl_abap_unit_assert=>assert_equals( exp = `123456`
                                        act = decoded_file_content ).

    teardown_1( ).
  ENDMETHOD.

  METHOD test_file_list_method.
    setup_3( ).

    DATA: files TYPE string_table.

    mime_repository->file_list( EXPORTING i_url = `.`
                                          i_check_authority = abap_false
                                IMPORTING e_files = files
                                EXCEPTIONS error_occured = 1
                                           is_not_folder = 2
                                           not_found = 3
                                           parameter_missing = 4
                                           permission_failure = 5
                                           OTHERS = 6
                              ).

    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( files ) ).

    teardown_1( ).
  ENDMETHOD.

  METHOD test_properties_method.
    setup_2( ).

    DATA: file_name TYPE string,
          file_size TYPE i.
    mime_repository->properties( EXPORTING i_url = `testFile1.js`
                                           i_check_authority = abap_false
                                 IMPORTING e_name = file_name
                                           e_size = file_size
                                 EXCEPTIONS error_occured = 1
                                            not_found = 2
                                            parameter_missing = 3
                                            permission_failure = 4
                                            OTHERS = 5
                               ).

    cl_abap_unit_assert=>assert_subrc( exp = 0
                                       act = sy-subrc ).
    " It's strange?! Returned name is in upper case.
    cl_abap_unit_assert=>assert_equals( exp = `TESTFILE1.JS`
                                        act = file_name ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = file_size ).

    teardown_1( ).
  ENDMETHOD.

  METHOD setup_1.
    " Clear the folder
    delete_all_files_in_folder( ).
  ENDMETHOD.

  METHOD setup_2.
    " Clear the folder
    delete_all_files_in_folder( ).
    " Create new file
    create_new_file( file_name = `testFile1.js`
                     file_content = `12345` ).
  ENDMETHOD.

  METHOD setup_3.
    " Clear the folder
    delete_all_files_in_folder( ).
    " Create new file
    create_new_file( file_name = `testFile1.js`
                     file_content = `12345` ).
    " Create new file
    create_new_file( file_name = `testFile2.js`
                     file_content = `123456` ).
  ENDMETHOD.

  METHOD teardown_1.
    " Clear the folder
    delete_all_files_in_folder( ).
  ENDMETHOD.
ENDCLASS.
