SET "server=%1"
SET "a=:"
SET "b=_"
CALL SET server=%%server:%a%=%b%%%
ECHO %server%
