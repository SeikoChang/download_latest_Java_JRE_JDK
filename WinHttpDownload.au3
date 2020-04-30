#include "WinHttp.au3"

$s_uname = 'user'
$s_pword = 'pass'
$s_site = 'https://site.com'
$s_login_path = 'path/to/login'
$s_file_path = 'path/to/file'

; Initialize and get session handle
$hOpen = _WinHttpOpen()
; Get connection handle
$hConnect = _WinHttpConnect($hOpen, $s_site)

; Fill the login form:
_WinHttpSimpleFormFill($hConnect, _
        $s_login_path, _
        "login-form", _
        "name:LoginForm[username]", $s_uname, _
        "name:LoginForm[password]", $s_pword)

$s_data = _WinHttpSimpleSSLRequest($hConnect, Default, $s_file_path)

; Close connection handle
_WinHttpCloseHandle($hConnect)
; Close session handle
_WinHttpCloseHandle($hOpen)

; Write the data to the file
FileWrite('Data.csv', $s_data)