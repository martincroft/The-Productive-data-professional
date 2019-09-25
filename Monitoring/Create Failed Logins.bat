SQLCMD -S  bob -U sa -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U Hacker -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U AnotherHacker -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U SomeoneTryingtoLookatpayroll -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U John -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U sa -P Passw0rd  -Q"Select @@Servername"
SQLCMD -S  bob -U sa -P Passw0rd  -Q"Select @@Servername"
pause