------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                            Copyright (C) 2007                            --
--                                 AdaCore                                  --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.          --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Ada.Strings.Unbounded;

with AWS.Messages;
with AWS.MIME;
with AWS.Response;
with AWS.Status;
with AWS.Templates;
with AWS.Services.ECWF.Context;

package AWS.Services.ECWF.Registry is

   use Ada.Strings.Unbounded;

   type Page is record
      Content      : Unbounded_String;
      --  Rendered page
      Content_Type : Unbounded_String;
      --  The page's content type
      Set          : Templates.Translate_Set;
      --  The translate set used to render the page
   end record;

   No_Page : constant Page;

   procedure Register
     (Key          : in String;
      Template     : in String;
      Data_CB      : access procedure
        (Request      : in     Status.Data;
         Context      : access ECWF.Context.Object;
         Translations : in out Templates.Translate_Set);
      Content_Type : in String := MIME.Text_HTML);
   --  Key is a Lazy_Tag or template page name. Template is the corresponding
   --  template file. Data_CB is the callback used to retrieve the translation
   --  table to render the page.

   procedure Register
     (Key          : in String;
      Template_CB  :  not null access function
        (Request : Status.Data) return String;
      Data_CB      : access procedure
        (Request      : in Status.Data;
         Context      : access ECWF.Context.Object;
         Translations : in out Templates.Translate_Set);
      Content_Type : in String := MIME.Text_HTML);
   --  Key is a Lazy_Tag or template page name. Template_CB is the
   --  callback used to retrieve is the corresponding template
   --  file. Data_CB is the callback used to retrieve the translation
   --  table to render the page.

   function Parse
     (Key          : in String;
      Request      : in Status.Data;
      Translations : in Templates.Translate_Set) return Page;
   --  Parse the Web page registered under Key

   function Build
     (Key           : in String;
      Request       : in Status.Data;
      Translations  : in Templates.Translate_Set;
      Status_Code   : in Messages.Status_Code := Messages.S200;
      Cache_Control : in Messages.Cache_Option := Messages.Unspecified)
      return Response.Data;
   --  Save as above but returns a standard Web page

private

   No_Page : constant Page :=
               (Null_Unbounded_String,
                Null_Unbounded_String,
                Templates.Null_Set);

end AWS.Services.ECWF.Registry;
