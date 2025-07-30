script "lib_XenoCanto"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_XenoCanto
type: library
version: 0.1


--> Working on
-


--> Xeno | Canto
-
command display_LocalBirds dView
   put "larus fuscus" into spName
   put lcw_Ask ("Species name...", spName, dView) into spName
   --
   put xeno_QueryArray (spName) into qArray
   put xeno_RecodingsData (qArray) into xData
   --
   put xData ["numPages"] into numPages
   put xData ["numRecordings"] into numRecordings
   put xData ["numSpecies"] into numSpecies
   put xData ["page"] into pageNum
   --
   put xData ["recordings"] into rIndexArray
   
   display_Tool rIndexArray, spName, "Xeno Canto", "lcw_Hitchhikers"
end display_LocalBirds

function xeno_QueryArray spName
   put spName into qArray ["sp"]
   --
   return qArray
end xeno_QueryArray

function xeno_RecodingsData qArray
   put xeno_RestUrl ("recordings", qArray) into restURL
   put jsonrpc_GetArray (restURL) into rData
   return rData
end xeno_RecodingsData

function xeno_RestUrl rPath, qArray
   put xeno_RestStem (rPath) into restStem
   put xeno_AddQuery (restStem, qArray) into restURL
   return restURL
end xeno_RestUrl

function xeno_AddQuery restStem, qArray
   put xeno_Query (qArray) into qString
   put restStem & "?query=" & qString into restURL
   --
   put xeno_GetApiKey() into apiKey
   put "&key=" & apiKey after restURL
   return restURL
end xeno_AddQuery

function xeno_Query qArray
   repeat for each key qKey in qArray
      put qKey & ":" after qString
      put qArray [qKey] into qValue
      put kwote (qValue) after qString
      put space after qString
   end repeat
   delete char -1 of qString
   return urlencode (qString)
end xeno_Query

function xeno_RestStem rPath
   put "https://xeno-canto.org" into apiRoot
   put 3 into vNum
   put apiRoot & "/api/" & vNum & "/" into restStem
   put rPath after restStem
   return restStem
end xeno_RestStem

function xeno_GetApiKey
   return secret_Get ("xeno-canto")
end xeno_GetApiKey

command xeno_SetApiKey apiKey
   secret_Set "xeno-canto", apiKey
end xeno_SetApiKey


--> Deps
-
