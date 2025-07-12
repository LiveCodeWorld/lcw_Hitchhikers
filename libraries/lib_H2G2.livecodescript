script "lib_H2G2"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_H2G2
type: library
version: 0.2


--> Variables
-
local LocalArray


--> Working on
-
function url_AddCorsProxy sURL
   return "https://corsproxy.io/?" & sURL
end url_AddCorsProxy


--> H2G2
-
function h2g2_FetchArticleArray sURL
   -- put "https://h2g2.com/entry/A88070231" into sURL
   local startNum, endNum
   
   if matchText (sURL, "https://h2g2.com/entry/(.+)", aName) is false then
      return "Error, not h2g2.com:" && sURL
   end if
   
   put h2g2_Article (sURL) into aContent
   htmlTag_SetOffsets startNum, endNum, aContent, "header"
   if the result is false then
      return empty
   end if
   
   # Use aName for page title
   set the itemdelimiter to slash
   put item -1 of sURL into aName
   
   # Construct Page Array
   put pageArray_Construct (aName, empty) into pArray
   
   # Use Header for metadata?
   put char startNum to endNum of aContent into sHeader
   delete char 1 to endNum of aContent
   
   # Tidy
   put word 1 to -1 of aContent into cLines -- <div id="entry_content"><span itemprop="articleBody">                   
   delete line 1 of cLines
   delete line -2 to -1 of cLines
   
   # Extract blockquotes
   _StripTags cLines, "blockquote"
   put the result into LocalArray ["blockTagArray"]
   
   # Extract Images
   _StripTags cLines, "img"
   put the result into LocalArray ["imgTagArray"]
   
   # Construct Story
   repeat for each line sLine in cLines
      if sLine is empty then next repeat
      
      switch
         case sLine begins with "[[_BlockQuote("
            put merge (sLine) into mText
            pageArray_AddMarkdown pArray, mText
            break
         case sLine begins with "[[_img("
            put merge (sLine) into imageTag
            --
            put htmlTag_OpeningToArray ("img", imageTag) into tagArray
            put tagArray ["src"] into imageURL
            put tagArray ["alt"] into altWord
            --
            pageArray_AddImage pArray, imageURL, altWord, empty, empty, empty, "wide"
            break
         case word 1 of sLine begins with "<center>"
            pageArray_AddHtml pArray, sLine
            break
         case word 1 of sLine begins with "<p"
         default
            put html_ToMarkDown (sLine) into mdTxet
            if mdTxet contains "<" then
               pageArray_AddHtml pArray, sLine
            else
               pageArray_AddMarkdown pArray, mdTxet
            end if
      end switch
   end repeat   
   --
   return pArray
end h2g2_FetchArticleArray

function h2G2_ArticleHeader sURL
   local startNum, endNum
   put h2g2_Article (sURL) into aContent
   htmlTag_SetOffsets startNum, endNum, aContent, "header"
   if the result is true then
      put char startNum to endNum of aContent into tagHtml
      return tagHtml
   else
      return empty
   end if
end h2G2_ArticleHeader

function h2g2_Article sURL
   -- put "https://h2g2.com/entry/A88070231" into sURL
   put h2g2_FetchCors (sURL) into xHtml
   put htmlTag_Get ("article", xHtml) into aContent
   return aContent
end h2g2_Article

function h2g2_LeftSide sURL
   put "https://h2g2.com/entry/A88070231" into sURL
   put h2g2_FetchCors (sURL) into xHtml
   --
   put html_GetCommentBlock (xHtml, "LEFT HAND SIDE") into cBlock
   return cBlock
end h2g2_LeftSide

function h2g2_FetchCors sURL
   put url_AddCorsProxy (sURL) into corsURL
   put url corsURL into xHtml
   return xHtml
end h2g2_FetchCors


--> Private
-
private Command _StripTags @sHTML, tagName
   put 1 into tagNum
   repeat
      htmlTag_SetOffsets startNum, endNum, sHTML, tagName
      if the result is false then return blockTagArray
      
      put char startNum to endNum of sHTML into blockTag
      put CR & "[[_" & tagName & "(" & tagNum & ")]]" & CR into char startNum to endNum of sHTML
      put blockTag into blockTagArray [tagNum]
      add 1 to tagNum
   end repeat
end _StripTags

function _Img itemNum
   put LocalArray ["imgTagArray"] into imgTagArray
   return imgTagArray [itemNum]
end _Img

function _BlockQuote itemNum
   put LocalArray ["blockTagArray"] into blockTagArray
   return blockTagArray [itemNum]
end _BlockQuote

command _HackCR @sHTML
   /*
   -- hscky stripping of br and p's
   if char 1 to 3 of sHTML = "<p>" then
      delete char 1 to 3 of sHTML
   end if
   if char -4 to -1 of sHTML = "</p>" then
      delete char -4 to -1 of sHTML
   end if
   */
   
   replace CR with empty in sHTML
   replace "<br/><br/>" with CR in sHTML
   replace ".</p><p>" with CR in sHTML
   --
   replace "</p>" with empty in sHTML
   --
   replace "<p/>" with CR in sHTML
   replace "<br/>" with CR in sHTML
   --
   put replaceText (sHTML, "<p[^>]*>", CR) into sHTML
   put replaceText (sHTML, "<br\b[^>]*>", CR) into sHTML
   put word 1 to -1 of sHTML into sHTML
end _HackCR

private command _AddArticleNode @pArray, treeID, aBodyNode, cName
   put aBodyNode & slash & cName into cNode
   put revXMLText (treeID, cNode) into sHTML
   
   switch
      case cName begins with "center[" -- center[1]
         # Is it an image?
         put _ListImageNodes (treeID, cNode) into imageNodes
         if imageNodes is empty then
            pageArray_AddHtml pArray, sHTML
         else
            _AddImage pArray, imageNodes, treeID, cNode
         end if
         break
      case cName begins with "p[" -- p[3]
         _HackCR sHTML
         if sHTML is not empty then
            pageArray_AddMarkdown pArray, sHTML
         end if
         break
      default
         _HackCR sHTML
         if sHTML is not empty then
            pageArray_AddHtml pArray, sHTML
         end if
   end switch
end _AddArticleNode

private command _AddImage @pArray, imageNodes, treeID, cNode
   repeat for each line imageNode in imageNodes
      put xmlTree_AttributeArrray (treeID, imageNode) into iArray
      put iArray ["src"] into imageUrl
      put iArray ["alt"] into imageAlt
      put iArray ["title"] into iTitle
      put iArray ["width"] into iWidth
      put iArray ["class"] into iClass
      --
      pageArray_AddImage pArray, imageURL, imageAlt, empty, empty, empty, "wide", iWidth
   end repeat
end _AddImage


--> Deps
-
