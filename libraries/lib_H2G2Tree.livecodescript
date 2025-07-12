script "lib_H2G2Tree"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_H2G2Tree
type: library
version: 0.1

/*
A library to prcess H2G2.com content using the revXML library.
Unfortunately this library does not work with the wasm based web platform.
*/


--> Working on
-


--> H2G2 | Tree
-
function h2g2_FetchArticle sURL, pStartNode
   -- <div id="entry_wrapper">
   -- put html_ListNodes (someHTML)
   -- put "/html/body/div[3]/div/div[2]/div[2]/div[2]/div[1]/article" into sNode
   -- put "html[1]/body[1]/div[1]/div[1]/div[2]/div[1]/div[1]/div[2]/div[2]/div[1]/article[1]" into sNode
   
   # Create XML TreeID and Start Node
   put h2g2_Tree (sURL) into treeID
   put _StartNode (treeID) into startNode
   
   # Article Node
   put _TreeArticleNode (treeID, startNode) into articleNode
   
   # Title
   put _ArticleHeaderTitle (treeID, articleNode) into hTitle
   
   # Conversations
   put _ConversationNum (treeID, articleNode) into cNum
   
   # Date
   put _PubDate (treeID, articleNode) into pubDate
   put _PostDate (treeID, articleNode) into postDate
   
   # Images
   put _ListImageNodes (treeID, startNode) into imageNodes
   
   # Extract Html
   put revXMLText (treeID, articleNode) into articleXhtml
   --
   revXMLDeleteTree treeID
   return articleXhtml
end h2g2_FetchArticle

function h2g2_Tree sURL
   put url sURL into xHtml
   put revXMLCreateTree (xHtml, false, true, false) into treeID
   return treeID
end h2g2_Tree

function h2g2_ConstructEntryUrl aID
   -- A88070231
   put "https://h2g2.com/entry/" & aID into sURL
   return sURL
end h2g2_ConstructEntryUrl

function h2g2_Content sURL
   put h2g2_Tree (sURL) into treeID
   put revXMLRootNode (treeID) into startNode -- html
   put _TreeEntryContent (treeID, startNode) into contentXhtml
   revXMLDeleteTree treeID
   return contentXhtml
end h2g2_Content


--> Private | Tree
-
private function _TreeFetch sURL -- not used
   if matchText (sURL, "https://h2g2.com/entry/(.+)", aName) is false then
      return "Error, not h2g2.com:" && sURL
   end if
   
   # Create XML TreeID and Start Node
   put h2g2_Tree (sURL) into treeID
   if treeID is not a number then
      return "Error, cannot parse xhtml:" && treeID
   else
      put _TreeArticleArray (treeID) into pArray
      return pArray
   end if
end _TreeFetch

private function _TreeArticleArray treeID, aName
   put _StartNode (treeID) into startNode
   put pageArray_Construct (aName, empty) into pArray
   
   put _TreeArticleBodyNode (treeID, startNode) into aBodyNode
   if item 1 of aBodyNode is "xmlerror" then
      return "Error, cannot locate h2g2 content:" && sURL
   else
      put revXMLChildNames (treeID, aBodyNode, CR, empty, true) into cNames
      repeat for each line cName in cNames
         _AddArticleNode pArray, treeID, aBodyNode, cName
      end repeat
   end if
   --
   revXMLDeleteTree treeID
   return pArray
end _TreeArticleArray

private function _TreeEntryHeaderNode treeID, pStartNode   
   put "entry_content" into divID
   put revXMLMatchingNode (treeID, pStartNode, "div", "id", divID, -1) into sNode
   return sNode
end _TreeEntryHeaderNode

private function _ConversationNum treeID, pStartNode
   -- <a href="#conversations" class="conversations_link"><span class="conversation_icon"/>0 Conversations</a>
   put revXMLMatchingNode (treeID, pStartNode, "a", "class", "conversations_link", -1) into cNode
   put revXMLNodeContents (treeID, cNode) into cText -- 0 Conversations
   put word 1 of cText into convNum
   return convNum
end _ConversationNum

private function _ListImageNodes treeID, startNode
   --/html/head/meta/link[2]/body/div/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/article/div
   put _TreeEntryContentNode (treeID, startNode) into cNode
   put revXMLChildContents (treeID, cNode, empty, CR, "full", -1) into imageNodes
   filter imageNodes with "*/img"
   return imageNodes
end _ListImageNodes

private function _TreeEntryContent treeID, pStartNode
   put _TreeEntryContentNode (treeID, pStartNode) into sNode
   put revXMLText (treeID, sNode) into sContent
   return sContent
end _TreeEntryContent

private function _ArticleHeaderTitle treeID, articleNode
   put articleNode & "/header" into headerNode
   put headerNode & "/h1" into headerNode
   --
   put revXMLNodeContents (treeID, headerNode) into hTitle
   --
   return hTitle
end _ArticleHeaderTitle

private function _TreeArticleNode treeID, pStartNode
   -- put "/html/head/meta/link[2]/body/div/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]" into articleNode
   
   # Match Node
   put "entry_wrapper" into divID
   put revXMLMatchingNode (treeID, pStartNode, "div", "id", divID, -1) into articleNode
   put "/article[1]" after articleNode
   return articleNode
end _TreeArticleNode

private function _StartNode treeID
   -- put "head" into startNode
   put revXMLRootNode (treeID) into startNode
   return startNode
end _StartNode

private function _DateTimeNode treeID, pStartNode
   -- could be made more robust?
   put _DatePublishedNode (treeID, pStartNode) into paraNode
   put paraNode & "/span/time" into timeNode
   return timeNode
end _DateTimeNode

private function _DatePublishedNode treeID, pStartNode
   -- <p itemprop="datePublished" content="2025-06-30 16:38:38">
   -- /html/head/meta/link[2]/body/div/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/article/header/div/div[1]/p
   -- put _DateNode (treeID, pStartNode) into dateNode
   -- put dateNode & "/p[1]" into paraNode
   
   put revXMLMatchingNode (treeID, pStartNode, "p", "itemprop", "datePublished", -1) into paraNode
   return paraNode
end _DatePublishedNode

private function _DateNode treeID, pStartNode
   put revXMLMatchingNode (treeID, pStartNode, "div", "id", "entry_dates", -1) into dateNode
   return dateNode
end _DateNode

private function _PostDate treeID, pStartNode
   -- <time datetime="2025-06-25">2 Weeks Ago</time>
   put _DateTimeNode (treeID, pStartNode) into timeNode
   put revXMLAttribute (treeID, timeNode, "datetime") into postDate
   -- get revXMLNodeContents (treeID, timeNode) --"2 Weeks Ago"
   return postDate
end _PostDate

private function _PubDate treeID, pStartNode
   -- <p itemprop="datePublished" content="2025-06-30 16:38:38">
   put _DatePublishedNode (treeID, pStartNode) into pubNode
   put revXMLAttribute (treeID, pubNode, "content") into pubDate
   return pubDate
end _PubDate

function _TreeArticleBodyNode treeID, pStartNode
   -- #entry_content > span:nth-child(1) 
   put revXMLMatchingNode (treeID, pStartNode, "span", "itemprop", "articleBody", -1) into sNode
   return sNode
end _TreeArticleBodyNode

function _TreeEntryContentNode treeID, pStartNode
   -- /html/head/meta/link[2]/body/div/div[1]/div[2]/div[1]/div[2]/div[2]/div[1]/article/div
   
   put "entry_content" into divID
   put revXMLMatchingNode (treeID, pStartNode, "div", "id", divID, -1) into sNode
   return sNode
end _TreeEntryContentNode

--> Deps
-
