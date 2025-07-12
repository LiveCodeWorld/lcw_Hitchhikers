script "Global | Hitchhikers | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Hitchhikers | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Hitchhikers | Menu
-
on menu_Hitchhikers dView
   put h2g2_Content ("https://h2g2.com/entry/A88070231")
end menu_Hitchhikers

private on _
end _

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Hitchhikers | Menu")
end submenu_Dev
